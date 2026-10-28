class_name Explosion
extends RefCounted

static func detonate(parent: Node, origin: Vector2, radius: float, impulse: float, energy: float, damage_scale: float, source: Node) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var space: PhysicsDirectSpaceState2D = parent.get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = radius
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, origin)
	params.collision_mask = 2 | 8
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hits: Array = space.intersect_shape(params, 48)
	var seen := {}
	var source_id := source.get_instance_id() if source else -900001
	for hit in hits:
		var body: Object = hit.collider
		if body == null or seen.has(body):
			continue
		if source != null and body == source:
			continue
		seen[body] = true
		if not (body is RigidBody2D):
			continue
		var rigid := body as RigidBody2D
		var offset := rigid.global_position - origin
		var dist := offset.length()
		var falloff := clampf(1.0 - dist / maxf(radius, 1.0), 0.0, 1.0)
		falloff *= falloff
		if falloff <= 0.001:
			continue
		var dir := offset.normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		if rigid.has_method("request_wake"):
			rigid.request_wake(Vector2.ZERO)
		rigid.apply_central_impulse(dir * impulse * falloff)
		if rigid.has_method("receive_impact"):
			rigid.receive_impact(source_id, DamageModel.min_speed() + 50.0, energy * falloff, damage_scale, dir * impulse * falloff * 0.15, true)
	_ring(parent, origin, radius)


static func _ring(parent: Node, origin: Vector2, radius: float) -> void:
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	var steps := 18
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(Vector2(cos(a), sin(a)) * 12.0)
	ring.polygon = pts
	ring.color = Color(1.0, 0.55, 0.18, 0.85)
	ring.z_index = 8
	parent.add_child(ring)
	ring.global_position = origin
	var tw := parent.create_tween()
	tw.tween_property(ring, "scale", Vector2.ONE * (radius / 12.0), 0.22)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.28)
	tw.finished.connect(ring.queue_free)
