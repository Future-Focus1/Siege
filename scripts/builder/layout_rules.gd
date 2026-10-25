class_name LayoutRules
extends RefCounted

## Grid legality shared by the builder, saves, and tests.
## Overlap and bounds live here so a tampered save cannot sneak an illegal layout through.


static func cell_errors(lines: PackedStringArray) -> PackedStringArray:
	Catalog.ensure()
	var errors := PackedStringArray()
	var occupied := {}
	for line in lines:
		if String(line).strip_edges().is_empty():
			continue
		var placement := Placement.parse(line)
		var data := Catalog.piece(placement.piece_id)
		if data == null:
			errors.append("unknown piece %s" % placement.piece_id)
			continue
		var material := Catalog.material(placement.material_id)
		if material == null:
			errors.append("unknown material %s" % placement.material_id)
			continue
		if not data.allows(placement.material_id):
			errors.append("%s cannot use %s" % [placement.piece_id, placement.material_id])
		var cells := data.world_cells(placement.col, placement.row, placement.rot)
		for cell in cells:
			if cell.x < 0 or cell.y < 0 or cell.x >= SiegeGrid.COLS or cell.y >= SiegeGrid.ROWS:
				errors.append("out of bounds %s at %d,%d" % [placement.piece_id, cell.x, cell.y])
				continue
			var key := "%d,%d" % [cell.x, cell.y]
			if occupied.has(key):
				errors.append("overlap at %s" % key)
			occupied[key] = placement.piece_id
	return errors
