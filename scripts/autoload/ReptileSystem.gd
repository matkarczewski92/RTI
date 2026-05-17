extends Node

signal reptile_released(instance_id: String)

const REPTILES_PATH: String = "res://data/reptiles.json"
const VARIANTS_PATH: String = "res://data/reptile_variants.json"
const CARE_ACTIONS_PATH: String = "res://data/care_actions.json"
const VALID_RARITIES: Array[String] = ["common", "rare", "exceptional", "ultra_rare", "shadow"]
const HAPPINESS_DECAY_INTERVAL_SECONDS := 300.0
const SATIETY_DECAY_INTERVAL_SECONDS := 420.0
const HYDRATION_DECAY_INTERVAL_SECONDS := 420.0
const CLEANLINESS_DECAY_INTERVAL_SECONDS := 600.0
const NEED_DECAY_AMOUNT := 1.0
const FEED_COOLDOWN_SECONDS := 20
const WATER_COOLDOWN_SECONDS := 20
const CLEAN_COOLDOWN_SECONDS := 60
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
const HABITAT_TYPES: Array[String] = ["grass", "sand", "stone", "jungle"]
const HABITAT_BIOMES: Array[String] = ["green_meadow", "dry_prairie"]
const DEFAULT_RESOURCE_REGEN_INTERVAL := 600
const DEFAULT_RESOURCE_REGEN_AMOUNT := 1
const HABITAT_MAX_LEVEL := 3
const HABITAT_UPGRADE_COST := 10000
const HABITAT_BUILD_BASE_DURATIONS_SECONDS: Array[int] = [10, 60, 180]
const HABITAT_BUILD_SCALE_AFTER_THIRD := 1.75
const HABITAT_UPGRADE_LEVEL_2_DURATION_SECONDS := 43200
const HABITAT_UPGRADE_LEVEL_3_DURATION_SECONDS := 86400

const RARITY_ICON_PATHS: Dictionary = {
	"common": "res://assets/art/ui/icons/icon_rarity_common.png",
	"rare": "res://assets/art/ui/icons/icon_rarity_rare.png",
	"exceptional": "res://assets/art/ui/icons/icon_rarity_exceptional.png",
	"ultra_rare": "res://assets/art/ui/icons/icon_rarity_ultra_rare.png"
}

var reptiles: Array = []
var variants: Array = []
var _care_actions_config: Dictionary = {}


func _ready() -> void:
	load_data()
	call_deferred("_initialize_runtime_state")


func _initialize_runtime_state() -> void:
	migrate_save_state()
	apply_time_updates(true)
	sync_discovered_variants_from_owned_reptiles()


func load_data() -> void:
	reptiles = _load_array(REPTILES_PATH)
	variants = _load_array(VARIANTS_PATH)
	_care_actions_config = _load_care_actions_config()


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
	var normalized_rarity: String = normalize_rarity(rarity)
	if normalized_rarity == "common":
		return get_variant_for_reptile(reptile_id, get_default_variant_id(reptile_id))
	return _find_explicit_variant_for_reptile_rarity(reptile_id, normalized_rarity)


func get_variant_for_reptile_rarity(reptile_id: String, rarity: String) -> Dictionary:
	var normalized_rarity: String = normalize_rarity(rarity)
	if normalized_rarity == "common":
		return get_variant_for_reptile(reptile_id, get_default_variant_id(reptile_id))

	var explicit_variant: Dictionary = _find_explicit_variant_for_reptile_rarity(reptile_id, normalized_rarity)
	if not explicit_variant.is_empty():
		return explicit_variant

	if not get_reptile(reptile_id).is_empty():
		return _make_rarity_fallback_variant(reptile_id, normalized_rarity)

	return {}


func _find_explicit_variant_for_reptile_rarity(reptile_id: String, rarity: String) -> Dictionary:
	var normalized_rarity: String = normalize_rarity(rarity)
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


func sync_discovered_variants_from_owned_reptiles() -> Dictionary:
	var instances: Dictionary = get_owned_reptile_instances()
	var discovered_value: Variant = GameState.get_value("discovered_variants", {})
	var discovered: Dictionary = {}
	if typeof(discovered_value) == TYPE_DICTIONARY:
		discovered = discovered_value as Dictionary

	var changed: bool = false
	var instances_changed: bool = false
	var counters_changed: bool = false
	var newly_discovered: Array[String] = []

	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
		var reptile_id: String = str(instance.get("reptile_id", instance.get("species_id", "")))
		if reptile_id.is_empty() or get_reptile(reptile_id).is_empty():
			continue

		var variant_id: String = str(instance.get("variant_id", ""))
		var variant: Dictionary = get_variant_for_reptile(reptile_id, variant_id)
		var rarity: String = normalize_rarity(str(instance.get("rarity", variant.get("rarity", "common"))))
		if rarity == "common" and not variant.is_empty():
			rarity = normalize_rarity(str(variant.get("rarity", rarity)))

		var canonical_variant: Dictionary = get_variant_for_reptile_rarity(reptile_id, rarity)
		var canonical_variant_id: String = str(canonical_variant.get("id", ""))
		if not canonical_variant_id.is_empty():
			variant_id = canonical_variant_id
			if str(instance.get("variant_id", "")) != canonical_variant_id:
				instance["variant_id"] = canonical_variant_id
				instances[instance_id] = instance
				instances_changed = true
		elif not variant_id.is_empty():
			variant_id = str(variant.get("id", variant_id))

		for discovered_variant_id in [variant_id, canonical_variant_id]:
			var normalized_variant_id: String = str(discovered_variant_id)
			if normalized_variant_id.is_empty():
				continue
			if not bool(discovered.get(normalized_variant_id, false)):
				discovered[normalized_variant_id] = true
				newly_discovered.append(normalized_variant_id)
				changed = true

	if changed:
		GameState.set_value("discovered_variants", discovered)
	if instances_changed:
		GameState.set_value("owned_reptile_instances", instances)
	counters_changed = _sync_incubator_hatch_progress_counters(instances)
	if changed or instances_changed or counters_changed:
		SaveSystem.save_game()

	_notify_achievement_progress_changed()
	return {
		"changed": changed or instances_changed or counters_changed,
		"newly_discovered": newly_discovered,
		"discovered_count": discovered.size()
	}


func get_owned_animal_variant(instance: Dictionary) -> Dictionary:
	var reptile_id: String = str(instance.get("reptile_id", ""))
	var raw: Variant = instance.get("variant_id", null)
	var variant_id: String = raw if typeof(raw) == TYPE_STRING else ""
	return get_variant_for_reptile(reptile_id, variant_id)


