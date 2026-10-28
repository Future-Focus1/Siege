class_name Layouts
extends RefCounted

static func get_layout(id: String) -> PackedStringArray:
	match id:
		"homestead":
			return homestead()
		"timber_outpost":
			return DemoLayout.timber_outpost()
		"stone_gate":
			return stone_gate()
		"packed_granary":
			return packed_granary()
		"shielded_keep":
			return shielded_keep()
		"iron_bastion":
			return iron_bastion()
		_:
			return PackedStringArray()


static func homestead() -> PackedStringArray:
	return PackedStringArray([
		"foundation_anchor,stone,1,0,0",
		"foundation_anchor,stone,4,0,0",
		"vertical_pillar,wood,1,1,0",
		"vertical_pillar,wood,5,1,0",
		"small_block,wood,5,4,0",
		"horizontal_beam,wood,1,4,0",
		"diagonal_brace,wood,2,1,0",
		"keep_core,core,2,5,0",
		"small_block,stone,1,5,0",
		"small_block,stone,4,5,0",
		"small_block,wood,2,7,0",
		"small_block,wood,3,7,0",
		"large_block,stone,6,0,0",
	])


static func stone_gate() -> PackedStringArray:
	return PackedStringArray([
		"foundation_anchor,stone,2,0,0",
		"foundation_anchor,stone,5,0,0",
		"large_block,stone,0,0,0",
		"vertical_pillar,stone,2,1,0",
		"vertical_pillar,stone,6,1,0",
		"small_block,stone,5,3,0",
		"horizontal_beam,stone,2,4,0",
		"keep_core,core,3,5,0",
		"small_block,stone,2,5,0",
		"small_block,stone,2,6,0",
		"small_block,stone,5,5,0",
		"small_block,wood,3,7,0",
		"small_block,wood,4,7,0",
	])


static func packed_granary() -> PackedStringArray:
	return PackedStringArray([
		"foundation_anchor,stone,1,0,0",
		"foundation_anchor,stone,4,0,0",
		"small_block,wood,0,0,0",
		"small_block,wood,0,1,0",
		"small_block,wood,0,2,0",
		"small_block,wood,3,1,0",
		"small_block,wood,3,2,0",
		"small_block,wood,6,1,0",
		"small_block,wood,6,2,0",
		"small_block,wood,7,0,0",
		"small_block,wood,7,1,0",
		"horizontal_beam,wood,0,3,0",
		"horizontal_beam,wood,4,3,0",
		"small_block,wood,0,4,0",
		"small_block,wood,1,4,0",
		"small_block,wood,2,4,0",
		"small_block,wood,5,4,0",
		"small_block,wood,6,4,0",
		"keep_core,core,2,5,0",
		"small_block,wood,1,5,0",
		"small_block,wood,4,5,0",
		"small_block,wood,1,6,0",
		"small_block,wood,4,6,0",
		"small_block,stone,2,7,0",
		"small_block,stone,3,7,0",
	])


static func shielded_keep() -> PackedStringArray:
	return PackedStringArray([
		"foundation_anchor,stone,0,0,0",
		"foundation_anchor,stone,3,0,0",
		"foundation_anchor,stone,5,0,0",
		"small_block,stone,0,1,0",
		"small_block,stone,1,1,0",
		"shield_generator,metal,0,2,0",
		"vertical_pillar,stone,3,1,0",
		"vertical_pillar,stone,6,1,0",
		"small_block,stone,5,3,0",
		"horizontal_beam,stone,3,4,0",
		"keep_core,core,4,5,0",
		"small_block,stone,3,5,0",
		"small_block,wood,4,7,0",
		"small_block,wood,5,7,0",
	])


static func iron_bastion() -> PackedStringArray:
	return PackedStringArray([
		"foundation_anchor,metal,1,0,0",
		"foundation_anchor,stone,4,0,0",
		"vertical_pillar,stone,1,1,0",
		"vertical_pillar,stone,5,1,0",
		"reinforced_beam,metal,1,4,0",
		"small_block,metal,5,4,0",
		"keep_core,core,2,5,0",
		"small_block,stone,1,5,0",
		"small_block,stone,6,1,0",
		"small_block,stone,7,1,0",
		"shield_generator,metal,6,2,0",
	])
