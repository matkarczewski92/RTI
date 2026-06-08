extends Node

signal upgrades_changed
signal upgrade_purchased(upgrade_id: String, level: int)

const UPGRADES_PATH := "res://data/upgrades.json"
const BASE_OFFLINE_CAP_SECONDS := 28800
const CARE_UPGRADE_ACTION_MAP := {
	"feed": "better_food",
	"water": "better_water",
	"clean": "better_clean",
	"play": "better_play"
}
const CARE_UPGRADE_REDUCTION_PER_LEVEL := 0.05
const CARE_UPGRADE_MIN_MULTIPLIER := 0.50
const BIOME_SCOPED_UPGRADE_IDS: Array[String] = ["upgrade_worker_efficiency", "food_storage", "water_storage", "better_food", "better_water"]
const LEGACY_BIOME_UPGRADE_MAP := {
	"better_food_green_meadow": {"upgrade_id": "better_food", "biome_id": "green_meadow"},
	"better_water_green_meadow": {"upgrade_id": "better_water", "biome_id": "green_meadow"},
	"better_food_dry_prairie": {"upgrade_id": "better_food", "biome_id": "dry_prairie"},
	"better_water_dry_prairie": {"upgrade_id": "better_water", "biome_id": "dry_prairie"}
}

var upgrades: Array = []
var upgrade_by_id: Dictionary = {}


func _ready() -> void:
	load_data()
	call_deferred("migrate_save_state")


