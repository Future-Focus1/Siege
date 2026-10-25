class_name DamageModel
extends RefCounted

static func _balance() -> BalanceConfig:
	Catalog.ensure()
	return Catalog.balance


static func min_speed() -> float:
	return _balance().min_rel_speed


static func impact_energy(mass_a: float, mass_b: float, rel_speed: float) -> float:
	if rel_speed < min_speed():
		return 0.0
	var reduced := mass_a
	if mass_b > 0.001:
		reduced = (mass_a * mass_b) / (mass_a + mass_b)
	return 0.5 * reduced * rel_speed * rel_speed


static func durability_loss(
	energy: float,
	damage_scale: float,
	impact_resistance: float,
	explosive: bool,
	explosion_resistance: float
) -> float:
	var rules := _balance()
	if energy < rules.min_energy:
		return 0.0
	var resist := explosion_resistance if explosive else impact_resistance
	resist = maxf(resist, 0.2)
	return energy / rules.energy_divisor * damage_scale / resist
