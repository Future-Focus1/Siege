extends Node2D

var failures: Array[String] = []


func _ready() -> void:
	_run()


func _run() -> void:
	Game.juice_enabled = false
	await get_tree().process_frame
	_check("contact damage is not applied twice", _logic_tracker())
	_check("resting speed does not create impact energy", _logic_rest_energy())
	_check("weapon reload times differ", _logic_reload())
	_check("faster weapon is ready first", _logic_scheduler())
	_check("core destruction is a victory for the attacker", _logic_outcome())
	_check("timeout ties stay ties", _logic_tie())
	_check("demo layout has no overlapping cells", _logic_layout())
	_check("campaign layouts and enemy loadouts are legal", _logic_encounters())
	_check("overlapping placement is rejected", _logic_overlap())
	_check("an unsupported core is rejected", _logic_unsupported())
	_check("a save round-trip restores the layout", _logic_save())
	_check("a heavy loadout is over budget", _logic_loadout())
	_check("match actions reject unknown weapons and illegal power", _logic_actions())
	_check("a shield spends energy and weakens a heavy shot", _logic_shield())
	_check("easy and hard aim are not the same roll", _logic_aim())
	_check("rapid reload is faster than siege master", _logic_perk_reload())
	_check("trajectory matches the projectile", await _phys_ballistics())
	_check("projectile does not pass through a block", await _phys_block())
	_check("resting contact does not damage blocks", await _phys_rest())
	_check("one hit does not damage the same block twice", await _phys_once())
	_check("explosion pushes a nearby body harder than a far one", await _phys_boom())
	_check("destroying the keep core ends the match", await _phys_core_match())
	_check("a campaign battle keeps two separate towers", await _phys_two_towers())
	Engine.time_scale = 1.0
	if failures.is_empty():
		print("ALL TESTS PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		print("TESTS FAILED: ", failures.size())
		get_tree().quit(1)


func _check(name: String, ok: bool) -> void:
	if ok:
		print("PASS: ", name)
	else:
		failures.append(name)
		printerr("FAIL: ", name)


func _logic_tracker() -> bool:
	var tracker := ContactTracker.new()
	var first := tracker.consume(7, 400.0, 1)
	var second := tracker.consume(7, 400.0, 1)
	tracker.end_step(1)
	var still := tracker.consume(7, 380.0, 2)
	return first and not second and not still


func _logic_rest_energy() -> bool:
	return DamageModel.impact_energy(5.0, 5.0, 12.0) == 0.0


func _logic_reload() -> bool:
	var bolt := Catalog.weapon("piercing_bolt")
	var explosive := Catalog.weapon("explosive_shot")
	var boulder := Catalog.weapon("heavy_boulder")
	return bolt.reload_seconds < explosive.reload_seconds and explosive.reload_seconds < boulder.reload_seconds


func _logic_scheduler() -> bool:
	var clock := InitiativeScheduler.new()
	clock.add_weapon("player", "piercing_bolt", 4.0)
	clock.add_weapon("player", "heavy_boulder", 9.0)
	clock.add_weapon("enemy", "piercing_bolt", 4.0)
	var first := clock.peek()
	if String(first.weapon_id) != "piercing_bolt" or float(first.time) != 4.0:
		return false
	if String(first.side) != "player":
		return false
	clock.begin_aim(first)
	clock.commit("player", "piercing_bolt", 4.0)
	var second := clock.peek()
	return String(second.side) == "enemy" and float(second.time) == 4.0


func _logic_outcome() -> bool:
	var outcome := MatchOutcome.new()
	outcome.note_core_destroyed("enemy")
	return outcome.finished and outcome.result == "victory" and outcome.reason == "core_destroyed"


func _logic_tie() -> bool:
	var outcome := MatchOutcome.new()
	outcome.note_timeout(0.50, 0.51, 0.02)
	return outcome.result == "tie"


func _logic_encounters() -> bool:
	var list := Catalog.encounter_list()
	if list.size() != 5:
		print("encounter count ", list.size())
		return false
	var previous := 0
	for enc in list:
		if enc.order <= previous:
			print("encounter order ", enc.id)
			return false
		previous = enc.order
		var problems := LayoutRules.validate(Layouts.get_layout(enc.layout_id))
		if not problems.is_empty():
			print(enc.layout_id, " ", problems)
			return false
		var loadout := Loadout.new()
		loadout.weapon_ids = enc.ai_weapons
		loadout.perk_id = enc.ai_perk
		var over := loadout.errors()
		if not over.is_empty():
			print(enc.id, " ", over)
			return false
	var homestead := LayoutRules.validate(Layouts.homestead())
	if not homestead.is_empty():
		print("homestead ", homestead)
		return false
	return true


func _logic_overlap() -> bool:
	var lines := PackedStringArray([
		"small_block,wood,0,0,0",
		"small_block,stone,0,0,0",
	])
	var problems := LayoutRules.edit_errors(lines)
	var rejected := false
	for line in problems:
		if line.begins_with("overlap"):
			rejected = true
	return rejected


func _logic_unsupported() -> bool:
	var lines := PackedStringArray(["keep_core,core,3,5,0"])
	var problems := LayoutRules.validate(lines)
	var rejected := false
	for line in problems:
		if line.contains("not supported") or line.contains("keep core"):
			rejected = true
	return rejected


func _logic_save() -> bool:
	var lines := Layouts.homestead()
	var saved := SaveGame.save_design("Test Keep", lines)
	if not bool(saved.get("ok", false)):
		print("save failed ", saved.get("errors", PackedStringArray()))
		return false
	var slug := String(saved.get("slug", ""))
	var loaded := SaveGame.load_design(slug)
	if not bool(loaded.get("ok", false)):
		print("load failed")
		return false
	var back: PackedStringArray = loaded.get("lines", PackedStringArray())
	if back.size() != lines.size():
		return false
	for i in lines.size():
		if back[i] != lines[i]:
			return false
	var overlap := PackedStringArray([
		"small_block,wood,0,0,0",
		"small_block,wood,0,0,0",
		"keep_core,core,2,2,0",
	])
	var refused := SaveGame.save_design("Illegal", overlap)
	if bool(refused.get("ok", false)):
		return false
	var path := "user://siege/designs/%s.json" % slug
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 99, "kind": "tower_design", "placements": []}))
	file.close()
	var tampered := SaveGame.load_design(slug)
	return not bool(tampered.get("ok", false))


