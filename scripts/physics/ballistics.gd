class_name Ballistics
extends RefCounted

## Semi-implicit Euler matching Godot's rigid body step when linear damp is zero:
## velocity += gravity * dt, then position += velocity * dt.


static func gravity_vector(gravity_scale: float = 1.0) -> Vector2:
	var g := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var dir: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	return dir * g * gravity_scale


static func step_dt() -> float:
	return 1.0 / float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))


static func simulate(origin: Vector2, velocity: Vector2, gravity_scale: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var pos := origin
	var vel := velocity
	var gravity := gravity_vector(gravity_scale)
	var dt := step_dt()
	points.append(pos)
	for _i in steps:
		vel += gravity * dt
		pos += vel * dt
		points.append(pos)
	return points
