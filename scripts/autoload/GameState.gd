extends Node

signal language_changed(language: String)
signal state_changed
signal save_loaded

const SAVE_VERSION := 2
const CURRENT_SAVE_VERSION := SAVE_VERSION
const DEFAULT_BIOME_ID := "green_meadow"
const LEVEL_PROGRESSION_PATH := "res://data/level_progression.json"

var state: Dictionary = {}
var _level_progression_cache: Dictionary = {}


func _ready() -> void:
	reset_to_default()


func get_default_settings() -> Dictionary:
	return {
		"language": "pl",
		"music_enabled": true,
		"sfx_enabled": true,
		"vibration_enabled": true
	}


func get_default_quest_state() -> Dictionary:
	return {
		"quests": {},
		"quest_progress": {},
		"quest_event_counters": {
			"incubator_entered_total": 0,
			"incubator_eggs_obtained_total": 0,
			"incubator_shop_eggs_bought_total": 0,
			"incubator_pairings_started_total": 0,
			"incubator_long_pairing_collected_total": 0,
			"incubator_successful_pairings_total": 0,
			"incubator_clutch_3_plus_total": 0,
			"incubator_clutch_5_total": 0,
			"incubator_loaded_10_eggs_container_total": 0,
			"incubator_incubations_started_total": 0,
			"incubator_run_3_containers_total": 0,
			"incubator_run_6_containers_total": 0,
			"incubator_water_actions_total": 0,
			"incubator_water_before_pause_total": 0,
			"incubator_resume_paused_incubation_total": 0,
			"incubator_hatches_total": 0,
			"incubator_hatch_rare_total": 0,
			"incubator_hatch_ultra_rare_total": 0,
			"incubator_hatch_exceptional_total": 0
		},
		"completed_quests": [],
		"claimed_quests": []
	}


func get_default_achievement_state() -> Dictionary:
	return {
		"completed_achievements": [],
		"claimed_achievements": []
	}


func get_default_worker_state() -> Dictionary:
	return {
		"workers": {},
		"worker_levels": {}
	}


func get_default_upgrade_state() -> Dictionary:
	return {
		"upgrades": {},
		"upgrade_levels": {}
	}


func get_default_onboarding_state() -> Dictionary:
	return {
		"welcome_seen": false,
		"active_task_id": "",
		"active_task_accepted": false,
		"active_task_completed": false,
		"completed_task_ids": [],
		"skipped_task_ids": [],
		"claimed_task_ids": [],
		"onboarding_finished": false,
		"bubble_visible": false,
		"event_counters": {}
	}


func normalize_onboarding_state(value: Variant) -> Dictionary:
	return _normalize_onboarding_state(value)


func get_default_habitat_state(habitat_id: String = "", biome_id: String = DEFAULT_BIOME_ID, slot_index: int = 0) -> Dictionary:
	return {
		"habitat_id": habitat_id,
		"biome_id": biome_id,
		"slot_index": slot_index,
		"purchased": false,
		"habitat_type": "grass",
		"habitat_level": 1,
		"is_building": false,
		"build_started_at": 0,
		"build_finish_at": 0,
		"is_upgrading": false,
		"upgrade_target_level": 0,
		"upgrade_started_at": 0,
		"upgrade_finish_at": 0,
		"reptile_id": "",
		"reptile_instance_id": "",
		"animal_instance_id": null,
		"variant_id": "",
		"habitat_variant_id": "default",
		"habitat_skin_id": "default"
	}


func get_default_animal_instance(instance_id: String = "") -> Dictionary:
	var now: int = int(Time.get_unix_time_from_system())
	return {
		"instance_id": instance_id,
		"animal_instance_id": instance_id,
		"reptile_id": "unknown_reptile",
		"species_id": "unknown_reptile",
		"variant_id": "unknown_reptile_common",
		"rarity": "common",
		"sex": "male",
		"custom_name": "",
		"name": "",
		"habitat_id": null,
		"source": "migration",
		"created_at": now,
		"reptile_level": 1,
		"reptile_xp": 0,
		"reptile_xp_to_next_level": 100,
		"reptile_total_xp": 0,
		"reptile_level_updated_at": now,
		"happiness": 100,
		"hydration": 100,
		"hunger": 100,
		"satiety": 100,
		"cleanliness": 100,
		"boredom": 0,
		"last_needs_update_timestamp": now,
		"last_feed_timestamp": 0,
		"last_water_timestamp": 0,
		"last_clean_timestamp": 0,
		"last_play_timestamp": 0,
		"last_fed_at": null,
		"last_water_at": null,
		"last_cleaned_at": null,
		"breeding_state": "none",
		"breeding_partner_id": null,
		"breeding_started_at": 0,
		"egg_lay_finish_at": 0,
		"incubator_egg_id": null,
		"paired_with_instance_id": "",
		"pregnancy_started_at": null,
		"egg_lay_ready_at": null,
		"eggs": [],
		"incubator_entry_id": "",
		"breeding_cooldown_until": 0
	}