func get_owned_animal_image_path(instance: Dictionary) -> String:
	var reptile_id: String = str(instance.get("reptile_id", ""))
	var reptile: Dictionary = get_reptile(reptile_id)
	var variant: Dictionary = get_owned_animal_variant(instance)

	# When the stored variant_id resolves to a different rarity than the instance's
	# actual rarity (stale data or null variant_id), prefer the rarity-based portrait.
	var instance_rarity: String = normalize_rarity(str(instance.get("rarity", "")))
	var variant_rarity: String = normalize_rarity(str(variant.get("rarity", "common")))
	if not instance_rarity.is_empty() and instance_rarity != variant_rarity:
		var rarity_variant: Dictionary = get_variant_for_reptile_rarity(reptile_id, instance_rarity)
		if not rarity_variant.is_empty():
			return _first_existing_path([
				str(rarity_variant.get("portrait_path", "")),
				str(rarity_variant.get("icon_path", "")),
				str(variant.get("portrait_path", "")),
				str(variant.get("icon_path", "")),
				str(reptile.get("portrait_path", "")),
				str(reptile.get("icon_path", ""))
			])

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


func get_habitat_types() -> Array[String]:
	var result: Array[String] = []
	for habitat_type in HABITAT_TYPES:
		result.append(habitat_type)
	return result


func normalize_habitat_type(habitat_type: String) -> String:
	var normalized: String = habitat_type.strip_edges().to_lower()
	if normalized == "desert":
		return "sand"
	if HABITAT_TYPES.has(normalized):
		return normalized

	return "grass"


func normalize_habitat_level(level: Variant) -> int:
	return int(clamp(int(level), 1, HABITAT_MAX_LEVEL))


func get_habitat_type_label_key(habitat_type: String) -> String:
	return "habitat.type." + normalize_habitat_type(habitat_type)


func get_habitat_level_label_key(level: Variant) -> String:
	match normalize_habitat_level(level):
		2:
			return "habitat.level.middle"
		3:
			return "habitat.level.top"
		_:
			return "habitat.level.basic"


func get_habitat_texture_path(habitat_type: String, habitat_level: Variant) -> String:
	var suffix: String = "basic"
	match normalize_habitat_level(habitat_level):
		2:
			suffix = "middle"
		3:
			suffix = "top"
		_:
			suffix = "basic"

	return "res://assets/art/habitats/" + normalize_habitat_type(habitat_type) + "_" + suffix + ".png"


func get_reptile_preferred_habitat_type(reptile_id: String) -> String:
	var reptile: Dictionary = get_reptile(reptile_id)
	if reptile.is_empty() or str(reptile.get("preferred_habitat_type", "")).is_empty():
		return ""

	return normalize_habitat_type(str(reptile.get("preferred_habitat_type", "")))


func get_habitat_match_multiplier(instance: Dictionary) -> float:
	var normalized: Dictionary = _normalize_owned_instance(instance)
	var preferred_type: String = get_reptile_preferred_habitat_type(str(normalized.get("reptile_id", "")))
	if preferred_type.is_empty():
		return 1.0

	var habitat: Dictionary = get_habitat_state(_id_or_empty(normalized.get("habitat_id", null)))
	if habitat.is_empty():
		return 1.0

	var current_type: String = normalize_habitat_type(str(habitat.get("habitat_type", "grass")))
	return 1.0 if current_type == preferred_type else 0.5


