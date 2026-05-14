extends Node

const REPTILES_PATH: String = "res://data/reptiles.json"
const VARIANTS_PATH: String = "res://data/reptile_variants.json"
const VALID_RARITIES: Array[String] = ["common", "rare", "exceptional", "ultra_rare"]
const NEED_DECAY_INTERVAL_SECONDS := 600.0
const NEED_DECAY_AMOUNT := 1.0
const FEED_COOLDOWN_SECONDS := 60
const WATER_COOLDOWN_SECONDS := 60
const CLEAN_COOLDOWN_SECONDS := 180
const PLAY_COOLDOWN_SECONDS := 5
const FEED_SATIETY_GAIN := 25.0
const WATER_HYDRATION_GAIN := 25.0
const CLEANLINESS_GAIN := 35.0
const PLAY_HAPPINESS_GAIN := 10.0
const CARE_SMALL_HAPPINESS_GAIN := 3.0
const CLEAN_HAPPINESS_GAIN := 5.0
const PLAY_REPTICASH_REWARD := 5
const FEED_XP_REWARD := 2
const WATER_XP_REWARD := 2
const CLEAN_XP_REWARD := 3
const PLAY_XP_REWARD := 0.1

const RARITY_ICON_PATHS: Dictionary = {
	"common": "res://assets/art/ui/icons/icon_rarity_common.png",
	"rare": "res://assets/art/ui/icons/icon_rarity_rare.png",
	"exceptional": "res://assets/art/ui/icons/icon_rarity_exceptional.png",
	"ultra_rare": "res://assets/art/ui/icons/icon_rarity_ultra_rare.png"
}

var reptiles: Array = []
var variants: Array = []


func _ready() -> void:
	load_data()
	call_deferred("_initialize_runtime_state")


func _initialize_runtime_state() -> void:
	migrate_save_state()
	apply_time_updates(true)


func load_data() -> void:
	reptiles = _load_array(REPTILES_PATH)
	variants = _load_array(VARIANTS_PATH)


func get_available_reptiles(biome_id: String) -> Array:
	var result: Array = []
	for reptile_value in reptiles:
		if typeof(reptile_value) != TYPE_DICTIONARY:
			continue

		var reptile: Dictionary = reptile_value as Dictionary
		if str(reptile.get("biome_id", "")) == biome_id:
			result.append(reptile)

	return result


func get_all_variants() -> Array:
	var result: Array = []
	for variant_value in variants:
		if typeof(variant_value) != TYPE_DICTIONARY:
			continue

		result.append(_normalize_variant(variant_value as Dictionary))

	return result


func get_owned_reptile_count() -> int:
	var instances: Dictionary = get_owned_reptile_instances()
	return instances.size()


func is_first_reptile_free() -> bool:
	return get_owned_reptile_count() == 0


func get_reptile_purchase_price(reptile_id: String) -> int:
	if is_first_reptile_free():
		return 0

	var reptile: Dictionary = get_reptile(reptile_id)
	return int(reptile.get("base_cost", 0))


func get_shop_variant_for_rarity(reptile_id: String, rarity: String) -> Dictionary:
	return get_variant_for_reptile_rarity(reptile_id, rarity)


func get_variant_for_reptile_rarity(reptile_id: String, rarity: String) -> Dictionary:
	var normalized_rarity: String = normalize_rarity(rarity)
	if normalized_rarity == "common":
		return get_variant_for_reptile(reptile_id, get_default_variant_id(reptile_id))

	for variant_value in variants:
		if typeof(variant_value) != TYPE_DICTIONARY:
			continue

		var variant: Dictionary = variant_value as Dictionary
		if str(variant.get("reptile_id", "")) == reptile_id and normalize_rarity(str(variant.get("rarity", "common"))) == normalized_rarity:
			return _normalize_variant(variant)

	return {}


func get_shop_purchase_price(reptile_id: String, rarity: String) -> int:
	if is_first_reptile_free():
		return 0

	var reptile: Dictionary = get_reptile(reptile_id)
	if reptile.is_empty():
		return -1

	var normalized_rarity: String = normalize_rarity(rarity)
	var base_cost: int = int(reptile.get("base_cost", 0))
	if normalized_rarity == "rare":
		return base_cost * 10
	if normalized_rarity != "common":
		return -1

	return base_cost


func get_reptile(reptile_id: String) -> Dictionary:
	for reptile_value in reptiles:
		if typeof(reptile_value) != TYPE_DICTIONARY:
			continue

		var reptile: Dictionary = reptile_value as Dictionary
		if str(reptile.get("id", "")) == reptile_id:
			return reptile

	return {}


