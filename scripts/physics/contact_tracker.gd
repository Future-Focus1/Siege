class_name ContactTracker
extends RefCounted

## One damaging blow per contact episode.
## Resting or sliding contacts stay latched and do not grind durability.

var _latched: Dictionary = {}
var _missing: Dictionary = {}
var _seen: Dictionary = {}


func consume(other_id: int, rel_speed: float, frame: int) -> bool:
	_seen[other_id] = frame
	var energetic := rel_speed >= DamageModel.min_speed()
	if _latched.has(other_id):
		return false
	if not energetic:
		return false
	_latched[other_id] = frame
	_missing[other_id] = 0
	return true


func end_step(frame: int) -> void:
	var drop: Array[int] = []
	for key in _latched.keys():
		var id := int(key)
		if _seen.has(id):
			_missing[id] = 0
			continue
		var miss := int(_missing.get(id, 0)) + 1
		_missing[id] = miss
		if miss >= 8:
			drop.append(id)
	for id in drop:
		_latched.erase(id)
		_missing.erase(id)
	_seen.clear()
	if frame < 0:
		pass
