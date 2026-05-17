extends Node

const RULES_PATH := "res://data/breeding_rules.json"
const RARITY_ORDER: Dictionary = {"common": 0, "rare": 1, "ultra_rare": 2, "exceptional": 3}

var _rules: Dictionary = {}


func _ready() -> void:
	_load_rules()


func _load_rules() -> void:
	var file := FileAccess.open(RULES_PATH, FileAccess.READ)
	if file == null:
		push_warning("BreedingSystem: breeding_rules.json not found.")
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) == TYPE_DICTIONARY:
		_rules = data as Dictionary
	else:
		push_warning("BreedingSystem: breeding_rules.json malformed.")


# ─── Public query helpers ──────────────────────────────────────────────

func get_fast_duration_seconds() -> int:
	var hours: int = int(_rules.get("durations_hours", {}).get("fast", 24))
	var base: int = hours * 3600
	if has_node("/root/IncubatorUpgradeSystem"):
		var sys: Node = get_node("/root/IncubatorUpgradeSystem")
		if sys.has_method("get_breeding_time_multiplier"):
			var mult: float = float(sys.call("get_breeding_time_multiplier"))
			return max(43200, int(float(base) * mult))
	return base


func get_long_duration_seconds() -> int:
	var hours: int = int(_rules.get("durations_hours", {}).get("long", 48))
	var base: int = hours * 3600
	if has_node("/root/IncubatorUpgradeSystem"):
		var sys: Node = get_node("/root/IncubatorUpgradeSystem")
		if sys.has_method("get_breeding_time_multiplier"):
			var mult: float = float(sys.call("get_breeding_time_multiplier"))
			return max(86400, int(float(base) * mult))
	return base


func get_cooldown_seconds() -> int:
	var hours: int = int(_rules.get("cooldown_hours", 24))
	return hours * 3600


func get_breeding_remaining_seconds(chamber: Dictionary) -> int:
	var ends_at: int = int(chamber.get("ends_at", 0))
	if ends_at <= 0:
		return 0
	return int(max(0, ends_at - Time.get_unix_time_from_system()))


func get_cooldown_remaining_seconds(instance: Dictionary) -> int:
	var until: int = int(instance.get("breeding_cooldown_until", 0))
	if until <= 0:
		return 0
	return int(max(0, until - Time.get_unix_time_from_system()))


func is_instance_available_for_breeding(instance: Dictionary) -> bool:
	if str(instance.get("breeding_state", "none")) == "breeding":
		return false
	if get_cooldown_remaining_seconds(instance) > 0:
		return false
	return true


func get_available_breeding_reptiles() -> Array:
	var result: Array = []
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = (instance_value as Dictionary).duplicate(true)
		var reptile_id: String = str(instance.get("reptile_id", instance.get("species_id", ""))).strip_edges()
		var sex: String = str(instance.get("sex", "")).strip_edges()
		if reptile_id.is_empty() or ReptileSystem.get_reptile(reptile_id).is_empty():
			continue
		if sex != "female" and sex != "male":
			continue
		if not is_instance_available_for_breeding(instance):
			continue
		if str(instance.get("instance_id", "")).is_empty():
			instance["instance_id"] = str(instance_id)
		instance["reptile_id"] = reptile_id
		instance["species_id"] = reptile_id
		instance["sex"] = sex
		result.append(instance)
	return result


func can_pair(instance_a: Dictionary, instance_b: Dictionary) -> Dictionary:
	if str(instance_a.get("reptile_id", "")) != str(instance_b.get("reptile_id", "")):
		return {"ok": false, "error_key": "incubator.error_wrong_species"}
	if str(instance_a.get("sex", "")) == str(instance_b.get("sex", "")):
		return {"ok": false, "error_key": "incubator.error_same_sex"}
	if not is_instance_available_for_breeding(instance_a):
		return {"ok": false, "error_key": "incubator.error_on_cooldown"}
	if not is_instance_available_for_breeding(instance_b):
		return {"ok": false, "error_key": "incubator.error_on_cooldown"}
	return {"ok": true}


