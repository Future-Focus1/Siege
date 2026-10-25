class_name ShieldField
extends Node2D

var host: StructuralPiece
var energy := 100.0
var capacity := 100.0
var radius := 260.0
var recharge_rate := 6.0
var _flash := 0.0


func setup(piece: StructuralPiece, data: PieceData, perk_id: String) -> void:
	host = piece
	capacity = data.shield_capacity * PerkRules.shield_capacity_scale(perk_id)
	energy = capacity
	radius = data.shield_radius * PerkRules.shield_radius_scale(perk_id)
	recharge_rate = data.shield_recharge * PerkRules.shield_recharge_scale(perk_id)
	z_index = 4
	queue_redraw()


func recharge(virtual_seconds: float) -> void:
	if virtual_seconds <= 0.0 or host == null or not is_instance_valid(host) or host.broken:
		return
	energy = minf(capacity, energy + recharge_rate * virtual_seconds)
	queue_redraw()


func consider(projectile: Projectile) -> void:
	if energy <= 1.0 or projectile == null or not is_instance_valid(projectile):
		return
	if projectile.has_meta("shield_checked") and int(projectile.get_meta("shield_checked")) == get_instance_id():
		return
	if global_position.distance_to(projectile.global_position) > radius:
		return
	var drain := 20.0
	if projectile.weapon:
		drain = projectile.weapon.shield_drain
	var spent := minf(energy, drain)
	var ratio := spent / maxf(drain, 0.001)
	energy -= spent
	projectile.set_meta("shield_checked", get_instance_id())
	projectile.apply_shield(ratio)
	_flash = 0.25
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()
	if host == null or not is_instance_valid(host) or host.broken:
		queue_free()


func _draw() -> void:
	var ratio := clampf(energy / maxf(capacity, 1.0), 0.0, 1.0)
	var alpha := 0.10 + ratio * 0.18 + (_flash * 0.45)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.45, 0.85, 1.0, alpha), 6.0)
	draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU * ratio, 32, Color(0.7, 0.95, 1.0, 0.55), 4.0)
