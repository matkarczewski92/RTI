extends Node

const EGG_SHOP_PATH := "res://data/egg_shop.json"
const SPECIES_INCUBATION_PATH := "res://data/species_incubation.json"
const INCUBATOR_CONFIG_PATH := "res://data/incubator.json"
const BIOMES_PATH := "res://data/biomes.json"

var _shop_offers: Array = []
var _shop_qualities: Dictionary = {}
var _quality_order: Array = []
var _species_data: Dictionary = {}
var _species_defaults: Dictionary = {"incubation_time_hours": 24, "egg_name_pl": "Jaja gadów", "egg_name_en": "Reptile Eggs"}
var _incubator_cfg: Dictionary = {}
var _humidity_cfg: Dictionary = {}
var _biomes_data: Array = []


func _ready() -> void:
	_load_configs()
	if not GameState.save_loaded.is_connected(_on_save_loaded):
		GameState.save_loaded.connect(_on_save_loaded)
	call_deferred("_on_save_loaded")


func _on_save_loaded() -> void:
	_tick_all_containers()


func _load_configs() -> void:
	var file := FileAccess.open(EGG_SHOP_PATH, FileAccess.READ)
	if file != null:
		var data: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			var d: Dictionary = data as Dictionary
			var offers: Variant = d.get("offers", [])
			if typeof(offers) == TYPE_ARRAY:
				_shop_offers = offers as Array
			var quals: Variant = d.get("qualities", {})
			if typeof(quals) == TYPE_DICTIONARY:
				_shop_qualities = quals as Dictionary
			var qorder: Variant = d.get("quality_order", [])
			if typeof(qorder) == TYPE_ARRAY:
				_quality_order = qorder as Array
		if _quality_order.is_empty():
			_quality_order = ["standard", "improved", "rare", "elite"]
	else:
		push_warning("IncubationSystem: egg_shop.json not found.")

	file = FileAccess.open(SPECIES_INCUBATION_PATH, FileAccess.READ)
	if file != null:
		var data: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			var d: Dictionary = data as Dictionary
			var defs: Variant = d.get("defaults", {})
			if typeof(defs) == TYPE_DICTIONARY:
				_species_defaults = defs as Dictionary
			var sp: Variant = d.get("species", {})
			if typeof(sp) == TYPE_DICTIONARY:
				_species_data = sp as Dictionary
	else:
		push_warning("IncubationSystem: species_incubation.json not found.")

	file = FileAccess.open(INCUBATOR_CONFIG_PATH, FileAccess.READ)
	if file != null:
		var data: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			_incubator_cfg = data as Dictionary
			var hc: Variant = _incubator_cfg.get("humidity", {})
			if typeof(hc) == TYPE_DICTIONARY:
				_humidity_cfg = hc as Dictionary
	else:
		push_warning("IncubationSystem: incubator.json not found.")

	file = FileAccess.open(BIOMES_PATH, FileAccess.READ)
	if file != null:
		var data: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_ARRAY:
			_biomes_data = data as Array
	else:
		push_warning("IncubationSystem: biomes.json not found.")


# ─── Public: config helpers ─────────────────────────────────────────────

func get_shop_offers() -> Array:
	return _shop_offers.duplicate(true)


func get_species_shop_qualities() -> Dictionary:
	return _shop_qualities.duplicate(true)


func get_quality_order() -> Array:
	return _quality_order.duplicate(true)


func _get_accessible_biome_ids() -> Dictionary:
	var current_level: int = int(GameState.get_value("level", 1))
	var accessible: Dictionary = {}
	for bv in _biomes_data:
		if typeof(bv) != TYPE_DICTIONARY:
			continue
		var b: Dictionary = bv as Dictionary
		var bid: String = str(b.get("id", ""))
		if bid.is_empty() or bid == "incubator":
			continue
		var req: Variant = b.get("unlock_requirements", {})
		var req_level: int = 0
		if typeof(req) == TYPE_DICTIONARY:
			req_level = int((req as Dictionary).get("level", 0))
		if req_level <= 0 or current_level >= req_level:
			accessible[bid] = true
	var saved_val: Variant = GameState.get_value("unlocked_biomes", [])
	if typeof(saved_val) == TYPE_ARRAY:
		for sv in (saved_val as Array):
			var sid: String = str(sv)
			if not sid.is_empty():
				accessible[sid] = true
	return accessible


