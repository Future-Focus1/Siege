class_name SiegeGrid
extends RefCounted

const CELL := 64
const COLS := 8
const ROWS := 12
const ORIGIN_X := 1020.0
const GROUND_Y := 1580.0


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		ORIGIN_X + (float(cell.x) + 0.5) * CELL,
		GROUND_Y - (float(cell.y) + 0.5) * CELL
	)


static func piece_center(cells: Array) -> Vector2:
	if cells.is_empty():
		return Vector2(ORIGIN_X, GROUND_Y)
	var sum := Vector2.ZERO
	for cell in cells:
		sum += cell_center(cell)
	return sum / float(cells.size())


static func bounds_size(cells: Array) -> Vector2:
	var min_x := 999
	var min_y := 999
	var max_x := -999
	var max_y := -999
	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return Vector2(float(max_x - min_x + 1) * CELL, float(max_y - min_y + 1) * CELL)