func get_drop_rates(rarity_a: String, rarity_b: String, is_long: bool) -> Dictionary:
	var pair_key: String = _canonical_pair_key(rarity_a, rarity_b)
	var all_rates: Dictionary = _rules.get("rarity_pair_drop_rates", {})
	var base: Dictionary = {}
	if typeof(all_rates.get(pair_key, null)) == TYPE_DICTIONARY:
		base = (all_rates.get(pair_key) as Dictionary).duplicate(true)
	else:
		base = {"common": 70, "rare": 25, "ultra_rare": 4, "exceptional": 1}

	if not is_long:
		return base

	return _apply_long_modifier(base, pair_key)


func get_predicted_breeding_odds(instance_a: Dictionary, instance_b: Dictionary, is_long: bool) -> Dictionary:
	var rarity_a: String = str(instance_a.get("rarity", "common"))
	var rarity_b: String = str(instance_b.get("rarity", "common"))
	var rates: Dictionary = get_drop_rates(rarity_a, rarity_b, is_long)
	var failure_risk: int = _get_fail_chance(_avg_condition(instance_a, instance_b))
	return {
		"rates": rates,
		"success_chance": max(0, 100 - failure_risk),
		"failure_risk": failure_risk,
		"egg_count_min": 1,
		"egg_count_max": 5
	}


func roll_egg_rarity(rates: Dictionary) -> String:
	var roll: float = randf() * 100.0
	var cumulative: float = 0.0
	for rarity in ["common", "rare", "ultra_rare", "exceptional"]:
		cumulative += float(rates.get(rarity, 0))
		if roll <= cumulative:
			return rarity
	return "common"


func roll_egg_count() -> int:
	var dist: Dictionary = _rules.get("egg_count_distribution", {"1": 100.0})
	var roll: float = randf() * 100.0
	var cumulative: float = 0.0
	for count_key in ["1", "2", "3", "4", "5"]:
		cumulative += float(dist.get(count_key, 0.0))
		if roll <= cumulative:
			return int(count_key)
	return 1


func roll_success(instance_a: Dictionary, instance_b: Dictionary) -> bool:
	var avg_condition: float = _avg_condition(instance_a, instance_b)
	var fail_chance: int = _get_fail_chance(avg_condition)
	return randf() * 100.0 >= float(fail_chance)


# ─── Start / collect breeding ──────────────────────────────────────────