func get_habitat_level_income_multiplier(instance: Dictionary) -> float:
	var normalized: Dictionary = _normalize_owned_instance(instance)
	if not _is_assigned_to_valid_habitat(normalized):
		return 1.0

	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(_id_or_empty(normalized.get("habitat_id", null)), {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return 1.0

	match int((habitat_value as Dictionary).get("habitat_level", 1)):
		2:
			return 1.25
		3:
			return 1.50
		_:
			return 1.0


func get_habitat_upgrade_cost() -> int:
	return HABITAT_UPGRADE_COST


func get_purchased_habitats_count_in_biome(biome_id: String) -> int:
	var count := 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return count

	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = habitat_value as Dictionary
		if str(habitat.get("biome_id", "")) != biome_id:
			continue
		if bool(habitat.get("purchased", false)):
			count += 1

	return count


func get_habitat_build_duration_seconds(biome_id: String) -> int:
	var already_purchased: int = get_purchased_habitats_count_in_biome(biome_id)
	if already_purchased < HABITAT_BUILD_BASE_DURATIONS_SECONDS.size():
		return HABITAT_BUILD_BASE_DURATIONS_SECONDS[already_purchased]

	var duration: float = float(HABITAT_BUILD_BASE_DURATIONS_SECONDS[HABITAT_BUILD_BASE_DURATIONS_SECONDS.size() - 1])
	for _index in range(HABITAT_BUILD_BASE_DURATIONS_SECONDS.size(), already_purchased + 1):
		duration *= HABITAT_BUILD_SCALE_AFTER_THIRD
	return int(round(duration))


func get_habitat_upgrade_duration_seconds(current_level: Variant = 1) -> int:
	var target_level: int = normalize_habitat_level(int(current_level) + 1)
	match target_level:
		3:
			return HABITAT_UPGRADE_LEVEL_3_DURATION_SECONDS
		_:
			return HABITAT_UPGRADE_LEVEL_2_DURATION_SECONDS


func get_habitat_max_level() -> int:
	return HABITAT_MAX_LEVEL


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
	var habitat_match_multiplier: float = get_habitat_match_multiplier(normalized)
	var habitat_level_multiplier: float = get_habitat_level_income_multiplier(normalized)
	return base_income * happiness_multiplier * variant_multiplier * habitat_match_multiplier * habitat_level_multiplier * get_worker_income_multiplier(normalized) * get_upgrade_income_multiplier(normalized)


func get_worker_income_multiplier(_instance: Dictionary) -> float:
	if not has_node("/root/WorkerSystem"):
		return 1.0

	var worker_system: Node = get_node("/root/WorkerSystem")
	if worker_system.has_method("get_manager_income_multiplier"):
		return float(worker_system.call("get_manager_income_multiplier"))

	return 1.0


func get_upgrade_income_multiplier(_instance: Dictionary) -> float:
	if not has_node("/root/UpgradeSystem"):
		return 1.0

	var upgrade_system: Node = get_node("/root/UpgradeSystem")
	var income_multiplier: float = 1.0
	var collection_multiplier: float = 1.0
	if upgrade_system.has_method("get_reptile_income_multiplier"):
		income_multiplier = float(upgrade_system.call("get_reptile_income_multiplier"))
	if upgrade_system.has_method("get_collection_bonus_multiplier"):
		collection_multiplier = float(upgrade_system.call("get_collection_bonus_multiplier"))
	return income_multiplier * collection_multiplier


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
		var habitat_id: String = _id_or_empty(instance.get("habitat_id", null))
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
	if _update_habitat_timers(now):
		changed = true

	if changed:
		_notify_achievement_progress_changed()
		if save_if_changed:
			SaveSystem.save_game()

	return changed


func get_resource_current(resource_id: String, biome_id: String = GameState.DEFAULT_BIOME_ID) -> int:
	return get_biome_resource_current(biome_id, resource_id)


func get_resource_max(resource_id: String, biome_id: String = GameState.DEFAULT_BIOME_ID) -> int:
	return get_biome_resource_max(biome_id, resource_id)


func get_biome_resource_current(biome_id: String, resource_id: String) -> int:
	_update_global_resources(Time.get_unix_time_from_system())
	var biome: Dictionary = _get_biome_resources(biome_id)
	return int(biome.get(resource_id + "_current", 0))


func get_biome_resource_max(biome_id: String, resource_id: String) -> int:
	var biome: Dictionary = _get_biome_resources(biome_id)
	var base_max: int = max(1, int(biome.get(resource_id + "_max", 100)))
	return _apply_storage_multiplier(resource_id, base_max)


func get_shop_config(resource_id: String) -> Dictionary:
	var shop_value: Variant = _care_actions_config.get("shop", {})
	if typeof(shop_value) != TYPE_DICTIONARY:
		return {}
	var shop: Dictionary = shop_value as Dictionary
	var item_value: Variant = shop.get("buy_" + resource_id, {})
	if typeof(item_value) != TYPE_DICTIONARY:
		return {}
	return item_value as Dictionary


func buy_resource(biome_id: String, resource_id: String) -> Dictionary:
	_update_global_resources(Time.get_unix_time_from_system())
	var shop_config_value: Variant = _care_actions_config.get("shop", {})
	if typeof(shop_config_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.feature_later"}
	var shop_config: Dictionary = shop_config_value as Dictionary
	var item_key: String = "buy_" + resource_id
	var item_value: Variant = shop_config.get(item_key, {})
	if typeof(item_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.feature_later"}
	var item: Dictionary = item_value as Dictionary
	var price: int = int(item.get("price", 0))
	var amount: int = int(item.get("amount", 0))
	if price <= 0 or amount <= 0:
		return {"success": false, "message_key": "ui.feature_later"}
	var effective_max: int = get_biome_resource_max(biome_id, resource_id)
	var current: int = get_biome_resource_current(biome_id, resource_id)
	if current >= effective_max:
		return {"success": false, "message_key": "shop.resource_full"}
	if not EconomySystem.can_afford("repticash", price):
		return {"success": false, "message_key": "ui.not_enough_rs"}
	EconomySystem.spend_currency("repticash", price)
	_set_biome_resource(biome_id, resource_id, min(current + amount, effective_max))
	SaveSystem.save_game()
	return {"success": true, "amount": amount, "resource": resource_id}


func _apply_storage_multiplier(resource_id: String, base_max: int) -> int:
	if not has_node("/root/UpgradeSystem"):
		return base_max
	var upgrade_system: Node = get_node("/root/UpgradeSystem")
	if not upgrade_system.has_method("get_resource_storage_multiplier"):
		return base_max
	var mult: float = float(upgrade_system.call("get_resource_storage_multiplier", resource_id))
	return max(1, int(round(float(base_max) * mult)))


func _get_biome_resources(biome_id: String) -> Dictionary:
	var br_value: Variant = GameState.get_value("biome_resources", {})
	if typeof(br_value) != TYPE_DICTIONARY:
		return {}
	var br: Dictionary = br_value as Dictionary
	var biome_value: Variant = br.get(biome_id, {})
	if typeof(biome_value) != TYPE_DICTIONARY:
		return {}
	return biome_value as Dictionary


func _set_biome_resource(biome_id: String, resource_id: String, value: int) -> void:
	var br_value: Variant = GameState.get_value("biome_resources", {})
	var br: Dictionary = {}
	if typeof(br_value) == TYPE_DICTIONARY:
		br = (br_value as Dictionary).duplicate(true)
	var biome: Dictionary = {}
	var biome_value: Variant = br.get(biome_id, {})
	if typeof(biome_value) == TYPE_DICTIONARY:
		biome = (biome_value as Dictionary).duplicate(true)
	var maximum: int = max(1, int(biome.get(resource_id + "_max", 100)))
	biome[resource_id + "_current"] = int(clamp(value, 0, maximum))
	br[biome_id] = biome
	GameState.set_value("biome_resources", br)


func _get_biome_id_for_instance(instance: Dictionary) -> String:
	var habitat_id: String = _id_or_empty(instance.get("habitat_id", null))
	if habitat_id.is_empty():
		return GameState.DEFAULT_BIOME_ID
	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return GameState.DEFAULT_BIOME_ID
	return str((habitat_value as Dictionary).get("biome_id", GameState.DEFAULT_BIOME_ID))


func perform_care_action(instance_id: String, action_id: String) -> Dictionary:
	apply_time_updates(false)
	var instances: Dictionary = get_owned_reptile_instances()
	if not instances.has(instance_id):
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var instance_value: Variant = instances.get(instance_id)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
	if not _is_assigned_to_valid_habitat(instance):
		return {"success": false, "message_key": "ui.place_reptile_to_care"}

	var now: int = Time.get_unix_time_from_system()
	var remaining: int = get_care_cooldown_remaining(instance, action_id, now)
	if remaining > 0:
		return {"success": false, "message_key": "ui.on_cooldown", "cooldown_remaining": remaining}

	var message_key: String = ""
	var xp_reward: float = 0.0
	var money_reward: float = 0.0
	var biome_id: String = _get_biome_id_for_instance(instance)
	match action_id:
		"feed":
			var feed_cost: int = _get_habitat_resource_cost(instance, "feed")
			if get_biome_resource_current(biome_id, "food") < feed_cost:
				return {"success": false, "message_key": "care.not_enough_food"}
			_set_biome_resource(biome_id, "food", get_biome_resource_current(biome_id, "food") - feed_cost)
			instance["hunger"] = _clamp_percent(float(instance.get("hunger", 100)) + _get_action_stat_gain("feed", FEED_SATIETY_GAIN))
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CARE_SMALL_HAPPINESS_GAIN)
			instance["last_feed_timestamp"] = now
			instance["last_fed_at"] = now
			xp_reward = FEED_XP_REWARD
			message_key = "ui.feed_success_xp"
		"water":
			var water_cost: int = _get_habitat_resource_cost(instance, "water")
			if get_biome_resource_current(biome_id, "water") < water_cost:
				return {"success": false, "message_key": "care.not_enough_water"}
			_set_biome_resource(biome_id, "water", get_biome_resource_current(biome_id, "water") - water_cost)
			instance["hydration"] = _clamp_percent(float(instance.get("hydration", 100)) + _get_action_stat_gain("water", WATER_HYDRATION_GAIN))
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CARE_SMALL_HAPPINESS_GAIN)
			instance["last_water_timestamp"] = now
			instance["last_water_at"] = now
			xp_reward = WATER_XP_REWARD
			message_key = "ui.water_success_xp"
		"clean":
			instance["cleanliness"] = _clamp_percent(float(instance.get("cleanliness", 100)) + _get_action_stat_gain("clean", CLEANLINESS_GAIN))
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CLEAN_HAPPINESS_GAIN)
			instance["last_clean_timestamp"] = now
			instance["last_cleaned_at"] = now
			xp_reward = CLEAN_XP_REWARD
			message_key = "ui.clean_success_xp"
		"play":
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + _get_action_stat_gain("play", PLAY_HAPPINESS_GAIN))
			instance["last_play_timestamp"] = now
			var play_reward_multiplier: float = _get_play_reward_multiplier()
			money_reward = float(PLAY_REPTICASH_REWARD) * play_reward_multiplier
			EconomySystem.add_currency("repticash", money_reward)
			xp_reward = float(PLAY_XP_REWARD) * play_reward_multiplier
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
		"money": money_reward if action_id == "play" else 0
	}


