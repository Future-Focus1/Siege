class_name ImpactDispatch
extends RefCounted

static func from_body(
	state: PhysicsDirectBodyState2D,
	self_body: RigidBody2D,
	prev_velocity: Vector2,
	damage_scale: float,
	knock_scale: float,
	explosive: bool
) -> void:
	var seen := {}
	var my_vel := prev_velocity
	if state.linear_velocity.length() > my_vel.length():
		my_vel = state.linear_velocity
	for i in state.get_contact_count():
		var other := state.get_contact_collider_object(i)
		if not (other is StructuralPiece):
			continue
		var piece := other as StructuralPiece
		if piece.broken:
			continue
		var id := piece.get_instance_id()
		if seen.has(id):
			continue
		seen[id] = true
		var normal: Vector2 = state.get_contact_local_normal(i)
		var other_vel := Vector2.ZERO
		if not piece.freeze:
			other_vel = piece.linear_velocity
		var rel := my_vel - other_vel
		var into := absf(rel.dot(normal))
		var other_mass := maxf(piece.mass, 0.2)
		var energy := DamageModel.impact_energy(maxf(self_body.mass, 0.05), other_mass, into)
		var dir := piece.global_position - self_body.global_position
		if dir.length_squared() < 1.0:
			dir = -normal if normal.length_squared() > 0.001 else Vector2.RIGHT
		dir = dir.normalized()
		var mass_bias := clampf(6.0 / other_mass, 0.25, 3.0)
		piece.receive_impact(self_body.get_instance_id(), into, energy, damage_scale, dir * knock_scale * mass_bias, explosive)
