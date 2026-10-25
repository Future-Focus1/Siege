extends Node2D

## One battle on two arenas. Towers stay where the last shot left them.
## The virtual clock decides whose weapon is ready. Aiming pauses that clock.

var player_arena: Arena
var enemy_arena: Arena
var player_catapult: Catapult
var enemy_catapult: Catapult
var camera_rig: CameraRig
var scheduler := InitiativeScheduler.new()
var state := MatchState.new()
var outcome := MatchOutcome.new()

var player_lines: PackedStringArray = PackedStringArray()
var enemy_lines: PackedStringArray = PackedStringArray()
var player_weapons: Array[WeaponData] = []
var enemy_weapons: Array[WeaponData] = []
var player_perk := ""
var enemy_perk := ""
var both_ai := false
var difficulty := "normal"
var active_side := ""
var active_weapon: WeaponData
var phase := "boot"
var finished := false
var ai_wait := 0.0
var flight := 0.0
var settle := 0.0
var ending_wait := 0.0
var pending_result := ""
var pending_reason := ""
var aim_elapsed := 0.0
var target_arena: Arena

var status_label: Label
var cores_label: Label
var aim_label: Label
var clock_label: Label
var weapon_row: HBoxContainer
var pause_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Catalog.ensure()
	difficulty = Game.difficulty
	both_ai = Game.mode == "local_duel"
	_gather_loadouts()
	_build_arenas()
	_build_hud()
	_arm_scheduler()
	state.log_event("started", {
		"mode": Game.mode,
		"difficulty": difficulty,
		"encounter_id": Game.encounter_id,
		"player_perk": player_perk,
		"enemy_perk": enemy_perk,
	})
	_advance()


func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().paused = false
	ImpactFeedback.restore()


func _gather_loadouts() -> void:
	player_perk = Game.loadout_perk
	for id in Game.loadout_weapons:
		var weapon := Catalog.weapon(String(id))
		if weapon:
			player_weapons.append(weapon)
	if player_weapons.is_empty():
		player_weapons.append(Catalog.weapon("heavy_boulder"))
	player_lines = Game.design_lines
	if LayoutRules.validate(player_lines).size() > 0:
		player_lines = Layouts.homestead()
	var encounter := Catalog.encounter(Game.encounter_id)
	if Game.mode == "local_duel" or encounter == null:
		enemy_lines = Layouts.get_layout("timber_outpost")
		enemy_perk = "marksman"
		enemy_weapons.append(Catalog.weapon("piercing_bolt"))
		enemy_weapons.append(Catalog.weapon("heavy_boulder"))
	else:
		enemy_lines = Layouts.get_layout(encounter.layout_id)
		enemy_perk = encounter.ai_perk
		for id in encounter.ai_weapons:
			var weapon := Catalog.weapon(String(id))
			if weapon:
				enemy_weapons.append(weapon)
	if LayoutRules.validate(enemy_lines).size() > 0:
		push_error("Enemy layout failed validation")
		for issue in LayoutRules.validate(enemy_lines):
			push_error(issue)
		enemy_lines = Layouts.get_layout("timber_outpost")
	if enemy_weapons.is_empty():
		enemy_weapons.append(Catalog.weapon("heavy_boulder"))


func _build_arenas() -> void:
	player_arena = Arena.new()
	player_arena.position = Vector2.ZERO
	player_arena.defender_perk = player_perk
	add_child(player_arena)
	player_arena.build_ground()
	player_arena.spawn_layout(player_lines)
	player_arena.core_lost.connect(_on_core_lost.bind("player"))
	player_arena.piece_damaged.connect(_on_damaged)
	player_arena.piece_broke.connect(_on_broke)

	enemy_arena = Arena.new()
	enemy_arena.position = Vector2(6400, 0)
	enemy_arena.defender_perk = enemy_perk
	add_child(enemy_arena)
	enemy_arena.build_ground()
	enemy_arena.spawn_layout(enemy_lines)
	enemy_arena.core_lost.connect(_on_core_lost.bind("enemy"))
	enemy_arena.piece_damaged.connect(_on_damaged)
	enemy_arena.piece_broke.connect(_on_broke)

	player_catapult = _make_catapult(enemy_arena, _on_player_fired)
	enemy_catapult = _make_catapult(player_arena, _ignore_enemy_drag)
	camera_rig = CameraRig.new()
	add_child(camera_rig)


