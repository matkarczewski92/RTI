extends Node

signal language_changed(language: String)
signal state_changed

const SAVE_VERSION := 1

var state: Dictionary = {}


func _ready() -> void:
	reset_to_default()


func get_default_state() -> Dictionary:
	var now: int = Time.get_unix_time_from_system()
	return {
		"save_version": SAVE_VERSION,
		"repticash": 100,
		"premium_currency": 0,
		"xp": 0,
		"level": 1,
		"food_current": 100,
		"food_max": 100,
		"water_current": 100,
		"water_max": 100,
		"last_food_regen_timestamp": now,
		"last_water_regen_timestamp": now,
		"food_regen_amount": 1,
		"water_regen_amount": 1,
		"food_regen_interval_seconds": 600,
		"water_regen_interval_seconds": 600,
		"language": "pl",
		"unlocked_biomes": ["green_meadow"],
		"habitats": {},
		"discovered_variants": {},
		"owned_reptile_instances": {},
		"owned_variant_instances": {},
		"quests": {},
		"workers": {},
		"upgrades": {},
		"last_saved_at": 0
	}


func reset_to_default() -> void:
	state = get_default_state()
	state_changed.emit()


func apply_loaded_state(loaded_state: Dictionary) -> void:
	var merged_state := get_default_state()
	for key in loaded_state.keys():
		if merged_state.has(key):
			merged_state[key] = loaded_state[key]

	state = merged_state
	state_changed.emit()
	language_changed.emit(get_language())


func get_value(key: String, fallback: Variant = null) -> Variant:
	return state.get(key, fallback)


func set_value(key: String, value: Variant) -> void:
	state[key] = value
	state_changed.emit()


func get_language() -> String:
	return str(state.get("language", "pl"))


func set_language(language: String) -> void:
	if language != "pl" and language != "en":
		language = "pl"

	if state.get("language", "pl") == language:
		return

	state["language"] = language
	language_changed.emit(language)
	state_changed.emit()