func get_available_species_for_shop() -> Array:
	var accessible: Dictionary = _get_accessible_biome_ids()
	print("[EggShop] Available biomes: ", accessible.keys())

	var result: Array = []
	for rv in ReptileSystem.reptiles:
		if typeof(rv) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = rv as Dictionary
		var species_id: String = str(r.get("id", ""))
		var biome_id: String = str(r.get("biome_id", ""))
		if species_id.is_empty() or biome_id.is_empty() or biome_id == "incubator":
			continue
		if not accessible.has(biome_id):
			print("[EggShop] Skipping: ", species_id, " biome=", biome_id, " -> biome not accessible")
			continue
		var cfg_val: Variant = _species_data.get(species_id, null)
		if typeof(cfg_val) != TYPE_DICTIONARY:
			push_warning("IncubationSystem: species " + species_id + " missing incubation config, skipped in shop.")
			print("[EggShop] Skipping: ", species_id, " biome=", biome_id, " -> no incubation config")
			continue
		var cfg: Dictionary = (cfg_val as Dictionary).duplicate(true)
		if not bool(cfg.get("enabled_in_egg_shop", true)):
			print("[EggShop] Skipping: ", species_id, " biome=", biome_id, " -> disabled in shop config")
			continue
		print("[EggShop] Including: ", species_id, " biome=", biome_id)
		cfg["species_id"] = species_id
		cfg["biome_id"] = biome_id
		result.append(cfg)

	print("[EggShop] Total species available: ", result.size(), " | offers will be: ", result.size(), " x ", _quality_order.size(), " = ", result.size() * _quality_order.size())
	return result


func buy_species_egg(species_id: String, quality_id: String) -> Dictionary:
	var quality_val: Variant = _shop_qualities.get(quality_id, null)
	if typeof(quality_val) != TYPE_DICTIONARY:
		return {"success": false, "error_key": "egg_shop.no_species_available"}
	var quality: Dictionary = quality_val as Dictionary

	var available: Array = get_available_species_for_shop()
	var species_cfg: Dictionary = {}
	for sv in available:
		if typeof(sv) == TYPE_DICTIONARY and str((sv as Dictionary).get("species_id", "")) == species_id:
			species_cfg = sv as Dictionary
			break
	if species_cfg.is_empty():
		return {"success": false, "error_key": "egg_shop.locked_species"}

	var price: int = int(quality.get("price", 0))
	if not EconomySystem.can_afford("repticash", price):
		return {"success": false, "error_key": "egg_shop.not_enough_coins"}

	EconomySystem.spend_currency("repticash", price)

	var now: int = int(Time.get_unix_time_from_system())
	var rates_val: Variant = quality.get("drop_rates", {})
	var rates: Dictionary = rates_val as Dictionary if typeof(rates_val) == TYPE_DICTIONARY else {}
	var visual_assets: Array = ["res://assets/art/incubator/eggs/egg.png", "res://assets/art/incubator/eggs/egg_v2.png"]
	var egg: Dictionary = {
		"egg_id": _create_shop_egg_id(),
		"reptile_id": species_id,
		"source": "shop",
		"offer_quality": quality_id,
		"hidden_drop_rates": rates.duplicate(true),
		"incubation_time_hours": int(species_cfg.get("incubation_time_hours", int(_species_defaults.get("incubation_time_hours", 24)))),
		"egg_name_pl": str(species_cfg.get("egg_name_pl", "")),
		"egg_name_en": str(species_cfg.get("egg_name_en", "")),
		"visual_asset": visual_assets[randi() % visual_assets.size()],
		"in_container": false,
		"container_index": -1,
		"created_at": now
	}
	var storage: Dictionary = _read_storage()
	var stored_eggs: Array = storage.get("eggs", []) as Array
	stored_eggs.append(egg)
	storage["eggs"] = stored_eggs
	_write_storage(storage)
	SaveSystem.save_game()
	_inc_counter("incubator:total_eggs", 1)
	AchievementSystem.notify_progress_changed()
	return {"success": true, "species_id": species_id, "quality_id": quality_id, "egg_id": str(egg.get("egg_id", ""))}


func get_species_incubation(species_id: String) -> Dictionary:
	var val: Variant = _species_data.get(species_id, null)
	if typeof(val) == TYPE_DICTIONARY:
		return (val as Dictionary).duplicate(true)
	push_warning("IncubationSystem: no species config for '" + species_id + "', using defaults.")
	return _species_defaults.duplicate(true)


func get_incubation_time_hours(species_id: String) -> int:
	var cfg: Dictionary = get_species_incubation(species_id)
	var fallback: int = int(_species_defaults.get("incubation_time_hours", 24))
	return int(cfg.get("incubation_time_hours", fallback))


func get_egg_name(species_id: String, language: String) -> String:
	var cfg: Dictionary = get_species_incubation(species_id)
	var key: String = "egg_name_" + language
	var val: String = str(cfg.get(key, ""))
	if not val.is_empty():
		return val
	var other: String = "egg_name_en" if language == "pl" else "egg_name_pl"
	val = str(cfg.get(other, ""))
	if not val.is_empty():
		return val
	return species_id


