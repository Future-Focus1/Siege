class_name Placement
extends RefCounted

var piece_id: String = ""
var material_id: String = ""
var col: int = 0
var row: int = 0
var rot: int = 0


static func parse(line: String) -> Placement:
	var bits := line.split(",")
	var placement := Placement.new()
	placement.piece_id = bits[0].strip_edges()
	placement.material_id = bits[1].strip_edges()
	placement.col = int(bits[2])
	placement.row = int(bits[3])
	placement.rot = int(bits[4]) if bits.size() > 4 else 0
	return placement


func encode() -> String:
	return "%s,%s,%d,%d,%d" % [piece_id, material_id, col, row, rot]


static func encode_all(rows: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for row in rows:
		if row is Placement:
			out.append(row.encode())
		else:
			out.append(String(row))
	return out
