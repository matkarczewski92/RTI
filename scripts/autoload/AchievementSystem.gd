extends Node

signal achievement_completed(achievement_id: String)
signal achievement_claimed(achievement_id: String)

const ACHIEVEMENTS_PATH := "res://data/collection_achievements.json"
const BIOMES_PATH := "res://data/biomes.json"

var achievements: Array = []


func _ready() -> void:
	load_data()
	call_deferred("migrate_save_state")


func load_data() -> bool:
	var file: FileAccess = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if file == null:
		achievements = []
		push_warning("Missing achievements data file: " + ACHIEVEMENTS_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		achievements = []
		push_warning("Invalid achievements data file: " + ACHIEVEMENTS_PATH)
		return false

	achievements = parsed as Array
	achievements.sort_custom(func(a: Variant, b: Variant) -> bool:
		if typeof(a) != TYPE_DICTIONARY or typeof(b) != TYPE_DICTIONARY:
			return false
		return int((a as Dictionary).get("sort_order", 0)) < int((b as Dictionary).get("sort_order", 0))
	)
	return true


func migrate_save_state() -> bool:
	var changed := false
	var claimed_value: Variant = GameState.get_value("claimed_achievements", null)
	if typeof(claimed_value) != TYPE_ARRAY:
		GameState.set_value("claimed_achievements", [])
		changed = true
	var completed_value: Variant = GameState.get_value("completed_achievements", null)
	if typeof(completed_value) != TYPE_ARRAY:
		GameState.set_value("completed_achievements", [])
		changed = true

	if changed:
		SaveSystem.save_game()

	return changed


func get_achievement_states() -> Array:
	migrate_save_state()
	var result: Array = []
	for achievement_value in achievements:
		if typeof(achievement_value) != TYPE_DICTIONARY:
			continue

		var achievement: Dictionary = achievement_value as Dictionary
		var progress: Dictionary = get_achievement_progress(achievement)
		var achievement_id: String = str(achievement.get("id", ""))
		var completed: bool = int(progress.get("current", 0)) >= int(progress.get("target", 1))
		var claimed: bool = is_claimed(achievement_id)
		var state: Dictionary = achievement.duplicate(true)
		state["current"] = int(progress.get("current", 0))
		state["target"] = int(progress.get("target", 1))
		state["completed"] = completed
		state["claimed"] = claimed
		state["claimable"] = completed and not claimed
		result.append(state)

	result.sort_custom(_sort_achievement_states)
	return result


func _sort_achievement_states(a: Variant, b: Variant) -> bool:
	if typeof(a) != TYPE_DICTIONARY or typeof(b) != TYPE_DICTIONARY:
		return false

	var achievement_a: Dictionary = a as Dictionary
	var achievement_b: Dictionary = b as Dictionary
	var group_a: int = _get_sort_group(achievement_a)
	var group_b: int = _get_sort_group(achievement_b)
	if group_a != group_b:
		return group_a < group_b

	return int(achievement_a.get("sort_order", 0)) < int(achievement_b.get("sort_order", 0))


func _get_sort_group(state: Dictionary) -> int:
	if bool(state.get("claimable", false)):
		return 0
	if bool(state.get("claimed", false)):
		return 2
	return 1


func get_achievement_progress(achievement: Dictionary) -> Dictionary:
	var requirement_type: String = str(achievement.get("requirement_type", ""))
	var requirement_target: String = str(achievement.get("requirement_target", ""))
	var requirement_value: int = max(1, int(achievement.get("requirement_value", 1)))
	var current := 0
	var target := requirement_value

	match requirement_type:
		"owned_count":
			current = ReptileSystem.get_owned_reptile_count()
		"assigned_count":
			current = _get_assigned_reptile_count()
		"discovered_count":
			current = _get_discovered_variant_count()
		"discovered_rarity_count":
			current = _get_discovered_rarity_count(requirement_target)
		"owned_sex_count":
			current = _get_owned_sex_count(requirement_target)
		"reptile_collection":
			var collection_progress: Dictionary = _get_reptile_collection_progress(requirement_target)
			current = int(collection_progress.get("current", 0))
			target = max(1, int(collection_progress.get("target", requirement_value)))
		"biome_discovered_count":
			current = _get_biome_discovered_variant_count(requirement_target)
		"biome_discovered_species_count":
			current = _get_biome_discovered_species_count(requirement_target)
		"discovered_reptile_species":
			current = 1 if _is_reptile_species_discovered(requirement_target) else 0
			target = 1
		"discovered_reptile_species_set":
			current = _get_required_reptile_species_discovered_count(achievement)
		"purchased_habitats_count":
			current = _get_purchased_habitats_count()
		"occupied_habitats_count":
			current = _get_occupied_habitats_count()
		"biome_habitats_filled_and_maxed":
			var biome_habitat_progress: Dictionary = _get_biome_filled_and_maxed_habitat_progress(requirement_target)
			current = int(biome_habitat_progress.get("current", 0))
			target = max(1, int(biome_habitat_progress.get("target", requirement_value)))
		"habitats_at_level_count":
			current = _get_habitats_at_level_count(max(1, int(requirement_target)))
		"lifetime_currency_earned":
			current = int(floor(float(GameState.get_value("lifetime_repticash_earned", 0.0))))
		"player_level_at_least":
			current = int(GameState.get_value("level", GameState.get_value("player_level", 1)))
		"care_action_count":
			current = _get_counter("care:" + requirement_target)
		"event_counter_at_least":
			current = _get_counter("incubator:" + requirement_target)
		"total_care_actions_count":
			current = _get_total_care_actions_count()
		"income_per_min_at_least":
			current = int(floor(EconomySystem.get_total_assigned_income_per_min()))
		"biome_unlocked":
			current = 1 if _is_biome_unlocked(requirement_target) else 0
			target = 1
		_:
			push_warning("Unknown achievement requirement type: " + requirement_type)
			current = 0

	return {
		"current": min(current, target),
		"target": target
	}


func is_claimed(achievement_id: String) -> bool:
	var claimed_value: Variant = GameState.get_value("claimed_achievements", [])
	if typeof(claimed_value) != TYPE_ARRAY:
		return false

	return (claimed_value as Array).has(achievement_id)


func claim_achievement(achievement_id: String) -> Dictionary:
	migrate_save_state()
	if is_claimed(achievement_id):
		return {"success": false, "message_key": "achievements.claimed"}

	var achievement: Dictionary = _get_achievement(achievement_id)
	if achievement.is_empty():
		return {"success": false, "message_key": "achievements.in_progress"}

	var progress: Dictionary = get_achievement_progress(achievement)
	if int(progress.get("current", 0)) < int(progress.get("target", 1)):
		return {"success": false, "message_key": "achievements.in_progress"}

	var reward_type: String = str(achievement.get("reward_type", "repticash"))
	var reward_amount: float = float(achievement.get("reward_amount", 0.0))
	var reward_xp: float = float(achievement.get("reward_xp", 0.0))
	if reward_amount > 0.0:
		EconomySystem.add_currency(reward_type, reward_amount)
	if reward_xp > 0.0:
		EconomySystem.add_currency("xp", reward_xp)

	var claimed: Array = GameState.get_value("claimed_achievements", []) as Array
	claimed.append(achievement_id)
	GameState.set_value("claimed_achievements", claimed)
	var completed: Array = GameState.get_value("completed_achievements", []) as Array
	if not completed.has(achievement_id):
		completed.append(achievement_id)
		GameState.set_value("completed_achievements", completed)
	SaveSystem.save_game()
	achievement_claimed.emit(achievement_id)
	_notify_quest_hook("on_achievement_claimed", achievement_id)
	return {
		"success": true,
		"reward_type": reward_type,
		"reward_amount": reward_amount,
		"reward_xp": reward_xp
	}


func notify_progress_changed() -> void:
	migrate_save_state()
	var completed_value: Variant = GameState.get_value("completed_achievements", [])
	var completed_ids: Array = completed_value as Array
	var changed := false
	for state_value in get_achievement_states():
		if typeof(state_value) != TYPE_DICTIONARY:
			continue

		var state: Dictionary = state_value as Dictionary
		if bool(state.get("completed", false)) and not bool(state.get("claimed", false)):
			var achievement_id: String = str(state.get("id", ""))
			if completed_ids.has(achievement_id):
				continue

			completed_ids.append(achievement_id)
			changed = true
			achievement_completed.emit(achievement_id)
			_notify_quest_hook("on_achievement_completed", achievement_id)

	if changed:
		GameState.set_value("completed_achievements", completed_ids)
		SaveSystem.save_game()


func _get_achievement(achievement_id: String) -> Dictionary:
	for achievement_value in achievements:
		if typeof(achievement_value) != TYPE_DICTIONARY:
			continue

		var achievement: Dictionary = achievement_value as Dictionary
		if str(achievement.get("id", "")) == achievement_id:
			return achievement

	return {}


func _get_assigned_reptile_count() -> int:
	var count := 0
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	for instance_value in instances.values():
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		if not str((instance_value as Dictionary).get("habitat_id", "")).is_empty():
			count += 1

	return count


func _get_owned_sex_count(sex: String) -> int:
	var count := 0
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	for instance_value in instances.values():
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		if str((instance_value as Dictionary).get("sex", "male")) == sex:
			count += 1

	return count


func _get_discovered_variant_count() -> int:
	return _get_discovered_variant_ids().size()


func _get_discovered_rarity_count(rarity: String) -> int:
	var count := 0
	for variant_id in _get_discovered_variant_ids():
		var variant: Dictionary = ReptileSystem.get_variant(str(variant_id))
		if ReptileSystem.normalize_rarity(str(variant.get("rarity", "common"))) == rarity:
			count += 1

	return count


func _get_reptile_collection_progress(reptile_id: String) -> Dictionary:
	var total := 0
	var discovered := 0
	for variant_value in ReptileSystem.get_all_variants():
		if typeof(variant_value) != TYPE_DICTIONARY:
			continue

		var variant: Dictionary = variant_value as Dictionary
		if str(variant.get("reptile_id", "")) != reptile_id:
			continue

		total += 1
		if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))):
			discovered += 1

	return {"current": discovered, "target": max(1, total)}


