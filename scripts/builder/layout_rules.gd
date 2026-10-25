class_name LayoutRules
extends RefCounted

## Placement rules shared by the editor, saves, and battles.
## Editing allows an unfinished tower. Saving and fighting require a supported keep.


static func edit_errors(lines: PackedStringArray) -> PackedStringArray:
	return _collect(lines, false)


static func validate(lines: PackedStringArray) -> PackedStringArray:
	return _collect(lines, true)


static func total_cost(lines: PackedStringArray) -> int:
	Catalog.ensure()
	var total := 0
	for line in lines:
		if String(line).strip_edges().is_empty():
			continue
		var placement := Placement.parse(line)
		var data := Catalog.piece(placement.piece_id)
		var material := Catalog.material(placement.material_id)
		if data == null or material == null:
			continue
		total += data.cost_for(material)
	return total


static func cell_errors(lines: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	for line in _collect(lines, false):
		if line.begins_with("overlap") or line.begins_with("out of bounds") or line.begins_with("unknown"):
			errors.append(line)
	return errors


static func _collect(lines: PackedStringArray, strict: bool) -> PackedStringArray:
	Catalog.ensure()
	var errors := PackedStringArray()
	var occupied := {}
	var counts := {}
	var entries: Array = []
	var cores := 0
	var budget := Catalog.balance.build_budget
	var spent := 0
	for line in lines:
		if String(line).strip_edges().is_empty():
			continue
		var placement := Placement.parse(line)
		var data := Catalog.piece(placement.piece_id)
		if data == null:
			errors.append("unknown piece %s" % placement.piece_id)
			continue
		var material := Catalog.material(placement.material_id)
		if material == null:
			errors.append("unknown material %s" % placement.material_id)
			continue
		if not data.allows(placement.material_id):
			errors.append("%s cannot use %s" % [placement.piece_id, placement.material_id])
		var used := int(counts.get(placement.piece_id, 0)) + 1
		counts[placement.piece_id] = used
		if used > data.max_count:
			errors.append("too many %s" % placement.piece_id)
		spent += data.cost_for(material)
		if data.is_core():
			cores += 1
		var cells := data.world_cells(placement.col, placement.row, placement.rot)
		var kept: Array[Vector2i] = []
		for cell in cells:
			if cell.x < 0 or cell.y < 0 or cell.x >= SiegeGrid.COLS or cell.y >= SiegeGrid.ROWS:
				errors.append("out of bounds %s at %d,%d" % [placement.piece_id, cell.x, cell.y])
				continue
			var key := "%d,%d" % [cell.x, cell.y]
			if occupied.has(key):
				errors.append("overlap at %s" % key)
			occupied[key] = placement.piece_id
			kept.append(cell)
		entries.append({"piece_id": placement.piece_id, "cells": kept, "core": data.is_core()})
	if lines.size() > Catalog.balance.max_pieces:
		errors.append("too many pieces")
	if spent > budget:
		errors.append("over budget %d/%d" % [spent, budget])
	if cores > 1:
		errors.append("only one keep core")
	if strict and cores != 1:
		errors.append("a keep core is required")
	if strict:
		for issue in _support_errors(entries):
			errors.append(issue)
	return errors


static func _support_errors(entries: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var count := entries.size()
	var neighbors: Array = []
	var grounded := {}
	for i in count:
		neighbors.append([])
		var cells: Array = entries[i].cells
		for cell in cells:
			if cell.y == 0:
				grounded[i] = true
				break
	for i in count:
		for j in range(i + 1, count):
			if _cells_touch(entries[i].cells, entries[j].cells):
				(neighbors[i] as Array).append(j)
				(neighbors[j] as Array).append(i)
	var seen := {}
	var queue: Array = []
	for key in grounded.keys():
		seen[key] = true
		queue.append(key)
	while not queue.is_empty():
		var current = queue.pop_front()
		for next in neighbors[current]:
			if seen.has(next):
				continue
			seen[next] = true
			queue.append(next)
	var core_supported := false
	var found_core := false
	for i in count:
		if bool(entries[i].core):
			found_core = true
			if seen.has(i):
				core_supported = true
		elif not seen.has(i):
			errors.append("unsupported %s" % String(entries[i].piece_id))
	if found_core and not core_supported:
		errors.append("keep core is not supported")
	return errors


static func _cells_touch(a: Array, b: Array) -> bool:
	for ca in a:
		for cb in b:
			if absi(ca.x - cb.x) + absi(ca.y - cb.y) == 1:
				return true
	return false
