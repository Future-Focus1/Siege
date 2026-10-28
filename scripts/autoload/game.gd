extends Node

## Session, profile, and scene changes. Combat code reads this instead of
## reaching into the save file itself.

var juice_enabled := true
var difficulty := "normal"
var encounter_id := ""
var sandbox := false
var mode := ""
var menu_page := "main"
var return_page := "main"
var design_lines: PackedStringArray = PackedStringArray()
var editor_lines: PackedStringArray = PackedStringArray()
var design_name := "Homestead"
var loadout_weapons: PackedStringArray = PackedStringArray(["heavy_boulder", "piercing_bolt"])
var loadout_perk := "marksman"
var selected_design := ""
var unlocked: PackedStringArray = PackedStringArray(["timber_outpost"])
var best: Dictionary = {}
var settings: Dictionary = {
	"sfx": true,
	"shake": true,
	"slowmo": true,
	"debug": false,
	"aim_time_limit": 0.0,
	"enforce_aim_limit": false,
}
var last_result: Dictionary = {}
var suppress_navigation := false


func _ready() -> void:
	_load_profile()


func allow_shake() -> bool:
	return juice_enabled and bool(settings.get("shake", true))


func allow_slowmo() -> bool:
	return juice_enabled and bool(settings.get("slowmo", true))


func allow_sfx() -> bool:
	return juice_enabled and bool(settings.get("sfx", true))


func wants_debug() -> bool:
	return bool(settings.get("debug", false))


func play_quick() -> void:
	mode = "quick"
	sandbox = false
	encounter_id = ""
	_go("res://scenes/battle/battle.tscn")


func open_battle() -> void:
	sandbox = mode == "sandbox"
	_go("res://scenes/battle/battle.tscn")


func open_workshop() -> void:
	_go("res://scenes/workshop/workshop.tscn")


func open_match() -> void:
	_go("res://scenes/battle/siege_match.tscn")


func open_menu(page: String) -> void:
	menu_page = page
	if is_inside_tree():
		get_tree().paused = false
	_go("res://scenes/main/main_menu.tscn")


func begin_sandbox() -> void:
	mode = "sandbox"
	sandbox = true
	encounter_id = ""
	if editor_lines.is_empty():
		editor_lines = Layouts.homestead()
	open_workshop()


func begin_campaign(id: String) -> void:
	var problems := _loadout_errors()
	if not problems.is_empty():
		last_result = {"error": problems[0]}
		return_page = "level_select"
		open_menu("loadout")
		return
	if not unlocked.has(id):
		return
	encounter_id = id
	mode = "campaign"
	sandbox = false
	var lines := player_layout()
	design_lines = lines
	open_match()


func begin_local_duel() -> void:
	var problems := _loadout_errors()
	if not problems.is_empty():
		last_result = {"error": problems[0]}
		return_page = "multiplayer"
		open_menu("loadout")
		return
	mode = "local_duel"
	sandbox = false
	encounter_id = ""
	design_lines = player_layout()
	open_match()


func player_layout() -> PackedStringArray:
	if selected_design != "":
		var loaded := SaveGame.load_design(selected_design)
		if bool(loaded.get("ok", false)):
			design_name = String(loaded.get("name", selected_design))
			var lines: PackedStringArray = loaded.get("lines", PackedStringArray())
			return lines
	design_name = "Homestead"
	return Layouts.homestead()


func note_battle(result: String, reason: String) -> void:
	last_result = {
		"result": result,
		"reason": reason,
		"encounter_id": encounter_id,
		"mode": mode,
		"design_name": design_name,
	}
	if mode == "campaign" and encounter_id != "":
		_record_best(encounter_id, result)
		if result == "victory":
			_unlock_next(encounter_id)
	save_profile()
	if suppress_navigation:
		return
	open_menu("results")


func save_profile() -> void:
	var weapons: Array = []
	for id in loadout_weapons:
		weapons.append(id)
	var open_ids: Array = []
	for id in unlocked:
		open_ids.append(id)
	SaveGame.save_profile({
		"difficulty": difficulty,
		"loadout_weapons": weapons,
		"loadout_perk": loadout_perk,
		"selected_design": selected_design,
		"design_name": design_name,
		"unlocked": open_ids,
		"best": best,
		"settings": settings,
	})


func quit_game() -> void:
	get_tree().quit()


func _go(path: String) -> void:
	if suppress_navigation or not is_inside_tree():
		return
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func _loadout_errors() -> PackedStringArray:
	var loadout := Loadout.new()
	loadout.weapon_ids = loadout_weapons
	loadout.perk_id = loadout_perk
	return loadout.errors()


func _load_profile() -> void:
	var data := SaveGame.load_profile()
	if data.is_empty():
		return
	difficulty = String(data.get("difficulty", difficulty))
	if difficulty != "easy" and difficulty != "normal" and difficulty != "hard":
		difficulty = "normal"
	loadout_perk = String(data.get("loadout_perk", loadout_perk))
	selected_design = String(data.get("selected_design", ""))
	design_name = String(data.get("design_name", design_name))
	var weapons := PackedStringArray()
	for id in data.get("loadout_weapons", []):
		weapons.append(String(id))
	if not weapons.is_empty():
		loadout_weapons = weapons
	var open_ids := PackedStringArray()
	for id in data.get("unlocked", []):
		open_ids.append(String(id))
	if not open_ids.is_empty():
		unlocked = open_ids
	if not unlocked.has("timber_outpost"):
		unlocked.append("timber_outpost")
	if typeof(data.get("best")) == TYPE_DICTIONARY:
		best = data.get("best")
	if typeof(data.get("settings")) == TYPE_DICTIONARY:
		var stored: Dictionary = data.get("settings")
		for key in settings.keys():
			if stored.has(key):
				settings[key] = stored[key]
	if not _loadout_errors().is_empty():
		loadout_weapons = PackedStringArray(["heavy_boulder", "piercing_bolt"])
		loadout_perk = "marksman"


func _record_best(id: String, result: String) -> void:
	if String(best.get(id, "")) == "victory":
		return
	best[id] = result


func _unlock_next(id: String) -> void:
	var list := Catalog.encounter_list()
	var found := false
	for enc in list:
		if found:
			var next_id := String(enc.id)
			if not unlocked.has(next_id):
				unlocked.append(next_id)
			return
		if String(enc.id) == id:
			found = true
