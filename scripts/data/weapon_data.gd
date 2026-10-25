class_name WeaponData
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var mass: float = 1.0
@export var damage_multiplier: float = 1.0
@export var impact_behavior: String = "heavy"
@export var reload_seconds: float = 6.0
@export var launch_speed: float = 1200.0
@export var cost: int = 1
@export var gravity_scale: float = 1.0
@export var knockback: float = 100.0
@export var projectile_radius: float = 12.0
@export var explosion_radius: float = 0.0
@export var explosion_impulse: float = 0.0
@export var explosion_damage: float = 0.0
@export var pierce_count: int = 0
@export var shield_drain: float = 20.0
@export var strengths: PackedStringArray = PackedStringArray()
@export var weaknesses: PackedStringArray = PackedStringArray()