func _get_biome_discovered_variant_count(biome_id: String) -> int:
	var count := 0
	for variant_id in _get_discovered_variant_ids():
		var variant: Dictionary = ReptileSystem.get_variant(str(variant_id))
		var reptile: Dictionary = ReptileSystem.get_reptile(str(variant.get("reptile_id", "")))
		if str(reptile.get("biome_id", "")) == biome_id:
			count += 1

	return count


func _get_biome_discovered_species_count(biome_id: String) -> int:
	var species_ids: Dictionary = {}
	for variant_id in _get_discovered_variant_ids():
		var variant: Dictionary = ReptileSystem.get_variant(str(variant_id))
		var reptile_id: String = str(variant.get("reptile_id", ""))
		var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
		if str(reptile.get("biome_id", "")) == biome_id:
			species_ids[reptile_id] = true

	for instance_value in ReptileSystem.get_owned_reptile_instances().values():
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue
		var instance_reptile_id: String = str((instance_value as Dictionary).get("reptile_id", ""))
		var instance_reptile: Dictionary = ReptileSystem.get_reptile(instance_reptile_id)
		if str(instance_reptile.get("biome_id", "")) == biome_id:
			species_ids[instance_reptile_id] = true

	return species_ids.size()


func _get_required_reptile_species_discovered_count(achievement: Dictionary) -> int:
	var required_value: Variant = achievement.get("required_reptile_ids", [])
	if typeof(required_value) != TYPE_ARRAY:
		return 0

	var count := 0
	for reptile_id_value in (required_value as Array):
		if _is_reptile_species_discovered(str(reptile_id_value)):
			count += 1
	return count


