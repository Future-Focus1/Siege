extends Control

var column: VBoxContainer
var note: Label
var chosen_weapons: Array[String] = []
var chosen_perk := ""


func _ready() -> void:
	get_tree().paused = false
	Catalog.ensure()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color("1b2430")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", 72)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	match Game.menu_page:
		"single_player":
			_single_player()
		"level_select":
			_level_select()
		"loadout":
			_loadout()
		"settings":
			_settings()
		"results":
			_results()
		"multiplayer":
			_multiplayer()
		"load_design":
			_load_design()
		_:
			_main()


func _title(text: String) -> void:
	var label := UiKit.label(text, 68)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)


func _blurb(text: String) -> void:
	var label := UiKit.label(text, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)


func _button(text: String, callback: Callable) -> Button:
	var button := UiKit.button(text)
	button.pressed.connect(callback)
	column.add_child(button)
	return button


func _main() -> void:
	_title("SIEGE")
	_blurb("Build a keep. Pull the catapult. Let physics finish the argument.")
	_button("Quick Battle", func() -> void: Game.play_quick())
	_button("Single Player", func() -> void: Game.open_menu("single_player"))
	_button("Tower Builder", func() -> void:
		Game.return_page = "main"
		Game.mode = "builder"
		if Game.editor_lines.is_empty():
			Game.editor_lines = Layouts.homestead()
		Game.open_workshop()
	)
	_button("Sandbox", func() -> void:
		Game.return_page = "main"
		Game.begin_sandbox()
	)
	_button("Loadout", func() -> void:
		Game.return_page = "main"
		Game.open_menu("loadout")
	)
	_button("Settings", func() -> void: Game.open_menu("settings"))
	_button("Multiplayer", func() -> void: Game.open_menu("multiplayer"))
	_button("Quit", func() -> void: Game.quit_game())


func _single_player() -> void:
	_title("Single Player")
	_blurb("Easy, Normal, and Hard change how the defender aims and which weapon it picks. They do not add health.")
	_blurb("Difficulty: %s" % Game.difficulty.capitalize())
	_button("Easy", func() -> void: _set_difficulty("easy"))
	_button("Normal", func() -> void: _set_difficulty("normal"))
	_button("Hard", func() -> void: _set_difficulty("hard"))
	_button("Level Select", func() -> void: Game.open_menu("level_select"))
	_button("Back", func() -> void: Game.open_menu("main"))


func _set_difficulty(level: String) -> void:
	Game.difficulty = level
	Game.save_profile()
	Game.open_menu("single_player")


func _level_select() -> void:
	_title("Level Select")
	var lines := Game.player_layout()
	var legal := LayoutRules.validate(lines).is_empty()
	_blurb("Your tower: %s%s" % [Game.design_name, "" if legal else " (invalid, Homestead will be used)"])
	_blurb("Win a level on any difficulty to open the next one.")
	for enc in Catalog.encounter_list():
		var id := String(enc.id)
		var open := Game.unlocked.has(id)
		var mark := ""
		if String(Game.best.get(id, "")) == "victory":
			mark = " · Cleared"
		var button := _button(enc.display_name + mark, _start_level.bind(id))
		button.disabled = not open
		if not open:
			button.text = "Locked · " + enc.display_name
		else:
			var info := UiKit.label(enc.briefing, 24)
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(info)
	_button("Build a tower", func() -> void:
		Game.return_page = "level_select"
		if Game.editor_lines.is_empty():
			Game.editor_lines = Layouts.homestead()
		Game.open_workshop()
	)
	_button("Back", func() -> void: Game.open_menu("single_player"))


func _start_level(id: String) -> void:
	if not Game.unlocked.has(id):
		return
	Game.begin_campaign(id)


func _loadout() -> void:
	_title("Loadout")
	_blurb("Weapons and one perk share a budget of %d. The tower keeps its own budget of %d." % [Catalog.balance.loadout_budget, Catalog.balance.build_budget])
	chosen_weapons.clear()
	for id in Game.loadout_weapons:
		chosen_weapons.append(String(id))
	chosen_perk = Game.loadout_perk
	note = UiKit.label("", 28)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for id in ["heavy_boulder", "explosive_shot", "piercing_bolt"]:
		var weapon := Catalog.weapon(id)
		if weapon == null:
			continue
		_button("%s · %d" % [weapon.display_name, weapon.cost], _toggle_weapon.bind(id))
		var about := UiKit.label(weapon.description, 24)
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(about)
	_blurb("One perk")
	for id in ["rapid_reload", "siege_master", "reinforced_foundations", "shield_specialist", "marksman", "lightweight_engineering"]:
		var perk := Catalog.perk(id)
		if perk == null:
			continue
		_button("%s · %d" % [perk.display_name, perk.cost], _toggle_perk.bind(id))
	column.add_child(note)
	_refresh_loadout_note()
	if Game.last_result.has("error"):
		note.text = String(Game.last_result.error)
		Game.last_result.erase("error")
	_button("Save loadout", _save_loadout)
	_button("Back", func() -> void: Game.open_menu(Game.return_page if Game.return_page != "" else "main"))


func _toggle_weapon(id: String) -> void:
	var index := chosen_weapons.find(id)
	if index >= 0:
		chosen_weapons.remove_at(index)
	else:
		chosen_weapons.append(id)
	_refresh_loadout_note()