func apply_worker_care_effect(instance_id: String, worker_type: String, threshold: float, effect_value: float) -> bool:
	var instances: Dictionary = get_owned_reptile_instances()
	if not instances.has(instance_id):
		return false

	var instance_value: Variant = instances.get(instance_id)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return false

	var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
	if not _is_assigned_to_valid_habitat(instance):
		return false

	var now: int = Time.get_unix_time_from_system()
	var worker_biome_id: String = _get_biome_id_for_instance(instance)
	var changed := false
	match worker_type:
		"food":
			if float(instance.get("hunger", 100)) >= threshold:
				return false
			var food_cost: int = _get_habitat_resource_cost(instance, "feed")
			if get_biome_resource_current(worker_biome_id, "food") < food_cost:
				return false
			_set_biome_resource(worker_biome_id, "food", get_biome_resource_current(worker_biome_id, "food") - food_cost)
			instance["hunger"] = _clamp_percent(float(instance.get("hunger", 100)) + effect_value)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CARE_SMALL_HAPPINESS_GAIN)
			instance["last_feed_timestamp"] = now
			instance["last_fed_at"] = now
			changed = true
		"water":
			if float(instance.get("hydration", 100)) >= threshold:
				return false
			var water_cost: int = _get_habitat_resource_cost(instance, "water")
			if get_biome_resource_current(worker_biome_id, "water") < water_cost:
				return false
			_set_biome_resource(worker_biome_id, "water", get_biome_resource_current(worker_biome_id, "water") - water_cost)
			instance["hydration"] = _clamp_percent(float(instance.get("hydration", 100)) + effect_value)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CARE_SMALL_HAPPINESS_GAIN)
			instance["last_water_timestamp"] = now
			instance["last_water_at"] = now
			changed = true
		"clean":
			if float(instance.get("cleanliness", 100)) >= threshold:
				return false
			instance["cleanliness"] = _clamp_percent(float(instance.get("cleanliness", 100)) + effect_value)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + CLEAN_HAPPINESS_GAIN)
			instance["last_clean_timestamp"] = now
			instance["last_cleaned_at"] = now
			changed = true
		"play":
			if float(instance.get("happiness", 100)) >= threshold:
				return false
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) + effect_value)
			instance["last_play_timestamp"] = now
			changed = true
		_:
			return false

	if not changed:
		return false

	instance["last_needs_update_timestamp"] = now
	instances[instance_id] = instance
	GameState.set_value("owned_reptile_instances", instances)
	return true