func _is_reptile_species_discovered(reptile_id: String) -> bool:
	if reptile_id.is_empty():
		return false

	for variant_id in _get_discovered_variant_ids():
		var variant: Dictionary = ReptileSystem.get_variant(str(variant_id))
		if str(variant.get("reptile_id", "")) == reptile_id:
			return true

	for instance_value in ReptileSystem.get_owned_reptile_instances().values():
		if typeof(instance_value) == TYPE_DICTIONARY and str((instance_value as Dictionary).get("reptile_id", "")) == reptile_id:
			return true

	return false


func _get_purchased_habitats_count() -> int:
	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return count
	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) == TYPE_DICTIONARY and bool((habitat_value as Dictionary).get("purchased", false)):
			count += 1
	return count


func _get_occupied_habitats_count() -> int:
	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return count
	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		if not bool(habitat.get("purchased", false)):
			continue
		var reptile_id: String = str(habitat.get("reptile_instance_id", habitat.get("animal_instance_id", "")))
		if reptile_id.is_empty():
			reptile_id = str(habitat.get("reptile_id", ""))
		if not reptile_id.is_empty():
			count += 1
	return count


func _get_biome_filled_and_maxed_habitat_progress(biome_id: String) -> Dictionary:
	var target := _get_biome_habitat_slot_count(biome_id)
	var max_level := 1
	if ReptileSystem.has_method("get_habitat_max_level"):
		max_level = max(1, int(ReptileSystem.call("get_habitat_max_level")))

	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return {"current": 0, "target": max(1, target)}

	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = habitat_value as Dictionary
		if str(habitat.get("biome_id", "")) != biome_id:
			continue
		if not bool(habitat.get("purchased", false)):
			continue
		if bool(habitat.get("is_building", false)) or bool(habitat.get("is_upgrading", false)):
			continue
		if int(habitat.get("habitat_level", 1)) < max_level:
			continue
		if _habitat_assigned_reptile_id(habitat).is_empty():
			continue
		count += 1

	return {"current": count, "target": max(1, target)}