func get_default_variant_id(reptile_id: String) -> String:
	var reptile: Dictionary = get_reptile(reptile_id)
	var default_variant_id: String = str(reptile.get("default_variant_id", ""))
	if not default_variant_id.is_empty():
		return default_variant_id

	for variant_value in variants:
		if typeof(variant_value) != TYPE_DICTIONARY:
			continue

		var variant: Dictionary = variant_value as Dictionary
		if str(variant.get("reptile_id", "")) == reptile_id:
			return str(variant.get("id", ""))

	return reptile_id + "_common"


func get_variant(variant_id: String) -> Dictionary:
	for variant_value in variants:
		if typeof(variant_value) != TYPE_DICTIONARY:
			continue

		var variant: Dictionary = variant_value as Dictionary
		if str(variant.get("id", "")) == variant_id:
			return _normalize_variant(variant)

	return _make_fallback_variant(variant_id)


func get_variant_for_reptile(reptile_id: String, variant_id: String = "") -> Dictionary:
	var resolved_variant_id: String = variant_id
	if resolved_variant_id.is_empty():
		resolved_variant_id = get_default_variant_id(reptile_id)

	var variant: Dictionary = get_variant(resolved_variant_id)
	if str(variant.get("reptile_id", "")) == reptile_id:
		return variant

	return get_variant(get_default_variant_id(reptile_id))


func get_owned_animal_variant(instance: Dictionary) -> Dictionary:
	var reptile_id: String = str(instance.get("reptile_id", ""))
	var variant_id: String = str(instance.get("variant_id", ""))
	return get_variant_for_reptile(reptile_id, variant_id)


func get_owned_animal_image_path(instance: Dictionary) -> String:
	var reptile_id: String = str(instance.get("reptile_id", ""))
	var reptile: Dictionary = get_reptile(reptile_id)
	var variant: Dictionary = get_owned_animal_variant(instance)
	return _first_existing_path([
		str(variant.get("portrait_path", "")),
		str(variant.get("icon_path", "")),
		str(reptile.get("portrait_path", "")),
		str(reptile.get("icon_path", ""))
	])


func get_rarity_label_key(rarity: String) -> String:
	return "rarity." + normalize_rarity(rarity)


func get_rarity_icon_path(rarity: String) -> String:
	return str(RARITY_ICON_PATHS.get(normalize_rarity(rarity), RARITY_ICON_PATHS["common"]))


func normalize_rarity(rarity: String) -> String:
	if VALID_RARITIES.has(rarity):
		return rarity

	return "common"


func get_base_reptile_income(reptile_id: String) -> float:
	var reptile: Dictionary = get_reptile(reptile_id)
	if reptile.is_empty():
		return 0.0

	return float(reptile.get("base_income_per_minute", 0.0))


func get_happiness_multiplier(happiness: Variant) -> float:
	var value: float = clamp(float(happiness), 0.0, 100.0)
	if value <= 25.0:
		return 0.25
	if value <= 50.0:
		return 0.50
	if value <= 80.0:
		return 1.00

	return 1.25


func get_rarity_income_multiplier(rarity: String) -> float:
	match normalize_rarity(rarity):
		"rare":
			return 1.10
		"exceptional":
			return 1.25
		"ultra_rare":
			return 1.50
		_:
			return 1.00


func get_variant_income_multiplier(variant: Dictionary) -> float:
	if variant.is_empty():
		return 1.0

	return get_rarity_income_multiplier(str(variant.get("rarity", "common")))


func get_effective_animal_income_per_min(instance: Dictionary) -> float:
	var normalized: Dictionary = _normalize_owned_instance(instance)
	if not _is_assigned_to_valid_habitat(normalized):
		return 0.0

	var base_income: float = get_base_reptile_income(str(normalized.get("reptile_id", "")))
	var happiness_multiplier: float = get_happiness_multiplier(normalized.get("happiness", 100))
	var variant_multiplier: float = get_variant_income_multiplier(get_owned_animal_variant(normalized))
	return base_income * happiness_multiplier * variant_multiplier * get_worker_income_multiplier(normalized) * get_upgrade_income_multiplier(normalized)


func get_worker_income_multiplier(_instance: Dictionary) -> float:
	return 1.0


func get_upgrade_income_multiplier(_instance: Dictionary) -> float:
	return 1.0


func get_total_assigned_income_per_min() -> float:
	var total: float = 0.0
	for contributor in get_animal_income_contributors():
		if typeof(contributor) != TYPE_DICTIONARY:
			continue

		total += float((contributor as Dictionary).get("income_per_min", 0.0))

	return total