func get_care_cooldown_remaining(instance: Dictionary, action_id: String, now: int = 0) -> int:
	if now <= 0:
		now = Time.get_unix_time_from_system()

	var last_timestamp: int = 0
	var cooldown: int = 0
	match action_id:
		"feed":
			last_timestamp = _timestamp_from_value(instance.get("last_feed_timestamp", instance.get("last_fed_at", 0)))
			cooldown = _get_effective_cooldown("feed", FEED_COOLDOWN_SECONDS)
		"water":
			last_timestamp = _timestamp_from_value(instance.get("last_water_timestamp", instance.get("last_water_at", 0)))
			cooldown = _get_effective_cooldown("water", WATER_COOLDOWN_SECONDS)
		"clean":
			last_timestamp = _timestamp_from_value(instance.get("last_clean_timestamp", instance.get("last_cleaned_at", 0)))
			cooldown = _get_effective_cooldown("clean", CLEAN_COOLDOWN_SECONDS)
		"play":
			last_timestamp = _timestamp_from_value(instance.get("last_play_timestamp", 0))
			cooldown = _get_effective_cooldown("play", PLAY_COOLDOWN_SECONDS)
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
	habitat = _normalize_habitat_state(habitat_id, habitat)
	if bool(habitat.get("is_building", false)):
		return {"success": false, "message_key": "habitat.building_in_progress"}
	if bool(habitat.get("is_upgrading", false)):
		return {"success": false, "message_key": "habitat.upgrading"}

	if (
		not str(habitat.get("reptile_instance_id", "")).is_empty()
		or not _id_or_empty(habitat.get("animal_instance_id", null)).is_empty()
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
	habitat["habitat_type"] = normalize_habitat_type(str(habitat.get("habitat_type", "grass")))
	habitat["habitat_level"] = normalize_habitat_level(habitat.get("habitat_level", 1))
	habitat["is_upgrading"] = false
	habitats[habitat_id] = habitat
	GameState.set_value("habitats", habitats)

	var new_variant_discovered: bool = mark_variant_discovered(variant_id)
	SaveSystem.save_game()
	_notify_achievement_progress_changed()

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
	_notify_achievement_progress_changed()

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
	habitat = _normalize_habitat_state(habitat_id, habitat)
	if bool(habitat.get("is_building", false)):
		return {"success": false, "message_key": "habitat.building_in_progress"}
	if bool(habitat.get("is_upgrading", false)):
		return {"success": false, "message_key": "habitat.upgrading"}

	if (
		not str(habitat.get("reptile_instance_id", "")).is_empty()
		or not _id_or_empty(habitat.get("animal_instance_id", null)).is_empty()
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
	habitat["habitat_type"] = normalize_habitat_type(str(habitat.get("habitat_type", "grass")))
	habitat["habitat_level"] = normalize_habitat_level(habitat.get("habitat_level", 1))
	habitat["is_upgrading"] = false
	habitats[habitat_id] = habitat
	GameState.set_value("habitats", habitats)
	SaveSystem.save_game()
	_notify_achievement_progress_changed()

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
			referenced_instance_id = _id_or_empty(habitat.get("animal_instance_id", null))
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
		if _id_or_empty(instance.get("habitat_id", null)) == habitat_id:
			return _normalize_owned_instance(instance)

	return {}


func get_habitat_state(habitat_id: String) -> Dictionary:
	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return {}

	return _normalize_habitat_state(habitat_id, habitat_value as Dictionary)


func is_habitat_upgrading(habitat_id: String) -> bool:
	var habitat: Dictionary = get_habitat_state(habitat_id)
	return bool(habitat.get("is_upgrading", false))


func is_habitat_building(habitat_id: String) -> bool:
	var habitat: Dictionary = get_habitat_state(habitat_id)
	return bool(habitat.get("is_building", false))


func get_habitat_build_remaining_seconds(habitat_id: String) -> int:
	var habitat: Dictionary = get_habitat_state(habitat_id)
	if not bool(habitat.get("is_building", false)):
		return 0

	var finish_at: int = _timestamp_from_value(habitat.get("build_finish_at", 0))
	return int(max(0, finish_at - Time.get_unix_time_from_system()))


func get_habitat_upgrade_remaining_seconds(habitat_id: String) -> int:
	var habitat: Dictionary = get_habitat_state(habitat_id)
	if not bool(habitat.get("is_upgrading", false)):
		return 0

	var finish_at: int = _timestamp_from_value(habitat.get("upgrade_finish_at", 0))
	return int(max(0, finish_at - Time.get_unix_time_from_system()))


func remove_reptile_from_habitat(habitat_id: String) -> Dictionary:
	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	var habitat: Dictionary = _normalize_habitat_state(habitat_id, habitat_value as Dictionary)
	if not bool(habitat.get("purchased", false)):
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	var instances: Dictionary = get_owned_reptile_instances()
	var instance_id: String = _get_assigned_instance_id_for_habitat(habitat, instances)
	if instance_id.is_empty():
		return {"success": false, "message_key": "ui.reptile_unavailable"}

	_unassign_instance_from_habitat(instance_id, habitat_id, instances, habitat)
	habitats[habitat_id] = habitat
	GameState.set_value("owned_reptile_instances", instances)
	GameState.set_value("habitats", habitats)
	SaveSystem.save_game()
	_notify_achievement_progress_changed()
	return {"success": true, "message_key": "habitat.remove_reptile"}


func release_reptile_instance(instance_id: String) -> Dictionary:
	var instances: Dictionary = get_owned_reptile_instances()
	if not instances.has(instance_id):
		return {"success": false, "message_key": "animals.reptile_not_found"}
	var instance_value: Variant = instances.get(instance_id)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "animals.reptile_not_found"}
	var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
	if not _id_or_empty(instance.get("habitat_id", null)).is_empty():
		return {"success": false, "message_key": "animals.release_blocked"}
	instances.erase(instance_id)
	GameState.set_value("owned_reptile_instances", instances)
	SaveSystem.save_game()
	_notify_achievement_progress_changed()
	reptile_released.emit(instance_id)
	return {"success": true}


func start_habitat_upgrade(habitat_id: String) -> Dictionary:
	var now: int = Time.get_unix_time_from_system()
	_update_habitat_timers(now)
	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	var habitat: Dictionary = _normalize_habitat_state(habitat_id, habitat_value as Dictionary)
	if not bool(habitat.get("purchased", false)):
		return {"success": false, "message_key": "ui.habitat_unavailable"}
	if bool(habitat.get("is_building", false)):
		return {"success": false, "message_key": "habitat.building_in_progress"}
	if bool(habitat.get("is_upgrading", false)):
		return {"success": false, "message_key": "habitat.upgrading"}

	var current_level: int = normalize_habitat_level(habitat.get("habitat_level", 1))
	if current_level >= HABITAT_MAX_LEVEL:
		return {"success": false, "message_key": "habitat.max_level"}
	var instances: Dictionary = get_owned_reptile_instances()
	var assigned_instance_id: String = _get_assigned_instance_id_for_habitat(habitat, instances)
	if not assigned_instance_id.is_empty():
		return {"success": false, "message_key": "habitat.remove_reptile_first"}
	if not EconomySystem.can_afford("repticash", HABITAT_UPGRADE_COST):
		return {"success": false, "message_key": "ui.not_enough_currency"}
	if not EconomySystem.spend_currency("repticash", HABITAT_UPGRADE_COST):
		return {"success": false, "message_key": "ui.not_enough_currency"}

	habitat["is_upgrading"] = true
	habitat["upgrade_target_level"] = current_level + 1
	habitat["upgrade_started_at"] = now
	habitat["upgrade_finish_at"] = now + get_habitat_upgrade_duration_seconds(current_level)
	habitat["habitat_level"] = current_level
	habitats[habitat_id] = habitat

	GameState.set_value("owned_reptile_instances", instances)
	GameState.set_value("habitats", habitats)
	SaveSystem.save_game()
	_notify_achievement_progress_changed()
	return {"success": true, "message_key": "habitat.upgrading", "animal_removed": false}


func remove_habitat(habitat_id: String) -> Dictionary:
	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return {"success": false, "message_key": "ui.habitat_unavailable"}

	var habitat: Dictionary = _normalize_habitat_state(habitat_id, habitat_value as Dictionary)
	if not bool(habitat.get("purchased", false)):
		return {"success": false, "message_key": "ui.habitat_unavailable"}
	if bool(habitat.get("is_upgrading", false)):
		return {"success": false, "message_key": "habitat.cannot_remove_during_upgrade"}

	var instances: Dictionary = get_owned_reptile_instances()
	if not _get_assigned_instance_id_for_habitat(habitat, instances).is_empty():
		return {"success": false, "message_key": "habitat.remove_reptile_first"}

	habitats[habitat_id] = {
		"habitat_id": habitat_id,
		"biome_id": str(habitat.get("biome_id", "")),
		"slot_index": int(habitat.get("slot_index", 0)),
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
		"animal_instance_id": "",
		"variant_id": "",
		"habitat_variant_id": "default",
		"habitat_skin_id": "default"
	}
	GameState.set_value("habitats", habitats)
	SaveSystem.save_game()
	_notify_achievement_progress_changed()
	return {"success": true, "message_key": "habitat.remove_habitat"}


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
	if _migrate_habitats_state(Time.get_unix_time_from_system()):
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
	var habitat_id: String = _id_or_empty(instance.get("habitat_id", null))
	var instance_id: String = _id_or_empty(instance.get("instance_id", null))
	if habitat_id.is_empty() or instance_id.is_empty():
		return false

	var habitats: Dictionary = _get_habitats_state()
	var habitat_value: Variant = habitats.get(habitat_id, {})
	if typeof(habitat_value) != TYPE_DICTIONARY:
		return false

	var habitat: Dictionary = habitat_value as Dictionary
	if not bool(habitat.get("purchased", false)):
		return false
	if bool(habitat.get("is_building", false)):
		return false
	if bool(habitat.get("is_upgrading", false)):
		return false

	var reptile_instance_id: String = _id_or_empty(habitat.get("reptile_instance_id", null))
	var animal_instance_id: String = _id_or_empty(habitat.get("animal_instance_id", null))
	return reptile_instance_id == instance_id or animal_instance_id == instance_id or (reptile_instance_id.is_empty() and animal_instance_id.is_empty() and str(habitat.get("reptile_id", "")) == str(instance.get("reptile_id", "")))


func _normalize_habitat_state(habitat_id: String, habitat: Dictionary) -> Dictionary:
	var normalized: Dictionary = habitat.duplicate(true)
	var normalized_habitat_id: String = _id_or_empty(normalized.get("habitat_id", habitat_id))
	normalized["habitat_id"] = habitat_id if normalized_habitat_id.is_empty() else normalized_habitat_id
	if str(normalized.get("biome_id", "")).is_empty():
		normalized["biome_id"] = "green_meadow"
	normalized["slot_index"] = int(normalized.get("slot_index", 0))
	normalized["purchased"] = bool(normalized.get("purchased", false))
	normalized["habitat_type"] = normalize_habitat_type(str(normalized.get("habitat_type", "grass")))
	normalized["habitat_level"] = normalize_habitat_level(normalized.get("habitat_level", 1))
	normalized["is_building"] = bool(normalized.get("is_building", false))
	normalized["build_started_at"] = _timestamp_from_value(normalized.get("build_started_at", 0))
	normalized["build_finish_at"] = _timestamp_from_value(normalized.get("build_finish_at", 0))
	normalized["is_upgrading"] = bool(normalized.get("is_upgrading", false))
	normalized["upgrade_target_level"] = int(normalized.get("upgrade_target_level", 0))
	normalized["upgrade_started_at"] = _timestamp_from_value(normalized.get("upgrade_started_at", 0))
	normalized["upgrade_finish_at"] = _timestamp_from_value(normalized.get("upgrade_finish_at", 0))
	normalized["reptile_id"] = _id_or_empty(normalized.get("reptile_id", ""))
	normalized["reptile_instance_id"] = _id_or_empty(normalized.get("reptile_instance_id", ""))
	normalized["animal_instance_id"] = _id_or_empty(normalized.get("animal_instance_id", ""))
	normalized["variant_id"] = str(normalized.get("variant_id", ""))
	normalized["habitat_variant_id"] = str(normalized.get("habitat_variant_id", "default"))
	normalized["habitat_skin_id"] = str(normalized.get("habitat_skin_id", "default"))
	return normalized


func _migrate_habitats_state(now: int) -> bool:
	var habitats: Dictionary = _get_habitats_state()
	var changed: bool = false
	for habitat_id_value in habitats.keys():
		var habitat_id: String = str(habitat_id_value)
		var habitat_value: Variant = habitats.get(habitat_id)
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var original: Dictionary = habitat_value as Dictionary
		var normalized: Dictionary = _normalize_habitat_state(habitat_id, original)
		if _finalize_habitat_build_if_due(normalized, now):
			changed = true
		if _finalize_habitat_upgrade_if_due(normalized, now):
			changed = true
		if normalized != original:
			changed = true
		habitats[habitat_id] = normalized

	if changed:
		GameState.set_value("habitats", habitats)

	return changed


func _update_habitat_timers(now: int) -> bool:
	var habitats: Dictionary = _get_habitats_state()
	var changed: bool = false
	for habitat_id_value in habitats.keys():
		var habitat_id: String = str(habitat_id_value)
		var habitat_value: Variant = habitats.get(habitat_id)
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = _normalize_habitat_state(habitat_id, habitat_value as Dictionary)
		if _finalize_habitat_build_if_due(habitat, now):
			habitats[habitat_id] = habitat
			changed = true
		if _finalize_habitat_upgrade_if_due(habitat, now):
			habitats[habitat_id] = habitat
			changed = true

	if changed:
		GameState.set_value("habitats", habitats)

	return changed


func _update_habitat_upgrades(now: int) -> bool:
	return _update_habitat_timers(now)


func _finalize_habitat_build_if_due(habitat: Dictionary, now: int) -> bool:
	if not bool(habitat.get("is_building", false)):
		return false

	var finish_at: int = _timestamp_from_value(habitat.get("build_finish_at", 0))
	if finish_at <= 0 or now < finish_at:
		return false

	habitat["is_building"] = false
	habitat["build_started_at"] = 0
	habitat["build_finish_at"] = 0
	habitat["habitat_level"] = normalize_habitat_level(habitat.get("habitat_level", 1))
	return true


func _finalize_habitat_upgrade_if_due(habitat: Dictionary, now: int) -> bool:
	if not bool(habitat.get("is_upgrading", false)):
		return false

	var finish_at: int = _timestamp_from_value(habitat.get("upgrade_finish_at", 0))
	if finish_at <= 0 or now < finish_at:
		return false

	var target_level: int = normalize_habitat_level(habitat.get("upgrade_target_level", int(habitat.get("habitat_level", 1)) + 1))
	habitat["habitat_level"] = target_level
	habitat["is_upgrading"] = false
	habitat["upgrade_target_level"] = 0
	habitat["upgrade_started_at"] = 0
	habitat["upgrade_finish_at"] = 0
	return true


func _get_assigned_instance_id_for_habitat(habitat: Dictionary, instances: Dictionary) -> String:
	var referenced_instance_id: String = _id_or_empty(habitat.get("reptile_instance_id", null))
	if referenced_instance_id.is_empty():
		referenced_instance_id = _id_or_empty(habitat.get("animal_instance_id", null))
	if not referenced_instance_id.is_empty() and instances.has(referenced_instance_id):
		return referenced_instance_id

	var habitat_id: String = str(habitat.get("habitat_id", ""))
	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue
		var instance: Dictionary = instance_value as Dictionary
		if _id_or_empty(instance.get("habitat_id", null)) == habitat_id:
			return str(instance_id)

	return ""


func _unassign_instance_from_habitat(instance_id: String, habitat_id: String, instances: Dictionary, habitat: Dictionary) -> void:
	if instances.has(instance_id):
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) == TYPE_DICTIONARY:
			var instance: Dictionary = _normalize_owned_instance(instance_value as Dictionary)
			if _id_or_empty(instance.get("habitat_id", null)) == habitat_id:
				instance["habitat_id"] = null
				instances[instance_id] = instance

	habitat["reptile_id"] = ""
	habitat["reptile_instance_id"] = ""
	habitat["animal_instance_id"] = ""
	habitat["variant_id"] = ""


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
	var br_value: Variant = GameState.get_value("biome_resources", {})
	if typeof(br_value) != TYPE_DICTIONARY:
		return false
	var br: Dictionary = (br_value as Dictionary).duplicate(true)
	var changed: bool = false
	for biome_id in HABITAT_BIOMES:
		var biome_value: Variant = br.get(biome_id, {})
		if typeof(biome_value) != TYPE_DICTIONARY:
			continue
		var biome: Dictionary = (biome_value as Dictionary).duplicate(true)
		for resource_id in ["food", "water"]:
			var eff_max: int = _apply_storage_multiplier(resource_id, max(1, int((biome as Dictionary).get(resource_id + "_max", 100))))
			if _regenerate_biome_resource_in_place(biome, resource_id, now, eff_max):
				changed = true
		br[biome_id] = biome
	if changed:
		GameState.set_value("biome_resources", br)
	return changed