func _get_biome_habitat_slot_count(biome_id: String) -> int:
	var file: FileAccess = FileAccess.open(BIOMES_PATH, FileAccess.READ)
	if file == null:
		return 1
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		return 1

	for biome_value in (parsed as Array):
		if typeof(biome_value) != TYPE_DICTIONARY:
			continue
		var biome: Dictionary = biome_value as Dictionary
		if str(biome.get("id", "")) == biome_id:
			return max(1, int(biome.get("habitat_slots", 1)))
	return 1


func _habitat_assigned_reptile_id(habitat: Dictionary) -> String:
	var instance_id: String = str(habitat.get("reptile_instance_id", ""))
	if instance_id.is_empty() or instance_id == "<null>" or instance_id.to_lower() == "null":
		instance_id = str(habitat.get("animal_instance_id", ""))
	if not instance_id.is_empty() and instance_id != "<null>" and instance_id.to_lower() != "null":
		return instance_id
	var reptile_id: String = str(habitat.get("reptile_id", ""))
	if reptile_id == "<null>" or reptile_id.to_lower() == "null":
		return ""
	return reptile_id


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


func _get_counter(counter_id: String) -> int:
	var counters_value: Variant = GameState.get_value("quest_event_counters", {})
	if typeof(counters_value) != TYPE_DICTIONARY:
		return 0
	return int((counters_value as Dictionary).get(counter_id, 0))


func _get_total_care_actions_count() -> int:
	return _get_counter("care:feed") + _get_counter("care:water") + _get_counter("care:clean") + _get_counter("care:play")


func _is_biome_unlocked(biome_id: String) -> bool:
	var unlocked_value: Variant = GameState.get_value("unlocked_biomes", [])
	if typeof(unlocked_value) != TYPE_ARRAY:
		return false
	return (unlocked_value as Array).has(biome_id)


func _get_discovered_variant_ids() -> Array:
	var result: Array = []
	var discovered_value: Variant = GameState.get_value("discovered_variants", {})
	if typeof(discovered_value) != TYPE_DICTIONARY:
		return result

	var discovered: Dictionary = discovered_value as Dictionary
	for variant_id in discovered.keys():
		if bool(discovered.get(variant_id, false)):
			result.append(str(variant_id))

	return result


func _notify_quest_hook(method_name: String, achievement_id: String) -> void:
	if not has_node("/root/QuestSystem"):
		return

	var quest_system: Node = get_node("/root/QuestSystem")
	if quest_system.has_method(method_name):
		quest_system.call(method_name, achievement_id)