func get_max_eggs_per_container() -> int:
	var base: int = int(_incubator_cfg.get("max_eggs_per_container", 10))
	if has_node("/root/IncubatorUpgradeSystem"):
		var sys: Node = get_node("/root/IncubatorUpgradeSystem")
		if sys.has_method("get_more_eggs_bonus"):
			base += int(sys.call("get_more_eggs_bonus"))
	return base


# ─── Public: container access ───────────────────────────────────────────

func get_containers() -> Dictionary:
	_tick_all_containers()
	return _read_containers()


func get_container(index: int) -> Dictionary:
	var containers: Dictionary = get_containers()
	var val: Variant = containers.get(str(index), null)
	if typeof(val) == TYPE_DICTIONARY:
		return (val as Dictionary).duplicate(true)
	return {}


func get_remaining_seconds(container: Dictionary) -> int:
	var required: int = int(container.get("required_active_seconds", 0))
	var completed: int = int(container.get("active_seconds_completed", 0))
	return max(0, required - completed)


# ─── Public: container actions ──────────────────────────────────────────

func load_eggs_into_container(container_index: int, egg_ids: Array, species_id: String) -> Dictionary:
	var containers: Dictionary = _read_containers()
	var key: String = str(container_index)
	var existing: Variant = containers.get(key, null)
	if typeof(existing) == TYPE_DICTIONARY:
		var st: String = str((existing as Dictionary).get("state", "empty"))
		if st != "empty":
			return {"success": false, "error_key": "incubation.error_already_started"}

	if egg_ids.size() < 1:
		return {"success": false, "error_key": "incubation.no_eggs_in_storage"}
	var max_eggs: int = get_max_eggs_per_container()
	if egg_ids.size() > max_eggs:
		return {"success": false, "error_key": "incubation.error_max_eggs"}

	var storage: Dictionary = _read_storage()
	var stored_eggs: Array = storage.get("eggs", []) as Array
	var available_by_id: Dictionary = {}
	for egg_val in stored_eggs:
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = egg_val as Dictionary
		var eid: String = str(egg.get("egg_id", ""))
		if not eid.is_empty() and not bool(egg.get("in_container", false)):
			available_by_id[eid] = egg

	for eid_v in egg_ids:
		var eid: String = str(eid_v)
		if not available_by_id.has(eid):
			return {"success": false, "error_key": "incubation.no_eggs_in_storage"}
		var egg: Dictionary = available_by_id[eid] as Dictionary
		if str(egg.get("reptile_id", "")) != species_id:
			return {"success": false, "error_key": "incubation.error_one_species"}

	for i in range(stored_eggs.size()):
		var egg_val: Variant = stored_eggs[i]
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = (egg_val as Dictionary).duplicate(true)
		var eid: String = str(egg.get("egg_id", ""))
		var ids_str: Array = []
		for v in egg_ids:
			ids_str.append(str(v))
		if ids_str.has(eid):
			egg["in_container"] = true
			egg["container_index"] = container_index
			stored_eggs[i] = egg
	storage["eggs"] = stored_eggs
	_write_storage(storage)

	var container: Dictionary = _empty_container()
	container["state"] = "loaded"
	container["species_id"] = species_id
	var ids_copy: Array = []
	for v in egg_ids:
		ids_copy.append(str(v))
	container["egg_instance_ids"] = ids_copy
	container["egg_count"] = egg_ids.size()
	container["incubation_time_hours"] = get_incubation_time_hours(species_id)
	container["required_active_seconds"] = container["incubation_time_hours"] * 3600
	containers[key] = container
	_write_containers(containers)
	SaveSystem.save_game()
	if egg_ids.size() >= get_max_eggs_per_container():
		_inc_counter("incubator:full_chamber_loads", 1)
		AchievementSystem.notify_progress_changed()
	return {"success": true}


func cancel_loaded_container(container_index: int) -> Dictionary:
	var containers: Dictionary = _read_containers()
	var key: String = str(container_index)
	var val: Variant = containers.get(key, null)
	if typeof(val) != TYPE_DICTIONARY:
		return {"success": false}
	var container: Dictionary = val as Dictionary
	if str(container.get("state", "")) != "loaded":
		return {"success": false, "error_key": "incubation.error_already_started"}
	_return_eggs_to_available(container)
	containers.erase(key)
	_write_containers(containers)
	SaveSystem.save_game()
	return {"success": true}


