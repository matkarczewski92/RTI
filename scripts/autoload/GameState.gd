extends Node

signal language_changed(language: String)
signal state_changed
signal save_loaded

const SAVE_VERSION := 4
const CURRENT_SAVE_VERSION := SAVE_VERSION
const DEFAULT_BIOME_ID := "green_meadow"
const LEVEL_PROGRESSION_PATH := "res://data/level_progression.json"
const FORMER_HOUSE_SPECIES_BIOMES := {
	"crested_gecko": "green_meadow",
	"ball_python": "green_meadow",
	"amur_snake": "green_meadow",
	"greek_tortoise": "dry_prairie",
	"uromastyx": "dry_prairie",
	"veiled_chameleon": "green_meadow",
	"green_iguana": "green_meadow"
}

var state: Dictionary = {}
var _level_progression_cache: Dictionary = {}


func _ready() -> void:
	reset_to_default()


func get_default_settings() -> Dictionary:
	return {
		"language": "en",
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
		"worker_levels": {},
		"workers_by_biome": {}
	}


func get_default_upgrade_state() -> Dictionary:
	return {
		"upgrades": {},
		"upgrade_levels": {},
		"upgrade_levels_by_biome": {}
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
		"first_assignment_xp_claimed": false,
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
		"starter_reptile_claimed": false,
		"habitat_action_xp_claims": {},
		"first_hatch_starter_granted": false,
		"onboarding_track_version": 2,
		"offline_income_rate_per_minute": -1.0,
		"expeditions": [],
		"expedition_log": [],
		"expedition_counter": 0,
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
		"language": "en",
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
		"resource_ads_window_started_at": 0,
		"resource_ads_used_count": 0,
		"resource_ads_reward_timestamps": [],
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
	if version < 3:
		migrated["onboarding_track_version"] = int(migrated.get("onboarding_track_version", 1))

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
	normalized["language"] = _normalize_language(str(normalized.get("language", "en")))
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

	for key in ["biomes", "biome_progress", "biome_progress_points", "quests", "quest_progress", "quest_event_counters", "workers", "worker_levels", "workers_by_biome", "upgrades", "upgrade_levels", "upgrade_levels_by_biome", "owned_variant_instances"]:
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
	normalized["biome_resources"] = _normalize_biome_resources(
		normalized.get("biome_resources", {}),
		now,
		int(normalized["food_max"]),
		int(normalized["water_max"])
	)
	normalized["resource_ads_window_started_at"] = _safe_timestamp(normalized.get("resource_ads_window_started_at", 0), 0, now)
	normalized["resource_ads_used_count"] = int(clamp(int(normalized.get("resource_ads_used_count", 0)), 0, 999999))
	var resource_ad_timestamps: Array = []
	var raw_resource_ad_timestamps: Variant = normalized.get("resource_ads_reward_timestamps", [])
	if typeof(raw_resource_ad_timestamps) == TYPE_ARRAY:
		for timestamp_value in (raw_resource_ad_timestamps as Array):
			resource_ad_timestamps.append(_safe_timestamp(timestamp_value, 0, now))
	normalized["resource_ads_reward_timestamps"] = resource_ad_timestamps

	normalized["last_active_timestamp"] = _safe_timestamp(normalized.get("last_active_timestamp", now), now, now)
	normalized["last_offline_income_at"] = _safe_timestamp(normalized.get("last_offline_income_at", normalized["last_active_timestamp"]), now, now)
	normalized["pending_offline_income"] = max(0.0, float(normalized.get("pending_offline_income", 0.0)))
	normalized["pending_offline_seconds"] = max(0, int(normalized.get("pending_offline_seconds", 0)))
	normalized["offline_claim_available"] = bool(normalized.get("offline_claim_available", false)) and float(normalized["pending_offline_income"]) > 0.0
	normalized["last_offline_claim_timestamp"] = _safe_timestamp(normalized.get("last_offline_claim_timestamp", 0), 0, now)

	normalized["habitats"] = _normalize_habitats(normalized.get("habitats", {}), now)
	normalized["owned_reptile_instances"] = _normalize_animals(_get_loaded_animals(normalized))
	_migrate_removed_house(normalized)
	var normalized_animals_value: Variant = normalized.get("owned_reptile_instances", {})
	var normalized_animals: Dictionary = normalized_animals_value as Dictionary
	normalized["owned_animals"] = normalized_animals.duplicate(true)
	_normalize_assignment_relationships(normalized)
	normalized["discovered_variants"] = _normalize_discovered_variants(normalized.get("discovered_variants", {}), normalized["owned_reptile_instances"])
	normalized["incubator_storage"] = _normalize_incubator_storage(normalized.get("incubator_storage", {}))
	normalized["incubator_storage"] = _release_hatched_reptiles_from_incubator_storage(normalized["incubator_storage"], normalized["owned_reptile_instances"])
	normalized["breeding_chambers"] = _normalize_breeding_chambers(normalized.get("breeding_chambers", {}))
	normalized["incubation_containers"] = _normalize_incubation_containers(normalized.get("incubation_containers", {}))
	# Check the incoming keys: defaults must not erase evidence from older saves.
	normalized["starter_reptile_claimed"] = bool(data.get("starter_reptile_claimed", _has_reptile_history(normalized)))
	normalized["first_hatch_starter_granted"] = bool(data.get("first_hatch_starter_granted", _has_incubator_history(normalized)))
	normalized["onboarding_track_version"] = max(1, int(data.get("onboarding_track_version", 1)))
	normalized["offline_income_rate_per_minute"] = max(-1.0, float(normalized.get("offline_income_rate_per_minute", -1.0)))
	_normalize_expeditions(normalized)
	normalized["habitat_action_xp_claims"] = _normalize_dictionary(data.get("habitat_action_xp_claims", {}))
	if not data.has("habitat_action_xp_claims"):
		# Existing progress is already settled; never grant action XP retroactively.
		for habitat_id: String in normalized["habitats"]:
			var habitat: Dictionary = normalized["habitats"][habitat_id]
			if not bool(habitat.get("purchased", false)): continue
			normalized["habitat_action_xp_claims"][habitat_id + ":build"] = true
			var last_level := int(habitat.get("habitat_level", 1))
			if bool(habitat.get("is_upgrading", false)): last_level = maxi(last_level, int(habitat.get("upgrade_target_level", last_level)))
			for level in range(2, last_level + 1):
				normalized["habitat_action_xp_claims"][habitat_id + ":upgrade:" + str(level)] = true
	return normalized


func _migrate_removed_house(data: Dictionary) -> void:
	# Keep stable animal/habitat IDs: saved pairings, eggs and discoveries refer to them.
	var habitats: Dictionary = data.get("habitats", {})
	var animals: Dictionary = data.get("owned_reptile_instances", {})
	var unlocked: Array = data.get("unlocked_biomes", [])
	var had_house_access: bool = unlocked.has("house")
	var had_house_records: bool = had_house_access
	for key in ["biomes", "biome_resources", "workers_by_biome", "upgrade_levels_by_biome"]:
		if _normalize_dictionary(data.get(key, {})).has("house"):
			had_house_records = true
	unlocked.erase("house")
	var next_slot: Dictionary = {"green_meadow": 13, "dry_prairie": 12}
	for habitat in habitats.values():
		var target: String = str(habitat.get("biome_id", ""))
		if next_slot.has(target):
			next_slot[target] = maxi(int(next_slot[target]), int(habitat.get("slot_index", 0)) + 1)
	var habitat_ids: Array = habitats.keys()
	habitat_ids.sort()
	for habitat_id in habitat_ids:
		var habitat: Dictionary = habitats[habitat_id]
		if str(habitat.get("biome_id", "")) != "house":
			continue
		had_house_records = true
		var animal_id: String = str(habitat.get("animal_instance_id", habitat.get("reptile_instance_id", "")))
		var animal: Dictionary = animals.get(animal_id, {})
		var species: String = str(animal.get("reptile_id", habitat.get("reptile_id", "")))
		var fallback: String = "dry_prairie" if str(habitat.get("habitat_type", "")) in ["sand", "stone"] else DEFAULT_BIOME_ID
		var target: String = str(FORMER_HOUSE_SPECIES_BIOMES.get(species, fallback))
		habitat["biome_id"] = target
		habitat["legacy_biome_id"] = "house"
		habitat["legacy_slot_index"] = int(habitat.get("slot_index", 0))
		habitat["slot_index"] = int(next_slot[target])
		next_slot[target] = int(next_slot[target]) + 1
		habitats[habitat_id] = habitat
		if (bool(habitat.get("purchased", false)) or not animal.is_empty()) and not unlocked.has(target):
			unlocked.append(target)
	for animal_id in animals.keys():
		var animal: Dictionary = animals[animal_id]
		var species: String = str(animal.get("reptile_id", ""))
		if FORMER_HOUSE_SPECIES_BIOMES.has(species):
			animal["biome_id"] = FORMER_HOUSE_SPECIES_BIOMES[species]
			# An owned animal must remain assignable even in an unusual low-level old save.
			if had_house_records and not unlocked.has(animal["biome_id"]):
				unlocked.append(animal["biome_id"])
		elif str(animal.get("biome_id", "")) == "house":
			animal["biome_id"] = DEFAULT_BIOME_ID
		animals[animal_id] = animal
	if had_house_access:
		for target in [DEFAULT_BIOME_ID, "dry_prairie"]:
			if not unlocked.has(target):
				unlocked.append(target)
	data["unlocked_biomes"] = unlocked
	data["habitats"] = habitats
	data["owned_reptile_instances"] = animals

	# Retain old regional records as an archive while transferring their usable value.
	var archive: Dictionary = _normalize_dictionary(data.get("legacy_house_progress", {}))
	for key in ["biomes", "biome_progress", "biome_progress_points", "biome_resources", "workers_by_biome", "upgrade_levels_by_biome"]:
		var regional: Dictionary = _normalize_dictionary(data.get(key, {}))
		if not regional.has("house"):
			continue
		var former: Variant = regional["house"]
		if not archive.has(key):
			archive[key] = former.duplicate(true) if typeof(former) in [TYPE_DICTIONARY, TYPE_ARRAY] else former
		if key == "biome_resources" and typeof(former) == TYPE_DICTIONARY:
			var destination: Dictionary = _normalize_dictionary(regional.get(DEFAULT_BIOME_ID, {}))
			for resource in ["food", "water"]:
				for suffix in ["_max", "_current"]:
					var stat: String = resource + suffix
					destination[stat] = int(destination.get(stat, 0)) + int(former.get(stat, 0))
			regional[DEFAULT_BIOME_ID] = destination
		elif key in ["workers_by_biome", "upgrade_levels_by_biome"] and typeof(former) == TYPE_DICTIONARY:
			# Existing caretakers/upgrades follow both groups of relocated residents.
			for target in [DEFAULT_BIOME_ID, "dry_prairie"]:
				var destination: Dictionary = _normalize_dictionary(regional.get(target, {}))
				for entry_id in former.keys():
					var old_entry: Variant = former[entry_id]
					if key == "workers_by_biome" and typeof(old_entry) == TYPE_DICTIONARY:
						var current: Dictionary = _normalize_dictionary(destination.get(entry_id, {}))
						if int(old_entry.get("level", 0)) > int(current.get("level", 0)):
							destination[entry_id] = old_entry.duplicate(true)
					elif key == "upgrade_levels_by_biome":
						destination[entry_id] = maxi(int(destination.get(entry_id, 0)), int(old_entry))
				regional[target] = destination
		elif typeof(former) in [TYPE_INT, TYPE_FLOAT]:
			regional[DEFAULT_BIOME_ID] = float(regional.get(DEFAULT_BIOME_ID, 0)) + float(former)
		regional.erase("house")
		data[key] = regional
	if not archive.is_empty():
		data["legacy_house_progress"] = archive
		data["workers"] = _normalize_dictionary(data.get("workers_by_biome", {}).get(DEFAULT_BIOME_ID, data.get("workers", {})))
	for key in ["current_biome", "current_biome_id", "active_biome", "active_biome_id", "selected_biome", "selected_biome_id"]:
		if str(data.get(key, "")) == "house":
			data[key] = DEFAULT_BIOME_ID


func _normalize_expeditions(data: Dictionary) -> void:
	var counter: int = maxi(0, int(data.get("expedition_counter", 0)))
	for key in ["expeditions", "expedition_log"]:
		var records: Array = []
		var seen: Dictionary = {}
		var raw: Variant = data.get(key, [])
		if raw is Array:
			for entry in raw:
				if not entry is Dictionary: continue
				var record: Dictionary = (entry as Dictionary).duplicate(true)
				var id: String = str(record.get("id", ""))
				if id.is_empty() or seen.has(id): continue
				seen[id] = true
				if id.begins_with("expedition_"):
					counter = maxi(counter, int(id.trim_prefix("expedition_")))
				record["started_at"] = maxi(0, int(record.get("started_at", 0)))
				record["ends_at"] = maxi(int(record["started_at"]), int(record.get("ends_at", 0)))
				record["reward"] = _normalize_dictionary(record.get("reward", {}))
				records.append(record)
		data[key] = records.slice(maxi(0, records.size() - 20)) if key == "expedition_log" else records
	data["expedition_counter"] = counter


func _has_reptile_history(data: Dictionary) -> bool:
	if not (data.get("owned_reptile_instances", {}) as Dictionary).is_empty() or not (data.get("discovered_variants", {}) as Dictionary).is_empty():
		return true
	var onboarding: Dictionary = data.get("onboarding_state", {})
	var evidence_ids: Array[String] = ["buy_first_reptile", "assign_first_reptile", "assign_first_reptile_to_habitat", "care_for_reptile", "own_two_reptiles"]
	for list_key in ["completed_quests", "claimed_quests"]:
		for task_id in data.get(list_key, []):
			if evidence_ids.has(str(task_id)):
				return true
	for list_key in ["completed_task_ids", "claimed_task_ids"]:
		for task_id in onboarding.get(list_key, []):
			if evidence_ids.has(str(task_id)):
				return true
	var counters: Dictionary = onboarding.get("event_counters", {})
	for event_id in ["reptile_bought", "reptile_owned", "reptile_assigned", "any_reptile_care_action"]:
		if int(counters.get(event_id, 0)) > 0:
			return true
	return false


func _has_incubator_history(data: Dictionary) -> bool:
	var storage: Dictionary = data.get("incubator_storage", {})
	for key in ["eggs", "reptiles", "hatchlings"]:
		if not (storage.get(key, []) as Array).is_empty():
			return true
	for key in ["breeding_chambers", "incubation_containers"]:
		if not (data.get(key, {}) as Dictionary).is_empty():
			return true
	for instance in (data.get("owned_reptile_instances", {}) as Dictionary).values():
		if str((instance as Dictionary).get("source", "")) in ["incubation", "starter_egg"]:
			return true
	for counter_key in (data.get("quest_event_counters", {}) as Dictionary).keys():
		if str(counter_key).begins_with("incubator") and int(data["quest_event_counters"][counter_key]) > 0:
			return true
	for key in ["completed_quests", "claimed_quests"]:
		for quest_id in data.get(key, []):
			if str(quest_id).begins_with("incubator_"):
				return true
	return false


func _normalize_incubator_storage(raw: Variant) -> Dictionary:
	var storage: Dictionary = {"reptiles": [], "eggs": [], "hatchlings": []}
	if typeof(raw) != TYPE_DICTIONARY:
		return storage
	var src: Dictionary = raw as Dictionary
	for key in ["reptiles", "eggs", "hatchlings"]:
		var val: Variant = src.get(key, [])
		storage[key] = val if typeof(val) == TYPE_ARRAY else []
	return storage


func _release_hatched_reptiles_from_incubator_storage(storage: Dictionary, owned_instances: Dictionary) -> Dictionary:
	for storage_key in ["reptiles", "hatchlings"]:
		var reptiles_value: Variant = storage.get(storage_key, [])
		if typeof(reptiles_value) != TYPE_ARRAY:
			storage[storage_key] = []
			continue

		var kept_reptiles: Array = []
		for entry_value in (reptiles_value as Array):
			if typeof(entry_value) != TYPE_DICTIONARY:
				kept_reptiles.append(entry_value)
				continue
			var entry: Dictionary = entry_value as Dictionary
			var instance_id: String = str(entry.get("instance_id", entry.get("animal_instance_id", ""))).strip_edges()
			if instance_id.is_empty() or not _is_owned_hatched_reptile(instance_id, owned_instances):
				kept_reptiles.append(entry)
		storage[storage_key] = kept_reptiles
	return storage


func _is_owned_hatched_reptile(instance_id: String, owned_instances: Dictionary) -> bool:
	if not owned_instances.has(instance_id):
		return false
	var instance_value: Variant = owned_instances.get(instance_id)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return false
	var instance: Dictionary = instance_value as Dictionary
	var source: String = str(instance.get("source", ""))
	var source_egg_id: String = str(instance.get("source_egg_id", "")).strip_edges()
	return source == "incubation" or not source_egg_id.is_empty() or instance_id.begins_with("hatch_")


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


func _normalize_biome_resources(value: Variant, now: int, base_food_max: int = 100, base_water_max: int = 100) -> Dictionary:
	var defaults: Dictionary = get_default_biome_resources()
	var safe_food_max: int = max(1, base_food_max)
	var safe_water_max: int = max(1, base_water_max)
	var result: Dictionary = {}
	for biome_id in defaults.keys():
		var d: Dictionary = (defaults[biome_id] as Dictionary).duplicate(true)
		d["food_max"] = safe_food_max
		d["water_max"] = safe_water_max
		d["food_current"] = int(clamp(int(d.get("food_current", safe_food_max)), 0, safe_food_max))
		d["water_current"] = int(clamp(int(d.get("water_current", safe_water_max)), 0, safe_water_max))
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
				result[biome_id]["food_max"] = safe_food_max
				result[biome_id]["water_max"] = safe_water_max
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
	return _normalize_language(str(state.get("language", "en")))


func set_language(language: String) -> void:
	language = _normalize_language(language)
	if state.get("language", "en") == language:
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
	settings["language"] = _normalize_language(str(settings.get("language", state.get("language", "en"))))
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
		animal["first_assignment_xp_claimed"] = true
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
		# Missing means a pre-feature animal, including those currently in storage.
		normalized["first_assignment_xp_claimed"] = bool(incoming.get("first_assignment_xp_claimed", true))
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
	# Existing residents stay assigned during habitat upgrades, including reloads.
	# New construction still cannot hold a resident.
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
		if instance_id == null or not animals.has(str(instance_id)) or bool(habitat.get("is_building", false)):
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
		if not bool(habitat.get("purchased", false)) or bool(habitat.get("is_building", false)):
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
	return get_required_xp_for_level(level)


func get_required_xp_for_level(level: int) -> int:
	if level <= 1:
		return 0

	var progression: Dictionary = _get_level_progression()
	var levels_value: Variant = progression.get("levels", {})
	var levels: Dictionary = levels_value as Dictionary if typeof(levels_value) == TYPE_DICTIONARY else {}
	var multiplier: float = maxf(1.01, float(progression.get("multiplier", 1.45)))
	var previous: int = 0
	for next_level in range(2, level + 1):
		var fallback: int = int(round(float(previous) * multiplier)) if next_level > 2 else int(progression.get("level_2_xp", 600))
		previous = maxi(previous + 1, int(levels.get(str(next_level), fallback)))
	return previous


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