func _regenerate_biome_resource_in_place(biome: Dictionary, resource_id: String, now: int, effective_max: int = -1) -> bool:
	var current: int = int(biome.get(resource_id + "_current", 0))
	var maximum: int = effective_max if effective_max > 0 else max(1, int(biome.get(resource_id + "_max", 100)))
	var timestamp_key: String = "last_" + resource_id + "_regen_timestamp"
	var last_timestamp: int = _timestamp_from_value(biome.get(timestamp_key, now))
	var action_id: String = "feed" if resource_id == "food" else "water"
	var action_config: Dictionary = _get_care_action_config(action_id)
	var amount: int = max(1, int(action_config.get("regen_amount", DEFAULT_RESOURCE_REGEN_AMOUNT)))
	var interval: int = max(1, int(action_config.get("regen_interval_seconds", DEFAULT_RESOURCE_REGEN_INTERVAL)))

	if last_timestamp <= 0:
		biome[timestamp_key] = now
		return true

	if current >= maximum:
		if last_timestamp != now:
			biome[timestamp_key] = now
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

	var changed: bool = false
	if new_current != current:
		biome[resource_id + "_current"] = new_current
		changed = true
	if new_timestamp != last_timestamp:
		biome[timestamp_key] = new_timestamp
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

		var satiety_decay: float = _calculate_need_decay(elapsed, SATIETY_DECAY_INTERVAL_SECONDS)
		var hydration_decay: float = _calculate_need_decay(elapsed, HYDRATION_DECAY_INTERVAL_SECONDS)
		var cleanliness_decay: float = _calculate_need_decay(elapsed, CLEANLINESS_DECAY_INTERVAL_SECONDS)
		var happiness_decay: float = _calculate_need_decay(elapsed, HAPPINESS_DECAY_INTERVAL_SECONDS) * _get_happiness_decay_multiplier()
		if satiety_decay > 0.0 or hydration_decay > 0.0 or cleanliness_decay > 0.0 or happiness_decay > 0.0:
			instance["hunger"] = _clamp_percent(float(instance.get("hunger", 100)) - satiety_decay)
			instance["hydration"] = _clamp_percent(float(instance.get("hydration", 100)) - hydration_decay)
			instance["cleanliness"] = _clamp_percent(float(instance.get("cleanliness", 100)) - cleanliness_decay)
			instance["happiness"] = _clamp_percent(float(instance.get("happiness", 100)) - happiness_decay)
			instance["last_needs_update_timestamp"] = now
			instances[instance_id] = instance
			changed = true

	if changed:
		GameState.set_value("owned_reptile_instances", instances)

	return changed


