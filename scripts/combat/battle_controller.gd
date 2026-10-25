extends Node2D

enum Phase { AIM, FLIGHT }

var arena: Arena
var catapult: Catapult
var camera_rig: CameraRig
var phase := Phase.AIM
var weapon: WeaponData
var victory := false
var flight := 0.0
var settle := 0.0
var status_label: Label
var aim_label: Label
var core_label: Label
var _recent_breaks := 0
var _break_window := 0.0


var weapon_choices: Array[WeaponData] = []
var using_sandbox := false


func _ready() -> void:
	Catalog.ensure()
	using_sandbox = Game.mode == "sandbox" and Game.design_lines.size() > 0
	if using_sandbox:
		for id in Game.loadout_weapons:
			var choice := Catalog.weapon(String(id))
			if choice:
				weapon_choices.append(choice)
	if weapon_choices.is_empty():
		weapon_choices.append(Catalog.weapon("heavy_boulder"))
	weapon = weapon_choices[0]
	_build_world()
	_build_hud()
	_open_aim()


func _build_world() -> void:
	arena = Arena.new()
	add_child(arena)
	arena.build_ground()
	if using_sandbox:
		arena.defender_perk = Game.loadout_perk
		arena.spawn_layout(Game.design_lines)
	else:
		arena.spawn_layout(DemoLayout.timber_outpost())
	arena.core_lost.connect(_on_core_lost)
	arena.piece_damaged.connect(_on_piece_damaged)
	arena.piece_broke.connect(_on_piece_broke)
	catapult = Catapult.new()
	catapult.position = Vector2(620, SiegeGrid.GROUND_Y - 120)
	add_child(catapult)
	catapult.speed_scale = PerkRules.launch_scale(Game.loadout_perk if using_sandbox else "")
	catapult.set_weapon(weapon)
	catapult.fired.connect(_on_fired)
	catapult.aim_changed.connect(_on_aim_changed)
	camera_rig = CameraRig.new()
	add_child(camera_rig)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_right = 1.0
	panel.offset_left = 28
	panel.offset_top = 48
	panel.offset_right = -28
	panel.offset_bottom = 300
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := UiKit.label(weapon.display_name if weapon else "SIEGE", 28)
	box.add_child(title)
	status_label = UiKit.label("Drag back from the catapult, then release.", 30)
	box.add_child(status_label)
	core_label = UiKit.label("Keep core intact", 30)
	box.add_child(core_label)
	aim_label = UiKit.label("Angle 58°   Power 0%", 30)
	box.add_child(aim_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	if weapon_choices.size() > 1:
		var swap := Button.new()
		swap.text = "Weapon"
		swap.custom_minimum_size = Vector2(220, 84)
		swap.theme = UiKit.theme()
		swap.pressed.connect(_cycle_weapon)
		row.add_child(swap)
	var reset := Button.new()
	reset.text = "Reset"
	reset.custom_minimum_size = Vector2(220, 84)
	reset.theme = UiKit.theme()
	reset.pressed.connect(reset_battle)
	row.add_child(reset)
	if using_sandbox:
		var back := Button.new()
		back.text = "Builder"
		back.custom_minimum_size = Vector2(220, 84)
		back.theme = UiKit.theme()
		back.pressed.connect(func() -> void: Game.open_workshop())
		row.add_child(back)


func _panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.12, 0.16, 0.82)
	box.set_corner_radius_all(24)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box


func _process(delta: float) -> void:
	ImpactFeedback.tick()
	_refresh_core_label()
	if _break_window > 0.0:
		_break_window -= delta
		if _break_window <= 0.0:
			_recent_breaks = 0
	if phase != Phase.FLIGHT:
		return
	flight += delta
	var moving := not arena.is_quiet()
	if flight > 0.55 and not moving:
		settle += delta
	else:
		settle = 0.0
	if arena.core_defeated():
		_on_core_lost()
		return
	if settle > 0.4 or flight > Catalog.balance.max_resolve_seconds:
		_finish_flight()


func _open_aim() -> void:
	if victory:
		return
	phase = Phase.AIM
	catapult.set_aim_enabled(true)
	status_label.text = "Drag back from the catapult, then release."
	camera_rig.follow_target = null


func _on_aim_changed(angle: float, amount: float) -> void:
	aim_label.text = "Angle %d°    Power %d%%" % [roundi(angle), roundi(amount * 100.0)]


func _on_fired(origin: Vector2, velocity: Vector2) -> void:
	if phase != Phase.AIM or victory:
		return
	phase = Phase.FLIGHT
	flight = 0.0
	settle = 0.0
	catapult.set_aim_enabled(false)
	var projectile := arena.launch(weapon, origin, velocity)
	if using_sandbox:
		projectile.scale_damage(PerkRules.damage_scale(Game.loadout_perk))
	camera_rig.follow_target = projectile
	status_label.text = "Shot away."
	aim_label.text = "Angle %d°    Power %d%%" % [roundi(catapult.angle_degrees), roundi(catapult.power * 100.0)]


func _finish_flight() -> void:
	camera_rig.follow_target = null
	if victory or arena.core_defeated():
		_on_core_lost()
		return
	_open_aim()


func _on_piece_damaged(piece: StructuralPiece, amount: float) -> void:
	ImpactFeedback.burst(arena, piece.global_position, Color("efe6d4"), 10 if amount < 45.0 else 16)
	camera_rig.add_shake(clampf(amount / 90.0, 0.12, 0.85))


func _on_piece_broke(_piece: StructuralPiece) -> void:
	_recent_breaks += 1
	_break_window = 0.5
	if _recent_breaks >= 4:
		ImpactFeedback.major(camera_rig)
		_recent_breaks = 0
		status_label.text = "The tower is coming apart."


func _on_core_lost() -> void:
	if victory:
		return
	victory = true
	phase = Phase.AIM
	catapult.set_aim_enabled(false)
	camera_rig.follow_target = null
	status_label.text = "The Keep has fallen. Victory."
	core_label.text = "Keep core destroyed"
	ImpactFeedback.major(camera_rig)


func _cycle_weapon() -> void:
	if phase != Phase.AIM or weapon_choices.size() < 2:
		return
	var index := weapon_choices.find(weapon)
	weapon = weapon_choices[(index + 1) % weapon_choices.size()]
	catapult.set_weapon(weapon)
	if status_label:
		status_label.text = weapon.display_name
	if aim_label:
		aim_label.text = "Angle %d°    Power %d%%" % [roundi(catapult.angle_degrees), roundi(catapult.power * 100.0)]


func _refresh_core_label() -> void:
	if victory:
		return
	if arena.core == null or not is_instance_valid(arena.core):
		core_label.text = "Keep core destroyed"
		return
	var ratio := arena.core.durability / arena.core.max_durability
	core_label.text = "Keep core %d%%" % roundi(ratio * 100.0)


func reset_battle() -> void:
	ImpactFeedback.restore()
	victory = false
	flight = 0.0
	settle = 0.0
	_recent_breaks = 0
	arena.clear_dynamic()
	# queue_free is deferred, so rebuild next frame to avoid overlap with dying bodies
	await get_tree().process_frame
	if using_sandbox:
		arena.defender_perk = Game.loadout_perk
		arena.spawn_layout(Game.design_lines)
	else:
		arena.spawn_layout(DemoLayout.timber_outpost())
	camera_rig.follow_target = null
	camera_rig.global_position = camera_rig.home
	_open_aim()
	_refresh_core_label()