func get_animal_income_contributors() -> Array:
	var result: Array = []
	var seen_instances: Dictionary = {}
	var seen_habitats: Dictionary = {}
	var instances: Dictionary = get_owned_reptile_instances()
	for instance_id in instances.keys():
		if seen_instances.has(instance_id):
			continue

		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
		var habitat_id: String = str(instance.get("habitat_id", ""))
		if seen_habitats.has(habitat_id):
			continue

		if not _is_assigned_to_valid_habitat(instance):
			continue

		var income: float = get_effective_animal_income_per_min(instance)
		if income <= 0.0:
			continue

		seen_instances[instance_id] = true
		seen_habitats[habitat_id] = true
		result.append({
			"instance_id": instance_id,
			"habitat_id": habitat_id,
			"income_per_min": income
		})

	return result


func apply_time_updates(save_if_changed: bool = false) -> bool:
	var now: int = Time.get_unix_time_from_system()
	var changed: bool = _update_global_resources(now)
	if _update_owned_reptile_needs(now):
		changed = true

	if changed and save_if_changed:
		SaveSystem.save_game()

	return changed


func get_resource_current(resource_id: String) -> int:
	_update_global_resources(Time.get_unix_time_from_system())
	if resource_id == "water":
		return int(GameState.get_value("water_current", 0))

	return int(GameState.get_value("food_current", 0))


func get_resource_max(resource_id: String) -> int:
	if resource_id == "water":
		return int(GameState.get_value("water_max", 100))

	return int(GameState.get_value("food_max", 100))


func perform_care_action(instance_id: String, action_id: String) -> Dictionary:
	apply_time_updates(false)
	var instances: Dictionary = get_owned_reptile_instances()
	if not instances.has(instance_id):
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var instance_value: Variant = instances.get(instance_id)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
	if str(instance.get("habitat_id", "")).is_empty():
		return {"success": false, "message_key": "ui.place_reptile_to_care"}

	var now: int = Time.get_unix_time_from_system()
	var remaining: int = get_care_cooldown_remaining(instance, action_id, now)
	if remaining > 0:
		return {"success": false, "message_key": "ui.on_cooldown", "cooldown_remaining": remaining}

	var message_key: String = ""
	var xp_reward: float = 0.0
	match action_id:
		"feed":
			if int(GameState.get_value("food_current", 0)) <= 0:
				return {"success": false, "message_key": "ui.no_food"}
			_set_global_resource("food", int(GameState.get_value("food_current", 0)) - 1)
			instance["hunger"] = _clamp_percent(float(instance.get("hunger", 100)) + FEED_SATIETY_GAIN)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CARE_SMALL_HAPPINESS_GAIN)
			instance["last_feed_timestamp"] = now
			instance["last_fed_at"] = now
			xp_reward = FEED_XP_REWARD
			message_key = "ui.feed_success_xp"
		"water":
			if int(GameState.get_value("water_current", 0)) <= 0:
				return {"success": false, "message_key": "ui.no_water"}
			_set_global_resource("water", int(GameState.get_value("water_current", 0)) - 1)
			instance["hydration"] = _clamp_percent(float(instance.get("hydration", 100)) + WATER_HYDRATION_GAIN)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CARE_SMALL_HAPPINESS_GAIN)
			instance["last_water_timestamp"] = now
			instance["last_water_at"] = now
			xp_reward = WATER_XP_REWARD
			message_key = "ui.water_success_xp"
		"clean":
			instance["cleanliness"] = _clamp_percent(float(instance.get("cleanliness", 100)) + CLEANLINESS_GAIN)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CLEAN_HAPPINESS_GAIN)
			instance["last_clean_timestamp"] = now
			instance["last_cleaned_at"] = now
			xp_reward = CLEAN_XP_REWARD
			message_key = "ui.clean_success_xp"
		"play":
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + PLAY_HAPPINESS_GAIN)
			instance["last_play_timestamp"] = now
			EconomySystem.add_currency("repticash", PLAY_REPTICASH_REWARD)
			xp_reward = PLAY_XP_REWARD
			message_key = "ui.play_success_reward"
		_:
			return {"success": false, "message_key": "ui.reptile_unavailable"}

	instance["last_needs_update_timestamp"] = now
	instances[instance_id] = instance
	GameState.set_value("owned_reptile_instances", instances)
	if xp_reward > 0:
		EconomySystem.add_currency("xp", xp_reward)
	SaveSystem.save_game()
	return {
		"success": true,
		"message_key": message_key,
		"instance_id": instance_id,
		"xp": xp_reward,
		"money": PLAY_REPTICASH_REWARD if action_id == "play" else 0
	}


