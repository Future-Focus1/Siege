class_name StructuralPiece
extends RigidBody2D

signal damaged(amount: float)
signal broke

var piece_id: String = ""
var material_id: String = ""
var grid_cells: Array[Vector2i] = []
var is_core := false
var is_foundation := false
var is_shield := false
var is_brace := false
var max_durability := 1.0
var durability := 1.0
var impact_resistance := 1.0
var explosion_resistance := 1.0
var compromised := false
var broken := false
var spawn_position := Vector2.ZERO
var last_impact := 0.0
var tracker := ContactTracker.new()

var _prev_velocity := Vector2.ZERO
var _pending_wake := false
var _pending_impulse := Vector2.ZERO
var _visual: Polygon2D
var _bar: Polygon2D
var _bar_width := 48.0


func configure(data: PieceData, material: MaterialData, cells: Array[Vector2i]) -> void:
	piece_id = String(data.id)
	material_id = String(material.id)
	grid_cells = cells
	is_core = data.is_core()
	is_foundation = data.is_foundation()
	is_shield = data.is_shield()
	is_brace = data.is_brace()
	impact_resistance = material.impact_resistance
	explosion_resistance = material.explosion_resistance
	var cell_count := maxi(cells.size(), 1)
	mass = maxf(0.25, float(cell_count) * material.density * data.mass_scale)
	max_durability = maxf(1.0, data.base_durability * material.durability_scale)
	durability = max_durability
	position = SiegeGrid.piece_center(cells)
	spawn_position = position
	gravity_scale = 1.0
	continuous_cd = CCD_MODE_CAST_RAY
	contact_monitor = true
	max_contacts_reported = 6
	can_sleep = true
	collision_layer = 2
	collision_mask = 1 | 2 | 4 | 8
	linear_damp_mode = DAMP_MODE_REPLACE
	angular_damp_mode = DAMP_MODE_REPLACE
	linear_damp = 0.2
	angular_damp = 1.4
	var phys := PhysicsMaterial.new()
	phys.friction = material.friction
	phys.bounce = material.bounce
	physics_material_override = phys
	freeze_mode = FREEZE_MODE_STATIC
	freeze = true
	_build_visual(data, material, cells)
	add_to_group("structural")


func provides_support(slip: float) -> bool:
	if broken:
		return false
	return global_position.distance_to(spawn_position) <= slip


func touches_ground_row() -> bool:
	for cell in grid_cells:
		if cell.y == 0:
			return true
	return false


func request_wake(impulse: Vector2) -> void:
	if broken:
		return
	_pending_wake = true
	_pending_impulse += impulse
	compromised = true


func receive_impact(
	from_id: int,
	rel_speed: float,
	energy: float,
	damage_scale: float,
	impulse: Vector2,
	explosive: bool
) -> float:
	if broken:
		return 0.0
	var speed := rel_speed if (explosive or rel_speed >= DamageModel.min_speed()) else 0.0
	if not tracker.consume(from_id, speed, Engine.get_physics_frames()):
		return 0.0
	var loss := DamageModel.durability_loss(
		energy, damage_scale, impact_resistance, explosive, explosion_resistance
	)
	if loss <= 0.0:
		return 0.0
	durability = maxf(0.0, durability - loss)
	last_impact = loss
	damaged.emit(loss)
	_flash()
	_update_bar()
	var plant := is_foundation and loss < max_durability * 0.2 and durability > max_durability * 0.72
	if not plant:
		request_wake(impulse)
	if durability <= 0.0:
		shatter()
	return loss


func shatter() -> void:
	if broken:
		return
	broken = true
	durability = 0.0
	_spawn_debris()
	broke.emit()
	queue_free()


func _physics_process(_delta: float) -> void:
	if broken:
		return
	tracker.end_step(Engine.get_physics_frames())
	if _pending_wake:
		_pending_wake = false
		freeze = false
		if _pending_impulse.length_squared() > 1.0:
			apply_central_impulse(_pending_impulse)
		_pending_impulse = Vector2.ZERO
	_prev_velocity = linear_velocity
	if Game.wants_debug():
		queue_redraw()