func _make_catapult(host: Arena, on_fired: Callable) -> Catapult:
	var catapult := Catapult.new()
	catapult.position = Vector2(620, SiegeGrid.GROUND_Y - 120)
	host.add_child(catapult)
	catapult.set_aim_enabled(false)
	catapult.fired.connect(on_fired)
	catapult.aim_changed.connect(_on_aim_changed)
	return catapult


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_right = 1.0
	panel.offset_left = 24
	panel.offset_top = 48
	panel.offset_right = -24
	panel.offset_bottom = 390
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	cores_label = UiKit.label("Your keep 100%    Their keep 100%", 28)
	box.add_child(cores_label)
	status_label = UiKit.label("Battle", 30)
	box.add_child(status_label)
	clock_label = UiKit.label("Clock", 26)
	box.add_child(clock_label)
	aim_label = UiKit.label("Angle —    Power —", 26)
	box.add_child(aim_label)
	weapon_row = HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 8)
	box.add_child(weapon_row)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(220, 72)
	pause_button.theme = UiKit.theme()
	pause_button.add_theme_font_size_override("font_size", 28)
	pause_button.pressed.connect(_toggle_pause)
	row.add_child(pause_button)
	var menu := Button.new()
	menu.text = "Menu"
	menu.custom_minimum_size = Vector2(220, 72)
	menu.theme = UiKit.theme()
	menu.add_theme_font_size_override("font_size", 28)
	menu.pressed.connect(func() -> void: Game.open_menu("main"))
	row.add_child(menu)


func _panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.12, 0.16, 0.84)
	box.set_corner_radius_all(22)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


func _arm_scheduler() -> void:
	scheduler.clear()
	for weapon in player_weapons:
		scheduler.add_weapon("player", String(weapon.id), weapon.reload_seconds * PerkRules.reload_scale(player_perk))
	for weapon in enemy_weapons:
		scheduler.add_weapon("enemy", String(weapon.id), weapon.reload_seconds * PerkRules.reload_scale(enemy_perk))


func _process(delta: float) -> void:
	ImpactFeedback.tick()
	_refresh_hud()
	if get_tree().paused or finished and phase != "ending":
		return
	if phase == "ending":
		ending_wait -= delta
		if ending_wait <= 0.0:
			_finish(pending_result, pending_reason)
		return
	if phase == "ai":
		ai_wait -= delta
		if ai_wait <= 0.0:
			_launch_ai()
		return
	if phase == "aim":
		var limit := float(Game.settings.get("aim_time_limit", 0.0))
		if bool(Game.settings.get("enforce_aim_limit", false)) and limit > 0.0:
			aim_elapsed += delta
			if aim_elapsed >= limit and active_weapon:
				var shot: Dictionary = player_catapult.pose(player_catapult.angle_degrees, maxf(player_catapult.power, 0.45))
				var origin: Vector2 = shot.origin
				var velocity: Vector2 = shot.velocity
				_commit("player", active_weapon, player_catapult.angle_degrees, player_catapult.power, origin, velocity, player_perk, enemy_arena)
		return
	if phase != "flight":
		return
	flight += delta
	var moving := target_arena != null and not target_arena.is_quiet()
	if flight > 0.55 and not moving:
		settle += delta
	else:
		settle = 0.0
	if _cores_resolved():
		return
	if settle > 0.45 or flight > Catalog.balance.max_resolve_seconds:
		_advance()


func _advance() -> void:
	if finished:
		return
	if _cores_resolved():
		return
	var event := scheduler.peek()
	if event.is_empty() or float(event.time) > Catalog.balance.max_battle_seconds:
		_begin_ending(_timeout_result(), "timeout")
		return
	var jump := float(event.time) - scheduler.clock
	scheduler.begin_aim(event)
	player_arena.recharge_shields(jump)
	enemy_arena.recharge_shields(jump)
	active_side = String(event.side)
	active_weapon = Catalog.weapon(String(event.weapon_id))
	aim_elapsed = 0.0
	flight = 0.0
	settle = 0.0
	_show_side(active_side)
	player_catapult.set_aim_enabled(false)
	enemy_catapult.set_aim_enabled(false)
	var ai_turn := both_ai or active_side == "enemy"
	if ai_turn:
		phase = "ai"
		ai_wait = 0.45
		status_label.text = "The defender is choosing a shot." if active_side == "enemy" else "Choosing your shot."
	else:
		phase = "aim"
		player_catapult.speed_scale = PerkRules.launch_scale(player_perk)
		player_catapult.set_weapon(active_weapon)
		player_catapult.set_aim_enabled(true)
		status_label.text = "Your shot. Drag back from the catapult."
		_show_ready_weapons()
	state.log_event("aim", {"side": active_side, "weapon_id": String(event.weapon_id), "clock": scheduler.clock})


