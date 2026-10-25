class_name CameraRig
extends Camera2D

var follow_target: Node2D
var home := Vector2(1060, 1000)
var shake := 0.0


func _ready() -> void:
	make_current()
	global_position = home
	position_smoothing_enabled = false
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func add_shake(amount: float) -> void:
	shake = maxf(shake, clampf(amount, 0.0, 1.0) * 28.0)


func _process(delta: float) -> void:
	var goal := home
	if follow_target != null and is_instance_valid(follow_target):
		goal = follow_target.global_position + Vector2(-30, -140)
		goal.x = clampf(goal.x, 900.0, 1280.0)
		goal.y = clampf(goal.y, 860.0, 1120.0)
	var blend := 1.0 - exp(-delta * 4.5)
	global_position = global_position.lerp(goal, blend)
	if shake > 0.0:
		offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		shake = move_toward(shake, 0.0, delta * 60.0)
	else:
		offset = Vector2.ZERO
