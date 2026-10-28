class_name MatchState
extends RefCounted

var status := "pending"
var result := ""
var reason := ""
var actions: Array = []
var events: Array = []


func accept(action: MatchAction, allowed_weapons: PackedStringArray) -> bool:
	if action.side != "player" and action.side != "enemy":
		return false
	if action.power < 0.0 or action.power > 1.0:
		return false
	if action.angle < 8.0 or action.angle > 82.0:
		return false
	if not allowed_weapons.has(action.weapon_id):
		return false
	actions.append(action.to_dict())
	log_event("action", action.to_dict())
	status = "active"
	return true


func log_event(kind: String, payload: Dictionary) -> void:
	payload["type"] = kind
	payload["at"] = Time.get_ticks_msec()
	events.append(payload)


func finish(match_result: String, match_reason: String) -> void:
	status = "finished"
	result = match_result
	reason = match_reason
	log_event("finished", {"result": match_result, "reason": match_reason})


func to_dict() -> Dictionary:
	return {
		"version": 1,
		"status": status,
		"result": result,
		"reason": reason,
		"actions": actions,
		"events": events,
	}
