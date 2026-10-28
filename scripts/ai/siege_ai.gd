class_name SiegeAi
extends RefCounted

static func pick_weapon(options: Array[WeaponData], arena: Arena, difficulty: String) -> WeaponData:
	if options.is_empty():
		return null
	if difficulty == "easy":
		for weapon in options:
			if String(weapon.impact_behavior) == "pierce":
				return weapon
		return options[0]
	var wood := 0
	var heavy := 0
	var core_exposed := false
	for piece in arena.pieces:
		if not is_instance_valid(piece) or piece.broken:
			continue
		if piece.material_id == "wood":
			wood += 1
		if piece.material_id == "stone" or piece.material_id == "metal":
			heavy += 1
		if piece.is_core and _blockers_toward_core(arena, piece) <= 1:
			core_exposed = true
	if difficulty == "hard" and core_exposed:
		for weapon in options:
			if String(weapon.impact_behavior) == "pierce":
				return weapon
	if wood >= heavy and wood >= 4:
		for weapon in options:
			if String(weapon.impact_behavior) == "explosive":
				return weapon
	for weapon in options:
		if String(weapon.impact_behavior) == "heavy":
			return weapon
	return options[0]


static func aim(origin: Vector2, weapon: WeaponData, arena: Arena, difficulty: String, perk_id: String) -> Dictionary:
	var best_score := -1.0e12
	var best := {"angle": 42.0, "power": 0.8}
	var step := 6.0
	var powers: Array[float] = [0.7, 0.95]
	match difficulty:
		"easy":
			step = 12.0
			powers = [0.7, 0.9]
		"hard":
			step = 3.0
			powers = [0.5, 0.65, 0.8, 1.0]
		_:
			step = 6.0
			powers = [0.55, 0.75, 0.95]
	var angle := 16.0
	while angle <= 74.0:
		for power in powers:
			var score := _score_shot(origin, angle, power, weapon, arena, difficulty)
			if score > best_score:
				best_score = score
				best = {"angle": angle, "power": power}
		angle += step
	var error := 6.0
	match difficulty:
		"easy":
			error = 12.0
		"hard":
			error = 2.2
	error *= PerkRules.aim_error_scale(perk_id)
	best["angle"] = clampf(float(best["angle"]) + randf_range(-error, error), 12.0, 78.0)
	best["power"] = clampf(float(best["power"]) + randf_range(-error, error) / 55.0, 0.35, 1.0)
	return best


static func _score_shot(origin: Vector2, angle: float, power: float, weapon: WeaponData, arena: Arena, difficulty: String) -> float:
	var points := _arc(origin, angle, power, weapon)
	var centroid := _centroid(arena)
	var closest_tower := _closest(points, centroid)
	if difficulty == "easy":
		return -closest_tower
	var score := -closest_tower * 0.15
	for piece in arena.pieces:
		if not is_instance_valid(piece) or piece.broken:
			continue
		var distance := _closest(points, piece.global_position)
		if distance > 90.0:
			continue
		var hit := 36.0 - distance * 0.25
		if piece.is_core:
			hit += 90.0
		elif piece.material_id == "wood":
			hit += 16.0
		elif piece.is_shield:
			hit += 22.0 if weapon.impact_behavior != "heavy" else 8.0
		if weapon.impact_behavior == "explosive":
			hit += _neighbors(arena, piece) * 4.0
		score += hit
	return score


static func _arc(origin: Vector2, angle: float, power: float, weapon: WeaponData) -> PackedVector2Array:
	var rad := deg_to_rad(angle)
	var direction := Vector2(cos(rad), -sin(rad))
	var speed := weapon.launch_speed * lerpf(0.52, 1.0, power)
	return Ballistics.simulate(origin, direction * speed, weapon.gravity_scale, 80)


static func _closest(points: PackedVector2Array, target: Vector2) -> float:
	var best := 1.0e12
	for point in points:
		best = minf(best, point.distance_to(target))
	return best


static func _centroid(arena: Arena) -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for piece in arena.pieces:
		if is_instance_valid(piece) and not piece.broken:
			sum += piece.global_position
			count += 1
	if count == 0:
		return Vector2(SiegeGrid.ORIGIN_X + 200.0, SiegeGrid.GROUND_Y - 200.0) + arena.global_position
	return sum / float(count)


static func _neighbors(arena: Arena, piece: StructuralPiece) -> int:
	var count := 0
	for other in arena.pieces:
		if other == piece or not is_instance_valid(other):
			continue
		if piece.global_position.distance_to(other.global_position) < 150.0:
			count += 1
	return count


static func _blockers_toward_core(arena: Arena, core: StructuralPiece) -> int:
	var origin := arena.to_global(Vector2(620, SiegeGrid.GROUND_Y - 200))
	var query := PhysicsRayQueryParameters2D.create(origin, core.global_position, 2)
	var hit := arena.get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 0
	var collider: Object = hit.get("collider")
	if collider == core:
		return 0
	return 2
