class_name MatchAction
extends RefCounted

var side := ""
var weapon_id := ""
var angle := 0.0
var power := 0.0
var virtual_time := 0.0


func to_dict() -> Dictionary:
	return {
		"side": side,
		"weapon_id": weapon_id,
		"angle": angle,
		"power": power,
		"virtual_time": virtual_time,
	}