func load_data() -> bool:
	var file: FileAccess = FileAccess.open(UPGRADES_PATH, FileAccess.READ)
	if file == null:
		upgrades = []
		upgrade_by_id = {}
		push_warning("Missing upgrades data file: " + UPGRADES_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		upgrades = []
		upgrade_by_id = {}
		push_warning("Invalid upgrades data file: " + UPGRADES_PATH)
		return false

	upgrades = []
	upgrade_by_id = {}
	for upgrade_value in (parsed as Array):
		if typeof(upgrade_value) != TYPE_DICTIONARY:
			continue
		var upgrade: Dictionary = _normalize_upgrade_definition(upgrade_value as Dictionary)
		var upgrade_id: String = str(upgrade.get("id", ""))
		if upgrade_id.is_empty():
			continue
		upgrades.append(upgrade)
		upgrade_by_id[upgrade_id] = upgrade

	upgrades.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	return true


func migrate_save_state() -> bool:
	var changed := false
	var levels_value: Variant = GameState.get_value("upgrade_levels", {})
	if typeof(levels_value) != TYPE_DICTIONARY:
		GameState.set_value("upgrade_levels", {})
		levels_value = GameState.get_value("upgrade_levels", {})
		changed = true
	var biome_levels_value: Variant = GameState.get_value("upgrade_levels_by_biome", {})
	var biome_levels: Dictionary = {}
	if typeof(biome_levels_value) == TYPE_DICTIONARY:
		biome_levels = biome_levels_value as Dictionary

	var levels: Dictionary = levels_value as Dictionary
	var legacy_value: Variant = GameState.get_value("upgrades", {})
	if typeof(legacy_value) == TYPE_DICTIONARY:
		var legacy: Dictionary = legacy_value as Dictionary
		for legacy_id in legacy.keys():
			if levels.has(legacy_id):
				continue
			var legacy_state: Variant = legacy.get(legacy_id)
			if typeof(legacy_state) == TYPE_DICTIONARY:
				levels[legacy_id] = int(max(0, int((legacy_state as Dictionary).get("level", 0))))
				changed = true
			elif typeof(legacy_state) == TYPE_INT or typeof(legacy_state) == TYPE_FLOAT:
				levels[legacy_id] = int(max(0, int(legacy_state)))
				changed = true

	for legacy_id in LEGACY_BIOME_UPGRADE_MAP.keys():
		if not levels.has(legacy_id):
			continue
		var legacy_level: int = int(max(0, int(levels.get(legacy_id, 0))))
		if legacy_level <= 0:
			continue
		var mapping: Dictionary = LEGACY_BIOME_UPGRADE_MAP[legacy_id] as Dictionary
		var mapped_upgrade_id: String = str(mapping.get("upgrade_id", ""))
		var mapped_biome_id: String = _normalize_biome_id(str(mapping.get("biome_id", "")))
		var biome_state: Dictionary = _get_biome_upgrade_levels(mapped_biome_id, biome_levels)
		biome_state[mapped_upgrade_id] = max(legacy_level, int(biome_state.get(mapped_upgrade_id, 0)))
		biome_levels[mapped_biome_id] = biome_state
		levels.erase(legacy_id)
		changed = true

	for upgrade_id in levels.keys():
		var normalized_level: int = int(max(0, int(levels.get(upgrade_id, 0))))
		var definition: Dictionary = get_upgrade_definition(str(upgrade_id))
		if not definition.is_empty():
			normalized_level = int(min(normalized_level, int(definition.get("max_level", normalized_level))))
		if _is_biome_scoped_upgrade(str(upgrade_id)) and normalized_level > 0:
			var default_biome_state: Dictionary = _get_biome_upgrade_levels(GameState.DEFAULT_BIOME_ID, biome_levels)
			default_biome_state[str(upgrade_id)] = max(normalized_level, int(default_biome_state.get(str(upgrade_id), 0)))
			biome_levels[GameState.DEFAULT_BIOME_ID] = default_biome_state
			levels.erase(upgrade_id)
			changed = true
			continue
		if levels.get(upgrade_id) != normalized_level:
			levels[upgrade_id] = normalized_level
			changed = true

	for biome_id_value in biome_levels.keys():
		var biome_id: String = _normalize_biome_id(str(biome_id_value))
		var biome_state_value: Variant = biome_levels.get(biome_id_value)
		if typeof(biome_state_value) != TYPE_DICTIONARY:
			biome_levels.erase(biome_id_value)
			changed = true
			continue
		var biome_state: Dictionary = biome_state_value as Dictionary
		for upgrade_id in biome_state.keys():
			var normalized_level: int = int(max(0, int(biome_state.get(upgrade_id, 0))))
			var definition: Dictionary = get_upgrade_definition(str(upgrade_id))
			if not definition.is_empty():
				normalized_level = int(min(normalized_level, int(definition.get("max_level", normalized_level))))
			if biome_state.get(upgrade_id) != normalized_level:
				biome_state[upgrade_id] = normalized_level
				changed = true
		if biome_id != str(biome_id_value):
			biome_levels.erase(biome_id_value)
			changed = true
		biome_levels[biome_id] = biome_state

	if changed:
		GameState.set_value("upgrade_levels", levels)
		GameState.set_value("upgrade_levels_by_biome", biome_levels)
		SaveSystem.save_game()

	return changed


func get_upgrade_definitions(include_disabled: bool = false) -> Array:
	var result: Array = []
	for upgrade_value in upgrades:
		if typeof(upgrade_value) != TYPE_DICTIONARY:
			continue
		var upgrade: Dictionary = upgrade_value as Dictionary
		if not include_disabled and not bool(upgrade.get("enabled", true)):
			continue
		result.append(upgrade)
	return result


func get_upgrade_definition(upgrade_id: String) -> Dictionary:
	var value: Variant = upgrade_by_id.get(upgrade_id, {})
	if typeof(value) == TYPE_DICTIONARY:
		return value as Dictionary
	return {}


func get_upgrade_level(upgrade_id: String, biome_id: String = "") -> int:
	if _is_biome_scoped_upgrade(upgrade_id):
		var biome_state: Dictionary = _get_biome_upgrade_levels(_normalize_biome_id(biome_id))
		return int(max(0, int(biome_state.get(upgrade_id, 0))))

	var levels_value: Variant = GameState.get_value("upgrade_levels", {})
	if typeof(levels_value) != TYPE_DICTIONARY:
		return 0

	var levels: Dictionary = levels_value as Dictionary
	return int(max(0, int(levels.get(upgrade_id, 0))))


func get_upgrade_cost(upgrade_id: String, biome_id: String = "") -> int:
	var upgrade: Dictionary = get_upgrade_definition(upgrade_id)
	if upgrade.is_empty():
		return -1

	var level: int = get_upgrade_level(upgrade_id, biome_id)
	var max_level: int = int(upgrade.get("max_level", 1))
	if level >= max_level:
		return -1

	var base_cost: float = float(upgrade.get("base_cost", 0))
	var multiplier: float = max(1.0, float(upgrade.get("cost_multiplier", 1.0)))
	return int(round(base_cost * pow(multiplier, level)))


func can_buy_upgrade(upgrade_id: String, biome_id: String = "") -> bool:
	var cost: int = get_upgrade_cost(upgrade_id, biome_id)
	return cost >= 0 and EconomySystem.can_afford("repticash", cost)


func buy_upgrade(upgrade_id: String, biome_id: String = "") -> Dictionary:
	var upgrade: Dictionary = get_upgrade_definition(upgrade_id)
	if upgrade.is_empty() or not bool(upgrade.get("enabled", true)):
		return {"success": false, "message_key": "upgrades.unavailable"}

	var target_biome_id: String = _normalize_biome_id(biome_id)
	var level: int = get_upgrade_level(upgrade_id, target_biome_id)
	var max_level: int = int(upgrade.get("max_level", 1))
	if level >= max_level:
		return {"success": false, "message_key": "ui.upgrade_max"}

	var cost: int = get_upgrade_cost(upgrade_id, target_biome_id)
	if cost > 0 and not EconomySystem.can_afford("repticash", cost):
		return {"success": false, "message_key": "ui.not_enough_rs", "cost": cost}
	if cost > 0 and not EconomySystem.spend_currency("repticash", cost):
		return {"success": false, "message_key": "ui.not_enough_rs", "cost": cost}

	if _is_biome_scoped_upgrade(upgrade_id):
		var biome_levels: Dictionary = _get_upgrade_levels_by_biome_state()
		var biome_state: Dictionary = _get_biome_upgrade_levels(target_biome_id, biome_levels)
		biome_state[upgrade_id] = level + 1
		biome_levels[target_biome_id] = biome_state
		GameState.set_value("upgrade_levels_by_biome", biome_levels)
	else:
		var levels_value: Variant = GameState.get_value("upgrade_levels", {})
		var levels: Dictionary = {}
		if typeof(levels_value) == TYPE_DICTIONARY:
			levels = levels_value as Dictionary
		levels[upgrade_id] = level + 1
		GameState.set_value("upgrade_levels", levels)
	SaveSystem.save_game()
	_notify_progress_changed()
	upgrade_purchased.emit(upgrade_id, level + 1)
	upgrades_changed.emit()
	return {"success": true, "upgrade_id": upgrade_id, "biome_id": target_biome_id, "level": level + 1, "cost": cost}


func get_reptile_income_multiplier() -> float:
	return _get_multiplier_effect("upgrade_reptile_income", 1.0)


func get_offline_income_cap_bonus_seconds() -> int:
	return int(round(_get_raw_effect("upgrade_offline_cap")))


func get_offline_income_cap_seconds() -> int:
	return BASE_OFFLINE_CAP_SECONDS + get_offline_income_cap_bonus_seconds()


func get_play_reward_multiplier() -> float:
	return _get_multiplier_effect("upgrade_play_reward", 1.0)


func get_happiness_decay_multiplier() -> float:
	var level: int = get_upgrade_level("upgrade_happiness_decay")
	var upgrade: Dictionary = get_upgrade_definition("upgrade_happiness_decay")
	var per_level: float = float(upgrade.get("effect_per_level", 0.05))
	return max(0.25, 1.0 - (float(level) * per_level))


func get_worker_efficiency_multiplier(biome_id: String = "") -> float:
	return _get_multiplier_effect("upgrade_worker_efficiency", 1.0, biome_id)


func get_collection_bonus_multiplier() -> float:
	return _get_multiplier_effect("upgrade_collection_bonus", 1.0)


func get_effect_value(upgrade_id: String, level: int = -1, biome_id: String = "") -> float:
	if level < 0:
		level = get_upgrade_level(upgrade_id, biome_id)
	var upgrade: Dictionary = get_upgrade_definition(upgrade_id)
	if upgrade.is_empty() or level <= 0:
		return 0.0
	return float(level) * float(upgrade.get("effect_per_level", 0.0))


func _get_raw_effect(upgrade_id: String, biome_id: String = "") -> float:
	return get_effect_value(upgrade_id, -1, biome_id)


func _get_multiplier_effect(upgrade_id: String, base: float, biome_id: String = "") -> float:
	return base + _get_raw_effect(upgrade_id, biome_id)


func _is_biome_scoped_upgrade(upgrade_id: String) -> bool:
	var upgrade: Dictionary = get_upgrade_definition(upgrade_id)
	if not upgrade.is_empty() and str(upgrade.get("scope", "global")) == "biome":
		return true
	return BIOME_SCOPED_UPGRADE_IDS.has(upgrade_id)


func _normalize_biome_id(biome_id: String) -> String:
	var normalized: String = biome_id.strip_edges()
	return GameState.DEFAULT_BIOME_ID if normalized.is_empty() else normalized


func _get_upgrade_levels_by_biome_state() -> Dictionary:
	var value: Variant = GameState.get_value("upgrade_levels_by_biome", {})
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}