func start_incubation(container_index: int) -> Dictionary:
	var containers: Dictionary = _read_containers()
	var key: String = str(container_index)
	var val: Variant = containers.get(key, null)
	if typeof(val) != TYPE_DICTIONARY:
		return {"success": false}
	var container: Dictionary = val as Dictionary
	if str(container.get("state", "")) != "loaded":
		return {"success": false, "error_key": "incubation.error_already_started"}
	var egg_count: int = int(container.get("egg_count", 0))
	if egg_count < 1:
		return {"success": false, "error_key": "incubation.no_eggs_in_storage"}

	var now: int = int(Time.get_unix_time_from_system())
	var decay_rate: float = _get_humidity_decay_rate(egg_count)
	var humidity_start: float = float(_humidity_cfg.get("start_percent", 100))

	if has_node("/root/IncubatorUpgradeSystem"):
		var sys: Node = get_node("/root/IncubatorUpgradeSystem")
		if sys.has_method("get_incubation_time_multiplier"):
			var time_mult: float = float(sys.call("get_incubation_time_multiplier"))
			var base_seconds: int = int(container.get("required_active_seconds", 86400))
			container["required_active_seconds"] = max(10800, int(float(base_seconds) * time_mult))
		if sys.has_method("get_humidity_decay_multiplier"):
			var decay_mult: float = float(sys.call("get_humidity_decay_multiplier"))
			decay_rate = decay_rate * decay_mult

	container["state"] = "running"
	container["humidity_percent"] = humidity_start
	container["humidity_decay_rate_per_hour"] = decay_rate
	container["started_at"] = now
	container["last_updated_at"] = now
	container["active_seconds_completed"] = 0
	container["is_closed"] = true
	containers[key] = container
	_write_containers(containers)
	SaveSystem.save_game()
	return {"success": true}


func water_container(container_index: int) -> Dictionary:
	var containers: Dictionary = _read_containers()
	var key: String = str(container_index)
	var val: Variant = containers.get(key, null)
	if typeof(val) != TYPE_DICTIONARY:
		return {"success": false}
	var now: int = int(Time.get_unix_time_from_system())
	var container: Dictionary = (val as Dictionary).duplicate(true)
	container = _tick_container(container, now)
	var state: String = str(container.get("state", "empty"))
	if state == "failed_dry" or state == "empty" or state == "loaded" or state == "ready_to_hatch":
		containers[key] = container
		_write_containers(containers)
		return {"success": false, "error_key": "incubation.water_no_effect"}
	var pre_water_state: String = state
	var pre_water_humidity: float = float(container.get("humidity_percent", 0.0))
	container["humidity_percent"] = float(_humidity_cfg.get("start_percent", 100))
	container["state"] = "running"
	containers[key] = container
	_write_containers(containers)
	SaveSystem.save_game()
	var pause_below: float = float(_humidity_cfg.get("pause_below_percent", 50))
	if pre_water_state == "paused_low_humidity":
		_inc_counter("incubator:saves", 1)
		AchievementSystem.notify_progress_changed()
	elif pre_water_state == "running" and pre_water_humidity >= pause_below:
		_inc_counter("incubator:proactive_waters", 1)
		AchievementSystem.notify_progress_changed()
	return {"success": true}


func clear_failed_container(container_index: int) -> Dictionary:
	var containers: Dictionary = _read_containers()
	var key: String = str(container_index)
	var val: Variant = containers.get(key, null)
	if typeof(val) != TYPE_DICTIONARY:
		return {"success": false}
	var container: Dictionary = val as Dictionary
	if str(container.get("state", "")) != "failed_dry":
		return {"success": false}
	containers.erase(key)
	_write_containers(containers)
	SaveSystem.save_game()
	return {"success": true}


# ─── Public: egg shop ───────────────────────────────────────────────────

func buy_egg(offer_id: String) -> Dictionary:
	var offer: Dictionary = {}
	for ov in _shop_offers:
		if typeof(ov) != TYPE_DICTIONARY:
			continue
		var od: Dictionary = ov as Dictionary
		if str(od.get("id", "")) == offer_id:
			offer = od
			break
	if offer.is_empty():
		return {"success": false, "error_key": "egg_shop.no_species_available"}

	var price: int = int(offer.get("price", 0))
	if not EconomySystem.can_afford("repticash", price):
		return {"success": false, "error_key": "egg_shop.not_enough_coins"}

	var species_mode: String = str(offer.get("species_mode", "unlocked_species_pool"))
	var species_id: String = ""
	if species_mode == "unlocked_species_pool":
		species_id = _pick_random_unlocked_species()
	elif species_mode == "fixed_species":
		species_id = str(offer.get("species_id", ""))
	if species_id.is_empty():
		return {"success": false, "error_key": "egg_shop.no_species_available"}

	EconomySystem.spend_currency("repticash", price)

	var now: int = int(Time.get_unix_time_from_system())
	var rates_val: Variant = offer.get("drop_rates", {})
	var rates: Dictionary = rates_val as Dictionary if typeof(rates_val) == TYPE_DICTIONARY else {}
	var egg: Dictionary = {
		"egg_id": _create_shop_egg_id(),
		"reptile_id": species_id,
		"source": "shop",
		"hidden_drop_rates": rates.duplicate(true),
		"in_container": false,
		"container_index": -1,
		"created_at": now
	}
	var storage: Dictionary = _read_storage()
	var stored_eggs: Array = storage.get("eggs", []) as Array
	stored_eggs.append(egg)
	storage["eggs"] = stored_eggs
	_write_storage(storage)
	SaveSystem.save_game()
	_inc_counter("incubator:total_eggs", 1)
	AchievementSystem.notify_progress_changed()
	return {"success": true, "species_id": species_id, "egg_id": str(egg.get("egg_id", ""))}


