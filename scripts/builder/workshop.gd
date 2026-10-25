extends Node2D

var lines: Array[String] = []
var undo_stack: Array = []
var redo_stack: Array = []
var armed_piece := "small_block"
var armed_material := "wood"
var armed_rot := 0
var selected := -1
var message := ""
var view: Node2D
var budget_label: Label
var message_label: Label
var name_field: LineEdit


func _ready() -> void:
	Catalog.ensure()
	if Game.editor_lines.size() > 0:
		for line in Game.editor_lines:
			lines.append(String(line))
	else:
		for line in Layouts.homestead():
			lines.append(line)
	_build_camera()
	_build_hud()
	_rebuild()


func _build_camera() -> void:
	view = Node2D.new()
	add_child(view)
	var camera := Camera2D.new()
	camera.position = Vector2(1280, 1080)
	add_child(camera)
	camera.make_current()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var top := PanelContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 24
	top.offset_top = 36
	top.offset_right = -24
	top.offset_bottom = 230
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_theme_stylebox_override("panel", _panel())
	layer.add_child(top)
	var top_box := VBoxContainer.new()
	top.add_child(top_box)
	var title := UiKit.label("Tower Builder", 40)
	top_box.add_child(title)
	budget_label = UiKit.label("Budget", 30)
	top_box.add_child(budget_label)
	message_label = UiKit.label("Tap the grid to place. Tap a piece to select it.", 26)
	top_box.add_child(message_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	top_box.add_child(actions)
	_action(actions, "Rotate", _rotate_selected)
	_action(actions, "Remove", _remove_selected)
	_action(actions, "Undo", _undo)
	_action(actions, "Redo", _redo)
	_action(actions, "Menu", func() -> void: Game.open_menu(Game.return_page if Game.return_page != "" else "main"))

	var bottom := PanelContainer.new()
	bottom.offset_left = 24
	bottom.offset_top = 1500
	bottom.offset_right = 1056
	bottom.offset_bottom = 1896
	bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom.add_theme_stylebox_override("panel", _panel())
	layer.add_child(bottom)
	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 8)
	bottom.add_child(bottom_box)
	var materials := HBoxContainer.new()
	materials.add_theme_constant_override("separation", 10)
	bottom_box.add_child(materials)
	for material_id in ["wood", "stone", "metal"]:
		var button := Button.new()
		button.text = material_id.capitalize()
		button.custom_minimum_size = Vector2(160, 72)
		button.theme = UiKit.theme()
		button.pressed.connect(_arm_material.bind(material_id))
		materials.add_child(button)
	var pieces := HBoxContainer.new()
	pieces.add_theme_constant_override("separation", 8)
	bottom_box.add_child(pieces)
	for piece_id in ["small_block", "large_block", "horizontal_beam", "vertical_pillar", "diagonal_brace"]:
		_piece_button(pieces, piece_id)
	var pieces_b := HBoxContainer.new()
	pieces_b.add_theme_constant_override("separation", 8)
	bottom_box.add_child(pieces_b)
	for piece_id in ["reinforced_beam", "foundation_anchor", "shield_generator", "keep_core"]:
		_piece_button(pieces_b, piece_id)
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 10)
	bottom_box.add_child(save_row)
	name_field = LineEdit.new()
	name_field.placeholder_text = "Design name"
	name_field.text = "My Tower"
	name_field.custom_minimum_size = Vector2(360, 72)
	name_field.add_theme_font_size_override("font_size", 28)
	save_row.add_child(name_field)
	_action(save_row, "Save", _save)
	_action(save_row, "Load", _load_menu)
	_action(save_row, "Test", _test_tower)


func _piece_button(parent: HBoxContainer, piece_id: String) -> void:
	var data := Catalog.piece(piece_id)
	var button := Button.new()
	button.text = data.display_name if data else piece_id
	button.custom_minimum_size = Vector2(190, 72)
	button.theme = UiKit.theme()
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(_arm_piece.bind(piece_id))
	parent.add_child(button)


func _action(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 72)
	button.theme = UiKit.theme()
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	parent.add_child(button)


func _panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.11, 0.15, 0.9)
	box.set_corner_radius_all(20)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


func _arm_piece(piece_id: String) -> void:
	armed_piece = piece_id
	var data := Catalog.piece(piece_id)
	if data and not data.allows(armed_material):
		armed_material = String(data.allowed_materials[0])
	message = "Placing %s" % data.display_name
	_refresh_labels()


func _arm_material(material_id: String) -> void:
	var data := Catalog.piece(armed_piece)
	if data and not data.allows(material_id):
		message = "%s cannot be %s" % [data.display_name, material_id]
		_refresh_labels()
		return
	armed_material = material_id
	message = "Material: %s" % material_id
	_refresh_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		_tap(_world_to_cell(world))
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * (event as InputEventScreenTouch).position
		_tap(_world_to_cell(world))


func _world_to_cell(world: Vector2) -> Vector2i:
	return Vector2i(
		floori((world.x - SiegeGrid.ORIGIN_X) / float(SiegeGrid.CELL)),
		floori((SiegeGrid.GROUND_Y - world.y) / float(SiegeGrid.CELL))
	)


