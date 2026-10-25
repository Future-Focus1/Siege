class_name Arena
extends Node2D

signal core_lost
signal piece_damaged(piece: StructuralPiece, amount: float)
signal piece_broke(piece: StructuralPiece)

var pieces: Array[StructuralPiece] = []
var core: StructuralPiece
var _support_tick := 0.0
var _core_announced := false
const PIECE_SCENE := preload("res://scenes/pieces/structural_piece.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile.tscn")


func _ready() -> void:
	queue_redraw()


func build_ground() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 2 | 4 | 8
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(2600, 90)
	floor_shape.shape = floor_rect
	floor_shape.position = Vector2(SiegeGrid.ORIGIN_X + 180.0, SiegeGrid.GROUND_Y + 45.0)
	floor_body.add_child(floor_shape)
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	mat.bounce = 0.0
	floor_body.physics_material_override = mat
	add_child(floor_body)

	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 2 | 4 | 8
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(40, 900)
	wall_shape.shape = wall_rect
	wall_shape.position = Vector2(SiegeGrid.ORIGIN_X + SiegeGrid.COLS * SiegeGrid.CELL + 48.0, SiegeGrid.GROUND_Y - 420.0)
	wall.add_child(wall_shape)
	add_child(wall)


func spawn_layout(lines: PackedStringArray) -> void:
	for line in lines:
		var placement := Placement.parse(line)
		spawn_placement(placement)


func spawn_placement(placement: Placement) -> StructuralPiece:
	var data := Catalog.piece(placement.piece_id)
	var material := Catalog.material(placement.material_id)
	var cells := data.world_cells(placement.col, placement.row, placement.rot)
	var piece := PIECE_SCENE.instantiate() as StructuralPiece
	piece.configure(data, material, cells)
	piece.damaged.connect(_on_damaged.bind(piece))
	piece.broke.connect(_on_broke.bind(piece))
	add_child(piece)
	piece.spawn_position = piece.global_position
	pieces.append(piece)
	if piece.is_core:
		core = piece
	return piece


func launch(data: WeaponData, origin: Vector2, velocity: Vector2) -> Projectile:
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	add_child(projectile)
	projectile.global_position = origin
	projectile.arm(data, velocity)
	return projectile


func clear_dynamic() -> void:
	for node in get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("debris"):
		if is_instance_valid(node):
			node.queue_free()
	for piece in pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	pieces.clear()
	core = null
	_core_announced = false


func core_defeated() -> bool:
	if _core_announced:
		return true
	if core == null or not is_instance_valid(core):
		return true
	if core.broken or core.durability <= 0.0:
		return true
	Catalog.ensure()
	var limit := Catalog.balance.core_defeat_distance
	if core.global_position.distance_to(core.spawn_position) >= limit:
		return true
	if core.global_position.y > SiegeGrid.GROUND_Y + 24.0:
		return true
	return false


func is_quiet() -> bool:
	for piece in pieces:
		if not is_instance_valid(piece) or piece.freeze:
			continue
		if piece.linear_velocity.length() > 28.0 or absf(piece.angular_velocity) > 0.8:
			return false
	for node in get_tree().get_nodes_in_group("projectile"):
		if node is RigidBody2D and (node as RigidBody2D).linear_velocity.length() > 40.0:
			return false
	for node in get_tree().get_nodes_in_group("debris"):
		if node is RigidBody2D and (node as RigidBody2D).linear_velocity.length() > 36.0:
			return false
	return true


func intact_ratio() -> float:
	if pieces.is_empty():
		return 0.0
	var alive := 0
	for piece in pieces:
		if is_instance_valid(piece) and not piece.broken and piece.durability > 0.0:
			alive += 1
	return float(alive) / float(pieces.size())


func _physics_process(delta: float) -> void:
	_support_tick += delta
	if _support_tick >= 0.12:
		_support_tick = 0.0
		refresh_support()
	if core_defeated() and not _core_announced:
		_core_announced = true
		core_lost.emit()


func _on_damaged(amount: float, piece: StructuralPiece) -> void:
	piece_damaged.emit(piece, amount)
	for neighbor in _neighbors_of(piece):
		if neighbor.is_foundation and amount < neighbor.max_durability * 0.22:
			continue
		if neighbor.freeze:
			neighbor.request_wake(Vector2.ZERO)
	refresh_support()


func _on_broke(piece: StructuralPiece) -> void:
	var neighbors := _neighbors_of(piece)
	pieces.erase(piece)
	if piece == core:
		core = null
	for neighbor in neighbors:
		if neighbor.is_foundation:
			continue
		neighbor.request_wake(Vector2.ZERO)
	refresh_support()
	piece_broke.emit(piece)
	if piece.is_core and not _core_announced:
		_core_announced = true
		core_lost.emit()


func refresh_support() -> void:
	Catalog.ensure()
	var slip := Catalog.balance.support_slip_distance
	var alive: Array[StructuralPiece] = []
	for piece in pieces:
		if is_instance_valid(piece) and not piece.broken:
			alive.append(piece)
	var supporters: Array[StructuralPiece] = []
	for piece in alive:
		if piece.provides_support(slip):
			supporters.append(piece)
	var supported: Dictionary = {}
	var queue: Array[StructuralPiece] = []
	for piece in supporters:
		if piece.touches_ground_row():
			supported[piece.get_instance_id()] = true
			queue.append(piece)
	var guard := 0
	while not queue.is_empty() and guard < 400:
		guard += 1
		var current: StructuralPiece = queue.pop_front()
		for neighbor in _neighbors_of(current):
			if not neighbor.provides_support(slip):
				continue
			var id := neighbor.get_instance_id()
			if supported.has(id):
				continue
			supported[id] = true
			queue.append(neighbor)
	for piece in alive:
		if not supported.has(piece.get_instance_id()):
			piece.request_wake(Vector2.ZERO)


func _neighbors_of(piece: StructuralPiece) -> Array[StructuralPiece]:
	var out: Array[StructuralPiece] = []
	for other in pieces:
		if other == piece or not is_instance_valid(other) or other.broken:
			continue
		if _cells_touch(piece.grid_cells, other.grid_cells):
			out.append(other)
	return out


func _cells_touch(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
	for ca in a:
		for cb in b:
			if absi(ca.x - cb.x) + absi(ca.y - cb.y) == 1:
				return true
	return false


func _draw() -> void:
	draw_rect(Rect2(-600, -400, 3400, 2600), Color("8ec6ea"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-400, SiegeGrid.GROUND_Y - 40),
		Vector2(500, SiegeGrid.GROUND_Y - 230),
		Vector2(980, SiegeGrid.GROUND_Y - 20),
	]), Color("9ccc74"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(700, SiegeGrid.GROUND_Y - 10),
		Vector2(1300, SiegeGrid.GROUND_Y - 160),
		Vector2(1900, SiegeGrid.GROUND_Y - 10),
	]), Color("7eae62"))
	draw_rect(Rect2(-600, SiegeGrid.GROUND_Y, 3400, 900), Color("6f8f4e"))
	draw_rect(Rect2(-600, SiegeGrid.GROUND_Y, 3400, 18), Color("8b6a43"))
	var left := SiegeGrid.ORIGIN_X
	var bottom := SiegeGrid.GROUND_Y
	var width := float(SiegeGrid.COLS * SiegeGrid.CELL)
	var height := float(SiegeGrid.ROWS * SiegeGrid.CELL)
	draw_rect(Rect2(left, bottom - height, width, height), Color(1, 1, 1, 0.04), false, 3.0)