func _get_biome_upgrade_levels(biome_id: String, source: Dictionary = {}) -> Dictionary:
	var target_biome_id: String = _normalize_biome_id(biome_id)
	var levels_by_biome: Dictionary = source
	if levels_by_biome.is_empty():
		levels_by_biome = _get_upgrade_levels_by_biome_state()
	var state_value: Variant = levels_by_biome.get(target_biome_id, {})
	if typeof(state_value) == TYPE_DICTIONARY:
		return (state_value as Dictionary).duplicate(true)
	return {}


func _normalize_upgrade_definition(upgrade: Dictionary) -> Dictionary:
	var normalized: Dictionary = upgrade.duplicate(true)
	normalized["id"] = str(normalized.get("id", ""))
	normalized["name_key"] = str(normalized.get("name_key", normalized.get("id", "")))
	normalized["description_key"] = str(normalized.get("description_key", normalized.get("id", "")))
	normalized["icon_path"] = str(normalized.get("icon_path", ""))
	normalized["type"] = str(normalized.get("type", ""))
	normalized["base_cost"] = int(max(0, int(normalized.get("base_cost", 0))))
	normalized["cost_multiplier"] = float(max(1.0, float(normalized.get("cost_multiplier", 1.0))))
	normalized["max_level"] = int(max(1, int(normalized.get("max_level", 1))))
	normalized["effect_type"] = str(normalized.get("effect_type", ""))
	normalized["effect_per_level"] = float(max(0.0, float(normalized.get("effect_per_level", 0.0))))
	normalized["scope"] = str(normalized.get("scope", "global"))
	normalized["unlocked_by_default"] = bool(normalized.get("unlocked_by_default", true))
	normalized["enabled"] = bool(normalized.get("enabled", true))
	normalized["sort_order"] = int(normalized.get("sort_order", 0))
	return normalized