func start_breeding(
	chamber_index: int,
	instance_id_a: String,
	instance_id_b: String,
	is_long: bool
) -> Dictionary:
	var chambers: Dictionary = _get_chambers()
	var chamber_key: String = str(chamber_index)
	if chambers.has(chamber_key) and str(chambers.get(chamber_key, {}).get("state", "empty")) != "empty":
		return {"success": false, "error_key": "incubator.error_chamber_full"}

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var inst_a_value: Variant = instances.get(instance_id_a, null)
	var inst_b_value: Variant = instances.get(instance_id_b, null)
	if typeof(inst_a_value) != TYPE_DICTIONARY or typeof(inst_b_value) != TYPE_DICTIONARY:
		return {"success": false, "error_key": "ui.reptile_unavailable"}

	var inst_a: Dictionary = inst_a_value as Dictionary
	var inst_b: Dictionary = inst_b_value as Dictionary
	var pair_check: Dictionary = can_pair(inst_a, inst_b)
	if not bool(pair_check.get("ok", false)):
		return {"success": false, "error_key": str(pair_check.get("error_key", ""))}

	var now: int = Time.get_unix_time_from_system()
	var duration: int = get_long_duration_seconds() if is_long else get_fast_duration_seconds()

	var rarity_a: String = str(inst_a.get("rarity", "common"))
	var rarity_b: String = str(inst_b.get("rarity", "common"))
	var rates: Dictionary = get_drop_rates(rarity_a, rarity_b, is_long)
	var will_succeed: bool = roll_success(inst_a, inst_b)
	var egg_count: int = roll_egg_count() if will_succeed else 0

	var eggs_data: Array = []
	for _i in range(egg_count):
		eggs_data.append({
			"egg_id": _create_egg_id(),
			"reptile_id": str(inst_a.get("reptile_id", "")),
			"rarity": roll_egg_rarity(rates),
			"created_at": now
		})

	var chamber: Dictionary = {
		"state": "breeding",
		"instance_id_a": instance_id_a,
		"instance_id_b": instance_id_b,
		"reptile_id": str(inst_a.get("reptile_id", "")),
		"rarity_a": rarity_a,
		"rarity_b": rarity_b,
		"is_long": is_long,
		"started_at": now,
		"ends_at": now + duration,
		"will_succeed": will_succeed,
		"eggs": eggs_data
	}
	chambers[chamber_key] = chamber
	GameState.set_value("breeding_chambers", chambers)

	_set_instance_breeding(instance_id_a, instance_id_b, instances)
	_set_instance_breeding(instance_id_b, instance_id_a, instances)
	GameState.set_value("owned_reptile_instances", instances)
	SaveSystem.save_game()
	_notify_quest_event("incubator_breeding_started", {
		"chamber_index": chamber_index,
		"is_long": is_long
	})

	return {"success": true}


func collect_breeding(chamber_index: int) -> Dictionary:
	var chambers: Dictionary = _get_chambers()
	var chamber_key: String = str(chamber_index)
	if not chambers.has(chamber_key):
		return {"success": false, "error_key": "ui.reptile_unavailable"}

	var chamber_value: Variant = chambers.get(chamber_key)
	if typeof(chamber_value) != TYPE_DICTIONARY:
		return {"success": false, "error_key": "ui.reptile_unavailable"}

	var chamber: Dictionary = chamber_value as Dictionary
	var chamber_state: String = str(chamber.get("state", "empty"))
	if chamber_state != "ready" and chamber_state != "failed":
		return {"success": false, "error_key": "ui.reptile_unavailable"}

	var instance_id_a: String = str(chamber.get("instance_id_a", ""))
	var instance_id_b: String = str(chamber.get("instance_id_b", ""))
	var eggs_data: Array = chamber.get("eggs", []) as Array
	var will_succeed: bool = bool(chamber.get("will_succeed", false))

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var now: int = Time.get_unix_time_from_system()
	var cooldown_until: int = now + get_cooldown_seconds()

	_return_instance_from_breeding(instance_id_a, cooldown_until, instances)
	_return_instance_from_breeding(instance_id_b, cooldown_until, instances)
	GameState.set_value("owned_reptile_instances", instances)

	if will_succeed and eggs_data.size() > 0:
		var storage: Dictionary = _get_storage()
		var stored_eggs: Array = storage.get("eggs", []) as Array
		for egg in eggs_data:
			stored_eggs.append(egg)
		storage["eggs"] = stored_eggs
		GameState.set_value("incubator_storage", storage)

	chambers.erase(chamber_key)
	GameState.set_value("breeding_chambers", chambers)
	SaveSystem.save_game()

	if will_succeed and eggs_data.size() > 0:
		var counters_val: Variant = GameState.get_value("quest_event_counters", {})
		var counters: Dictionary = counters_val as Dictionary if typeof(counters_val) == TYPE_DICTIONARY else {}
		counters["incubator:total_eggs"] = int(counters.get("incubator:total_eggs", 0)) + eggs_data.size()
		counters["incubator:successful_pairings"] = int(counters.get("incubator:successful_pairings", 0)) + 1
		GameState.set_value("quest_event_counters", counters)
		AchievementSystem.notify_progress_changed()
		_notify_quest_event("incubator_egg_obtained", {"amount": eggs_data.size(), "source": "breeding"})
	_notify_quest_event("incubator_breeding_collected", {
		"chamber_index": chamber_index,
		"succeeded": will_succeed,
		"egg_count": eggs_data.size() if will_succeed else 0,
		"is_long": bool(chamber.get("is_long", false))
	})

	return {
		"success": true,
		"egg_count": eggs_data.size() if will_succeed else 0,
		"succeeded": will_succeed
	}


