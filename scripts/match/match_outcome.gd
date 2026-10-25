class_name MatchOutcome
extends RefCounted

var finished := false
var result := ""
var reason := ""


func note_core_destroyed(owner_side: String) -> void:
	if finished:
		return
	finished = true
	reason = "core_destroyed"
	result = "defeat" if owner_side == "player" else "victory"


func note_timeout(player_score: float, enemy_score: float, epsilon: float) -> void:
	if finished:
		return
	finished = true
	reason = "timeout"
	if absf(player_score - enemy_score) < epsilon:
		result = "tie"
	elif player_score > enemy_score:
		result = "victory"
	else:
		result = "defeat"
