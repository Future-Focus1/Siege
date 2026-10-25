extends Node

var juice_enabled := true
var difficulty := "normal"
var encounter_id := ""
var sandbox := false


func play_quick() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")


func quit_game() -> void:
	get_tree().quit()