func _logic_loadout() -> bool:
	var heavy := Loadout.new()
	heavy.weapon_ids = PackedStringArray(["heavy_boulder", "explosive_shot", "piercing_bolt"])
	heavy.perk_id = "siege_master"
	if heavy.errors().is_empty():
		print("expected over budget, cost ", heavy.cost())
		return false
	var legal := Loadout.new()
	legal.weapon_ids = PackedStringArray(["heavy_boulder", "piercing_bolt"])
	legal.perk_id = "marksman"
	return legal.errors().is_empty() and legal.cost() <= Catalog.balance.loadout_budget


func _logic_actions() -> bool:
	var clock := MatchState.new()
	var allowed := PackedStringArray(["heavy_boulder"])
	var unknown := MatchAction.new()
	unknown.side = "player"
	unknown.weapon_id = "fire_pot"
	unknown.angle = 40.0
	unknown.power = 0.6
	if clock.accept(unknown, allowed):
		return false
	var too_hard := MatchAction.new()
	too_hard.side = "player"
	too_hard.weapon_id = "heavy_boulder"
	too_hard.angle = 40.0
	too_hard.power = 1.4
	if clock.accept(too_hard, allowed):
		return false
	var good := MatchAction.new()
	good.side = "enemy"
	good.weapon_id = "heavy_boulder"
	good.angle = 42.0
	good.power = 0.8
	good.virtual_time = 9.0
	if not clock.accept(good, allowed):
		return false
	return clock.actions.size() == 1 and clock.events.size() == 1


func _logic_shield() -> bool:
	var field := ShieldField.new()
	field.energy = 80.0
	field.capacity = 80.0
	field.radius = 300.0
	field.position = Vector2.ZERO
	var shot := Projectile.new()
	shot.weapon = Catalog.weapon("heavy_boulder")
	shot.linear_velocity = Vector2(500, 0)
	shot.position = Vector2(30, 0)
	var before := shot._damage_scale
	field.consider(shot)
	return field.energy == 25.0 and shot._shielded and shot._damage_scale < before