# ─── Tick: update chamber states ──────────────────────────────────────

func tick_chambers() -> void:
	var now: int = Time.get_unix_time_from_system()
	var chambers: Dictionary = _get_chambers()
	var changed: bool = false
	for key in chambers.keys():
		var val: Variant = chambers.get(key)
		if typeof(val) != TYPE_DICTIONARY:
			continue
		var chamber: Dictionary = val as Dictionary
		if str(chamber.get("state", "")) == "breeding" and now >= int(chamber.get("ends_at", 0)):
			chamber["state"] = "ready" if bool(chamber.get("will_succeed", false)) else "failed"
			chambers[key] = chamber
			changed = true
	if changed:
		GameState.set_value("breeding_chambers", chambers)


func get_chambers() -> Dictionary:
	tick_chambers()
	return _get_chambers()


func get_storage() -> Dictionary:
	return _get_storage()


func return_reptile_from_storage(instance_id: String) -> bool:
	var storage: Dictionary = _get_storage()
	var reptiles: Array = storage.get("reptiles", []) as Array
	var found: bool = false
	var new_list: Array = []
	for entry in reptiles:
		if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("instance_id", "")) == instance_id:
			found = true
		else:
			new_list.append(entry)
	if not found:
		push_warning("BreedingSystem.return_reptile_from_storage: id not in storage: " + instance_id)
		return false
	storage["reptiles"] = new_list
	GameState.set_value("incubator_storage", storage)

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	if instances.has(instance_id):
		var inst_value: Variant = instances.get(instance_id)
		if typeof(inst_value) == TYPE_DICTIONARY:
			var inst: Dictionary = inst_value as Dictionary
			var src_rarity: String = str(inst.get("rarity", ""))
			var src_variant: String = str(inst.get("variant_id", ""))
			inst["habitat_id"] = null
			instances[instance_id] = inst
			GameState.set_value("owned_reptile_instances", instances)
			print("[Wróć do puli] id=", instance_id, " src_rarity=", src_rarity, " src_variant=", src_variant, " final_rarity=", inst.get("rarity", ""), " final_variant=", inst.get("variant_id", ""))
			if src_rarity != str(inst.get("rarity", "")):
				push_error("BreedingSystem: rarity changed during pool transfer! " + src_rarity + " → " + str(inst.get("rarity", "")))
			if src_variant != str(inst.get("variant_id", "")):
				push_error("BreedingSystem: variant_id changed during pool transfer! " + src_variant + " → " + str(inst.get("variant_id", "")))

	SaveSystem.save_game()
	return true


# ─── Private helpers ───────────────────────────────────────────────────

func _get_chambers() -> Dictionary:
	var val: Variant = GameState.get_value("breeding_chambers", {})
	if typeof(val) != TYPE_DICTIONARY:
		return {}
	return (val as Dictionary).duplicate(true)


func _get_storage() -> Dictionary:
	var val: Variant = GameState.get_value("incubator_storage", {})
	if typeof(val) != TYPE_DICTIONARY:
		return {"reptiles": [], "eggs": [], "hatchlings": []}
	return (val as Dictionary).duplicate(true)


func _set_instance_breeding(instance_id: String, partner_id: String, instances: Dictionary) -> void:
	var val: Variant = instances.get(instance_id, null)
	if typeof(val) != TYPE_DICTIONARY:
		return
	var inst: Dictionary = val as Dictionary
	inst["breeding_state"] = "breeding"
	inst["breeding_partner_id"] = partner_id
	inst["habitat_id"] = null
	inst["breeding_started_at"] = Time.get_unix_time_from_system()
	instances[instance_id] = inst