func _show_side(side: String) -> void:
	var arena := enemy_arena if side == "player" else player_arena
	camera_rig.travel_to(arena.global_position + Vector2(1060, 1000))


func _show_ready_weapons() -> void:
	for child in weapon_row.get_children():
		child.queue_free()
	if phase != "aim":
		return
	for id in scheduler.ready_weapons("player", scheduler.clock):
		var weapon := Catalog.weapon(id)
		if weapon == null:
			continue
		var button := Button.new()
		button.text = weapon.display_name
		button.custom_minimum_size = Vector2(230, 64)
		button.theme = UiKit.theme()
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_select_weapon.bind(weapon))
		weapon_row.add_child(button)


func _select_weapon(weapon: WeaponData) -> void:
	if phase != "aim" or finished:
		return
	active_weapon = weapon
	player_catapult.set_weapon(weapon)
	status_label.text = weapon.display_name


func _on_player_fired(origin: Vector2, velocity: Vector2) -> void:
	if phase != "aim" or finished or active_side != "player" or active_weapon == null:
		return
	_commit("player", active_weapon, player_catapult.angle_degrees, player_catapult.power, origin, velocity, player_perk, enemy_arena)


func _ignore_enemy_drag(_origin: Vector2, _velocity: Vector2) -> void:
	pass


func _launch_ai() -> void:
	if phase != "ai" or finished:
		return
	phase = "locking"
	var attacking_player := active_side == "player"
	var catapult := player_catapult if attacking_player else enemy_catapult
	var target := enemy_arena if attacking_player else player_arena
	var perk := player_perk if attacking_player else enemy_perk
	var options: Array[WeaponData] = []
	for id in scheduler.ready_weapons(active_side, scheduler.clock):
		var weapon := Catalog.weapon(id)
		if weapon:
			options.append(weapon)
	if options.is_empty() and active_weapon:
		options.append(active_weapon)
	var chosen := SiegeAi.pick_weapon(options, target, difficulty)
	if chosen == null:
		chosen = active_weapon
	active_weapon = chosen
	catapult.speed_scale = PerkRules.launch_scale(perk)
	catapult.set_weapon(chosen)
	var plan := SiegeAi.aim(catapult.global_position, chosen, target, difficulty, perk)
	var shot: Dictionary = catapult.pose(float(plan.angle), float(plan.power))
	var origin: Vector2 = shot.origin
	var velocity: Vector2 = shot.velocity
	_commit(active_side, chosen, catapult.angle_degrees, catapult.power, origin, velocity, perk, target)


func _commit(side: String, weapon: WeaponData, angle: float, power: float, origin: Vector2, velocity: Vector2, perk: String, target: Arena) -> void:
	if weapon == null or target == null:
		return
	var weapon_id := String(weapon.id)
	if not scheduler.ready_weapons(side, scheduler.clock).has(weapon_id):
		state.log_event("rejected", {"side": side, "weapon_id": weapon_id, "why": "not ready"})
		return
	var action := MatchAction.new()
	action.side = side
	action.weapon_id = weapon_id
	action.angle = angle
	action.power = power
	action.virtual_time = scheduler.clock
	var allowed := _allowed(side)
	if not state.accept(action, allowed):
		state.log_event("rejected", {"side": side, "weapon_id": weapon_id})
		scheduler.commit(side, weapon_id, weapon.reload_seconds * PerkRules.reload_scale(perk))
		call_deferred("_advance")
		return
	scheduler.commit(side, weapon_id, weapon.reload_seconds * PerkRules.reload_scale(perk))
	for child in weapon_row.get_children():
		child.queue_free()
	player_catapult.set_aim_enabled(false)
	enemy_catapult.set_aim_enabled(false)
	var projectile := target.launch(weapon, origin, velocity)
	projectile.scale_damage(PerkRules.damage_scale(perk))
	target_arena = target
	camera_rig.follow_target = projectile
	phase = "flight"
	flight = 0.0
	settle = 0.0
	Sfx.play("shot")
	status_label.text = "%s away." % weapon.display_name
	aim_label.text = "Angle %d°    Power %d%%" % [roundi(angle), roundi(power * 100.0)]