# ─── Public: storage helpers ────────────────────────────────────────────

func get_available_storage_eggs() -> Array:
	var storage: Dictionary = _read_storage()
	var all_eggs: Array = storage.get("eggs", []) as Array
	var result: Array = []
	for egg_val in all_eggs:
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = egg_val as Dictionary
		if not bool(egg.get("in_container", false)):
			result.append(egg.duplicate(true))
	return result


func get_eggs_by_species() -> Dictionary:
	var available: Array = get_available_storage_eggs()
	var groups: Dictionary = {}
	for egg_val in available:
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = egg_val as Dictionary
		var sid: String = str(egg.get("reptile_id", ""))
		if sid.is_empty():
			continue
		if not groups.has(sid):
			groups[sid] = []
		(groups[sid] as Array).append(egg)
	return groups


# ─── Tick logic ─────────────────────────────────────────────────────────

func _tick_all_containers() -> void:
	var containers: Dictionary = _read_containers()
	var now: int = int(Time.get_unix_time_from_system())
	var changed: bool = false
	for key in containers.keys():
		var val: Variant = containers.get(key)
		if typeof(val) != TYPE_DICTIONARY:
			continue
		var container: Dictionary = val as Dictionary
		var state: String = str(container.get("state", "empty"))
		if state == "running" or state == "paused_low_humidity":
			var updated: Dictionary = _tick_container(container, now)
			containers[key] = updated
			changed = true
	if changed:
		_write_containers(containers)


func _tick_container(container: Dictionary, now: int) -> Dictionary:
	var c: Dictionary = container.duplicate(true)
	var state: String = str(c.get("state", "empty"))
	var last_updated: int = int(c.get("last_updated_at", now))
	var elapsed: float = float(max(0, now - last_updated))
	if elapsed < 1.0:
		return c

	var pause_below: float = float(_humidity_cfg.get("pause_below_percent", 50))

	if state == "running":
		var humidity: float = float(c.get("humidity_percent", 100.0))
		var decay_rate: float = float(c.get("humidity_decay_rate_per_hour", 10.0))
		var active_completed: float = float(c.get("active_seconds_completed", 0))
		var required: float = float(c.get("required_active_seconds", 86400))

		var secs_to_dry: float = (humidity / decay_rate) * 3600.0 if decay_rate > 0.0 else 9999999.0
		var secs_to_pause: float = 0.0
		if humidity > pause_below:
			secs_to_pause = ((humidity - pause_below) / decay_rate) * 3600.0 if decay_rate > 0.0 else 9999999.0

		var new_humidity: float = maxf(humidity - (decay_rate * (elapsed / 3600.0)), 0.0)
		var remaining_active: float = required - active_completed

		if secs_to_dry <= elapsed:
			var active_before_dry: float = min(secs_to_dry, secs_to_pause)
			if remaining_active <= active_before_dry:
				# Completes before drying
				c["active_seconds_completed"] = required
				c["state"] = "ready_to_hatch"
				c["ready_at"] = last_updated + int(remaining_active)
				c["completed_at"] = c["ready_at"]
				if bool(_humidity_cfg.get("stop_decay_when_ready", true)):
					c["humidity_percent"] = maxf(humidity - (decay_rate * (remaining_active / 3600.0)), 0.0)
				else:
					c["humidity_percent"] = 0.0
			else:
				# Eggs dry out
				c["failed_at"] = last_updated + int(secs_to_dry)
				c["state"] = "failed_dry"
				c["humidity_percent"] = 0.0
				_destroy_eggs_in_container(c)
		else:
			var active_elapsed: float = min(elapsed, secs_to_pause) if humidity > pause_below else 0.0
			var new_active: float = active_completed + active_elapsed
			if new_active >= required:
				c["active_seconds_completed"] = required
				c["state"] = "ready_to_hatch"
				c["ready_at"] = last_updated + int(remaining_active)
				c["completed_at"] = c["ready_at"]
				c["humidity_percent"] = new_humidity
			elif new_humidity < pause_below:
				c["active_seconds_completed"] = new_active
				c["humidity_percent"] = new_humidity
				c["state"] = "paused_low_humidity"
			else:
				c["active_seconds_completed"] = new_active
				c["humidity_percent"] = new_humidity

	elif state == "paused_low_humidity":
		var humidity: float = float(c.get("humidity_percent", 0.0))
		var decay_rate: float = float(c.get("humidity_decay_rate_per_hour", 10.0))
		var new_humidity: float = maxf(humidity - (decay_rate * (elapsed / 3600.0)), 0.0)
		c["humidity_percent"] = new_humidity
		if new_humidity <= 0.0:
			var secs_to_dry: float = (humidity / decay_rate) * 3600.0 if decay_rate > 0.0 else 0.0
			c["failed_at"] = last_updated + int(secs_to_dry)
			c["state"] = "failed_dry"
			_destroy_eggs_in_container(c)

	c["last_updated_at"] = now
	return c


