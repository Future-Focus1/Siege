class_name PerkRules
extends RefCounted

static func reload_scale(perk_id: String) -> float:
	match perk_id:
		"rapid_reload":
			return 0.80
		"siege_master":
			return 1.12
		_:
			return 1.0


static func damage_scale(perk_id: String) -> float:
	match perk_id:
		"siege_master":
			return 1.18
		"marksman":
			return 0.92
		_:
			return 1.0


static func aim_error_scale(perk_id: String) -> float:
	return 0.55 if perk_id == "marksman" else 1.0


static func launch_scale(perk_id: String) -> float:
	return 0.95 if perk_id == "rapid_reload" else 1.0


static func apply_to_piece(piece: StructuralPiece, perk_id: String) -> void:
	if piece == null:
		return
	if perk_id == "reinforced_foundations" and (piece.is_foundation or piece.touches_ground_row()):
		piece.max_durability *= 1.40
		piece.durability = piece.max_durability
		piece.mass *= 1.15
	elif perk_id == "lightweight_engineering" and piece.material_id == "wood":
		piece.mass *= 0.75
		piece.max_durability *= 0.88
		piece.durability = piece.max_durability


static func shield_capacity_scale(perk_id: String) -> float:
	return 1.35 if perk_id == "shield_specialist" else 1.0


static func shield_recharge_scale(perk_id: String) -> float:
	return 1.20 if perk_id == "shield_specialist" else 1.0


static func shield_radius_scale(perk_id: String) -> float:
	return 0.90 if perk_id == "shield_specialist" else 1.0