func _allowed(side: String) -> PackedStringArray:
	var source := player_weapons if side == "player" else enemy_weapons
	var ids := PackedStringArray()
	for weapon in source:
		ids.append(String(weapon.id))
	return ids


func _on_aim_changed(angle: float, amount: float) -> void:
	if phase != "aim":
		return
	aim_label.text = "Angle %d°    Power %d%%" % [roundi(angle), roundi(amount * 100.0)]


func _on_damaged(piece: StructuralPiece, amount: float) -> void:
	ImpactFeedback.burst(piece.get_parent(), piece.global_position, Color("efe6d4"), 8 if amount < 40.0 else 14)
	camera_rig.add_shake(clampf(amount / 90.0, 0.1, 0.7))


func _on_broke(_piece: StructuralPiece) -> void:
	Sfx.play("break")
	ImpactFeedback.burst(self, _piece.global_position, Color("c9b59a"), 16)


func _on_core_lost(owner: String) -> void:
	if finished:
		return
	var result := "defeat" if owner == "player" else "victory"
	_begin_ending(result, "core_destroyed")


func _cores_resolved() -> bool:
	if player_arena.core_defeated():
		_begin_ending("defeat", "core_destroyed")
		return true
	if enemy_arena.core_defeated():
		_begin_ending("victory", "core_destroyed")
		return true
	return false


func _timeout_result() -> String:
	var judged := MatchOutcome.new()
	judged.note_timeout(_score(player_arena), _score(enemy_arena), Catalog.balance.tie_epsilon)
	return judged.result


func _score(arena: Arena) -> float:
	return _core_ratio(arena) * 0.7 + arena.intact_ratio() * 0.3


func _core_ratio(arena: Arena) -> float:
	if arena.core == null or not is_instance_valid(arena.core) or arena.core.broken or arena.core.durability <= 0.0:
		return 0.0
	return clampf(arena.core.durability / arena.core.max_durability, 0.0, 1.0)


func _begin_ending(result: String, reason: String) -> void:
	if finished:
		return
	finished = true
	phase = "ending"
	pending_result = result
	pending_reason = reason
	player_catapult.set_aim_enabled(false)
	enemy_catapult.set_aim_enabled(false)
	camera_rig.follow_target = null
	if reason == "core_destroyed" or reason == "collapse":
		ImpactFeedback.major(camera_rig)
	var title := "Victory" if result == "victory" else ("Defeat" if result == "defeat" else "Tie")
	status_label.text = title
	ending_wait = 0.85


func _finish(result: String, reason: String) -> void:
	phase = "done"
	get_tree().paused = false
	ImpactFeedback.restore()
	outcome.finished = true
	outcome.result = result
	outcome.reason = reason
	state.finish(result, reason)
	var record := state.to_dict()
	record["mode"] = Game.mode
	record["encounter_id"] = Game.encounter_id
	record["difficulty"] = difficulty
	SaveGame.append_log(record)
	Game.note_battle(result, reason)


func _toggle_pause() -> void:
	if finished:
		return
	get_tree().paused = not get_tree().paused
	pause_button.text = "Resume" if get_tree().paused else "Pause"


func _refresh_hud() -> void:
	if cores_label == null:
		return
	cores_label.text = "Your keep %d%%    Their keep %d%%" % [
		roundi(_core_ratio(player_arena) * 100.0),
		roundi(_core_ratio(enemy_arena) * 100.0),
	]
	var who := "You" if active_side == "player" else "Defender"
	var weapon_name := active_weapon.display_name if active_weapon else "—"
	var next_time := scheduler.peek()
	var next_label := "—"
	if not next_time.is_empty():
		next_label = "%.0fs" % float(next_time.time)
	clock_label.text = "%s  ·  %s  ·  clock %.0fs  ·  next %s%s" % [
		who,
		weapon_name,
		scheduler.clock,
		next_label,
		"  ·  debug" if Game.wants_debug() else "",
	]
	if Game.wants_debug():
		var bodies := Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
		clock_label.text += "  ·  active %d" % int(bodies)