# ─── Private helpers ────────────────────────────────────────────────────

func _empty_container() -> Dictionary:
	return {
		"state": "empty",
		"species_id": "",
		"egg_instance_ids": [],
		"egg_count": 0,
		"incubation_time_hours": 0,
		"required_active_seconds": 0,
		"active_seconds_completed": 0,
		"started_at": 0,
		"last_updated_at": 0,
		"completed_at": 0,
		"humidity_percent": 100.0,
		"humidity_decay_rate_per_hour": 10.0,
		"failed_at": 0,
		"ready_at": 0,
		"is_closed": false
	}


func _read_containers() -> Dictionary:
	var val: Variant = GameState.get_value("incubation_containers", {})
	if typeof(val) == TYPE_DICTIONARY:
		return (val as Dictionary).duplicate(true)
	return {}


func _write_containers(containers: Dictionary) -> void:
	GameState.set_value("incubation_containers", containers)


func _read_storage() -> Dictionary:
	var val: Variant = GameState.get_value("incubator_storage", {})
	if typeof(val) == TYPE_DICTIONARY:
		return (val as Dictionary).duplicate(true)
	return {"reptiles": [], "eggs": [], "hatchlings": []}


func _write_storage(storage: Dictionary) -> void:
	GameState.set_value("incubator_storage", storage)


func _destroy_eggs_in_container(container: Dictionary) -> void:
	var ids: Array = container.get("egg_instance_ids", []) as Array
	if ids.is_empty():
		return
	var ids_str: Dictionary = {}
	for v in ids:
		ids_str[str(v)] = true
	var storage: Dictionary = _read_storage()
	var all_eggs: Array = storage.get("eggs", []) as Array
	var new_eggs: Array = []
	for egg_val in all_eggs:
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = egg_val as Dictionary
		if not ids_str.has(str(egg.get("egg_id", ""))):
			new_eggs.append(egg)
	storage["eggs"] = new_eggs
	_write_storage(storage)


func _return_eggs_to_available(container: Dictionary) -> void:
	var ids: Array = container.get("egg_instance_ids", []) as Array
	if ids.is_empty():
		return
	var ids_str: Dictionary = {}
	for v in ids:
		ids_str[str(v)] = true
	var storage: Dictionary = _read_storage()
	var all_eggs: Array = storage.get("eggs", []) as Array
	for i in range(all_eggs.size()):
		var egg_val: Variant = all_eggs[i]
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = (egg_val as Dictionary).duplicate(true)
		if ids_str.has(str(egg.get("egg_id", ""))):
			egg["in_container"] = false
			egg["container_index"] = -1
			all_eggs[i] = egg
	storage["eggs"] = all_eggs
	_write_storage(storage)


func _pick_random_unlocked_species() -> String:
	var accessible: Dictionary = _get_accessible_biome_ids()
	var all_reptiles: Array = ReptileSystem.reptiles
	var candidates: Array = []
	for rv in all_reptiles:
		if typeof(rv) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = rv as Dictionary
		if accessible.has(str(r.get("biome_id", ""))):
			candidates.append(str(r.get("id", "")))
	if candidates.is_empty():
		push_warning("IncubationSystem: no unlocked species available.")
		return ""
	return candidates[randi() % candidates.size()]


func _get_humidity_decay_rate(egg_count: int) -> float:
	var base: float = float(_humidity_cfg.get("base_decay_per_hour", 10.0))
	var mults_val: Variant = _humidity_cfg.get("egg_count_multipliers", [])
	if typeof(mults_val) != TYPE_ARRAY:
		return base
	for mv in (mults_val as Array):
		if typeof(mv) != TYPE_DICTIONARY:
			continue
		var m: Dictionary = mv as Dictionary
		if egg_count >= int(m.get("min", 1)) and egg_count <= int(m.get("max", 10)):
			return base * float(m.get("multiplier", 1.0))
	return base


func _create_shop_egg_id() -> String:
	return "shop_egg_" + str(int(Time.get_unix_time_from_system())) + "_" + str(randi() % 100000)


# ─── Public: hatch ──────────────────────────────────────────────────────