func get_resource_storage_multiplier(resource_id: String, biome_id: String = "") -> float:
	var upgrade_id: String = resource_id + "_storage"
	var level: int = get_upgrade_level(upgrade_id, biome_id)
	if level <= 0:
		return 1.0
	var base_percent: float = float(get_upgrade_definition(upgrade_id).get("effect_per_level", 50.0))
	var multiplier: float = 1.0
	for i in range(1, level + 1):
		multiplier *= (1.0 + base_percent / (float(i) * 100.0))
	return multiplier


func get_action_cost_multiplier(action_id: String, biome_id: String = "") -> float:
	var base_upgrade_id: String = str(CARE_UPGRADE_ACTION_MAP.get(action_id, ""))
	if base_upgrade_id.is_empty():
		return 1.0
	var upgrade_id: String = base_upgrade_id
	var level: int = get_upgrade_level(upgrade_id, biome_id)
	if level <= 0:
		return 1.0
	return max(CARE_UPGRADE_MIN_MULTIPLIER, 1.0 - float(level) * CARE_UPGRADE_REDUCTION_PER_LEVEL)


func get_action_cooldown_multiplier(action_id: String) -> float:
	return get_action_cost_multiplier(action_id)


func _notify_progress_changed() -> void:
	if has_node("/root/QuestSystem"):
		var quest_system: Node = get_node("/root/QuestSystem")
		if quest_system.has_method("notify_event"):
			quest_system.call("notify_event", "state_changed", {})