func _logic_aim() -> bool:
	var weapon := Catalog.weapon("piercing_bolt")
	var arena := Arena.new()
	seed(5)
	var easy := SiegeAi.aim(Vector2(620, 1400), weapon, arena, "easy", "")
	seed(5)
	var hard := SiegeAi.aim(Vector2(620, 1400), weapon, arena, "hard", "")
	seed(5)
	var marked := SiegeAi.aim(Vector2(620, 1400), weapon, arena, "easy", "marksman")
	var easy_bolt := SiegeAi.pick_weapon([Catalog.weapon("heavy_boulder"), weapon], arena, "easy")
	print("aim easy ", easy.angle, " hard ", hard.angle, " marksman ", marked.angle)
	return String(easy_bolt.impact_behavior) == "pierce" and float(easy.angle) != float(hard.angle) and float(easy.angle) != float(marked.angle)


func _logic_perk_reload() -> bool:
	return PerkRules.reload_scale("rapid_reload") < 1.0 and PerkRules.reload_scale("siege_master") > 1.0 and PerkRules.damage_scale("siege_master") > 1.0 and PerkRules.damage_scale("marksman") < 1.0


func _logic_layout() -> bool:
	var errors := LayoutRules.cell_errors(DemoLayout.timber_outpost())
	if not errors.is_empty():
		print("layout errors: ", errors)
	return errors.is_empty()


func _phys_ballistics() -> bool:
	var data := Catalog.weapon("heavy_boulder")
	var projectile := load("res://scenes/projectiles/projectile.tscn").instantiate() as Projectile
	add_child(projectile)
	var origin := Vector2(80, -5200)
	var velocity := Vector2(460, -160)
	projectile.global_position = origin
	projectile.arm(data, velocity)
	var predicted := Ballistics.simulate(origin, velocity, data.gravity_scale, 30)
	var worst := 0.0
	for i in predicted.size():
		await get_tree().physics_frame
		if not is_instance_valid(projectile):
			return false
		var xf: Transform2D = PhysicsServer2D.body_get_state(
			projectile.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM
		)
		worst = maxf(worst, xf.origin.distance_to(predicted[i]))
	print("ballistics max error px: ", snappedf(worst, 0.01))
	projectile.queue_free()
	return worst < 4.0


func _phys_block() -> bool:
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask = 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 160)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = Vector2(240, -7300)
	add_child(wall)
	var projectile := load("res://scenes/projectiles/projectile.tscn").instantiate() as Projectile
	add_child(projectile)
	projectile.global_position = Vector2(-80, -7300)
	projectile.arm(Catalog.weapon("piercing_bolt"), Vector2(2400, 0))
	for _i in 40:
		await get_tree().physics_frame
	var stopped := is_instance_valid(projectile) and projectile.global_position.x < 280.0 and projectile.touched
	print("block test x=", projectile.global_position.x if is_instance_valid(projectile) else -1, " touched=", projectile.touched if is_instance_valid(projectile) else false)
	if is_instance_valid(projectile):
		projectile.queue_free()
	wall.queue_free()
	return stopped


func _phys_rest() -> bool:
	var data := Catalog.piece("small_block")
	var material := Catalog.material("wood")
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(500, 40)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0, -4000)
	add_child(floor_body)
	var scene: PackedScene = load("res://scenes/pieces/structural_piece.tscn")
	var cells: Array[Vector2i] = [Vector2i(0, 0)]
	var bottom := scene.instantiate() as StructuralPiece
	var top := scene.instantiate() as StructuralPiece
	bottom.configure(data, material, cells)
	top.configure(data, material, cells)
	add_child(bottom)
	add_child(top)
	bottom.global_position = Vector2(0, -4050)
	top.global_position = Vector2(0, -4110)
	bottom.spawn_position = bottom.global_position
	top.spawn_position = top.global_position
	bottom.freeze = false
	top.freeze = false
	bottom.linear_velocity = Vector2.ZERO
	top.linear_velocity = Vector2.ZERO
	var mat_b := bottom.physics_material_override as PhysicsMaterial
	var mat_t := top.physics_material_override as PhysicsMaterial
	mat_b.bounce = 0.0
	mat_t.bounce = 0.0
	var start_bottom := bottom.durability
	var start_top := top.durability
	for _i in 180:
		await get_tree().physics_frame
		if not is_instance_valid(bottom) or not is_instance_valid(top):
			return false
	var ok := absf(bottom.durability - start_bottom) < 0.01 and absf(top.durability - start_top) < 0.01
	print("resting durability loss bottom=", start_bottom - bottom.durability, " top=", start_top - top.durability)
	bottom.queue_free()
	top.queue_free()
	floor_body.queue_free()
	return ok