func hatch_batch(container_index: int) -> Dictionary:
	var containers: Dictionary = _read_containers()
	var key: String = str(container_index)
	var val: Variant = containers.get(key, null)
	if typeof(val) != TYPE_DICTIONARY:
		return {"success": false, "error_key": "hatch.error_incomplete"}
	var container: Dictionary = (val as Dictionary).duplicate(true)

	if str(container.get("state", "")) != "ready_to_hatch":
		return {"success": false, "error_key": "hatch.error_incomplete"}
	if bool(container.get("hatch_in_progress", false)):
		return {"success": false, "error_key": "hatch.already_collected"}

	container["hatch_in_progress"] = true
	containers[key] = container
	_write_containers(containers)

	var egg_ids: Array = container.get("egg_instance_ids", []) as Array
	var species_id: String = str(container.get("species_id", ""))
	if egg_ids.is_empty() or species_id.is_empty():
		container["hatch_in_progress"] = false
		containers[key] = container
		_write_containers(containers)
		return {"success": false, "error_key": "hatch.error_incomplete"}

	var storage: Dictionary = _read_storage()
	var all_eggs: Array = storage.get("eggs", []) as Array
	var egg_map: Dictionary = {}
	for egg_val in all_eggs:
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = egg_val as Dictionary
		egg_map[str(egg.get("egg_id", ""))] = egg

	var hatch_results: Array = []
	var new_instances: Array = []
	var now: int = int(Time.get_unix_time_from_system())

	for eid_v in egg_ids:
		var eid: String = str(eid_v)
		var egg: Dictionary = {}
		if egg_map.has(eid):
			egg = egg_map[eid] as Dictionary
		else:
			push_warning("IncubationSystem: egg " + eid + " not in storage, skipping.")
			continue
		var rarity: String = _roll_egg_rarity(egg)
		var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(species_id, rarity)
		if variant.is_empty():
			push_warning("IncubationSystem: no variant for " + species_id + "/" + rarity + ", trying fallback.")
			variant = _fallback_variant(species_id, rarity)
		if variant.is_empty():
			push_warning("IncubationSystem: no valid variant for egg " + eid + ", skipping.")
			continue
		var variant_id: String = str(variant.get("id", species_id + "_" + rarity))
		var sex: String = "female" if randf() < 0.5 else "male"
		var instance_id: String = _create_hatchling_id(species_id)
		print("[Hatch] egg=", eid, " species=", species_id, " rarity=", rarity, " variant_id=", variant_id, " sex=", sex)
		var instance: Dictionary = GameState.get_default_animal_instance(instance_id)
		instance["instance_id"] = instance_id
		instance["animal_instance_id"] = instance_id
		instance["reptile_id"] = species_id
		instance["species_id"] = species_id
		instance["variant_id"] = variant_id
		instance["rarity"] = rarity
		instance["sex"] = sex
		instance["source"] = "incubation"
		instance["created_at"] = now
		instance["habitat_id"] = null
		instance["source_egg_id"] = eid
		var parent_a: String = str(egg.get("parent_a_id", ""))
		var parent_b: String = str(egg.get("parent_b_id", ""))
		if not parent_a.is_empty():
			instance["parent_a_id"] = parent_a
		if not parent_b.is_empty():
			instance["parent_b_id"] = parent_b
		new_instances.append(instance)
		var is_new: bool = not _is_variant_discovered(variant_id)
		hatch_results.append({
			"instance_id": instance_id,
			"species_id": species_id,
			"variant_id": variant_id,
			"rarity": rarity,
			"sex": sex,
			"is_new_discovery": is_new,
			"portrait_path": str(variant.get("portrait_path", ""))
		})

	if new_instances.is_empty():
		container["hatch_in_progress"] = false
		containers[key] = container
		_write_containers(containers)
		return {"success": false, "error_key": "hatch.error_generic"}

	var owned: Dictionary = ReptileSystem.get_owned_reptile_instances()
	for inst in new_instances:
		owned[str(inst.get("instance_id", ""))] = inst
	GameState.set_value("owned_reptile_instances", owned)

	for result_val in hatch_results:
		if typeof(result_val) == TYPE_DICTIONARY:
			_mark_variant_discovered(str((result_val as Dictionary).get("variant_id", "")))

	storage = _read_storage()
	all_eggs = storage.get("eggs", []) as Array
	var consumed_ids: Dictionary = {}
	for eid_v in egg_ids:
		consumed_ids[str(eid_v)] = true
	var remaining_eggs: Array = []
	for egg_val in all_eggs:
		if typeof(egg_val) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = egg_val as Dictionary
		if not consumed_ids.has(str(egg.get("egg_id", ""))):
			remaining_eggs.append(egg)
	storage["eggs"] = remaining_eggs
	var storage_reptiles: Array = storage.get("reptiles", []) as Array
	for inst in new_instances:
		var sid: String = str(inst.get("instance_id", ""))
		print("[Hatch→Storage] id=", sid, " species=", inst.get("species_id", ""), " rarity=", inst.get("rarity", ""), " variant_id=", inst.get("variant_id", ""))
		storage_reptiles.append({"instance_id": sid, "source": "incubation"})
	storage["reptiles"] = storage_reptiles
	_write_storage(storage)

	containers = _read_containers()
	containers.erase(key)
	_write_containers(containers)
	SaveSystem.save_game()
	_inc_counter("incubator:total_hatches", new_instances.size())
	for result_val in hatch_results:
		if typeof(result_val) == TYPE_DICTIONARY:
			match str((result_val as Dictionary).get("rarity", "")):
				"rare":       _inc_counter("incubator:rare_hatches", 1)
				"ultra_rare": _inc_counter("incubator:ultra_rare_hatches", 1)
				"exceptional": _inc_counter("incubator:exceptional_hatches", 1)
	AchievementSystem.notify_progress_changed()
	return {"success": true, "results": hatch_results}


