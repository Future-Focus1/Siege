class_name UiKit
extends RefCounted

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var made := Theme.new()
	made.default_font_size = 40
	var normal := _box(Color("243140"), Color("e2b33a"))
	var hover := _box(Color("314055"), Color("f0d48a"))
	var pressed := _box(Color("1a2430"), Color("c4922a"))
	var disabled := _box(Color("2a3038"), Color("5c656e"))
	made.set_stylebox("normal", "Button", normal)
	made.set_stylebox("hover", "Button", hover)
	made.set_stylebox("pressed", "Button", pressed)
	made.set_stylebox("disabled", "Button", disabled)
	made.set_stylebox("focus", "Button", normal)
	made.set_color("font_color", "Button", Color("f6f1e4"))
	made.set_color("font_hover_color", "Button", Color.WHITE)
	made.set_color("font_pressed_color", "Button", Color("f6f1e4"))
	made.set_color("font_disabled_color", "Button", Color("9aa3ab"))
	made.set_font_size("font_size", "Button", 40)
	made.set_font_size("font_size", "Label", 36)
	made.set_color("font_color", "Label", Color("f6f1e4"))
	_theme = made
	return made


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(4)
	box.set_corner_radius_all(22)
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	return box


static func button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(520, 112)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	return button


static func label(text: String, size: int = 36) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node