func _calculate_need_decay(elapsed_seconds: int, interval_seconds: float) -> float:
	return float(elapsed_seconds) / max(1.0, interval_seconds) * NEED_DECAY_AMOUNT


func _timestamp_from_value(value: Variant) -> int:
	if value == null:
		return 0
	return int(value)


func _clamp_percent(value: float) -> float:
	return clamp(value, 0.0, 100.0)


func _get_play_reward_multiplier() -> float:
	if not has_node("/root/UpgradeSystem"):
		return 1.0

	var upgrade_system: Node = get_node("/root/UpgradeSystem")
	if upgrade_system.has_method("get_play_reward_multiplier"):
		return float(upgrade_system.call("get_play_reward_multiplier"))

	return 1.0


func _get_happiness_decay_multiplier() -> float:
	if not has_node("/root/UpgradeSystem"):
		return 1.0

	var upgrade_system: Node = get_node("/root/UpgradeSystem")
	if upgrade_system.has_method("get_happiness_decay_multiplier"):
		return float(upgrade_system.call("get_happiness_decay_multiplier"))

	return 1.0


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
	elif _id_or_empty(normalized.get("habitat_id", null)).is_empty():
		normalized["habitat_id"] = null
	if not normalized.has("breeding_state"):
		normalized["breeding_state"] = "none"
	if not normalized.has("breeding_partner_id"):
		normalized["breeding_partner_id"] = null
	if not normalized.has("breeding_started_at"):
		normalized["breeding_started_at"] = 0
	if not normalized.has("egg_lay_finish_at"):
		normalized["egg_lay_finish_at"] = 0
	if not normalized.has("incubator_egg_id"):
		normalized["incubator_egg_id"] = null
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
	if not normalized.has("breeding_cooldown_until"):
		normalized["breeding_cooldown_until"] = 0

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
	for rarity in ["ultra_rare", "exceptional", "rare", "common", "shadow"]:
		var suffix: String = "_" + rarity
		if variant_id.ends_with(suffix):
			var reptile_id: String = variant_id.substr(0, variant_id.length() - suffix.length())
			return _make_rarity_fallback_variant(reptile_id, rarity)

	return _make_rarity_fallback_variant(variant_id, "common")


func _make_rarity_fallback_variant(reptile_id: String, rarity: String) -> Dictionary:
	var normalized_rarity: String = normalize_rarity(rarity)
	var source_variant: Dictionary = {}
	for source_rarity in [normalized_rarity, "rare", "common"]:
		for variant_value in variants:
			if typeof(variant_value) != TYPE_DICTIONARY:
				continue
			var candidate: Dictionary = variant_value as Dictionary
			if str(candidate.get("reptile_id", "")) == reptile_id and normalize_rarity(str(candidate.get("rarity", "common"))) == str(source_rarity):
				source_variant = _normalize_variant(candidate)
				break
		if not source_variant.is_empty():
			break

	var reptile: Dictionary = get_reptile(reptile_id)
	return _normalize_variant({
		"id": reptile_id + "_" + normalized_rarity,
		"reptile_id": reptile_id,
		"rarity": normalized_rarity,
		"name_key": get_rarity_label_key(normalized_rarity),
		"portrait_path": str(source_variant.get("portrait_path", reptile.get("portrait_path", ""))),
		"icon_path": str(source_variant.get("icon_path", source_variant.get("portrait_path", reptile.get("icon_path", "")))),
		"gallery_shadow_path": str(source_variant.get("gallery_shadow_path", "res://assets/art/reptiles/gallery/" + reptile_id + "_shadow.png")),
		"rarity_icon_path": get_rarity_icon_path(normalized_rarity),
		"income_multiplier": _get_default_income_multiplier(normalized_rarity),
		"obtain_method": "fallback"
	})


