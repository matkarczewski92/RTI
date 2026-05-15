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
	if bool(state.get("claimable", false)):
		return 0
	if bool(state.get("claimed", false)):
		return 2
	return 1


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

	result.sort_custom(func(a: Variant, b: Variant) -> bool:
		var qa: Dictionary = a as Dictionary
		var qb: Dictionary = b as Dictionary
		if bool(qa.get("claimable", false)) != bool(qb.get("claimable", false)):
			return bool(qa.get("claimable", false))
		return int(qa.get("sort_order", 0)) < int(qb.get("sort_order", 0))
	)
	if limit > 0 and result.size() > limit:
		return result.slice(0, limit)
	return result


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
	if reward_amount > 0.0:
		EconomySystem.add_currency(reward_type, reward_amount)
	if reward_xp > 0.0:
		EconomySystem.add_currency("xp", reward_xp)

	var claimed: Array = GameState.get_value("claimed_quests", []) as Array
	claimed.append(quest_id)
	GameState.set_value("claimed_quests", claimed)
	var completed: Array = GameState.get_value("completed_quests", []) as Array
	if not completed.has(quest_id):
		completed.append(quest_id)
		GameState.set_value("completed_quests", completed)
	SaveSystem.save_game()
	quest_claimed.emit(quest_id)
	return {"success": true, "reward_type": reward_type, "reward_amount": reward_amount, "reward_xp": reward_xp}


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
	var completed: bool = int(progress.get("current", 0)) >= int(progress.get("target", 1))
	var claimed: bool = is_claimed(quest_id)
	var state: Dictionary = quest.duplicate(true)
	state["current"] = int(progress.get("current", 0))
	state["target"] = int(progress.get("target", 1))
	state["completed"] = completed
	state["claimed"] = claimed
	state["claimable"] = completed and not claimed
	return state


func _calculate_progress(quest: Dictionary) -> Dictionary:
	var requirement_type: String = str(quest.get("requirement_type", ""))
	var requirement_target: String = str(quest.get("requirement_target", ""))
	var target: int = max(1, int(quest.get("requirement_value", 1)))
	var current := 0
	match requirement_type:
		"purchased_habitats_count":
			current = _get_purchased_habitats_count()
		"usable_habitats_count":
			current = _get_usable_habitats_count()
		"screen_opened":
			current = _get_counter("screen:" + requirement_target)
		"owned_reptiles_count":
			current = ReptileSystem.get_owned_reptile_count()
		"owned_reptiles_with_sex_count":
			current = _get_owned_reptiles_with_sex_count(requirement_target)
		"assigned_reptiles_count":
			current = _get_assigned_reptiles_count()
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


func _get_counter(counter_id: String) -> int:
	var counters_value: Variant = GameState.get_value("quest_event_counters", {})
	if typeof(counters_value) != TYPE_DICTIONARY:
		return 0
	return int((counters_value as Dictionary).get(counter_id, 0))


func _get_quest(quest_id: String) -> Dictionary:
	for quest_value in quests:
		if typeof(quest_value) == TYPE_DICTIONARY and str((quest_value as Dictionary).get("id", "")) == quest_id:
			return quest_value as Dictionary
	return {}


func _get_purchased_habitats_count() -> int:
	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return count
	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) == TYPE_DICTIONARY and bool((habitat_value as Dictionary).get("purchased", false)):
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
