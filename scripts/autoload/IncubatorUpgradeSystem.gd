extends Node

signal upgrade_purchased(upgrade_id: String, level: int)

const UPGRADES_PATH := "res://data/incubator_upgrades.json"
const MIN_FAST_BREEDING_SECONDS := 43200   # 12h
const MIN_LONG_BREEDING_SECONDS := 86400   # 24h
const MIN_INCUBATION_SECONDS := 10800      # 3h

var _upgrades: Array = []
var _upgrade_by_id: Dictionary = {}


func _ready() -> void:
	_load_data()


func _load_data() -> bool:
	var file := FileAccess.open(UPGRADES_PATH, FileAccess.READ)
	if file == null:
		push_warning("IncubatorUpgradeSystem: incubator_upgrades.json not found.")
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("IncubatorUpgradeSystem: incubator_upgrades.json malformed.")
		return false
	_upgrades = []
	_upgrade_by_id = {}
	for val in (parsed as Array):
		if typeof(val) != TYPE_DICTIONARY:
			continue
		var upgrade: Dictionary = val as Dictionary
		var id: String = str(upgrade.get("id", ""))
		if id.is_empty():
			continue
		_upgrades.append(upgrade)
		_upgrade_by_id[id] = upgrade
	return true


# ─── Public: data access ────────────────────────────────────────────────

func get_upgrade_definitions() -> Array:
	var result: Array = []
	for val in _upgrades:
		if typeof(val) != TYPE_DICTIONARY:
			continue
		var upgrade: Dictionary = val as Dictionary
		if bool(upgrade.get("enabled", true)):
			result.append(upgrade)
	return result


func get_upgrade_definition(upgrade_id: String) -> Dictionary:
	var val: Variant = _upgrade_by_id.get(upgrade_id, {})
	if typeof(val) == TYPE_DICTIONARY:
		return val as Dictionary
	return {}


func get_level(upgrade_id: String) -> int:
	var levels_val: Variant = GameState.get_value("upgrade_levels", {})
	if typeof(levels_val) != TYPE_DICTIONARY:
		return 0
	var levels: Dictionary = levels_val as Dictionary
	return int(max(0, int(levels.get(upgrade_id, 0))))


func get_cost(upgrade_id: String) -> int:
	var upgrade: Dictionary = get_upgrade_definition(upgrade_id)
	if upgrade.is_empty():
		return -1
	var level: int = get_level(upgrade_id)
	var max_level: int = int(upgrade.get("max_level", 5))
	if level >= max_level:
		return -1
	var prices_val: Variant = upgrade.get("prices", [])
	if typeof(prices_val) != TYPE_ARRAY:
		return -1
	var prices: Array = prices_val as Array
	if level >= prices.size():
		return -1
	return int(prices[level])


func can_buy(upgrade_id: String) -> bool:
	var cost: int = get_cost(upgrade_id)
	return cost >= 0 and EconomySystem.can_afford("repticash", cost)


func buy(upgrade_id: String) -> Dictionary:
	var upgrade: Dictionary = get_upgrade_definition(upgrade_id)
	if upgrade.is_empty() or not bool(upgrade.get("enabled", true)):
		return {"success": false, "message_key": "upgrades.unavailable"}

	var level: int = get_level(upgrade_id)
	var max_level: int = int(upgrade.get("max_level", 5))
	if level >= max_level:
		return {"success": false, "message_key": "ui.upgrade_max"}

	var cost: int = get_cost(upgrade_id)
	if cost < 0:
		return {"success": false, "message_key": "ui.upgrade_max"}
	if not EconomySystem.can_afford("repticash", cost):
		return {"success": false, "message_key": "ui.not_enough_rs", "cost": cost}
	if not EconomySystem.spend_currency("repticash", cost):
		return {"success": false, "message_key": "ui.not_enough_rs", "cost": cost}

	var levels_val: Variant = GameState.get_value("upgrade_levels", {})
	var levels: Dictionary = {}
	if typeof(levels_val) == TYPE_DICTIONARY:
		levels = levels_val as Dictionary
	levels[upgrade_id] = level + 1
	GameState.set_value("upgrade_levels", levels)
	SaveSystem.save_game()
	upgrade_purchased.emit(upgrade_id, level + 1)
	return {"success": true, "upgrade_id": upgrade_id, "level": level + 1, "cost": cost}


# ─── Effect getters ──────────────────────────────────────────────────────

func get_breeding_time_multiplier() -> float:
	var level: int = get_level("incubator_faster_connection")
	if level <= 0:
		return 1.0
	var upgrade: Dictionary = get_upgrade_definition("incubator_faster_connection")
	var per_level: float = float(upgrade.get("effect_per_level", 0.05))
	return maxf(0.0, 1.0 - float(level) * per_level)


func get_incubation_time_multiplier() -> float:
	var level: int = get_level("incubator_faster_incubation")
	if level <= 0:
		return 1.0
	var upgrade: Dictionary = get_upgrade_definition("incubator_faster_incubation")
	var per_level: float = float(upgrade.get("effect_per_level", 0.05))
	return maxf(0.0, 1.0 - float(level) * per_level)


func get_humidity_decay_multiplier() -> float:
	var level: int = get_level("incubator_humidity_longer")
	if level <= 0:
		return 1.0
	var upgrade: Dictionary = get_upgrade_definition("incubator_humidity_longer")
	var per_level: float = float(upgrade.get("effect_per_level", 0.10))
	return maxf(0.0, 1.0 - float(level) * per_level)


func get_more_eggs_bonus() -> int:
	return get_level("incubator_more_eggs")