func get_care_cooldown_remaining(instance: Dictionary, action_id: String, now: int = 0) -> int:
	if now <= 0:
		now = Time.get_unix_time_from_system()

	var last_timestamp: int = 0
	var cooldown: int = 0
	match action_id:
		"feed":
			last_timestamp = _timestamp_from_value(instance.get("last_feed_timestamp", instance.get("last_fed_at", 0)))
			cooldown = FEED_COOLDOWN_SECONDS
		"water":
			last_timestamp = _timestamp_from_value(instance.get("last_water_timestamp", instance.get("last_water_at", 0)))
			cooldown = WATER_COOLDOWN_SECONDS
		"clean":
			last_timestamp = _timestamp_from_value(instance.get("last_clean_timestamp", instance.get("last_cleaned_at", 0)))
			cooldown = CLEAN_COOLDOWN_SECONDS
		"play":
			last_timestamp = _timestamp_from_value(instance.get("last_play_timestamp", 0))
			cooldown = PLAY_COOLDOWN_SECONDS
		_:
			return 0

	if last_timestamp <= 0:
		return 0

	return int(max(0, cooldown - (now - last_timestamp)))


func reptile_needs_attention(instance: Dictionary) -> bool:
	var normalized: Dictionary = _normalize_owned_instance(instance)
	return (
		float(normalized.get("happiness", 100)) < 50.0
		or float(normalized.get("hunger", 100)) < 50.0
		or float(normalized.get("hydration", 100)) < 50.0
		or float(normalized.get("cleanliness", 100)) < 50.0
	)


func is_variant_discovered(variant_id: String) -> bool:
	var discovered_value: Variant = GameState.get_value("discovered_variants", {})
	if typeof(discovered_value) != TYPE_DICTIONARY:
		return false

	var discovered: Dictionary = discovered_value as Dictionary
	return bool(discovered.get(variant_id, false))


func purchase_and_assign_reptile(reptile_id: String, habitat_id: String, biome_id: String, sex: String = "male") -> Dictionary:
	var reptile: Dictionary = get_reptile(reptile_id)
	if reptile.is_empty():
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var price: int = get_reptile_purchase_price(reptile_id)
	if price > 0 and not EconomySystem.can_afford("repticash", price):
		return {"success": false, "message_key": "ui.not_enough_currency"}

	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	var habitat: Dictionary = habitat_value as Dictionary
	if not bool(habitat.get("purchased", false)):
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	if (
		not str(habitat.get("reptile_instance_id", "")).is_empty()
		or not str(habitat.get("animal_instance_id", "")).is_empty()
		or not str(habitat.get("reptile_id", "")).is_empty()
	):
		return {"success": false, "message_key": "ui.habitat_occupied"}

	if price > 0 and not EconomySystem.spend_currency("repticash", price):
		return {"success": false, "message_key": "ui.not_enough_currency"}

	var normalized_sex: String = _normalize_sex(sex)
	var variant_id: String = get_default_variant_id(reptile_id)
	var instance_id: String = _create_instance_id()
	var now: int = Time.get_unix_time_from_system()
	var instance: Dictionary = {
		"instance_id": instance_id,
		"reptile_id": reptile_id,
		"variant_id": variant_id,
		"sex": normalized_sex,
		"custom_name": "",
		"habitat_id": habitat_id,
		"created_at": now,
		"happiness": 100,
		"hydration": 100,
		"hunger": 100,
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
		"paired_with_instance_id": "",
		"pregnancy_started_at": null,
		"egg_lay_ready_at": null,
		"eggs": [],
		"incubator_entry_id": ""
	}

	var instances: Dictionary = get_owned_reptile_instances()
	instances[instance_id] = instance
	GameState.set_value("owned_reptile_instances", instances)

	habitat["reptile_id"] = reptile_id
	habitat["reptile_instance_id"] = instance_id
	habitat["animal_instance_id"] = instance_id
	habitat["variant_id"] = variant_id
	habitat["habitat_variant_id"] = str(habitat.get("habitat_variant_id", "default"))
	habitat["habitat_skin_id"] = str(habitat.get("habitat_skin_id", "default"))
	habitats[habitat_id] = habitat
	GameState.set_value("habitats", habitats)

	var new_variant_discovered: bool = mark_variant_discovered(variant_id)
	SaveSystem.save_game()

	return {
		"success": true,
		"message_key": "ui.reptile_added",
		"instance_id": instance_id,
		"variant_id": variant_id,
		"new_variant_discovered": new_variant_discovered,
		"price": price
	}