func _draw() -> void:
	if not Game.wants_debug():
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, Vector2(-20, 8), "%dkg %d" % [roundi(mass), roundi(durability)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.92))


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if freeze or broken:
		return
	ImpactDispatch.from_body(state, self, _prev_velocity, 0.85, 90.0, false)
	_prev_velocity = state.linear_velocity


func _build_visual(data: PieceData, material: MaterialData, cells: Array[Vector2i]) -> void:
	var size := SiegeGrid.bounds_size(cells) - Vector2(4, 4)
	var color := material.color
	if is_core:
		color = Color("e2b33a")
	if is_brace:
		var ends := _brace_delta(cells)
		var length := ends.length() + 18.0
		var angle := ends.angle()
		var col_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(maxf(length, 20.0), 16.0)
		col_shape.shape = rect
		col_shape.rotation = angle
		add_child(col_shape)
		_visual = _rect_poly(Vector2(maxf(length, 20.0), 16.0), color.lightened(0.08))
		_visual.rotation = angle
		add_child(_visual)
	else:
		var col_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		col_shape.shape = rect
		add_child(col_shape)
		var shadow := _rect_poly(size + Vector2(6, 6), color.darkened(0.35))
		add_child(shadow)
		_visual = _rect_poly(size - Vector2(8, 8), color)
		add_child(_visual)
		if is_core:
			var gem := Polygon2D.new()
			gem.polygon = PackedVector2Array([
				Vector2(0, -18), Vector2(14, 0), Vector2(0, 18), Vector2(-14, 0)
			])
			gem.color = Color("fff1c2")
			add_child(gem)
		elif is_foundation:
			var stripe := _rect_poly(Vector2(size.x * 0.7, 8), color.darkened(0.25))
			stripe.position = Vector2(0, size.y * 0.22)
			add_child(stripe)
	_bar_width = clampf(size.x, 28.0, 90.0)
	_bar = Polygon2D.new()
	_bar.color = Color("7dce73")
	_bar.position = Vector2(0, -size.y * 0.5 - 10.0)
	add_child(_bar)
	_update_bar()
	z_index = 3 if is_core else 1
	if data.kind == PieceData.Kind.SHIELD:
		z_index = 2


func _brace_delta(cells: Array[Vector2i]) -> Vector2:
	if cells.size() < 2:
		return Vector2(CELL_FALLBACK(), 0)
	return SiegeGrid.cell_center(cells[cells.size() - 1]) - SiegeGrid.cell_center(cells[0])


func CELL_FALLBACK() -> float:
	return float(SiegeGrid.CELL)


func _rect_poly(size: Vector2, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var h := size * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)
	])
	poly.color = color
	return poly


func _update_bar() -> void:
	if _bar == null:
		return
	var ratio := clampf(durability / max_durability, 0.0, 1.0)
	var w := _bar_width * ratio
	_bar.polygon = PackedVector2Array([
		Vector2(-_bar_width * 0.5, -3),
		Vector2(-_bar_width * 0.5 + w, -3),
		Vector2(-_bar_width * 0.5 + w, 3),
		Vector2(-_bar_width * 0.5, 3),
	])
	_bar.color = Color(1.0 - ratio, ratio, 0.25)


func _flash() -> void:
	if _visual == null or not is_inside_tree():
		return
	_visual.modulate = Color(2.2, 2.2, 2.2)
	var tw := create_tween()
	tw.tween_property(_visual, "modulate", Color.WHITE, 0.18)


func _spawn_debris() -> void:
	var parent := get_parent()
	if parent == null:
		return
	Catalog.ensure()
	var mat := Catalog.material(material_id)
	var color := mat.debris_color if mat else Color.GRAY
	var count := 2 if not is_core else 4
	# Spawning bodies inside a physics callback is illegal, so the bits arrive next idle frame.
	DebrisBit.burst.call_deferred(parent, color, global_position, linear_velocity, count)