func _tap(cell: Vector2i) -> void:
	var hit := _index_at(cell)
	if hit >= 0:
		selected = hit
		message = "Selected piece"
		_rebuild()
		return
	if cell.x < 0 or cell.y < 0 or cell.x >= SiegeGrid.COLS or cell.y >= SiegeGrid.ROWS:
		return
	var placement := Placement.new()
	placement.piece_id = armed_piece
	placement.material_id = armed_material
	placement.col = cell.x
	placement.row = cell.y
	placement.rot = armed_rot
	var trial := _packed()
	trial.append(placement.encode())
	var problems := LayoutRules.edit_errors(trial)
	if not problems.is_empty():
		message = problems[0]
		_refresh_labels()
		return
	_push_undo()
	lines.append(placement.encode())
	selected = lines.size() - 1
	message = "Placed"
	_rebuild()


func _index_at(cell: Vector2i) -> int:
	for i in lines.size():
		var placement := Placement.parse(lines[i])
		var data := Catalog.piece(placement.piece_id)
		if data == null:
			continue
		for occupied in data.world_cells(placement.col, placement.row, placement.rot):
			if occupied == cell:
				return i
	return -1


func _rotate_selected() -> void:
	if selected < 0 or selected >= lines.size():
		armed_rot = posmod(armed_rot + 1, 4)
		message = "Place rotation %d" % armed_rot
		_refresh_labels()
		return
	var placement := Placement.parse(lines[selected])
	var trial_lines := lines.duplicate()
	placement.rot = posmod(placement.rot + 1, 4)
	trial_lines[selected] = placement.encode()
	var problems := LayoutRules.edit_errors(_to_packed(trial_lines))
	if not problems.is_empty():
		message = problems[0]
		_refresh_labels()
		return
	_push_undo()
	lines = trial_lines
	message = "Rotated"
	_rebuild()


func _remove_selected() -> void:
	if selected < 0 or selected >= lines.size():
		message = "Select a piece first"
		_refresh_labels()
		return
	_push_undo()
	lines.remove_at(selected)
	selected = -1
	message = "Removed"
	_rebuild()


func _undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(_packed())
	_restore(undo_stack.pop_back())
	message = "Undone"


func _redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(_packed())
	_restore(redo_stack.pop_back())
	message = "Redone"


func _save() -> void:
	var design_name := name_field.text.strip_edges()
	if design_name.is_empty():
		design_name = "My Tower"
	var result := SaveGame.save_design(design_name, _packed())
	if not bool(result.get("ok", false)):
		var problems: PackedStringArray = result.get("errors", PackedStringArray())
		message = problems[0] if problems.size() else "Save failed"
	else:
		message = "Saved %s" % design_name
		Game.selected_design = String(result.get("slug", ""))
		Game.save_profile()
	_refresh_labels()


func _load_menu() -> void:
	Game.editor_lines = _packed()
	Game.open_menu("load_design")


func _test_tower() -> void:
	var problems := LayoutRules.validate(_packed())
	if not problems.is_empty():
		message = problems[0]
		_refresh_labels()
		return
	Game.editor_lines = _packed()
	Game.design_lines = _packed()
	Game.mode = "sandbox"
	Game.open_battle()


func _push_undo() -> void:
	undo_stack.append(_packed())
	if undo_stack.size() > 40:
		undo_stack.pop_front()
	redo_stack.clear()


func _restore(snapshot: PackedStringArray) -> void:
	lines.clear()
	for line in snapshot:
		lines.append(String(line))
	selected = -1
	_rebuild()


func _packed() -> PackedStringArray:
	return _to_packed(lines)


func _to_packed(source: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for line in source:
		out.append(String(line))
	return out


func _rebuild() -> void:
	for child in view.get_children():
		child.queue_free()
	for i in lines.size():
		var placement := Placement.parse(lines[i])
		var data := Catalog.piece(placement.piece_id)
		var material := Catalog.material(placement.material_id)
		if data == null or material == null:
			continue
		for cell in data.world_cells(placement.col, placement.row, placement.rot):
			var square := Polygon2D.new()
			var half := 26.0
			square.polygon = PackedVector2Array([
				Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
			])
			square.position = SiegeGrid.cell_center(cell)
			square.color = material.color
			if i == selected:
				square.color = square.color.lightened(0.35)
			view.add_child(square)
	_refresh_labels()
	queue_redraw()


func _refresh_labels() -> void:
	var spent := LayoutRules.total_cost(_packed())
	var budget := Catalog.balance.build_budget
	budget_label.text = "Budget %d / %d    %s / %s" % [spent, budget, armed_piece, armed_material]
	var strict := LayoutRules.validate(_packed())
	var note := message
	if not strict.is_empty():
		note = "%s  —  %s" % [message, strict[0]]
	message_label.text = note


func _draw() -> void:
	var left := SiegeGrid.ORIGIN_X
	var bottom := SiegeGrid.GROUND_Y
	var width := float(SiegeGrid.COLS * SiegeGrid.CELL)
	var height := float(SiegeGrid.ROWS * SiegeGrid.CELL)
	draw_rect(Rect2(left - 80, bottom - height - 80, width + 160, height + 200), Color("8ec6ea"))
	draw_rect(Rect2(left - 200, bottom, width + 400, 400), Color("6f8f4e"))
	draw_rect(Rect2(left, bottom - height, width, height), Color(1, 1, 1, 0.08), false, 4.0)
	for col in SiegeGrid.COLS + 1:
		var x := left + float(col * SiegeGrid.CELL)
		draw_line(Vector2(x, bottom - height), Vector2(x, bottom), Color(1, 1, 1, 0.18), 2.0)
	for row in SiegeGrid.ROWS + 1:
		var y := bottom - float(row * SiegeGrid.CELL)
		draw_line(Vector2(left, y), Vector2(left + width, y), Color(1, 1, 1, 0.18), 2.0)
