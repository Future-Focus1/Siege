class_name CameraRig
extends Camera2D

var follow_target: Node2D
var home := Vector2(1060, 1000)
var shake := 0.0
var traveling := false
var _tween: Tween


func _init() -> void:
	# Entering the tree makes the camera current before _ready. Interpolation
	# must already be off, or Godot forces the physics tick and warns.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	position_smoothing_enabled = false


func _ready() -> void:
	global_position = home
	make_current()


func add_shake(amount: float) -> void:
	if not Game.allow_shake():
		return
	shake = maxf(shake, clampf(amount, 0.0, 1.0) * 28.0)


func travel_to(place: Vector2) -> void:
	home = place
	follow_target = null
	traveling = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", place, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(func() -> void: traveling = false)


func _process(delta: float) -> void:
	if traveling:
		_apply_shake(delta)
		return
	var goal := home
	if follow_target != null and is_instance_valid(follow_target):
		goal = follow_target.global_position + Vector2(-30, -140)
		goal.x = clampf(goal.x, home.x - 160.0, home.x + 240.0)
		goal.y = clampf(goal.y, home.y - 80.0, home.y + 120.0)
	var blend := 1.0 - exp(-delta * 4.5)
	global_position = global_position.lerp(goal, blend)
	_apply_shake(delta)


func _apply_shake(delta: float) -> void:
	if shake > 0.0:
		offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		shake = move_toward(shake, 0.0, delta * 60.0)
	else:
		offset = Vector2.ZERO