func _phys_once() -> bool:
	var block := load("res://scenes/pieces/structural_piece.tscn").instantiate() as StructuralPiece
	var cells: Array[Vector2i] = [Vector2i(0, 0)]
	block.configure(Catalog.piece("small_block"), Catalog.material("stone"), cells)
	add_child(block)
	block.global_position = Vector2(0, -7600)
	block.freeze = true
	var hits := [0]
	var start_durability := block.durability
	block.damaged.connect(func(_amount: float) -> void: hits[0] += 1)
	var projectile := load("res://scenes/projectiles/projectile.tscn").instantiate() as Projectile
	add_child(projectile)
	projectile.global_position = Vector2(-220, -7600)
	projectile.arm(Catalog.weapon("heavy_boulder"), Vector2(900, 0))
	for _i in 45:
		await get_tree().physics_frame
	print("single contact damage events=", hits[0], " start=", start_durability, " durability=", block.durability if is_instance_valid(block) else -1)
	var ok: bool = int(hits[0]) == 1
	if is_instance_valid(projectile):
		projectile.queue_free()
	if is_instance_valid(block):
		block.queue_free()
	return ok


func _phys_boom() -> bool:
	var near := _loose_box(Vector2(180, -8600))
	var far := _loose_box(Vector2(900, -8600))
	await get_tree().physics_frame
	var weapon := Catalog.weapon("explosive_shot")
	Explosion.detonate(self, Vector2(80, -8600), weapon.explosion_radius, weapon.explosion_impulse, weapon.explosion_damage, 1.0, null)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var near_speed := near.linear_velocity.length()
	var far_speed := far.linear_velocity.length()
	print("explosion near=", snappedf(near_speed, 0.1), " far=", snappedf(far_speed, 0.1))
	var ok := near_speed > far_speed + 20.0 and far_speed < 15.0
	near.queue_free()
	far.queue_free()
	return ok


func _loose_box(at: Vector2) -> RigidBody2D:
	var body := RigidBody2D.new()
	body.gravity_scale = 0.0
	body.mass = 2.0
	body.collision_layer = 2
	body.collision_mask = 1
	body.can_sleep = false
	body.sleeping = false
	body.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	body.linear_damp = 0.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	body.global_position = at
	return body


func _phys_core_match() -> bool:
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if battle.victory:
		print("keep was already defeated before the hit")
		battle.queue_free()
		return false
	var core: StructuralPiece = battle.arena.core
	if core == null:
		print("battle spawned no keep core")
		battle.queue_free()
		return false
	core.receive_impact(4242, 1600.0, 8000000.0, 8.0, Vector2.ZERO, false)
	await get_tree().physics_frame
	var won: bool = battle.victory
	print("core match victory=", won, " core durability=", core.durability if is_instance_valid(core) else 0)
	Engine.time_scale = 1.0
	battle.queue_free()
	return won


func _phys_two_towers() -> bool:
	Game.suppress_navigation = true
	Game.mode = "campaign"
	Game.encounter_id = "timber_outpost"
	Game.difficulty = "easy"
	Game.design_lines = Layouts.homestead()
	Game.loadout_weapons = PackedStringArray(["piercing_bolt"])
	Game.loadout_perk = "marksman"
	var siege = load("res://scenes/battle/siege_match.tscn").instantiate()
	add_child(siege)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player_core: StructuralPiece = siege.player_arena.core
	var enemy_core: StructuralPiece = siege.enemy_arena.core
	var separated := false
	if player_core != null and enemy_core != null:
		separated = enemy_core.global_position.x > player_core.global_position.x + 1000.0
	var ok: bool = player_core != null and enemy_core != null and separated and not siege.finished and siege.player_arena != siege.enemy_arena
	print("two towers player=", player_core != null, " enemy=", enemy_core != null, " finished=", siege.finished, " separated=", separated)
	siege.queue_free()
	Game.mode = ""
	Game.encounter_id = ""
	await get_tree().process_frame
	return ok
