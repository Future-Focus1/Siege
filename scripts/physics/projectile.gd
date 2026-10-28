class_name Projectile
extends RigidBody2D

var weapon: WeaponData
var touched := false
var _prev_velocity := Vector2.ZERO
var _behavior := "heavy"
var _damage_scale := 1.0
var _knock := 100.0
var _pierces_left := 0
var _exploded := false
var _shielded := false
var _life := 8.0
var _visual: Polygon2D


func _ready() -> void:
	add_to_group("projectile")
	continuous_cd = CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 4
	can_sleep = false
	collision_layer = 4
	collision_mask = 1 | 2 | 8
	linear_damp_mode = DAMP_MODE_REPLACE
	angular_damp_mode = DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = 0.0
	gravity_scale = 1.0


func arm(data: WeaponData, velocity: Vector2) -> void:
	weapon = data
	_behavior = data.impact_behavior
	_damage_scale = data.damage_multiplier
	_knock = data.knockback
	_pierces_left = data.pierce_count
	mass = data.mass
	gravity_scale = data.gravity_scale
	linear_velocity = velocity
	_prev_velocity = velocity
	var phys := PhysicsMaterial.new()
	phys.friction = 0.4
	phys.bounce = 0.18 if _behavior == "pierce" else 0.04
	physics_material_override = phys
	_build_visual(data.projectile_radius)


func _build_visual(radius: float) -> void:
	if _visual:
		_visual.queue_free()
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape_node.shape = circle
	add_child(shape_node)
	_visual = Polygon2D.new()
	var pts := PackedVector2Array()
	var n := 14
	for i in n:
		var a := TAU * float(i) / float(n)
		var r := radius
		if _behavior == "pierce" and i % 2 == 0:
			r *= 0.72
		pts.append(Vector2(cos(a), sin(a)) * r)
	_visual.polygon = pts
	match _behavior:
		"explosive":
			_visual.color = Color("e25b2a")
		"pierce":
			_visual.color = Color("d7e4ee")
		_:
			_visual.color = Color("6e727a")
	add_child(_visual)
	if _behavior == "pierce":
		_visual.rotation = _prev_velocity.angle()


func scale_damage(multiplier: float) -> void:
	_damage_scale *= multiplier


func apply_shield(ratio: float) -> void:
	if _shielded or weapon == null:
		return
	_shielded = true
	match _behavior:
		"heavy":
			if ratio > 0.75:
				_damage_scale *= 0.25
				linear_velocity *= 0.20
			else:
				_damage_scale *= 1.0 - 0.50 * ratio
				linear_velocity *= 1.0 - 0.35 * ratio
			_prev_velocity = linear_velocity
		"explosive":
			if ratio > 0.30 and not _exploded:
				_exploded = true
				call_deferred("_boom", global_position)
		"pierce":
			_damage_scale *= 1.0 - 0.15 * ratio
			linear_velocity *= 1.0 - 0.12 * ratio
			_prev_velocity = linear_velocity
		_:
			_damage_scale *= 1.0 - 0.30 * ratio
			linear_velocity *= 1.0 - 0.25 * ratio
			_prev_velocity = linear_velocity


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 or global_position.y > SiegeGrid.GROUND_Y + 700.0:
		queue_free()
	if _visual and _behavior == "pierce":
		_visual.rotation = linear_velocity.angle()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		touched = true
	var approach := _prev_velocity
	if state.linear_velocity.length() > approach.length():
		approach = state.linear_velocity
	ImpactDispatch.from_body(state, self, _prev_velocity, _damage_scale, _knock, false)
	if _behavior == "pierce":
		_keep_piercing(state, approach)
	elif _behavior == "explosive" and touched and not _exploded:
		_exploded = true
		var at := global_position
		call_deferred("_boom", at)
	_prev_velocity = state.linear_velocity


func _keep_piercing(state: PhysicsDirectBodyState2D, approach: Vector2) -> void:
	if _pierces_left <= 0 or approach.length() < 200.0:
		return
	for i in state.get_contact_count():
		var other := state.get_contact_collider_object(i)
		if not (other is StructuralPiece):
			continue
		var piece := other as StructuralPiece
		var heavy := piece.material_id == "metal" or (piece.material_id == "stone" and piece.mass >= 3.0)
		if heavy or piece.is_foundation or piece.is_core:
			_pierces_left = 0
			return
		add_collision_exception_with(piece)
		_pierces_left -= 1
		var speed := maxf(approach.length() * 0.9, 240.0)
		state.linear_velocity = approach.normalized() * speed
		_prev_velocity = state.linear_velocity
		return


func _boom(at: Vector2) -> void:
	if weapon == null:
		queue_free()
		return
	var parent := get_parent()
	if parent:
		Explosion.detonate(
			parent,
			at,
			weapon.explosion_radius,
			weapon.explosion_impulse,
			weapon.explosion_damage,
			weapon.damage_multiplier,
			self
		)
		ImpactFeedback.burst(parent, at, Color("ffb15a"), 22)
	queue_free()
