class_name Catapult
extends Node2D

signal fired(origin: Vector2, velocity: Vector2)
signal aim_changed(angle_degrees: float, power: float)

const MAX_PULL := 340.0
const MIN_POWER := 0.18

var weapon: WeaponData
var enabled := true
var aiming := false
var power := 0.0
var angle_degrees := 58.0
var launch_dir := Vector2.RIGHT

var _arm: Polygon2D
var _trajectory: Line2D
var _block_mouse_until := 0


func _ready() -> void:
	z_index = 6
	launch_dir = Vector2(cos(deg_to_rad(angle_degrees)), -sin(deg_to_rad(angle_degrees)))
	_build()
	_apply_arm()


func set_weapon(data: WeaponData) -> void:
	weapon = data


func set_aim_enabled(on: bool) -> void:
	enabled = on
	if not on:
		aiming = false


func muzzle_global() -> Vector2:
	return _arm.to_global(Vector2(96, 0))


func compute_shot() -> Dictionary:
	var speed := weapon.launch_speed * lerpf(0.52, 1.0, power)
	return {
		"origin": muzzle_global(),
		"velocity": launch_dir * speed,
	}


func _build() -> void:
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-50, 42), Vector2(58, 42), Vector2(36, -4), Vector2(-30, -4)
	])
	base.color = Color("6d4b33")
	add_child(base)
	var brace := Polygon2D.new()
	brace.polygon = PackedVector2Array([
		Vector2(-8, 8), Vector2(24, -30), Vector2(36, -18), Vector2(4, 14)
	])
	brace.color = Color("8a8e96")
	add_child(brace)
	_arm = Polygon2D.new()
	_arm.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(96, -8), Vector2(96, 8), Vector2(0, 8)
	])
	_arm.color = Color("c4844a")
	add_child(_arm)
	var cup := Polygon2D.new()
	cup.position = Vector2(96, 0)
	cup.polygon = PackedVector2Array([
		Vector2(-8, -18), Vector2(16, -12), Vector2(16, 12), Vector2(-8, 18)
	])
	cup.color = Color("4e545c")
	_arm.add_child(cup)
	_trajectory = Line2D.new()
	_trajectory.width = 10.0
	_trajectory.default_color = Color(1, 0.96, 0.84, 0.92)
	_trajectory.joint_mode = Line2D.LINE_JOINT_ROUND
	_trajectory.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trajectory.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trajectory.visible = false
	add_child(_trajectory)


func _apply_arm() -> void:
	_arm.rotation = launch_dir.angle()
	_arm.position = -launch_dir * power * 28.0
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or weapon == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_block_mouse_until = Time.get_ticks_msec() + 120
		if touch.pressed:
			aiming = true
			_drag(touch.position)
		elif aiming:
			aiming = false
			_release()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and aiming:
		_block_mouse_until = Time.get_ticks_msec() + 120
		_drag((event as InputEventScreenDrag).position)
		get_viewport().set_input_as_handled()
	elif Time.get_ticks_msec() < _block_mouse_until:
		return
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			aiming = true
			_drag(mouse.position)
		elif aiming:
			aiming = false
			_release()
	elif event is InputEventMouseMotion and aiming:
		if event.button_mask & MOUSE_BUTTON_LEFT:
			_drag(event.position)


func _drag(screen_pos: Vector2) -> void:
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var axle := to_global(Vector2(18, -6))
	var pull := axle - world
	if pull.length() < 12.0:
		power = 0.0
		_trajectory.visible = false
		_apply_arm()
		aim_changed.emit(angle_degrees, power)
		return
	var angle_up := rad_to_deg(atan2(-pull.y, pull.x))
	angle_degrees = clampf(angle_up, 12.0, 78.0)
	var rad := deg_to_rad(angle_degrees)
	launch_dir = Vector2(cos(rad), -sin(rad))
	power = clampf(pull.length() / MAX_PULL, 0.0, 1.0)
	_apply_arm()
	_update_trajectory()
	aim_changed.emit(angle_degrees, power)


func _release() -> void:
	if weapon == null or power < MIN_POWER:
		power = 0.0
		_arm.position = Vector2.ZERO
		_trajectory.visible = false
		aim_changed.emit(angle_degrees, 0.0)
		return
	var shot := compute_shot()
	_update_trajectory()
	fired.emit(shot.origin, shot.velocity)
	var tw := create_tween()
	tw.tween_property(_arm, "position", Vector2.ZERO, 0.1)


func _update_trajectory() -> void:
	if weapon == null or power < 0.04:
		_trajectory.visible = false
		return
	var shot := compute_shot()
	var points := Ballistics.simulate(shot.origin, shot.velocity, weapon.gravity_scale, 70)
	var local := PackedVector2Array()
	var step := 2
	for i in points.size():
		if i % step == 0:
			local.append(to_local(points[i]))
	_trajectory.points = local
	_trajectory.visible = local.size() >= 2


func _draw() -> void:
	if aiming and power > 0.04:
		draw_line(Vector2(18, -6), to_local(muzzle_global()), Color(0.95, 0.9, 0.75, 0.8), 4.0)
