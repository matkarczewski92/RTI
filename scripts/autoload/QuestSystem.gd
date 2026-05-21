extends Node

signal quest_completed(quest_id: String)
signal quest_claimed(quest_id: String)

const QUESTS_PATH := "res://data/quests.json"

var quests: Array = []


func _ready() -> void:
	load_data()
	call_deferred("migrate_save_state")


func load_data() -> bool:
	var file: FileAccess = FileAccess.open(QUESTS_PATH, FileAccess.READ)
	if file == null:
		quests = []
		push_warning("Missing quests data file: " + QUESTS_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		quests = []
		push_warning("Invalid quests data file: " + QUESTS_PATH)
		return false

	quests = parsed as Array
	quests.sort_custom(func(a: Variant, b: Variant) -> bool:
		if typeof(a) != TYPE_DICTIONARY or typeof(b) != TYPE_DICTIONARY:
			return false
		return int((a as Dictionary).get("sort_order", 0)) < int((b as Dictionary).get("sort_order", 0))
	)
	return true


func migrate_save_state() -> bool:
	var changed := false
	if typeof(GameState.get_value("quest_progress", null)) != TYPE_DICTIONARY:
		GameState.set_value("quest_progress", {})
		changed = true
	if typeof(GameState.get_value("quest_event_counters", null)) != TYPE_DICTIONARY:
		GameState.set_value("quest_event_counters", {})
		changed = true
	if typeof(GameState.get_value("completed_quests", null)) != TYPE_ARRAY:
		GameState.set_value("completed_quests", [])
		changed = true
	if typeof(GameState.get_value("claimed_quests", null)) != TYPE_ARRAY:
		GameState.set_value("claimed_quests", [])
		changed = true
	var counters_value: Variant = GameState.get_value("quest_event_counters", {})
	var counters: Dictionary = counters_value as Dictionary if typeof(counters_value) == TYPE_DICTIONARY else {}
	for counter_id in _get_required_counter_ids():
		if not counters.has(counter_id):
			counters[counter_id] = 0
			changed = true
	if changed:
		GameState.set_value("quest_event_counters", counters)

	if changed:
		SaveSystem.save_game()

	return changed


func get_all_quests(include_hidden: bool = false) -> Array:
	migrate_save_state()
	var result: Array = []
	for quest_value in quests:
		if typeof(quest_value) != TYPE_DICTIONARY:
			continue

		var quest: Dictionary = quest_value as Dictionary
		if not include_hidden and bool(quest.get("is_hidden", false)):
			continue
		if not include_hidden and not _is_quest_visible(quest):
			continue

		result.append(_make_quest_state(quest))

	result.sort_custom(_sort_quest_states)
	return result


func _sort_quest_states(a: Variant, b: Variant) -> bool:
	if typeof(a) != TYPE_DICTIONARY or typeof(b) != TYPE_DICTIONARY:
		return false

	var quest_a: Dictionary = a as Dictionary
	var quest_b: Dictionary = b as Dictionary
	var group_a: int = _get_sort_group(quest_a)
	var group_b: int = _get_sort_group(quest_b)
	if group_a != group_b:
		return group_a < group_b

	return int(quest_a.get("sort_order", 0)) < int(quest_b.get("sort_order", 0))


func _get_sort_group(state: Dictionary) -> int:
	var onboarding: bool = bool(state.get("is_onboarding", false))
	if bool(state.get("claimable", false)):
		return 0 if onboarding else 1
	if bool(state.get("claimed", false)):
		return 6
	if onboarding:
		return 2
	return 3


func get_active_quests(limit: int = 0) -> Array:
	var result: Array = []
	for state_value in get_all_quests(false):
		if typeof(state_value) != TYPE_DICTIONARY:
			continue

		var state: Dictionary = state_value as Dictionary
		if not bool(state.get("is_active", true)):
			continue
		if bool(state.get("claimed", false)):
			continue
		result.append(state)

	result.sort_custom(_sort_quest_states)
	if limit > 0 and result.size() > limit:
		return result.slice(0, limit)
	return result


func get_next_step_quest() -> Dictionary:
	for state_value in get_active_quests(0):
		if typeof(state_value) != TYPE_DICTIONARY:
			continue

		var state: Dictionary = state_value as Dictionary
		if bool(state.get("claimed", false)):
			continue
		return state

	return {}


func get_completed_unclaimed_quests() -> Array:
	var result: Array = []
	for state_value in get_all_quests(false):
		if typeof(state_value) == TYPE_DICTIONARY and bool((state_value as Dictionary).get("claimable", false)):
			result.append(state_value)
	return result


func get_claimed_quests() -> Array:
	var result: Array = []
	for state_value in get_all_quests(false):
		if typeof(state_value) == TYPE_DICTIONARY and bool((state_value as Dictionary).get("claimed", false)):
			result.append(state_value)
	return result


func get_quest_progress(quest_id: String) -> Dictionary:
	var quest: Dictionary = _get_quest(quest_id)
	if quest.is_empty():
		return {"current": 0, "target": 1}
	return _calculate_progress(quest)


func claim_quest_reward(quest_id: String) -> Dictionary:
	migrate_save_state()
	if is_claimed(quest_id):
		return {"success": false, "message_key": "quests.claimed"}

	var quest: Dictionary = _get_quest(quest_id)
	if quest.is_empty():
		return {"success": false, "message_key": "quests.in_progress"}

	var state: Dictionary = _make_quest_state(quest)
	if not bool(state.get("completed", false)):
		return {"success": false, "message_key": "quests.in_progress"}

	var reward_type: String = str(quest.get("reward_type", "repticash"))
	var reward_amount: float = float(quest.get("reward_amount", 0.0))
	var reward_xp: float = float(quest.get("reward_xp", 0.0))
	var reward_food_max: int = max(0, int(quest.get("reward_food_max", 0)))
	var reward_water_max: int = max(0, int(quest.get("reward_water_max", 0)))
	if reward_amount > 0.0:
		EconomySystem.add_currency(reward_type, reward_amount)
	if reward_xp > 0.0:
		EconomySystem.add_currency("xp", reward_xp)
	if reward_food_max > 0:
		reward_food_max = _grant_resource_capacity_reward("food", reward_food_max)
	if reward_water_max > 0:
		reward_water_max = _grant_resource_capacity_reward("water", reward_water_max)

	var claimed: Array = GameState.get_value("claimed_quests", []) as Array
	claimed.append(quest_id)
	GameState.set_value("claimed_quests", claimed)
	var completed: Array = GameState.get_value("completed_quests", []) as Array
	if not completed.has(quest_id):
		completed.append(quest_id)
		GameState.set_value("completed_quests", completed)
	SaveSystem.save_game()
	quest_claimed.emit(quest_id)
	return {
		"success": true,
		"reward_type": reward_type,
		"reward_amount": reward_amount,
		"reward_xp": reward_xp,
		"reward_food_max": reward_food_max,
		"reward_water_max": reward_water_max
	}


func _grant_resource_capacity_reward(resource_id: String, amount: int) -> int:
	if amount <= 0:
		return 0
	if not ReptileSystem.has_method("increase_resource_max"):
		return 0
	return int(ReptileSystem.call("increase_resource_max", resource_id, amount))


func notify_event(event_type: String, payload: Dictionary = {}) -> void:
	migrate_save_state()
	match event_type:
		"screen_opened":
			_increment_counter("screen:" + str(payload.get("screen", "")), 1)
		"care_action_success":
			_increment_counter("care:" + str(payload.get("action", "")), 1)
		"reptile_named":
			_increment_counter("named", 1)
		"habitat_purchased":
			_increment_counter("habitat_purchased", 1)
		"reptile_purchased":
			_increment_counter("reptile_purchased", 1)
		"reptile_assigned":
			_increment_counter("reptile_assigned", 1)
		"variant_discovered":
			_increment_counter("variant_discovered", 1)
		"offline_income_claimed":
			_increment_counter("offline_income_claimed", 1)
		"incubator_entered":
			_set_counter_at_least("incubator_entered_total", 1)
		"incubator_egg_obtained":
			var egg_amount: int = max(1, int(payload.get("amount", 1)))
			_increment_counter("incubator_eggs_obtained_total", egg_amount)
			if str(payload.get("source", "")) == "shop":
				_increment_counter("incubator_shop_eggs_bought_total", egg_amount)
		"incubator_breeding_started":
			_increment_counter("incubator_pairings_started_total", 1)
		"incubator_breeding_collected":
			var egg_count: int = max(0, int(payload.get("egg_count", 0)))
			if bool(payload.get("is_long", false)):
				_set_counter_at_least("incubator_long_pairing_collected_total", 1)
			if bool(payload.get("succeeded", false)) and egg_count > 0:
				_increment_counter("incubator_successful_pairings_total", 1)
				if egg_count >= 3:
					_set_counter_at_least("incubator_clutch_3_plus_total", 1)
				if egg_count == 5:
					_set_counter_at_least("incubator_clutch_5_total", 1)
		"incubator_eggs_loaded":
			if int(payload.get("egg_count", 0)) == 10:
				_set_counter_at_least("incubator_loaded_10_eggs_container_total", 1)
		"incubator_incubation_started":
			_increment_counter("incubator_incubations_started_total", 1)
			var running_count: int = int(payload.get("running_count", 0))
			if running_count >= 3:
				_set_counter_at_least("incubator_run_3_containers_total", 1)
			if running_count >= 6:
				_set_counter_at_least("incubator_run_6_containers_total", 1)
		"incubator_container_watered":
			_increment_counter("incubator_water_actions_total", 1)
			if str(payload.get("previous_state", "")) == "running" and float(payload.get("previous_humidity_percent", 0.0)) >= 50.0:
				_set_counter_at_least("incubator_water_before_pause_total", 1)
			if str(payload.get("previous_state", "")) == "paused_low_humidity" and str(payload.get("new_state", "")) == "running":
				_set_counter_at_least("incubator_resume_paused_incubation_total", 1)
		"incubator_hatched":
			var hatch_count: int = max(0, int(payload.get("count", 0)))
			_increment_counter("incubator_hatches_total", hatch_count)
			var rarities_value: Variant = payload.get("rarities", [])
			var rarities: Array = rarities_value as Array if typeof(rarities_value) == TYPE_ARRAY else []
			for rarity_value in rarities:
				match str(rarity_value):
					"rare":
						_set_counter_at_least("incubator_hatch_rare_total", 1)
					"ultra_rare":
						_set_counter_at_least("incubator_hatch_ultra_rare_total", 1)
					"exceptional":
						_set_counter_at_least("incubator_hatch_exceptional_total", 1)
		_:
			pass
	_mark_new_completions()
	SaveSystem.save_game()


func is_claimed(quest_id: String) -> bool:
	var claimed_value: Variant = GameState.get_value("claimed_quests", [])
	if typeof(claimed_value) != TYPE_ARRAY:
		return false
	return (claimed_value as Array).has(quest_id)


func _make_quest_state(quest: Dictionary) -> Dictionary:
	var progress: Dictionary = _calculate_progress(quest)
	var quest_id: String = str(quest.get("id", ""))
	var prerequisites_met: bool = _are_prerequisites_met(quest)
	var accessible: bool = _is_quest_accessible(quest)
	var completed: bool = accessible and prerequisites_met and int(progress.get("current", 0)) >= int(progress.get("target", 1))
	var claimed: bool = is_claimed(quest_id)
	var state: Dictionary = quest.duplicate(true)
	state["current"] = int(progress.get("current", 0))
	state["target"] = int(progress.get("target", 1))
	state["completed"] = completed
	state["claimed"] = claimed
	state["claimable"] = completed and not claimed
	state["prerequisites_met"] = prerequisites_met
	state["accessible"] = accessible
	return state


func _is_quest_visible(quest: Dictionary) -> bool:
	if not _is_quest_accessible(quest):
		return false
	if bool(quest.get("hide_until_prerequisites_met", false)):
		return _are_prerequisites_met(quest)
	if not bool(quest.get("is_onboarding", false)):
		return true
	return _are_prerequisites_met(quest)


func _are_prerequisites_met(quest: Dictionary) -> bool:
	var prerequisites_value: Variant = quest.get("prerequisite_quest_ids", [])
	if typeof(prerequisites_value) != TYPE_ARRAY:
		return true

	for prerequisite_value in (prerequisites_value as Array):
		var prerequisite_id: String = str(prerequisite_value)
		if prerequisite_id.is_empty():
			continue
		if is_claimed(prerequisite_id):
			continue
		if _is_quest_completed(prerequisite_id):
			continue
		return false

	return true


func _is_quest_completed(quest_id: String) -> bool:
	var quest: Dictionary = _get_quest(quest_id)
	if quest.is_empty():
		return false
	if not _is_quest_accessible(quest):
		return false
	if not _are_prerequisites_met(quest):
		return false

	var completed_value: Variant = GameState.get_value("completed_quests", [])
	if typeof(completed_value) == TYPE_ARRAY and (completed_value as Array).has(quest_id):
		return true

	var progress: Dictionary = _calculate_progress(quest)
	return int(progress.get("current", 0)) >= int(progress.get("target", 1))


func _calculate_progress(quest: Dictionary) -> Dictionary:
	var requirement_type: String = str(quest.get("requirement_type", ""))
	var requirement_target: String = str(quest.get("requirement_target", ""))
	var target: int = max(1, int(quest.get("requirement_value", 1)))
	var current := 0
	if not _is_quest_accessible(quest):
		return {"current": 0, "target": target}
	match requirement_type:
		"purchased_habitats_count":
			current = _get_purchased_habitats_count()
		"purchased_habitats_count_in_biome":
			current = _get_purchased_habitats_count(requirement_target)
		"usable_habitats_count":
			current = _get_usable_habitats_count()
		"screen_opened":
			current = _get_counter("screen:" + requirement_target)
		"biome_unlocked":
			current = 1 if _is_biome_unlocked(requirement_target) else 0
		"owned_reptiles_count":
			current = ReptileSystem.get_owned_reptile_count()
		"owned_reptile_species_count":
			current = _get_owned_reptile_species_count(quest)
		"owned_reptiles_with_sex_count":
			current = _get_owned_reptiles_with_sex_count(requirement_target)
		"assigned_reptiles_count":
			current = _get_assigned_reptiles_count()
		"species_assignments_count":
			current = _get_species_assignments_count(quest)
		"habitat_types_covered_by_biome_reptiles":
			current = _get_habitat_types_covered_count(quest)
		"named_reptiles_count":
			current = _get_named_reptiles_count()
		"discovered_variants_count":
			current = _get_discovered_variant_count()
		"care_action_count":
			current = _get_counter("care:" + requirement_target)
		"total_care_actions_count":
			current = _get_total_care_actions_count()
		"current_currency_at_least":
			current = int(floor(float(EconomySystem.get_currency(requirement_target if not requirement_target.is_empty() else "repticash"))))
		"lifetime_currency_earned":
			current = int(floor(float(GameState.get_value("lifetime_repticash_earned", EconomySystem.get_currency("repticash")))))
		"player_level_at_least":
			current = int(GameState.get_value("level", 1))
		"habitats_at_level_count":
			current = _get_habitats_at_level_count(max(1, int(requirement_target)))
		"offline_income_claimed_count":
			current = _get_counter("offline_income_claimed")
		"claimed_quests_count":
			current = _get_claimed_quests_count()
		"workers_hired_count":
			current = _get_workers_hired_count()
		"event_counter_at_least":
			current = _get_counter(requirement_target)
		_:
			push_warning("Unknown quest requirement type: " + requirement_type)
			current = 0

	return {"current": min(current, target), "target": target}


func _mark_new_completions() -> void:
	var completed: Array = GameState.get_value("completed_quests", []) as Array
	var changed := false
	for state_value in get_all_quests(false):
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = state_value as Dictionary
		var quest_id: String = str(state.get("id", ""))
		if bool(state.get("completed", false)) and not completed.has(quest_id):
			completed.append(quest_id)
			changed = true
			quest_completed.emit(quest_id)
	if changed:
		GameState.set_value("completed_quests", completed)


func _increment_counter(counter_id: String, amount: int) -> void:
	if counter_id.ends_with(":"):
		return
	var counters: Dictionary = GameState.get_value("quest_event_counters", {}) as Dictionary
	counters[counter_id] = int(counters.get(counter_id, 0)) + amount
	GameState.set_value("quest_event_counters", counters)


func _set_counter_at_least(counter_id: String, value: int) -> void:
	if counter_id.ends_with(":"):
		return
	var counters: Dictionary = GameState.get_value("quest_event_counters", {}) as Dictionary
	counters[counter_id] = max(int(counters.get(counter_id, 0)), value)
	GameState.set_value("quest_event_counters", counters)


func _get_counter(counter_id: String) -> int:
	var counters_value: Variant = GameState.get_value("quest_event_counters", {})
	if typeof(counters_value) != TYPE_DICTIONARY:
		return 0
	return int((counters_value as Dictionary).get(counter_id, 0))


func _get_required_counter_ids() -> Array[String]:
	return [
		"incubator_entered_total",
		"incubator_eggs_obtained_total",
		"incubator_shop_eggs_bought_total",
		"incubator_pairings_started_total",
		"incubator_long_pairing_collected_total",
		"incubator_successful_pairings_total",
		"incubator_clutch_3_plus_total",
		"incubator_clutch_5_total",
		"incubator_loaded_10_eggs_container_total",
		"incubator_incubations_started_total",
		"incubator_run_3_containers_total",
		"incubator_run_6_containers_total",
		"incubator_water_actions_total",
		"incubator_water_before_pause_total",
		"incubator_resume_paused_incubation_total",
		"incubator_hatches_total",
		"incubator_hatch_rare_total",
		"incubator_hatch_ultra_rare_total",
		"incubator_hatch_exceptional_total"
	]


func _get_quest(quest_id: String) -> Dictionary:
	for quest_value in quests:
		if typeof(quest_value) == TYPE_DICTIONARY and str((quest_value as Dictionary).get("id", "")) == quest_id:
			return quest_value as Dictionary
	return {}


func _is_quest_accessible(quest: Dictionary) -> bool:
	var required_dlc: String = str(quest.get("requires_dlc", ""))
	if not required_dlc.is_empty() and not _is_biome_unlocked(required_dlc):
		return false

	var required_biome: String = str(quest.get("requires_biome", ""))
	if required_biome.is_empty():
		required_biome = str(quest.get("biome_id", ""))
	var requires_biome_unlocked: bool = bool(quest.get("requires_biome_unlocked", false)) \
		or bool(quest.get("is_paid_content", false)) \
		or not required_dlc.is_empty()
	if requires_biome_unlocked and not required_biome.is_empty():
		return _is_biome_unlocked(required_biome)

	return true


func _is_biome_unlocked(biome_id: String) -> bool:
	if biome_id.is_empty():
		return true
	if biome_id == GameState.DEFAULT_BIOME_ID:
		return true

	var unlocked_value: Variant = GameState.get_value("unlocked_biomes", [])
	if typeof(unlocked_value) != TYPE_ARRAY:
		return false
	return (unlocked_value as Array).has(biome_id)


func _get_purchased_habitats_count(biome_id: String = "") -> int:
	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return count
	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		if not biome_id.is_empty() and str(habitat.get("biome_id", "")) != biome_id:
			continue
		if bool(habitat.get("purchased", false)):
			count += 1
	return count


func _get_usable_habitats_count() -> int:
	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return count
	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		if bool(habitat.get("purchased", false)) and not bool(habitat.get("is_building", false)) and not bool(habitat.get("is_upgrading", false)):
			count += 1
	return count


func _get_assigned_reptiles_count() -> int:
	var count := 0
	for instance_value in ReptileSystem.get_owned_reptile_instances().values():
		if typeof(instance_value) == TYPE_DICTIONARY and not str((instance_value as Dictionary).get("habitat_id", "")).is_empty():
			count += 1
	return count


func _get_named_reptiles_count() -> int:
	var count := 0
	for instance_value in ReptileSystem.get_owned_reptile_instances().values():
		if typeof(instance_value) == TYPE_DICTIONARY and not str((instance_value as Dictionary).get("custom_name", "")).strip_edges().is_empty():
			count += 1
	return count


func _get_owned_reptiles_with_sex_count(sex: String) -> int:
	var count := 0
	for instance_value in ReptileSystem.get_owned_reptile_instances().values():
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue
		var instance_sex: String = str((instance_value as Dictionary).get("sex", ""))
		if sex == "any" and (instance_sex == "male" or instance_sex == "female"):
			count += 1
		elif instance_sex == sex:
			count += 1
	return count


func _get_discovered_variant_count() -> int:
	var count := 0
	var discovered_value: Variant = GameState.get_value("discovered_variants", {})
	if typeof(discovered_value) != TYPE_DICTIONARY:
		return 0
	for discovered in (discovered_value as Dictionary).values():
		if bool(discovered):
			count += 1
	return count


func _get_species_assignments_count(quest: Dictionary) -> int:
	var assignments_value: Variant = quest.get("required_assignments", [])
	if typeof(assignments_value) != TYPE_ARRAY:
		return 0

	var biome_id: String = str(quest.get("biome_id", ""))
	if biome_id.is_empty():
		biome_id = str(quest.get("requires_biome", ""))

	var count := 0
	for assignment_value in (assignments_value as Array):
		if typeof(assignment_value) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = assignment_value as Dictionary
		var reptile_id: String = str(assignment.get("reptile_id", ""))
		var habitat_type: String = ReptileSystem.normalize_habitat_type(str(assignment.get("habitat_type", "")))
		if _has_species_assigned_to_habitat_type(reptile_id, habitat_type, biome_id):
			count += 1
	return count


func _get_habitat_types_covered_count(quest: Dictionary) -> int:
	var required_types_value: Variant = quest.get("required_habitat_types", [])
	if typeof(required_types_value) != TYPE_ARRAY:
		return 0

	var biome_id: String = str(quest.get("biome_id", ""))
	if biome_id.is_empty():
		biome_id = str(quest.get("requires_biome", ""))

	var count := 0
	for type_value in (required_types_value as Array):
		var habitat_type: String = ReptileSystem.normalize_habitat_type(str(type_value))
		if _has_any_biome_reptile_assigned_to_habitat_type(biome_id, habitat_type):
			count += 1
	return count


func _get_owned_reptile_species_count(quest: Dictionary) -> int:
	var required_species_value: Variant = quest.get("required_reptile_ids", [])
	if typeof(required_species_value) != TYPE_ARRAY:
		return 0

	var count := 0
	for reptile_id_value in (required_species_value as Array):
		if _owns_reptile_species(str(reptile_id_value)):
			count += 1
	return count


func _has_species_assigned_to_habitat_type(reptile_id: String, habitat_type: String, biome_id: String = "") -> bool:
	if reptile_id.is_empty() or habitat_type.is_empty():
		return false

	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return false

	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		if not biome_id.is_empty() and str(habitat.get("biome_id", "")) != biome_id:
			continue
		if ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", ""))) != habitat_type:
			continue
		if str(habitat.get("reptile_id", "")) == reptile_id:
			return true
	return false


func _has_any_biome_reptile_assigned_to_habitat_type(biome_id: String, habitat_type: String) -> bool:
	if biome_id.is_empty() or habitat_type.is_empty():
		return false

	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return false

	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		if str(habitat.get("biome_id", "")) != biome_id:
			continue
		if ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", ""))) != habitat_type:
			continue
		var reptile_id: String = str(habitat.get("reptile_id", ""))
		if not reptile_id.is_empty() and ReptileSystem.is_reptile_available_in_biome(reptile_id, biome_id):
			return true
	return false


func _owns_reptile_species(reptile_id: String) -> bool:
	if reptile_id.is_empty():
		return false

	for instance_value in ReptileSystem.get_owned_reptile_instances().values():
		if typeof(instance_value) == TYPE_DICTIONARY and str((instance_value as Dictionary).get("reptile_id", "")) == reptile_id:
			return true
	return false


func _get_total_care_actions_count() -> int:
	return _get_counter("care:feed") + _get_counter("care:water") + _get_counter("care:clean") + _get_counter("care:play")


func _get_habitats_at_level_count(required_level: int) -> int:
	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return count
	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		if bool(habitat.get("purchased", false)) and not bool(habitat.get("is_building", false)) and int(habitat.get("habitat_level", 1)) >= required_level:
			count += 1
	return count


func _get_claimed_quests_count() -> int:
	var claimed_value: Variant = GameState.get_value("claimed_quests", [])
	if typeof(claimed_value) != TYPE_ARRAY:
		return 0
	return (claimed_value as Array).size()


func _get_workers_hired_count() -> int:
	var workers_value: Variant = GameState.get_value("workers", {})
	if typeof(workers_value) == TYPE_DICTIONARY:
		var count := 0
		for worker_value in (workers_value as Dictionary).values():
			if typeof(worker_value) == TYPE_DICTIONARY and int((worker_value as Dictionary).get("level", 0)) > 0:
				count += 1
		return count
	return 0