func purchase_reptile_from_shop(reptile_id: String, rarity: String, sex: String = "male") -> Dictionary:
	var reptile: Dictionary = get_reptile(reptile_id)
	if reptile.is_empty():
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var variant: Dictionary = get_shop_variant_for_rarity(reptile_id, rarity)
	if variant.is_empty():
		return {"success": false, "message_key": "shop.unavailable"}

	var price: int = get_shop_purchase_price(reptile_id, rarity)
	if price < 0:
		return {"success": false, "message_key": "shop.unavailable"}

	if price > 0 and not EconomySystem.can_afford("repticash", price):
		return {"success": false, "message_key": "ui.not_enough_currency"}

	if price > 0 and not EconomySystem.spend_currency("repticash", price):
		return {"success": false, "message_key": "ui.not_enough_currency"}

	var variant_id: String = str(variant.get("id", get_default_variant_id(reptile_id)))
	var instance_id: String = _create_instance_id()
	var now: int = Time.get_unix_time_from_system()
	var instance: Dictionary = {
		"instance_id": instance_id,
		"reptile_id": reptile_id,
		"variant_id": variant_id,
		"sex": _normalize_sex(sex),
		"custom_name": "",
		"habitat_id": null,
		"source": "shop",
		"created_at": now,
		"happiness": 100,
		"hydration": 100,
		"hunger": 100,
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
		"paired_with_instance_id": "",
		"pregnancy_started_at": null,
		"egg_lay_ready_at": null,
		"eggs": [],
		"incubator_entry_id": ""
	}

	var instances: Dictionary = get_owned_reptile_instances()
	instances[instance_id] = instance
	GameState.set_value("owned_reptile_instances", instances)

	var new_variant_discovered: bool = mark_variant_discovered(variant_id)
	SaveSystem.save_game()

	return {
		"success": true,
		"message_key": "ui.reptile_added",
		"instance_id": instance_id,
		"variant_id": variant_id,
		"new_variant_discovered": new_variant_discovered,
		"price": price
	}


func get_owned_unassigned_reptiles() -> Array:
	var result: Array = []
	var instances: Dictionary = get_owned_reptile_instances()
	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
		var habitat_value: Variant = instance.get("habitat_id", null)
		if habitat_value == null or str(habitat_value).is_empty():
			result.append(instance)

	return result


func assign_reptile_to_habitat(instance_id: String, habitat_id: String, biome_id: String) -> Dictionary:
	var instances: Dictionary = get_owned_reptile_instances()
	if not instances.has(instance_id):
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var instance_value: Variant = instances.get(instance_id)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
	var current_habitat: Variant = instance.get("habitat_id", null)
	if current_habitat != null and not str(current_habitat).is_empty():
		return {"success": false, "message_key": "ui.habitat_occupied"}

	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	var habitat: Dictionary = habitat_value as Dictionary
	if str(habitat.get("biome_id", biome_id)) != biome_id or not bool(habitat.get("purchased", false)):
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	if (
		not str(habitat.get("reptile_instance_id", "")).is_empty()
		or not str(habitat.get("animal_instance_id", "")).is_empty()
		or not str(habitat.get("reptile_id", "")).is_empty()
	):
		return {"success": false, "message_key": "ui.habitat_occupied"}

	instance["habitat_id"] = habitat_id
	instances[instance_id] = instance
	GameState.set_value("owned_reptile_instances", instances)

	habitat["reptile_id"] = str(instance.get("reptile_id", ""))
	habitat["reptile_instance_id"] = instance_id
	habitat["animal_instance_id"] = instance_id
	habitat["variant_id"] = str(instance.get("variant_id", get_default_variant_id(str(instance.get("reptile_id", "")))))
	habitat["habitat_variant_id"] = str(habitat.get("habitat_variant_id", "default"))
	habitat["habitat_skin_id"] = str(habitat.get("habitat_skin_id", "default"))
	habitats[habitat_id] = habitat
	GameState.set_value("habitats", habitats)
	SaveSystem.save_game()

	return {
		"success": true,
		"message_key": "ui.reptile_added",
		"instance_id": instance_id,
		"variant_id": str(instance.get("variant_id", ""))
	}


func get_owned_reptile_instances() -> Dictionary:
	var value: Variant = GameState.get_value("owned_reptile_instances", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value as Dictionary


func get_reptile_for_habitat(habitat_id: String) -> Dictionary:
	var instances: Dictionary = get_owned_reptile_instances()
	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) == TYPE_DICTIONARY:
		var habitat: Dictionary = habitat_value as Dictionary
		var referenced_instance_id: String = str(habitat.get("reptile_instance_id", ""))
		if referenced_instance_id.is_empty():
			referenced_instance_id = str(habitat.get("animal_instance_id", ""))
		if not referenced_instance_id.is_empty() and instances.has(referenced_instance_id):
			var referenced_instance_value: Variant = instances.get(referenced_instance_id)
			if typeof(referenced_instance_value) == TYPE_DICTIONARY:
				var referenced_instance: Dictionary = referenced_instance_value as Dictionary
				return _normalize_owned_instance(referenced_instance)

		var saved_reptile_id: String = str(habitat.get("reptile_id", ""))
		if not saved_reptile_id.is_empty():
			return {
				"instance_id": referenced_instance_id,
				"reptile_id": saved_reptile_id,
				"variant_id": str(habitat.get("variant_id", get_default_variant_id(saved_reptile_id))),
				"sex": str(habitat.get("sex", "male")),
				"habitat_id": habitat_id
			}

	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = instance_value as Dictionary
		if str(instance.get("habitat_id", "")) == habitat_id:
			return _normalize_owned_instance(instance)

	return {}


