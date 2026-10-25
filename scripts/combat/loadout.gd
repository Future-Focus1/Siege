class_name Loadout
extends RefCounted

var weapon_ids: PackedStringArray = PackedStringArray()
var perk_id: String = ""


func cost() -> int:
	Catalog.ensure()
	var total := 0
	for id in weapon_ids:
		var weapon := Catalog.weapon(id)
		if weapon:
			total += weapon.cost
	if perk_id != "":
		var perk := Catalog.perk(perk_id)
		if perk:
			total += perk.cost
	return total


func errors() -> PackedStringArray:
	Catalog.ensure()
	var found := PackedStringArray()
	if weapon_ids.is_empty():
		found.append("equip at least one weapon")
	var seen := {}
	for id in weapon_ids:
		if seen.has(id):
			found.append("duplicate weapon %s" % id)
		seen[id] = true
		if Catalog.weapon(id) == null:
			found.append("unknown weapon %s" % id)
	if perk_id != "" and Catalog.perk(perk_id) == null:
		found.append("unknown perk %s" % perk_id)
	var budget := Catalog.balance.loadout_budget
	var spent := cost()
	if spent > budget:
		found.append("loadout over budget %d/%d" % [spent, budget])
	return found


func weapons() -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for id in weapon_ids:
		var weapon := Catalog.weapon(id)
		if weapon:
			out.append(weapon)
	return out
