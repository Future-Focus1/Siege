class_name PieceData
extends Resource

enum Kind { BLOCK, BEAM, PILLAR, BRACE, REINFORCED, FOUNDATION, SHIELD, CORE }

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var kind: Kind = Kind.BLOCK
@export var base_cost: int = 4
@export var fixed_cost: int = 0
@export var base_durability: float = 80.0
@export var mass_scale: float = 1.0
@export var cells: PackedInt32Array = PackedInt32Array()
@export var allowed_materials: PackedStringArray = PackedStringArray()
@export var shield_radius: float = 0.0
@export var shield_capacity: float = 0.0
@export var shield_recharge: float = 0.0
@export var max_count: int = 60


func allows(material_id: String) -> bool:
	if allowed_materials.is_empty():
		return true
	return allowed_materials.has(material_id)


func cost_for(material: MaterialData) -> int:
	if fixed_cost > 0:
		return fixed_cost
	return maxi(1, roundi(float(base_cost) * material.cost_scale))


func rotated_cells(quarter: int) -> Array[Vector2i]:
	var pts: Array[Vector2i] = []
	for i in range(0, cells.size(), 2):
		pts.append(Vector2i(cells[i], cells[i + 1]))
	var turns := posmod(quarter, 4)
	for _t in turns:
		var next: Array[Vector2i] = []
		for c in pts:
			next.append(Vector2i(c.y, -c.x))
		pts = next
	if pts.is_empty():
		return pts
	var min_x := pts[0].x
	var min_y := pts[0].y
	for c in pts:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
	var out: Array[Vector2i] = []
	for c in pts:
		out.append(Vector2i(c.x - min_x, c.y - min_y))
	return out


func world_cells(col: int, row: int, quarter: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in rotated_cells(quarter):
		out.append(Vector2i(col + c.x, row + c.y))
	return out


func is_brace() -> bool:
	return kind == Kind.BRACE


func is_foundation() -> bool:
	return kind == Kind.FOUNDATION


func is_core() -> bool:
	return kind == Kind.CORE


func is_shield() -> bool:
	return kind == Kind.SHIELD