func mark_variant_discovered(variant_id: String) -> bool:
	if variant_id.is_empty():
		return false

	var discovered_value: Variant = GameState.get_value("discovered_variants", {})
	var discovered: Dictionary = {}
	if typeof(discovered_value) == TYPE_DICTIONARY:
		discovered = discovered_value as Dictionary

	var was_discovered: bool = bool(discovered.get(variant_id, false))
	discovered[variant_id] = true
	GameState.set_value("discovered_variants", discovered)
	return not was_discovered


func migrate_save_state() -> bool:
	var changed: bool = false
	if _migrate_global_care_resources():
		changed = true

	var instances: Dictionary = get_owned_reptile_instances()
	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = instance_value as Dictionary
		var normalized: Dictionary = _normalize_owned_instance(instance)
		var reptile_id: String = str(normalized.get("reptile_id", ""))
		var variant_id: String = str(normalized.get("variant_id", get_default_variant_id(reptile_id)))
		if not instance.has("variant_id") or not instance.has("breeding_state") or not instance.has("sex") or not instance.has("habitat_id") or not instance.has("custom_name") or typeof(instance.get("custom_name", "")) != TYPE_STRING or not instance.has("happiness") or not instance.has("hydration") or not instance.has("hunger") or not instance.has("cleanliness") or not instance.has("last_needs_update_timestamp") or not instance.has("last_feed_timestamp") or not instance.has("last_water_timestamp") or not instance.has("last_clean_timestamp") or not instance.has("last_play_timestamp"):
			instances[instance_id] = normalized
			changed = true

		if not variant_id.is_empty() and not is_variant_discovered(variant_id):
			mark_variant_discovered(variant_id)
			changed = true

	if changed:
		GameState.set_value("owned_reptile_instances", instances)
		SaveSystem.save_game()

	return changed


func set_reptile_custom_name(instance_id: String, custom_name: String) -> bool:
	var instances: Dictionary = get_owned_reptile_instances()
	if not instances.has(instance_id):
		return false

	var instance_value: Variant = instances.get(instance_id)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return false

	var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
	instance["custom_name"] = custom_name
	instances[instance_id] = instance
	GameState.set_value("owned_reptile_instances", instances)
	SaveSystem.save_game()
	return true


func _create_instance_id() -> String:
	var instances: Dictionary = get_owned_reptile_instances()
	var index: int = instances.size() + 1
	var instance_id: String = "animal_%03d" % index
	while instances.has(instance_id):
		index += 1
		instance_id = "animal_%03d" % index

	return instance_id


func _normalize_sex(sex: String) -> String:
	if sex == "female":
		return "female"

	return "male"


func _is_assigned_to_valid_habitat(instance: Dictionary) -> bool:
	var habitat_id: String = str(instance.get("habitat_id", ""))
	var instance_id: String = str(instance.get("instance_id", ""))
	if habitat_id.is_empty() or instance_id.is_empty():
		return false

	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return false

	var habitat: Dictionary = habitat_value as Dictionary
	if not bool(habitat.get("purchased", false)):
		return false

	var reptile_instance_id: String = str(habitat.get("reptile_instance_id", ""))
	var animal_instance_id: String = str(habitat.get("animal_instance_id", ""))
	return reptile_instance_id == instance_id or animal_instance_id == instance_id or (reptile_instance_id.is_empty() and animal_instance_id.is_empty() and str(habitat.get("reptile_id", "")) == str(instance.get("reptile_id", "")))


func _migrate_global_care_resources() -> bool:
	var changed: bool = false
	var now: int = Time.get_unix_time_from_system()
	changed = _ensure_game_state_int("food_max", 100, 1, 999999) or changed
	changed = _ensure_game_state_int("water_max", 100, 1, 999999) or changed
	changed = _ensure_game_state_int("food_current", 100, 0, int(GameState.get_value("food_max", 100))) or changed
	changed = _ensure_game_state_int("water_current", 100, 0, int(GameState.get_value("water_max", 100))) or changed
	changed = _ensure_game_state_int("food_regen_amount", 1, 1, 999999) or changed
	changed = _ensure_game_state_int("water_regen_amount", 1, 1, 999999) or changed
	changed = _ensure_game_state_int("food_regen_interval_seconds", 600, 1, 999999) or changed
	changed = _ensure_game_state_int("water_regen_interval_seconds", 600, 1, 999999) or changed
	changed = _ensure_game_state_int("last_food_regen_timestamp", now, 0, 2147483647) or changed
	changed = _ensure_game_state_int("last_water_regen_timestamp", now, 0, 2147483647) or changed
	return changed


