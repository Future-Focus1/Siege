class_name ImpactFeedback
extends RefCounted

static var _slow_until := 0


static func burst(parent: Node, at: Vector2, color: Color, amount: int) -> void:
	if not _juice() or parent == null or not parent.is_inside_tree():
		return
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.amount = amount
	particles.explosiveness = 0.92
	particles.lifetime = 0.5
	particles.gravity = Vector2(0, 540)
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 240.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	particles.color = color
	particles.local_coords = false
	particles.z_index = 12
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	var timer := parent.get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)


static func major(camera: CameraRig) -> void:
	if camera:
		camera.add_shake(1.0)
	if not _juice():
		return
	Engine.time_scale = 0.32
	_slow_until = Time.get_ticks_msec() + 480


static func tick() -> void:
	if _slow_until > 0 and Time.get_ticks_msec() >= _slow_until:
		Engine.time_scale = 1.0
		_slow_until = 0


static func restore() -> void:
	Engine.time_scale = 1.0
	_slow_until = 0


static func _juice() -> bool:
	return Game.juice_enabled
