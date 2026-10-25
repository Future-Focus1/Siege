class_name Catalog
extends RefCounted

static var _ready := false
static var materials: Dictionary = {}
static var pieces: Dictionary = {}
static var weapons: Dictionary = {}
static var perks: Dictionary = {}
static var encounters: Dictionary = {}
static var balance: BalanceConfig


static func clear() -> void:
	materials.clear()
	pieces.clear()
	weapons.clear()
	perks.clear()
	encounters.clear()
	balance = null
	_ready = false


static func ensure() -> void:
	if _ready:
		return
	_ready = true
	balance = load("res://data/balance/default_balance.tres") as BalanceConfig
	_load_dir("res://data/materials/", materials)
	_load_dir("res://data/pieces/", pieces)
	_load_dir("res://data/weapons/", weapons)
	_load_dir("res://data/perks/", perks)
	_load_dir("res://data/encounters/", encounters)


static func material(id: String) -> MaterialData:
	ensure()
	return materials.get(id) as MaterialData


static func piece(id: String) -> PieceData:
	ensure()
	return pieces.get(id) as PieceData


static func weapon(id: String) -> WeaponData:
	ensure()
	return weapons.get(id) as WeaponData


static func perk(id: String) -> PerkData:
	ensure()
	return perks.get(id) as PerkData


static func encounter(id: String) -> EncounterData:
	ensure()
	return encounters.get(id) as EncounterData


static func encounter_list() -> Array[EncounterData]:
	ensure()
	var out: Array[EncounterData] = []
	for key in encounters.keys():
		out.append(encounters[key])
	out.sort_custom(func(a: EncounterData, b: EncounterData) -> bool: return a.order < b.order)
	return out


static func _load_dir(path: String, into: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Catalog could not open %s" % path)
		return
	for fname in dir.get_files():
		if not fname.ends_with(".tres"):
			continue
		var res = load(path + fname)
		if res == null or not ("id" in res):
			push_error("Catalog skipped %s" % fname)
			continue
		into[String(res.id)] = res
