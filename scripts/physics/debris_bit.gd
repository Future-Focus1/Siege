class_name DebrisBit
extends RigidBody2D

var life := 5.5
var _prev_velocity := Vector2.ZERO


static func burst(parent: Node, color: Color, origin: Vector2, base_vel: Vector2, count: int) -> void:
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	Catalog.ensure()
	var room := Catalog.balance.max_debris - parent.get_tree().get_nodes_in_group("debris").size()
	var amount := mini(count, maxi(room, 0))
	for _i in amount:
		var bit := DebrisBit.new()
		var jitter := Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var vel := base_vel + Vector2(randf_range(-160, 160), randf_range(-220, -40))
		parent.add_child(bit)
		bit.setup(Vector2(16, 14), color, vel, origin + jitter)


func setup(size: Vector2, color: Color, vel: Vector2, pos: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	add_child(shape_node)
	var vis := Polygon2D.new()
	var h := size * 0.5
	vis.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)
	])
	vis.color = color
	add_child(vis)
	global_position = pos
	mass = 0.4
	gravity_scale = 1.0
	linear_velocity = vel
	_prev_velocity = vel
	angular_velocity = randf_range(-6.0, 6.0)
	collision_layer = 8
	collision_mask = 1 | 2
	continuous_cd = CCD_MODE_CAST_RAY
	contact_monitor = true
	max_contacts_reported = 3
	linear_damp_mode = DAMP_MODE_REPLACE
	angular_damp_mode = DAMP_MODE_REPLACE
	linear_damp = 0.35
	angular_damp = 1.2
	can_sleep = true
	add_to_group("debris")


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0 or global_position.y > SiegeGrid.GROUND_Y + 520.0:
		queue_free()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	ImpactDispatch.from_body(state, self, _prev_velocity, 0.55, 40.0, false)
	_prev_velocity = state.linear_velocity