func _ensure_game_state_int(key: String, fallback: int, minimum: int, maximum: int) -> bool:
	var value: Variant = GameState.get_value(key, null)
	if value == null:
		GameState.set_value(key, fallback)
		return true

	var normalized: int = int(clamp(int(value), minimum, maximum))
	if int(value) == normalized:
		return false

	GameState.set_value(key, normalized)
	return true


func _update_global_resources(now: int) -> bool:
	var changed: bool = false
	changed = _regenerate_resource("food", now) or changed
	changed = _regenerate_resource("water", now) or changed
	return changed


func _regenerate_resource(resource_id: String, now: int) -> bool:
	var current_key: String = resource_id + "_current"
	var max_key: String = resource_id + "_max"
	var timestamp_key: String = "last_" + resource_id + "_regen_timestamp"
	var amount_key: String = resource_id + "_regen_amount"
	var interval_key: String = resource_id + "_regen_interval_seconds"
	var current: int = int(GameState.get_value(current_key, 0))
	var maximum: int = max(1, int(GameState.get_value(max_key, 100)))
	var amount: int = max(1, int(GameState.get_value(amount_key, 1)))
	var interval: int = max(1, int(GameState.get_value(interval_key, 600)))
	var last_timestamp: int = _timestamp_from_value(GameState.get_value(timestamp_key, now))
	var changed: bool = false

	if last_timestamp <= 0:
		GameState.set_value(timestamp_key, now)
		return true

	if current >= maximum:
		if last_timestamp != now:
			GameState.set_value(timestamp_key, now)
			return true
		return false

	var elapsed: int = max(0, now - last_timestamp)
	var ticks: int = int(floor(float(elapsed) / float(interval)))
	if ticks <= 0:
		return false

	var new_current: int = min(maximum, current + ticks * amount)
	var new_timestamp: int = last_timestamp + ticks * interval
	if new_current >= maximum:
		new_timestamp = now

	if new_current != current:
		GameState.set_value(current_key, new_current)
		changed = true
	if new_timestamp != last_timestamp:
		GameState.set_value(timestamp_key, new_timestamp)
		changed = true

	return changed


func _set_global_resource(resource_id: String, value: int) -> void:
	var current_key: String = resource_id + "_current"
	var max_key: String = resource_id + "_max"
	var maximum: int = max(1, int(GameState.get_value(max_key, 100)))
	GameState.set_value(current_key, int(clamp(value, 0, maximum)))


func _update_owned_reptile_needs(now: int) -> bool:
	var instances: Dictionary = get_owned_reptile_instances()
	var changed: bool = false
	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
		var last_timestamp: int = _timestamp_from_value(instance.get("last_needs_update_timestamp", now))
		if last_timestamp <= 0:
			instance["last_needs_update_timestamp"] = now
			instances[instance_id] = instance
			changed = true
			continue

		var elapsed: int = max(0, now - last_timestamp)
		if elapsed <= 0:
			if instance != instance_value:
				instances[instance_id] = instance
				changed = true
			continue

		var decay: float = float(elapsed) / NEED_DECAY_INTERVAL_SECONDS * NEED_DECAY_AMOUNT
		if decay > 0.0:
			instance["hunger"] = _clamp_percent(float(instance.get("hunger", 100)) - decay)
			instance["hydration"] = _clamp_percent(float(instance.get("hydration", 100)) - decay)
			instance["cleanliness"] = _clamp_percent(float(instance.get("cleanliness", 100)) - decay)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) - decay)
			instance["last_needs_update_timestamp"] = now
			instances[instance_id] = instance
			changed = true

	if changed:
		GameState.set_value("owned_reptile_instances", instances)

	return changed


func _timestamp_from_value(value: Variant) -> int:
	if value == null:
		return 0
	return int(value)


func _clamp_percent(value: float) -> float:
	return clamp(value, 0.0, 100.0)


