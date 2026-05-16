extends Node

const EGG_SHOP_PATH := "res://data/egg_shop.json"
const SPECIES_INCUBATION_PATH := "res://data/species_incubation.json"
const INCUBATOR_CONFIG_PATH := "res://data/incubator.json"

var _shop_offers: Array = []
var _species_data: Dictionary = {}
var _species_defaults: Dictionary = {"incubation_time_hours": 24, "egg_name_pl": "Jaja gadów", "egg_name_en": "Reptile Eggs"}
var _incubator_cfg: Dictionary = {}
var _humidity_cfg: Dictionary = {}


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
			var offers: Variant = (data as Dictionary).get("offers", [])
			if typeof(offers) == TYPE_ARRAY:
				_shop_offers = offers as Array
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


# ─── Public: config helpers ─────────────────────────────────────────────

func get_shop_offers() -> Array:
	return _shop_offers.duplicate(true)


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
	return int(_incubator_cfg.get("max_eggs_per_container", 10))


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
	container["humidity_percent"] = float(_humidity_cfg.get("start_percent", 100))
	container["state"] = "running"
	containers[key] = container
	_write_containers(containers)
	SaveSystem.save_game()
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
	var unlocked_val: Variant = GameState.get_value("unlocked_biomes", [])
	var unlocked: Array = unlocked_val as Array if typeof(unlocked_val) == TYPE_ARRAY else []
	var all_reptiles: Array = ReptileSystem.reptiles
	var candidates: Array = []
	for rv in all_reptiles:
		if typeof(rv) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = rv as Dictionary
		if unlocked.has(str(r.get("biome_id", ""))):
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
