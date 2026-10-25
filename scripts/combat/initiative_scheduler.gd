class_name InitiativeScheduler
extends RefCounted

## Shared virtual battle clock. Fast weapons come off cooldown sooner.
## The clock pauses while someone is aiming so relaxed offline aim does not
## recharge the opponent.

var clock := 0.0
var paused := false
var last_side := ""
var next_ready: Dictionary = {}


func clear() -> void:
	clock = 0.0
	paused = false
	last_side = ""
	next_ready.clear()


func add_weapon(side: String, weapon_id: String, ready_at: float) -> void:
	next_ready["%s|%s" % [side, weapon_id]] = ready_at


func ready_weapons(side: String, at_time: float) -> PackedStringArray:
	var out := PackedStringArray()
	for key in next_ready.keys():
		var parts := String(key).split("|")
		if parts.size() != 2 or parts[0] != side:
			continue
		if float(next_ready[key]) <= at_time + 0.0001:
			out.append(parts[1])
	return out


func peek() -> Dictionary:
	var best_t := INF
	var keys: Array[String] = []
	for key in next_ready.keys():
		var t := float(next_ready[key])
		if t < best_t - 0.0001:
			best_t = t
			keys.clear()
			keys.append(String(key))
		elif absf(t - best_t) <= 0.0001:
			keys.append(String(key))
	if keys.is_empty():
		return {}
	var chosen := _tie_break(keys)
	var parts := chosen.split("|")
	return {"side": parts[0], "weapon_id": parts[1], "time": best_t}


func begin_aim(event: Dictionary) -> void:
	clock = float(event.time)
	paused = true


func commit(side: String, weapon_id: String, reload_seconds: float) -> void:
	var key := "%s|%s" % [side, weapon_id]
	var ready_at := float(next_ready.get(key, clock))
	clock = maxf(clock, ready_at)
	next_ready[key] = clock + reload_seconds
	last_side = side
	paused = false


func _tie_break(keys: Array[String]) -> String:
	var preferred := "player" if last_side != "player" else "enemy"
	var same_side: Array[String] = []
	for key in keys:
		if key.begins_with(preferred + "|"):
			same_side.append(key)
	if same_side.is_empty():
		for key in keys:
			same_side.append(key)
	same_side.sort()
	return same_side[0]