func _toggle_perk(id: String) -> void:
	chosen_perk = "" if chosen_perk == id else id
	_refresh_loadout_note()


func _refresh_loadout_note() -> void:
	if note == null:
		return
	var loadout := Loadout.new()
	var ids := PackedStringArray()
	for id in chosen_weapons:
		ids.append(id)
	loadout.weapon_ids = ids
	loadout.perk_id = chosen_perk
	var problems := loadout.errors()
	var armed := ", ".join(chosen_weapons) if not chosen_weapons.is_empty() else "none"
	var perk_name := chosen_perk if chosen_perk != "" else "none"
	note.text = "Cost %d / %d\nWeapons: %s\nPerk: %s" % [loadout.cost(), Catalog.balance.loadout_budget, armed, perk_name]
	if not problems.is_empty():
		note.text += "\n" + problems[0]


func _save_loadout() -> void:
	var ids := PackedStringArray()
	for id in chosen_weapons:
		ids.append(id)
	var loadout := Loadout.new()
	loadout.weapon_ids = ids
	loadout.perk_id = chosen_perk
	var problems := loadout.errors()
	if not problems.is_empty():
		note.text = problems[0]
		return
	Game.loadout_weapons = ids
	Game.loadout_perk = chosen_perk
	Game.save_profile()
	Game.open_menu(Game.return_page if Game.return_page != "" else "main")


func _settings() -> void:
	_title("Settings")
	_blurb("Portrait play. These switches are saved on this device.")
	_button("Sound: %s" % _on_off("sfx"), func() -> void: _flip("sfx"))
	_button("Camera shake: %s" % _on_off("shake"), func() -> void: _flip("shake"))
	_button("Slow motion: %s" % _on_off("slowmo"), func() -> void: _flip("slowmo"))
	_button("Debug numbers: %s" % _on_off("debug"), func() -> void: _flip("debug"))
	var limited := bool(Game.settings.get("enforce_aim_limit", false))
	_button("Aim time limit: %s" % ("20s" if limited else "Off"), _flip_aim)
	_blurb("The aim limit stays off for single player unless you turn it on. It is here for a later competitive match.")
	_button("Back", func() -> void: Game.open_menu("main"))


func _on_off(key: String) -> String:
	return "On" if bool(Game.settings.get(key, false)) else "Off"


func _flip(key: String) -> void:
	Game.settings[key] = not bool(Game.settings.get(key, false))
	Game.save_profile()
	Game.open_menu("settings")


func _flip_aim() -> void:
	var on := not bool(Game.settings.get("enforce_aim_limit", false))
	Game.settings["enforce_aim_limit"] = on
	Game.settings["aim_time_limit"] = 20.0 if on else 0.0
	Game.save_profile()
	Game.open_menu("settings")


func _results() -> void:
	var result := String(Game.last_result.get("result", "tie"))
	var heading := "Tie"
	if result == "victory":
		heading = "Victory"
	elif result == "defeat":
		heading = "Defeat"
	_title(heading)
	var reason := String(Game.last_result.get("reason", ""))
	var detail := "The battle ended."
	if reason == "core_destroyed":
		detail = "A keep was broken or fell clear of its supports."
	elif reason == "timeout":
		detail = "The battle clock ran out. The stronger keep wins. Equal keeps tie."
	var enc := Catalog.encounter(String(Game.last_result.get("encounter_id", "")))
	if enc:
		detail = "%s\n%s" % [enc.display_name, detail]
	_blurb(detail)
	_button("Main Menu", func() -> void: Game.open_menu("main"))
	_button("Rematch", _rematch)


func _rematch() -> void:
	var played := String(Game.last_result.get("mode", ""))
	if played == "campaign":
		Game.begin_campaign(String(Game.last_result.get("encounter_id", "")))
	elif played == "local_duel":
		Game.begin_local_duel()
	elif played == "sandbox" and Game.design_lines.size() > 0:
		Game.mode = "sandbox"
		Game.open_battle()
	else:
		Game.play_quick()


func _multiplayer() -> void:
	_title("Multiplayer")
	_blurb("Online play is a later phase. This screen does not search for players, and it does not start a networked match.")
	_blurb("You can run a local two-sided battle on this device. Both keeps use the same rules, and nothing is sent to a server.")
	_button("Local two-sided test", func() -> void: Game.begin_local_duel())
	_button("Back", func() -> void: Game.open_menu("main"))


func _load_design() -> void:
	_title("Load Design")
	var designs := SaveGame.list_designs()
	if designs.is_empty():
		_blurb("No saved towers yet. A tower has to pass the building rules before it can be saved.")
	for entry in designs:
		var design_name := String(entry.get("name", "Tower"))
		var slug := String(entry.get("slug", ""))
		_button(design_name, _pick_design.bind(slug))
	_button("Back", func() -> void: Game.open_workshop())


func _pick_design(slug: String) -> void:
	var loaded := SaveGame.load_design(slug)
	if not bool(loaded.get("ok", false)):
		var problems: PackedStringArray = loaded.get("errors", PackedStringArray())
		note = UiKit.label(problems[0] if problems.size() else "Could not load", 28)
		column.add_child(note)
		return
	var lines: PackedStringArray = loaded.get("lines", PackedStringArray())
	Game.editor_lines = lines
	Game.selected_design = slug
	Game.design_name = String(loaded.get("name", slug))
	Game.save_profile()
	Game.open_workshop()