func get_default_biome_resources() -> Dictionary:
	var now: float = Time.get_unix_time_from_system()
	var biome_default: Dictionary = {
		"food_current": 100,
		"food_max": 100,
		"water_current": 100,
		"water_max": 100,
		"last_food_regen_timestamp": now,
		"last_water_regen_timestamp": now
	}
	return {
		"green_meadow": biome_default.duplicate(true),
		"dry_prairie": biome_default.duplicate(true)
	}


func get_default_save_data() -> Dictionary:
	var now: float = Time.get_unix_time_from_system()
	var defaults: Dictionary = {
		"save_version": CURRENT_SAVE_VERSION,
		"created_at": now,
		"last_saved_at": 0,
		"repticash": 100,
		"lifetime_repticash_earned": 0,
		"premium_currency": 0,
		"premium": 0,
		"xp": 0,
		"player_xp": 0,
		"level": 1,
		"player_level": 1,
		"last_rewarded_level": 1,
		"onboarding_state": get_default_onboarding_state(),
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
		"biome_resources": get_default_biome_resources(),
		"language": "pl",
		"settings": get_default_settings(),
		"unlocked_biomes": [DEFAULT_BIOME_ID],
		"biomes": {},
		"biome_progress": {},
		"biome_progress_points": {},
		"habitats": {},
		"owned_animals": {},
		"owned_reptile_instances": {},
		"discovered_variants": {},
		"owned_variant_instances": {},
		"claimed_collection_rewards": [],
		"tutorial_completed": false,
		"last_income_timestamp": now,
		"last_active_timestamp": now,
		"last_offline_income_at": now,
		"pending_offline_income": 0.0,
		"pending_offline_seconds": 0,
		"offline_claim_available": false,
		"last_offline_claim_timestamp": 0,
		"biome_2_ready_popup_seen": false,
		"incubator_storage": {
			"reptiles": [],
			"eggs": [],
			"hatchlings": []
		},
		"breeding_chambers": {},
		"incubation_containers": {}
	}
	for key in get_default_achievement_state().keys():
		defaults[key] = get_default_achievement_state()[key]
	for key in get_default_quest_state().keys():
		defaults[key] = get_default_quest_state()[key]
	for key in get_default_worker_state().keys():
		defaults[key] = get_default_worker_state()[key]
	for key in get_default_upgrade_state().keys():
		defaults[key] = get_default_upgrade_state()[key]
	return defaults


func get_default_state() -> Dictionary:
	return get_default_save_data()


func reset_to_default() -> void:
	state = get_default_save_data()
	language_changed.emit(get_language())
	state_changed.emit()


func apply_loaded_state(loaded_state: Dictionary) -> void:
	state = migrate_save_data(loaded_state)
	save_loaded.emit()
	state_changed.emit()
	language_changed.emit(get_language())