func _normalize_owned_instance(instance: Dictionary) -> Dictionary:
	var normalized: Dictionary = instance.duplicate(true)
	var reptile_id: String = str(normalized.get("reptile_id", ""))
	if str(normalized.get("variant_id", "")).is_empty():
		normalized["variant_id"] = get_default_variant_id(reptile_id)

	normalized["sex"] = _normalize_sex(str(normalized.get("sex", "male")))
	normalized["custom_name"] = str(normalized.get("custom_name", ""))
	normalized["happiness"] = _clamp_percent(float(normalized.get("happiness", 100)))
	normalized["hydration"] = _clamp_percent(float(normalized.get("hydration", 100)))
	normalized["hunger"] = _clamp_percent(float(normalized.get("hunger", 100)))
	normalized["cleanliness"] = _clamp_percent(float(normalized.get("cleanliness", 100)))
	normalized["boredom"] = _clamp_percent(float(normalized.get("boredom", 0)))
	if not normalized.has("last_needs_update_timestamp"):
		normalized["last_needs_update_timestamp"] = Time.get_unix_time_from_system()
	normalized["last_feed_timestamp"] = _timestamp_from_value(normalized.get("last_feed_timestamp", normalized.get("last_fed_at", 0)))
	normalized["last_water_timestamp"] = _timestamp_from_value(normalized.get("last_water_timestamp", normalized.get("last_water_at", 0)))
	normalized["last_clean_timestamp"] = _timestamp_from_value(normalized.get("last_clean_timestamp", normalized.get("last_cleaned_at", 0)))
	normalized["last_play_timestamp"] = _timestamp_from_value(normalized.get("last_play_timestamp", 0))
	if not normalized.has("habitat_id"):
		normalized["habitat_id"] = null
	if not normalized.has("breeding_state"):
		normalized["breeding_state"] = "none"
	if not normalized.has("paired_with_instance_id"):
		normalized["paired_with_instance_id"] = ""
	if not normalized.has("pregnancy_started_at"):
		normalized["pregnancy_started_at"] = null
	if not normalized.has("egg_lay_ready_at"):
		normalized["egg_lay_ready_at"] = null
	if not normalized.has("eggs"):
		normalized["eggs"] = []
	if not normalized.has("incubator_entry_id"):
		normalized["incubator_entry_id"] = ""

	return normalized


func _normalize_variant(variant: Dictionary) -> Dictionary:
	var normalized: Dictionary = variant.duplicate(true)
	var reptile_id: String = str(normalized.get("reptile_id", ""))
	var rarity: String = normalize_rarity(str(normalized.get("rarity", "common")))
	normalized["rarity"] = rarity
	if str(normalized.get("id", "")).is_empty():
		normalized["id"] = reptile_id + "_" + rarity
	if str(normalized.get("name_key", "")).is_empty():
		normalized["name_key"] = "variant." + reptile_id + "." + rarity + ".name"
	if str(normalized.get("portrait_path", "")).is_empty():
		var reptile: Dictionary = get_reptile(reptile_id)
		normalized["portrait_path"] = str(reptile.get("portrait_path", ""))
	if str(normalized.get("icon_path", "")).is_empty():
		normalized["icon_path"] = str(normalized.get("portrait_path", ""))
	if str(normalized.get("rarity_icon_path", "")).is_empty():
		normalized["rarity_icon_path"] = get_rarity_icon_path(rarity)
	if not normalized.has("income_multiplier"):
		normalized["income_multiplier"] = _get_default_income_multiplier(rarity)
	if str(normalized.get("obtain_method", "")).is_empty():
		normalized["obtain_method"] = "default" if rarity == "common" else "future_drop"

	return normalized


func _make_fallback_variant(variant_id: String) -> Dictionary:
	var reptile_id: String = variant_id
	if reptile_id.ends_with("_common"):
		reptile_id = reptile_id.substr(0, reptile_id.length() - 7)
	return _normalize_variant({
		"id": variant_id,
		"reptile_id": reptile_id,
		"rarity": "common",
		"name_key": "variant." + reptile_id + ".common.name",
		"income_multiplier": 1.0,
		"obtain_method": "fallback"
	})


func _first_existing_path(paths: Array) -> String:
	for path_value in paths:
		var path: String = str(path_value)
		if path.is_empty():
			continue
		if ResourceLoader.exists(path):
			return path

	for path_value in paths:
		var path: String = str(path_value)
		if not path.is_empty():
			return path

	return ""


func _get_default_income_multiplier(rarity: String) -> float:
	match normalize_rarity(rarity):
		"rare":
			return 1.1
		"exceptional":
			return 1.25
		"ultra_rare":
			return 1.5
		_:
			return 1.0


func _get_habitats_state() -> Dictionary:
	var value: Variant = GameState.get_value("habitats", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value as Dictionary


func _load_array(path: String) -> Array:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Missing data file: " + path)
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("Invalid data file: " + path)
		return []

	return parsed as Array
