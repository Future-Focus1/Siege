class_name SaveGame
extends RefCounted

const VERSION := 1


static func ensure() -> void:
	DirAccess.make_dir_recursive_absolute("user://siege/designs")
	DirAccess.make_dir_recursive_absolute("user://siege/logs")


static func save_design(design_name: String, lines: PackedStringArray) -> Dictionary:
	ensure()
	var problems := LayoutRules.validate(lines)
	if not problems.is_empty():
		return {"ok": false, "errors": problems}
	var slug := _slug(design_name)
	var payload := {
		"version": VERSION,
		"kind": "tower_design",
		"name": design_name,
		"placements": _string_array(lines),
	}
	var path := "user://siege/designs/%s.json" % slug
	if not _write_json(path, payload):
		return {"ok": false, "errors": PackedStringArray(["could not write design"])}
	_touch_index(slug, design_name)
	return {"ok": true, "slug": slug}


static func load_design(slug: String) -> Dictionary:
	ensure()
	var parsed: Variant = _read_json("user://siege/designs/%s.json" % slug)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "errors": PackedStringArray(["design file is missing or unreadable"])}
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != VERSION or String(data.get("kind", "")) != "tower_design":
		return {"ok": false, "errors": PackedStringArray(["unsupported design version"])}
	var lines := PackedStringArray()
	for entry in data.get("placements", []):
		lines.append(String(entry))
	var problems := LayoutRules.validate(lines)
	if not problems.is_empty():
		return {"ok": false, "errors": problems}
	return {"ok": true, "name": String(data.get("name", slug)), "lines": lines, "slug": slug}


static func list_designs() -> Array[Dictionary]:
	ensure()
	var index: Variant = _read_json("user://siege/designs/index.json")
	var out: Array[Dictionary] = []
	if typeof(index) != TYPE_DICTIONARY:
		return out
	for entry in index.get("designs", []):
		if typeof(entry) == TYPE_DICTIONARY:
			out.append(entry)
	return out


static func save_profile(profile: Dictionary) -> void:
	ensure()
	profile["version"] = VERSION
	_write_json("user://siege/profile.json", profile)


static func load_profile() -> Dictionary:
	ensure()
	var parsed: Variant = _read_json("user://siege/profile.json")
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != VERSION:
		return {}
	return data


static func append_log(record: Dictionary) -> void:
	ensure()
	record["version"] = VERSION
	var stamp := str(Time.get_unix_time_from_system()).replace(".", "_")
	_write_json("user://siege/logs/match_%s.json" % stamp, record)


static func _touch_index(slug: String, design_name: String) -> void:
	var index: Dictionary = {}
	var parsed: Variant = _read_json("user://siege/designs/index.json")
	if typeof(parsed) == TYPE_DICTIONARY:
		index = parsed
	var designs: Array = index.get("designs", [])
	var next: Array = []
	var replaced := false
	for entry in designs:
		if typeof(entry) == TYPE_DICTIONARY and String(entry.get("slug", "")) == slug:
			next.append({"slug": slug, "name": design_name})
			replaced = true
		elif typeof(entry) == TYPE_DICTIONARY:
			next.append(entry)
	if not replaced:
		next.append({"slug": slug, "name": design_name})
	_write_json("user://siege/designs/index.json", {"version": VERSION, "designs": next})


static func _string_array(lines: PackedStringArray) -> Array:
	var out: Array = []
	for line in lines:
		out.append(String(line))
	return out


static func _slug(design_name: String) -> String:
	var slug := ""
	for i in design_name.length():
		var ch := design_name.substr(i, 1).to_lower()
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			slug += ch
		else:
			slug += "_"
	slug = slug.strip_edges()
	if slug.is_empty():
		slug = "design"
	return slug.substr(0, 40)


static func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  "))
	return true


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed
