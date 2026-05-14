extends Node

signal language_changed(language: String)
signal state_changed
signal save_loaded

const SAVE_VERSION := 1

var state: Dictionary = {}


func _ready() -> void:
	reset_to_default()


func get_default_state() -> Dictionary:
	var now: float = Time.get_unix_time_from_system()
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
		"completed_achievements": [],
		"claimed_achievements": [],
		"owned_reptile_instances": {},
		"owned_variant_instances": {},
		"quests": {},
		"quest_progress": {},
		"quest_event_counters": {},
		"completed_quests": [],
		"claimed_quests": [],
		"workers": {},
		"upgrades": {},
		"last_saved_at": 0,
		"last_income_timestamp": now,
		"last_active_timestamp": now,
		"pending_offline_income": 0,
		"pending_offline_seconds": 0,
		"offline_claim_available": false,
		"last_offline_claim_timestamp": 0
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
	save_loaded.emit()
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_value("last_active_timestamp", Time.get_unix_time_from_system())
		if has_node("/root/SaveSystem"):
			var save_sys = get_node("/root/SaveSystem")
			if save_sys.has_method("save_game"):
				save_sys.save_game()