func migrate_save_data(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	var version: int = int(migrated.get("save_version", 0))
	if version < 1:
		migrated = migrate_from_v0_to_v1(migrated)
		version = 1
	if version < 2:
		migrated = migrate_from_v1_to_v2(migrated)
		version = 2

	migrated["save_version"] = CURRENT_SAVE_VERSION
	return normalize_save_data(migrated)


func migrate_from_v0_to_v1(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	if not migrated.has("owned_animals") and not migrated.has("owned_reptile_instances"):
		migrated["owned_animals"] = {}
	_migrate_old_embedded_habitat_animals(migrated)
	migrated["save_version"] = 1
	return migrated


func migrate_from_v1_to_v2(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	_migrate_old_embedded_habitat_animals(migrated)
	migrated["save_version"] = 2
	return migrated


func normalize_save_data(data: Dictionary) -> Dictionary:
	var defaults: Dictionary = get_default_save_data()
	var normalized: Dictionary = defaults.duplicate(true)
	for key in data.keys():
		normalized[key] = data[key]
	_migrate_old_embedded_habitat_animals(normalized)

	var now: int = int(Time.get_unix_time_from_system())
	normalized["save_version"] = CURRENT_SAVE_VERSION
	normalized["created_at"] = _safe_timestamp(normalized.get("created_at", now), now)
	normalized["last_saved_at"] = _safe_timestamp(normalized.get("last_saved_at", 0), 0)
	normalized["language"] = _normalize_language(str(normalized.get("language", "pl")))
	var incoming_settings: Variant = normalized.get("settings", {})
	normalized["settings"] = _merge_dictionary(get_default_settings(), incoming_settings)
	var settings_language: String = normalized["language"]
	if typeof(incoming_settings) == TYPE_DICTIONARY and (incoming_settings as Dictionary).has("language"):
		settings_language = str((incoming_settings as Dictionary).get("language", normalized["language"]))
	normalized["settings"]["language"] = _normalize_language(settings_language)
	normalized["language"] = str(normalized["settings"]["language"])
	normalized["repticash"] = max(0.0, float(normalized.get("repticash", normalized.get("currency", 100))))
	normalized["lifetime_repticash_earned"] = max(0.0, float(normalized.get("lifetime_repticash_earned", 0.0)))
	normalized["premium_currency"] = max(0.0, float(normalized.get("premium_currency", normalized.get("premium", 0))))
	normalized["premium"] = normalized["premium_currency"]
	var had_last_rewarded_level: bool = data.has("last_rewarded_level")
	normalized["xp"] = max(0.0, float(normalized.get("xp", normalized.get("player_xp", 0))))
	normalized["player_xp"] = normalized["xp"]
	var saved_level: int = max(1, int(normalized.get("level", normalized.get("player_level", 1))))
	normalized["level"] = max(saved_level, _get_level_for_xp(float(normalized["xp"])))
	normalized["player_level"] = normalized["level"]
	if had_last_rewarded_level:
		normalized["last_rewarded_level"] = int(clamp(int(normalized.get("last_rewarded_level", 1)), 1, int(normalized["level"])))
	else:
		normalized["last_rewarded_level"] = int(normalized["level"])

	for key in ["unlocked_biomes", "completed_achievements", "claimed_achievements", "completed_quests", "claimed_quests", "claimed_collection_rewards"]:
		normalized[key] = _normalize_unique_string_array(normalized.get(key, []))

	for key in ["biomes", "biome_progress", "biome_progress_points", "quests", "quest_progress", "quest_event_counters", "workers", "worker_levels", "upgrades", "upgrade_levels", "owned_variant_instances"]:
		normalized[key] = _normalize_dictionary(normalized.get(key, {}))

	normalized["onboarding_state"] = _normalize_onboarding_state(normalized.get("onboarding_state", {}))

	normalized["worker_levels"] = _normalize_level_dictionary(normalized.get("worker_levels", normalized.get("workers", {})))
	normalized["upgrade_levels"] = _normalize_level_dictionary(normalized.get("upgrade_levels", normalized.get("upgrades", {})))
	normalized["workers"] = _normalize_dictionary(normalized.get("workers", normalized["worker_levels"]))
	normalized["upgrades"] = _normalize_dictionary(normalized.get("upgrades", normalized["upgrade_levels"]))

	normalized["food_max"] = max(1, int(normalized.get("food_max", 100)))
	normalized["water_max"] = max(1, int(normalized.get("water_max", 100)))
	normalized["food_current"] = int(clamp(int(normalized.get("food_current", 100)), 0, int(normalized["food_max"])))
	normalized["water_current"] = int(clamp(int(normalized.get("water_current", 100)), 0, int(normalized["water_max"])))
	normalized["food_regen_amount"] = max(1, int(normalized.get("food_regen_amount", 1)))
	normalized["water_regen_amount"] = max(1, int(normalized.get("water_regen_amount", 1)))
	normalized["food_regen_interval_seconds"] = max(1, int(normalized.get("food_regen_interval_seconds", 600)))
	normalized["water_regen_interval_seconds"] = max(1, int(normalized.get("water_regen_interval_seconds", 600)))
	normalized["last_food_regen_timestamp"] = _safe_timestamp(normalized.get("last_food_regen_timestamp", now), now, now)
	normalized["last_water_regen_timestamp"] = _safe_timestamp(normalized.get("last_water_regen_timestamp", now), now, now)
	normalized["biome_resources"] = _normalize_biome_resources(normalized.get("biome_resources", {}), now)

	normalized["last_active_timestamp"] = _safe_timestamp(normalized.get("last_active_timestamp", now), now, now)
	normalized["last_offline_income_at"] = _safe_timestamp(normalized.get("last_offline_income_at", normalized["last_active_timestamp"]), now, now)
	normalized["pending_offline_income"] = max(0.0, float(normalized.get("pending_offline_income", 0.0)))
	normalized["pending_offline_seconds"] = max(0, int(normalized.get("pending_offline_seconds", 0)))
	normalized["offline_claim_available"] = bool(normalized.get("offline_claim_available", false)) and float(normalized["pending_offline_income"]) > 0.0
	normalized["last_offline_claim_timestamp"] = _safe_timestamp(normalized.get("last_offline_claim_timestamp", 0), 0, now)

	normalized["habitats"] = _normalize_habitats(normalized.get("habitats", {}), now)
	normalized["owned_reptile_instances"] = _normalize_animals(_get_loaded_animals(normalized))
	var normalized_animals_value: Variant = normalized.get("owned_reptile_instances", {})
	var normalized_animals: Dictionary = normalized_animals_value as Dictionary
	normalized["owned_animals"] = normalized_animals.duplicate(true)
	_normalize_assignment_relationships(normalized)
	normalized["discovered_variants"] = _normalize_discovered_variants(normalized.get("discovered_variants", {}), normalized["owned_reptile_instances"])
	normalized["incubator_storage"] = _normalize_incubator_storage(normalized.get("incubator_storage", {}))
	normalized["breeding_chambers"] = _normalize_breeding_chambers(normalized.get("breeding_chambers", {}))
	normalized["incubation_containers"] = _normalize_incubation_containers(normalized.get("incubation_containers", {}))
	return normalized


func _normalize_incubator_storage(raw: Variant) -> Dictionary:
	var storage: Dictionary = {"reptiles": [], "eggs": [], "hatchlings": []}
	if typeof(raw) != TYPE_DICTIONARY:
		return storage
	var src: Dictionary = raw as Dictionary
	for key in ["reptiles", "eggs", "hatchlings"]:
		var val: Variant = src.get(key, [])
		storage[key] = val if typeof(val) == TYPE_ARRAY else []
	return storage


func _normalize_breeding_chambers(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = {}
	var src: Dictionary = raw as Dictionary
	for key in src.keys():
		var val: Variant = src.get(key)
		if typeof(val) == TYPE_DICTIONARY:
			result[str(key)] = val
	return result


func _normalize_incubation_containers(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = {}
	var src: Dictionary = raw as Dictionary
	for key in src.keys():
		var val: Variant = src.get(key)
		if typeof(val) == TYPE_DICTIONARY:
			result[str(key)] = val
	return result


func _normalize_biome_resources(value: Variant, now: int) -> Dictionary:
	var defaults: Dictionary = get_default_biome_resources()
	var result: Dictionary = {}
	for biome_id in defaults.keys():
		var d: Dictionary = (defaults[biome_id] as Dictionary).duplicate(true)
		d["last_food_regen_timestamp"] = now
		d["last_water_regen_timestamp"] = now
		result[biome_id] = d

	if typeof(value) == TYPE_DICTIONARY:
		var src: Dictionary = value as Dictionary
		for biome_id_key in src.keys():
			var biome_id: String = str(biome_id_key)
			var biome_value: Variant = src.get(biome_id_key)
			if typeof(biome_value) != TYPE_DICTIONARY:
				continue
			var incoming: Dictionary = biome_value as Dictionary
			if not result.has(biome_id):
				result[biome_id] = (defaults.get("green_meadow", {}) as Dictionary).duplicate(true)
			var existing: Dictionary = result[biome_id]
			existing["food_max"] = max(1, int(incoming.get("food_max", existing["food_max"])))
			existing["water_max"] = max(1, int(incoming.get("water_max", existing["water_max"])))
			existing["food_current"] = int(clamp(int(incoming.get("food_current", existing["food_current"])), 0, int(existing["food_max"])))
			existing["water_current"] = int(clamp(int(incoming.get("water_current", existing["water_current"])), 0, int(existing["water_max"])))
			existing["last_food_regen_timestamp"] = _safe_timestamp(incoming.get("last_food_regen_timestamp", now), now, now)
			existing["last_water_regen_timestamp"] = _safe_timestamp(incoming.get("last_water_regen_timestamp", now), now, now)
			result[biome_id] = existing

	return result


func get_value(key: String, fallback: Variant = null) -> Variant:
	return state.get(key, fallback)


func set_value(key: String, value: Variant) -> void:
	state[key] = value
	if key == "owned_reptile_instances":
		state["owned_animals"] = value
	elif key == "owned_animals":
		state["owned_reptile_instances"] = value
	elif key == "xp":
		state["player_xp"] = value
	elif key == "player_xp":
		state["xp"] = value
	elif key == "level":
		state["player_level"] = value
	elif key == "player_level":
		state["level"] = value
	elif key == "premium_currency":
		state["premium"] = value
	elif key == "premium":
		state["premium_currency"] = value
	state_changed.emit()


func get_language() -> String:
	return _normalize_language(str(state.get("language", "pl")))


func set_language(language: String) -> void:
	language = _normalize_language(language)
	if state.get("language", "pl") == language:
		var existing_settings: Dictionary = get_settings()
		existing_settings["language"] = language
		state["settings"] = existing_settings
		return

	state["language"] = language
	var settings: Dictionary = get_settings()
	settings["language"] = language
	state["settings"] = settings
	language_changed.emit(language)
	state_changed.emit()


func get_settings() -> Dictionary:
	var settings: Dictionary = _merge_dictionary(get_default_settings(), state.get("settings", {}))
	settings["language"] = _normalize_language(str(settings.get("language", state.get("language", "pl"))))
	return settings


func get_setting(key: String, fallback: Variant = null) -> Variant:
	var settings: Dictionary = get_settings()
	return settings.get(key, fallback)


func set_setting(key: String, value: Variant) -> void:
	var settings: Dictionary = get_settings()
	settings[key] = value
	if key == "language":
		set_language(str(value))
		return
	state["settings"] = settings
	state_changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_value("last_active_timestamp", Time.get_unix_time_from_system())
		if has_node("/root/SaveSystem"):
			var save_sys = get_node("/root/SaveSystem")
			if save_sys.has_method("save_game"):
				save_sys.save_game()


func _migrate_old_embedded_habitat_animals(data: Dictionary) -> void:
	var habitats: Dictionary = _normalize_dictionary(data.get("habitats", {}))
	var animals: Dictionary = _get_loaded_animals(data)
	for habitat_key in habitats.keys():
		var habitat_id: String = str(habitat_key)
		var habitat_value: Variant = habitats.get(habitat_key)
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat_source: Dictionary = habitat_value as Dictionary
		var habitat: Dictionary = habitat_source.duplicate(true)
		var existing_instance_id: String = _first_non_empty_string([
			habitat.get("animal_instance_id", null),
			habitat.get("reptile_instance_id", null),
			habitat.get("instance_id", null)
		])
		if not existing_instance_id.is_empty() and animals.has(existing_instance_id):
			continue

		var embedded: Dictionary = {}
		if typeof(habitat.get("animal", null)) == TYPE_DICTIONARY:
			embedded = habitat.get("animal") as Dictionary
		elif typeof(habitat.get("reptile", null)) == TYPE_DICTIONARY:
			embedded = habitat.get("reptile") as Dictionary

		var reptile_id: String = _first_non_empty_string([
			embedded.get("reptile_id", ""),
			embedded.get("species_id", ""),
			embedded.get("animal_id", ""),
			habitat.get("reptile_id", ""),
			habitat.get("animal_id", "")
		])
		if reptile_id.is_empty():
			continue

		var instance_id: String = existing_instance_id
		if instance_id.is_empty():
			instance_id = "migrated_" + habitat_id
		if animals.has(instance_id):
			continue

		var animal: Dictionary = get_default_animal_instance(instance_id)
		animal["instance_id"] = instance_id
		animal["animal_instance_id"] = instance_id
		animal["reptile_id"] = reptile_id
		animal["species_id"] = reptile_id
		animal["variant_id"] = _first_non_empty_string([embedded.get("variant_id", ""), habitat.get("variant_id", ""), reptile_id + "_common"])
		animal["rarity"] = str(embedded.get("rarity", habitat.get("rarity", "common")))
		animal["sex"] = str(embedded.get("sex", habitat.get("sex", "male")))
		animal["custom_name"] = _first_non_empty_string([embedded.get("custom_name", ""), embedded.get("name", ""), habitat.get("custom_reptile_name", ""), habitat.get("name", "")])
		animal["name"] = str(animal["custom_name"])
		animal["habitat_id"] = habitat_id
		for care_key in ["happiness", "hunger", "satiety", "hydration", "cleanliness", "last_feed_timestamp", "last_water_timestamp", "last_clean_timestamp", "last_play_timestamp", "last_fed_at", "last_water_at", "last_cleaned_at"]:
			if embedded.has(care_key):
				animal[care_key] = embedded[care_key]
			elif habitat.has(care_key):
				animal[care_key] = habitat[care_key]
		animals[instance_id] = animal
		habitat["animal_instance_id"] = instance_id
		habitat["reptile_instance_id"] = instance_id
		habitats[habitat_id] = habitat

	data["habitats"] = habitats
	data["owned_reptile_instances"] = animals
	data["owned_animals"] = animals.duplicate(true)


func _get_loaded_animals(data: Dictionary) -> Dictionary:
	var value: Variant = data.get("owned_reptile_instances", null)
	if typeof(value) != TYPE_DICTIONARY:
		value = data.get("owned_animals", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var loaded_animals: Dictionary = value as Dictionary
	return loaded_animals.duplicate(true)


func _normalize_habitats(value: Variant, now: int) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result

	var habitats: Dictionary = value as Dictionary
	for habitat_key in habitats.keys():
		var habitat_id: String = str(habitat_key)
		var habitat_value: Variant = habitats.get(habitat_key)
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var incoming: Dictionary = habitat_value as Dictionary
		var normalized: Dictionary = _merge_dictionary(get_default_habitat_state(habitat_id), incoming)
		var normalized_habitat_id: String = _first_non_empty_string([normalized.get("habitat_id", ""), habitat_id])
		normalized["habitat_id"] = normalized_habitat_id
		normalized["biome_id"] = _first_non_empty_string([normalized.get("biome_id", ""), DEFAULT_BIOME_ID])
		normalized["slot_index"] = int(normalized.get("slot_index", 0))
		normalized["purchased"] = bool(normalized.get("purchased", false))
		normalized["habitat_type"] = _normalize_habitat_type(str(normalized.get("habitat_type", "grass")))
		normalized["habitat_level"] = int(clamp(int(normalized.get("habitat_level", 1)), 1, 3))
		normalized["is_building"] = bool(normalized.get("is_building", false))
		normalized["build_started_at"] = _safe_timestamp(normalized.get("build_started_at", 0), 0, now)
		normalized["build_finish_at"] = _safe_timestamp(normalized.get("build_finish_at", 0), 0, now + 315360000)
		if bool(normalized["is_building"]) and int(normalized["build_finish_at"]) <= now:
			normalized["is_building"] = false
			normalized["build_started_at"] = 0
			normalized["build_finish_at"] = 0
		normalized["is_upgrading"] = bool(normalized.get("is_upgrading", false))
		normalized["upgrade_target_level"] = int(clamp(int(normalized.get("upgrade_target_level", 0)), 0, 3))
		normalized["upgrade_started_at"] = _safe_timestamp(normalized.get("upgrade_started_at", 0), 0, now)
		normalized["upgrade_finish_at"] = _safe_timestamp(normalized.get("upgrade_finish_at", 0), 0, now + 315360000)
		if bool(normalized["is_upgrading"]) and int(normalized["upgrade_finish_at"]) <= now:
			var fallback_target_level: int = int(normalized["habitat_level"]) + 1
			normalized["habitat_level"] = int(clamp(int(normalized.get("upgrade_target_level", fallback_target_level)), 1, 3))
			normalized["is_upgrading"] = false
			normalized["upgrade_target_level"] = 0
			normalized["upgrade_started_at"] = 0
			normalized["upgrade_finish_at"] = 0
		normalized["animal_instance_id"] = _nullable_id(normalized.get("animal_instance_id", normalized.get("reptile_instance_id", null)))
		normalized["reptile_instance_id"] = "" if normalized["animal_instance_id"] == null else str(normalized["animal_instance_id"])
		normalized["reptile_id"] = str(normalized.get("reptile_id", ""))
		normalized["variant_id"] = str(normalized.get("variant_id", ""))
		result[habitat_id] = normalized
	return result


func _normalize_animals(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result

	var animals: Dictionary = value as Dictionary
	var used_ids: Dictionary = {}
	for key in animals.keys():
		var animal_value: Variant = animals.get(key)
		if typeof(animal_value) != TYPE_DICTIONARY:
			continue

		var incoming: Dictionary = animal_value as Dictionary
		var instance_id: String = _first_non_empty_string([incoming.get("instance_id", ""), incoming.get("animal_instance_id", ""), key])
		instance_id = _make_unique_instance_id(instance_id, used_ids)
		used_ids[instance_id] = true
		var normalized: Dictionary = _merge_dictionary(get_default_animal_instance(instance_id), incoming)
		normalized["instance_id"] = instance_id
		normalized["animal_instance_id"] = instance_id
		var reptile_id: String = _first_non_empty_string([normalized.get("reptile_id", ""), normalized.get("species_id", ""), "unknown_reptile"])
		normalized["reptile_id"] = reptile_id
		normalized["species_id"] = reptile_id
		normalized["variant_id"] = _first_non_empty_string([normalized.get("variant_id", ""), reptile_id + "_common"])
		normalized["rarity"] = _normalize_rarity(str(normalized.get("rarity", "common")))
		normalized["sex"] = _normalize_sex(str(normalized.get("sex", "male")))
		normalized["custom_name"] = _first_non_empty_string([normalized.get("custom_name", ""), normalized.get("name", "")])
		normalized["name"] = str(normalized["custom_name"])
		normalized["habitat_id"] = _nullable_id(normalized.get("habitat_id", null))
		normalized["reptile_level"] = max(1, int(normalized.get("reptile_level", 1)))
		normalized["reptile_xp"] = max(0, int(normalized.get("reptile_xp", 0)))
		normalized["reptile_xp_to_next_level"] = max(0, int(normalized.get("reptile_xp_to_next_level", 100)))
		normalized["reptile_total_xp"] = max(0, int(normalized.get("reptile_total_xp", normalized["reptile_xp"])))
		normalized["reptile_level_updated_at"] = _safe_timestamp(normalized.get("reptile_level_updated_at", 0), 0)
		normalized["happiness"] = _percent(normalized.get("happiness", 100))
		normalized["hunger"] = _percent(normalized.get("hunger", normalized.get("satiety", 100)))
		normalized["satiety"] = normalized["hunger"]
		normalized["hydration"] = _percent(normalized.get("hydration", 100))
		normalized["cleanliness"] = _percent(normalized.get("cleanliness", 100))
		normalized["last_needs_update_timestamp"] = _safe_timestamp(normalized.get("last_needs_update_timestamp", Time.get_unix_time_from_system()), int(Time.get_unix_time_from_system()))
		normalized["last_feed_timestamp"] = _safe_timestamp(normalized.get("last_feed_timestamp", normalized.get("last_fed_at", 0)), 0)
		normalized["last_water_timestamp"] = _safe_timestamp(normalized.get("last_water_timestamp", normalized.get("last_water_at", 0)), 0)
		normalized["last_clean_timestamp"] = _safe_timestamp(normalized.get("last_clean_timestamp", normalized.get("last_cleaned_at", 0)), 0)
		normalized["last_play_timestamp"] = _safe_timestamp(normalized.get("last_play_timestamp", 0), 0)
		normalized["breeding_state"] = _first_non_empty_string([normalized.get("breeding_state", ""), "none"])
		normalized["breeding_partner_id"] = _nullable_id(normalized.get("breeding_partner_id", normalized.get("paired_with_instance_id", null)))
		normalized["breeding_started_at"] = _safe_timestamp(normalized.get("breeding_started_at", normalized.get("pregnancy_started_at", 0)), 0)
		normalized["egg_lay_finish_at"] = _safe_timestamp(normalized.get("egg_lay_finish_at", normalized.get("egg_lay_ready_at", 0)), 0)
		normalized["incubator_egg_id"] = _nullable_id(normalized.get("incubator_egg_id", normalized.get("incubator_entry_id", null)))
		normalized["breeding_cooldown_until"] = _safe_timestamp(normalized.get("breeding_cooldown_until", 0), 0)
		result[instance_id] = normalized
	return result


func _normalize_assignment_relationships(save_data: Dictionary) -> void:
	var habitats: Dictionary = save_data.get("habitats", {})
	var animals: Dictionary = save_data.get("owned_reptile_instances", {})
	var occupied_habitats: Dictionary = {}
	var assigned_animals: Dictionary = {}

	for habitat_id_key in habitats.keys():
		var habitat_id: String = str(habitat_id_key)
		var habitat_value: Variant = habitats.get(habitat_id_key, {})
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		var instance_id: Variant = _nullable_id(habitat.get("animal_instance_id", habitat.get("reptile_instance_id", null)))
		if instance_id == null or not animals.has(str(instance_id)) or bool(habitat.get("is_building", false)) or bool(habitat.get("is_upgrading", false)):
			habitat["animal_instance_id"] = null
			habitat["reptile_instance_id"] = ""
			habitat["reptile_id"] = ""
			habitat["variant_id"] = ""
			habitats[habitat_id] = habitat
			continue
		if assigned_animals.has(str(instance_id)):
			habitat["animal_instance_id"] = null
			habitat["reptile_instance_id"] = ""
			habitat["reptile_id"] = ""
			habitat["variant_id"] = ""
			habitats[habitat_id] = habitat
			continue

		var linked_animal_value: Variant = animals.get(str(instance_id), {})
		if typeof(linked_animal_value) != TYPE_DICTIONARY:
			continue
		var animal: Dictionary = linked_animal_value as Dictionary
		animal["habitat_id"] = habitat_id
		animals[str(instance_id)] = animal
		habitat["animal_instance_id"] = str(instance_id)
		habitat["reptile_instance_id"] = str(instance_id)
		habitat["reptile_id"] = str(animal.get("reptile_id", ""))
		habitat["variant_id"] = str(animal.get("variant_id", ""))
		habitats[habitat_id] = habitat
		occupied_habitats[habitat_id] = str(instance_id)
		assigned_animals[str(instance_id)] = habitat_id

	for animal_id_key in animals.keys():
		var animal_id: String = str(animal_id_key)
		var animal_value: Variant = animals.get(animal_id_key, {})
		if typeof(animal_value) != TYPE_DICTIONARY:
			continue
		var animal: Dictionary = animal_value as Dictionary
		var habitat_id_value: Variant = _nullable_id(animal.get("habitat_id", null))
		if habitat_id_value == null:
			animal["habitat_id"] = null
			animals[animal_id] = animal
			continue
		var habitat_id: String = str(habitat_id_value)
		if not habitats.has(habitat_id) or occupied_habitats.has(habitat_id) or assigned_animals.has(animal_id):
			if assigned_animals.get(animal_id, "") != habitat_id:
				animal["habitat_id"] = null
				animals[animal_id] = animal
			continue
		var target_habitat_value: Variant = habitats.get(habitat_id, {})
		if typeof(target_habitat_value) != TYPE_DICTIONARY:
			animal["habitat_id"] = null
			animals[animal_id] = animal
			continue
		var habitat: Dictionary = target_habitat_value as Dictionary
		if not bool(habitat.get("purchased", false)) or bool(habitat.get("is_building", false)) or bool(habitat.get("is_upgrading", false)):
			animal["habitat_id"] = null
			animals[animal_id] = animal
			continue
		animal["habitat_id"] = habitat_id
		habitat["animal_instance_id"] = animal_id
		habitat["reptile_instance_id"] = animal_id
		habitat["reptile_id"] = str(animal.get("reptile_id", ""))
		habitat["variant_id"] = str(animal.get("variant_id", ""))
		animals[animal_id] = animal
		habitats[habitat_id] = habitat
		occupied_habitats[habitat_id] = animal_id
		assigned_animals[animal_id] = habitat_id

	save_data["habitats"] = habitats
	save_data["owned_reptile_instances"] = animals
	save_data["owned_animals"] = animals.duplicate(true)


func _normalize_discovered_variants(value: Variant, animals: Dictionary) -> Dictionary:
	var discovered: Dictionary = {}
	if typeof(value) == TYPE_DICTIONARY:
		for key in (value as Dictionary).keys():
			var variant_id: String = str(key).strip_edges()
			if not variant_id.is_empty() and bool((value as Dictionary).get(key, true)):
				discovered[variant_id] = true
	elif typeof(value) == TYPE_ARRAY:
		for entry in (value as Array):
			var variant_id: String = str(entry).strip_edges()
			if not variant_id.is_empty():
				discovered[variant_id] = true
	elif typeof(value) == TYPE_STRING:
		var variant_id: String = str(value).strip_edges()
		if not variant_id.is_empty():
			discovered[variant_id] = true

	for animal_value in animals.values():
		if typeof(animal_value) != TYPE_DICTIONARY:
			continue
		var animal: Dictionary = animal_value as Dictionary
		var animal_variant_id: String = str(animal.get("variant_id", "")).strip_edges()
		if not animal_variant_id.is_empty():
			discovered[animal_variant_id] = true
	return discovered


func _merge_dictionary(defaults: Dictionary, value: Variant) -> Dictionary:
	var result: Dictionary = defaults.duplicate(true)
	if typeof(value) == TYPE_DICTIONARY:
		for key in (value as Dictionary).keys():
			result[key] = (value as Dictionary)[key]
	return result


func _normalize_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary_value: Dictionary = value as Dictionary
		return dictionary_value.duplicate(true)
	return {}


func _normalize_level_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result
	for key in (value as Dictionary).keys():
		var id: String = str(key)
		if id.is_empty():
			continue
		result[id] = max(0, int((value as Dictionary).get(key, 0)))
	return result


func _normalize_unique_string_array(value: Variant) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	if typeof(value) == TYPE_DICTIONARY:
		for key in (value as Dictionary).keys():
			if bool((value as Dictionary).get(key, false)):
				var id_from_key: String = str(key).strip_edges()
				if not id_from_key.is_empty() and not seen.has(id_from_key):
					seen[id_from_key] = true
					result.append(id_from_key)
		return result
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in (value as Array):
		var id: String = str(entry).strip_edges()
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		result.append(id)
	return result


func _normalize_onboarding_state(value: Variant) -> Dictionary:
	var result: Dictionary = get_default_onboarding_state()
	if typeof(value) != TYPE_DICTIONARY:
		return result

	var source: Dictionary = value as Dictionary
	result["welcome_seen"] = bool(source.get("welcome_seen", false))
	result["active_task_id"] = str(source.get("active_task_id", ""))
	result["active_task_accepted"] = bool(source.get("active_task_accepted", false))
	result["active_task_completed"] = bool(source.get("active_task_completed", false))
	result["completed_task_ids"] = _normalize_unique_string_array(source.get("completed_task_ids", []))
	result["skipped_task_ids"] = _normalize_unique_string_array(source.get("skipped_task_ids", []))
	result["claimed_task_ids"] = _normalize_unique_string_array(source.get("claimed_task_ids", []))
	result["onboarding_finished"] = bool(source.get("onboarding_finished", false))
	result["bubble_visible"] = bool(source.get("bubble_visible", false))

	var counters: Dictionary = {}
	var counters_value: Variant = source.get("event_counters", {})
	if typeof(counters_value) == TYPE_DICTIONARY:
		for key in (counters_value as Dictionary).keys():
			var counter_id: String = str(key).strip_edges()
			if not counter_id.is_empty():
				counters[counter_id] = max(0, int((counters_value as Dictionary).get(key, 0)))
	result["event_counters"] = counters
	return result


func _safe_timestamp(value: Variant, fallback: int, max_value: int = 2147483647) -> int:
	if value == null:
		return fallback
	var timestamp: int = int(value)
	if timestamp < 0:
		return fallback
	if timestamp > max_value:
		return max_value
	return timestamp


func _get_level_for_xp(total_xp: float) -> int:
	var level: int = 1
	while total_xp >= float(_get_required_xp_for_level(level + 1)):
		level += 1
	return level


func _get_required_xp_for_level(level: int) -> int:
	if level <= 1:
		return 0

	var progression: Dictionary = _get_level_progression()
	var levels_val: Variant = progression.get("levels", null)
	if typeof(levels_val) == TYPE_DICTIONARY:
		var levels_dict: Dictionary = levels_val as Dictionary
		var key := str(level)
		if levels_dict.has(key):
			return int(levels_dict[key])

	var required: float = float(progression.get("level_2_xp", 1000.0))
	var multiplier: float = float(progression.get("multiplier", 1.75))
	for _next_level in range(3, level + 1):
		required *= multiplier
	return int(round(required))


func _get_level_progression() -> Dictionary:
	if not _level_progression_cache.is_empty():
		return _level_progression_cache

	var file := FileAccess.open(LEVEL_PROGRESSION_PATH, FileAccess.READ)
	if file == null:
		_level_progression_cache = {"level_2_xp": 1000.0, "multiplier": 1.75}
		return _level_progression_cache

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_level_progression_cache = parsed as Dictionary
	else:
		_level_progression_cache = {"level_2_xp": 1000.0, "multiplier": 1.75}
	return _level_progression_cache


func _nullable_id(value: Variant) -> Variant:
	if value == null:
		return null
	var text: String = str(value).strip_edges()
	if text.is_empty() or text == "<null>" or text.to_lower() == "null":
		return null
	return text


func _first_non_empty_string(values: Array) -> String:
	for value in values:
		if value == null:
			continue
		var text: String = str(value).strip_edges()
		if not text.is_empty() and text.to_lower() != "null":
			return text
	return ""


func _make_unique_instance_id(base_id: String, used_ids: Dictionary) -> String:
	var id: String = base_id.strip_edges()
	if id.is_empty():
		id = "animal_001"
	if not used_ids.has(id):
		return id
	var index: int = 2
	var candidate: String = id + "_" + str(index)
	while used_ids.has(candidate):
		index += 1
		candidate = id + "_" + str(index)
	return candidate


func _normalize_language(language: String) -> String:
	if language == "en":
		return "en"
	return "pl"


func _normalize_habitat_type(habitat_type: String) -> String:
	var normalized: String = habitat_type.strip_edges().to_lower()
	if normalized == "desert":
		return "sand"
	if ["grass", "sand", "stone", "jungle"].has(normalized):
		return normalized
	return "grass"


func _normalize_rarity(rarity: String) -> String:
	if ["common", "rare", "exceptional", "ultra_rare"].has(rarity):
		return rarity
	return "common"


func _normalize_sex(sex: String) -> String:
	if sex == "female":
		return "female"
	return "male"


func _percent(value: Variant) -> float:
	return clamp(float(value), 0.0, 100.0)