# ─── Public: dev helpers ─────────────────────────────────────────────────

func skip_all_incubations() -> void:
	var containers: Dictionary = _read_containers()
	var now: int = int(Time.get_unix_time_from_system())
	var changed: bool = false
	for ckey in containers.keys():
		var val: Variant = containers.get(ckey)
		if typeof(val) != TYPE_DICTIONARY:
			continue
		var container: Dictionary = (val as Dictionary).duplicate(true)
		var state: String = str(container.get("state", "empty"))
		if state == "loaded":
			var egg_count: int = int(container.get("egg_count", 0))
			container["state"] = "running"
			container["humidity_percent"] = float(_humidity_cfg.get("start_percent", 100))
			container["humidity_decay_rate_per_hour"] = _get_humidity_decay_rate(egg_count)
			container["started_at"] = now
			container["last_updated_at"] = now
			container["active_seconds_completed"] = 0
			container["is_closed"] = true
			state = "running"
		if state == "running" or state == "paused_low_humidity":
			var required: int = int(container.get("required_active_seconds", 86400))
			container["active_seconds_completed"] = required
			container["state"] = "ready_to_hatch"
			container["ready_at"] = now
			container["completed_at"] = now
			container["last_updated_at"] = now
			containers[ckey] = container
			changed = true
	if changed:
		_write_containers(containers)
		SaveSystem.save_game()


# ─── Private: hatch helpers ──────────────────────────────────────────────

func _roll_egg_rarity(egg: Dictionary) -> String:
	var rates_val: Variant = egg.get("hidden_drop_rates", null)
	if typeof(rates_val) == TYPE_DICTIONARY and not (rates_val as Dictionary).is_empty():
		return _roll_weighted_rarity(rates_val as Dictionary)
	var pre: String = ReptileSystem.normalize_rarity(str(egg.get("rarity", "")))
	if not pre.is_empty():
		return pre
	push_warning("IncubationSystem: egg has no rarity/rates, using fallback.")
	return _roll_weighted_rarity({"common": 60, "rare": 30, "ultra_rare": 7, "exceptional": 3})


func _roll_weighted_rarity(rates: Dictionary) -> String:
	var total: float = 0.0
	for r in ["common", "rare", "ultra_rare", "exceptional"]:
		total += float(rates.get(r, 0.0))
	if total <= 0.0:
		return "common"
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for r in ["common", "rare", "ultra_rare", "exceptional"]:
		cumulative += float(rates.get(r, 0.0))
		if roll <= cumulative:
			return r
	return "common"


func _fallback_variant(species_id: String, failed_rarity: String) -> Dictionary:
	var order: Array = ["exceptional", "ultra_rare", "rare", "common"]
	var start_idx: int = order.find(failed_rarity)
	if start_idx < 0:
		start_idx = 0
	for i in range(start_idx + 1, order.size()):
		var v: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(species_id, order[i])
		if not v.is_empty():
			return v
	return {}


func _is_variant_discovered(variant_id: String) -> bool:
	var disc: Variant = GameState.get_value("discovered_variants", {})
	if typeof(disc) != TYPE_DICTIONARY:
		return false
	return bool((disc as Dictionary).get(variant_id, false))


func _mark_variant_discovered(variant_id: String) -> void:
	if variant_id.is_empty():
		return
	var disc: Variant = GameState.get_value("discovered_variants", {})
	var d: Dictionary = disc as Dictionary if typeof(disc) == TYPE_DICTIONARY else {}
	d[variant_id] = true
	GameState.set_value("discovered_variants", d)
	print("[Gallery] discovered variant_id=", variant_id)


func _create_hatchling_id(species_id: String) -> String:
	return "hatch_" + species_id + "_" + str(int(Time.get_unix_time_from_system())) + "_" + str(randi() % 100000)


func _inc_counter(counter_id: String, amount: int) -> void:
	var counters_val: Variant = GameState.get_value("quest_event_counters", {})
	var counters: Dictionary = counters_val as Dictionary if typeof(counters_val) == TYPE_DICTIONARY else {}
	counters[counter_id] = int(counters.get(counter_id, 0)) + amount
	GameState.set_value("quest_event_counters", counters)