func _return_instance_from_breeding(instance_id: String, cooldown_until: int, instances: Dictionary) -> void:
	if not instances.has(instance_id):
		return
	var val: Variant = instances.get(instance_id)
	if typeof(val) != TYPE_DICTIONARY:
		return
	var inst: Dictionary = val as Dictionary
	inst["breeding_state"] = "none"
	inst["breeding_partner_id"] = null
	inst["breeding_started_at"] = 0
	inst["breeding_cooldown_until"] = cooldown_until
	inst["habitat_id"] = null
	instances[instance_id] = inst


func _canonical_pair_key(rarity_a: String, rarity_b: String) -> String:
	var order_a: int = int(RARITY_ORDER.get(rarity_a, 0))
	var order_b: int = int(RARITY_ORDER.get(rarity_b, 0))
	if order_a <= order_b:
		return rarity_a + "+" + rarity_b
	return rarity_b + "+" + rarity_a


func _apply_long_modifier(base: Dictionary, pair_key: String) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	var modifier: Dictionary = _rules.get("long_breeding_modifier", {})
	var ur_bonus: float = float(modifier.get("ultra_rare_bonus_pp", 5))
	var exc_bonus: float = float(modifier.get("exceptional_bonus_pp", 5))
	var caps: Dictionary = modifier.get("exceptional_caps", {})

	var new_ur: float = float(result.get("ultra_rare", 0)) + ur_bonus
	var exc_base: float = float(result.get("exceptional", 0))
	var exc_cap: float = 9999.0
	if typeof(caps.get(pair_key, null)) != TYPE_NIL:
		exc_cap = float(caps.get(pair_key))
	var new_exc: float = min(exc_base + exc_bonus, exc_cap)

	var total_added: float = (new_ur - float(result.get("ultra_rare", 0))) + (new_exc - exc_base)
	result["ultra_rare"] = new_ur
	result["exceptional"] = new_exc

	var subtract_order: Array = modifier.get("subtract_order", ["common", "rare"]) as Array
	var remaining: float = total_added
	for key in subtract_order:
		if remaining <= 0.0:
			break
		var current: float = float(result.get(key, 0))
		var take: float = min(current, remaining)
		result[key] = current - take
		remaining -= take

	return result


func _avg_condition(inst_a: Dictionary, inst_b: Dictionary) -> float:
	var stats_a: float = (
		float(inst_a.get("happiness", 100))
		+ float(inst_a.get("hunger", 100))
		+ float(inst_a.get("hydration", 100))
		+ float(inst_a.get("cleanliness", 100))
	) / 4.0
	var stats_b: float = (
		float(inst_b.get("happiness", 100))
		+ float(inst_b.get("hunger", 100))
		+ float(inst_b.get("hydration", 100))
		+ float(inst_b.get("cleanliness", 100))
	) / 4.0
	return (stats_a + stats_b) / 2.0


func _get_fail_chance(condition: float) -> int:
	var fail_table: Dictionary = _rules.get("failure_chance_by_condition", {})
	var thresholds: Array = []
	for key in fail_table.keys():
		thresholds.append(int(key))
	thresholds.sort()
	thresholds.reverse()
	for threshold in thresholds:
		if condition >= float(threshold):
			return int(fail_table.get(str(threshold), 0))
	return 70


func _create_egg_id() -> String:
	return "egg_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 100000)


func _notify_quest_event(event_type: String, payload: Dictionary = {}) -> void:
	if has_node("/root/QuestSystem"):
		var quest_system: Node = get_node("/root/QuestSystem")
		if quest_system.has_method("notify_event"):
			quest_system.call("notify_event", event_type, payload)