func _sync_incubator_hatch_progress_counters(instances: Dictionary) -> bool:
	var total_hatches: int = 0
	var has_rare: bool = false
	var has_ultra_rare: bool = false
	var has_exceptional: bool = false

	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue
		var instance: Dictionary = instance_value as Dictionary
		var source: String = str(instance.get("source", ""))
		var source_egg_id: String = _id_or_empty(instance.get("source_egg_id", null))
		if source != "incubation" and source_egg_id.is_empty() and not str(instance_id).begins_with("hatch_"):
			continue

		total_hatches += 1
		var reptile_id: String = str(instance.get("reptile_id", instance.get("species_id", "")))
		var variant_id: String = str(instance.get("variant_id", ""))
		var variant: Dictionary = get_variant_for_reptile(reptile_id, variant_id)
		var rarity: String = normalize_rarity(str(instance.get("rarity", variant.get("rarity", "common"))))
		if rarity == "common" and not variant.is_empty():
			rarity = normalize_rarity(str(variant.get("rarity", rarity)))
		match rarity:
			"rare":
				has_rare = true
			"ultra_rare":
				has_ultra_rare = true
			"exceptional":
				has_exceptional = true

	var counters_value: Variant = GameState.get_value("quest_event_counters", {})
	var counters: Dictionary = counters_value as Dictionary if typeof(counters_value) == TYPE_DICTIONARY else {}
	var changed: bool = false
	changed = _set_counter_at_least_in_dictionary(counters, "incubator_hatches_total", total_hatches) or changed
	changed = _set_counter_at_least_in_dictionary(counters, "incubator:total_hatches", total_hatches) or changed
	if has_rare:
		changed = _set_counter_at_least_in_dictionary(counters, "incubator_hatch_rare_total", 1) or changed
		changed = _set_counter_at_least_in_dictionary(counters, "incubator:rare_hatches", 1) or changed
	if has_ultra_rare:
		changed = _set_counter_at_least_in_dictionary(counters, "incubator_hatch_ultra_rare_total", 1) or changed
		changed = _set_counter_at_least_in_dictionary(counters, "incubator:ultra_rare_hatches", 1) or changed
	if has_exceptional:
		changed = _set_counter_at_least_in_dictionary(counters, "incubator_hatch_exceptional_total", 1) or changed
		changed = _set_counter_at_least_in_dictionary(counters, "incubator:exceptional_hatches", 1) or changed

	if changed:
		GameState.set_value("quest_event_counters", counters)
	return changed


func _set_counter_at_least_in_dictionary(counters: Dictionary, counter_id: String, value: int) -> bool:
	if value <= 0:
		return false
	var current: int = int(counters.get(counter_id, 0))
	if current >= value:
		return false
	counters[counter_id] = value
	return true


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


func _id_or_empty(value: Variant) -> String:
	if value == null:
		return ""
	var text: String = str(value).strip_edges()
	if text.is_empty() or text == "<null>" or text.to_lower() == "null":
		return ""
	return text


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


func _notify_achievement_progress_changed() -> void:
	if has_node("/root/AchievementSystem"):
		var achievement_system: Node = get_node("/root/AchievementSystem")
		if achievement_system.has_method("notify_progress_changed"):
			achievement_system.call("notify_progress_changed")
	if has_node("/root/QuestSystem"):
		var quest_system: Node = get_node("/root/QuestSystem")
		if quest_system.has_method("notify_event"):
			quest_system.call("notify_event", "state_changed", {})


func _load_care_actions_config() -> Dictionary:
	var file: FileAccess = FileAccess.open(CARE_ACTIONS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Missing care actions config: " + CARE_ACTIONS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid care actions config: " + CARE_ACTIONS_PATH)
		return {}
	return parsed as Dictionary


func _get_care_action_config(action_id: String) -> Dictionary:
	var actions_value: Variant = _care_actions_config.get("actions", {})
	if typeof(actions_value) != TYPE_DICTIONARY:
		return {}
	var action_value: Variant = (actions_value as Dictionary).get(action_id, {})
	if typeof(action_value) != TYPE_DICTIONARY:
		return {}
	return action_value as Dictionary


func _get_action_stat_gain(action_id: String, fallback: float) -> float:
	var config: Dictionary = _get_care_action_config(action_id)
	if config.is_empty():
		return fallback
	return float(config.get("increase_percent", fallback))


func _get_habitat_resource_cost(instance: Dictionary, action_id: String) -> int:
	var resource_id: String = "food" if action_id == "feed" else "water"
	var action_config: Dictionary = _get_care_action_config(action_id)
	var biome_id: String = _get_biome_id_for_instance(instance)

	var base_cost: float
	if action_config.has("resource_cost"):
		base_cost = float(max(1, int(action_config.get("resource_cost", 1))))
	else:
		var habitat_level: int = 1
		var habitat_id: String = _id_or_empty(instance.get("habitat_id", null))
		if not habitat_id.is_empty():
			var habitats: Dictionary = _get_habitats_state()
			var habitat_value: Variant = habitats.get(habitat_id, {})
			if typeof(habitat_value) == TYPE_DICTIONARY:
				habitat_level = normalize_habitat_level((habitat_value as Dictionary).get("habitat_level", 1))

		var level_costs_value: Variant = _care_actions_config.get("habitat_level_resource_cost_percent", {})
		var cost_percent: int = 5
		if typeof(level_costs_value) == TYPE_DICTIONARY:
			cost_percent = int((level_costs_value as Dictionary).get(str(habitat_level), 5))

		var resource_max: int = get_biome_resource_max(biome_id, resource_id)
		base_cost = float(resource_max) * float(cost_percent) / 100.0

	var cost_multiplier: float = 1.0
	if has_node("/root/UpgradeSystem"):
		var upgrade_system: Node = get_node("/root/UpgradeSystem")
		if upgrade_system.has_method("get_action_cost_multiplier"):
			cost_multiplier = float(upgrade_system.call("get_action_cost_multiplier", action_id, biome_id))

	return max(1, roundi(base_cost * cost_multiplier))


func _get_effective_cooldown(action_id: String, base_cooldown: int) -> int:
	var config: Dictionary = _get_care_action_config(action_id)
	var cooldown: int = base_cooldown
	if not config.is_empty() and config.has("cooldown_seconds"):
		cooldown = max(1, int(config.get("cooldown_seconds", base_cooldown)))

	var resource_value: Variant = config.get("resource", null)
	var has_resource: bool = resource_value != null and str(resource_value) != "null" and not str(resource_value).is_empty()
	if has_resource:
		return cooldown

	var cooldown_multiplier: float = 1.0
	if has_node("/root/UpgradeSystem"):
		var upgrade_system: Node = get_node("/root/UpgradeSystem")
		if upgrade_system.has_method("get_action_cooldown_multiplier"):
			cooldown_multiplier = float(upgrade_system.call("get_action_cooldown_multiplier", action_id))

	return max(1, roundi(float(cooldown) * cooldown_multiplier))


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
