extends Node
## One saved roll per departure; claiming never rolls again or starts incubation.

signal expeditions_changed
signal expedition_started(expedition: Dictionary)
signal expedition_claimed(expedition: Dictionary)

const CONFIG_PATH := "res://data/expeditions.json"
const RARITIES: Array[String] = ["common", "rare", "ultra_rare", "exceptional"]
var _config: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _transaction_active := false

func _ready() -> void:
	_rng.randomize()
	load_data()

func load_data() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	_config = parsed as Dictionary if parsed is Dictionary else {}
	return not _config.is_empty()

func get_regions() -> Array:
	return (_config.get("regions", []) as Array).duplicate(true)

func get_modes() -> Array:
	return (_config.get("modes", []) as Array).duplicate(true)

func get_slot_limit() -> int:
	return 2 if int(GameState.get_value("level", 1)) >= int(_config.get("second_slot_level", 8)) else 1

func get_region_state(region_id: String) -> Dictionary:
	var region: Dictionary = _definition("regions", region_id)
	if region.is_empty(): return {"unlocked": false, "region": {}, "unlock_level": 9999}
	var pool: Array[String] = _species_pool(region)
	var undiscovered := 0
	for species_id in pool:
		if not _species_discovered(species_id): undiscovered += 1
	return {
		"region": region, "unlocked": int(GameState.get_value("level", 1)) >= int(region.get("unlock_level", 1)),
		"unlock_level": int(region.get("unlock_level", 1)), "species_count": pool.size(),
		"undiscovered_species_count": undiscovered, "slot_limit": get_slot_limit(),
		"active_count": _active_records().size()
	}

func get_mode_chances(mode_id: String) -> Dictionary:
	return (_definition("modes", mode_id).get("rarity_chances", {}) as Dictionary).duplicate(true)

func get_reward_kind_chances() -> Dictionary:
	return (_config.get("reward_kind_chances", {"egg": 85, "reptile": 15}) as Dictionary).duplicate(true)

func get_expedition_cost(region_id: String, mode_id: String) -> Dictionary:
	var region: Dictionary = _definition("regions", region_id)
	var mode: Dictionary = _definition("modes", mode_id)
	if region.is_empty() or mode.is_empty(): return {}
	return {
		"cash": maxi(0, roundi(float(region.get("base_cash_cost", 0)) * float(mode.get("cash_multiplier", 1.0)))),
		"food": clampi(int(mode.get("food_cost", 0)), 0, 35),
		"water": clampi(int(mode.get("water_cost", 0)), 0, 35),
		"resource_biome_id": str(_config.get("resource_biome_id", "green_meadow"))
	}

func get_active_expeditions() -> Array:
	var result: Array = []
	for record: Dictionary in _active_records(): result.append(_public_record(record))
	return result

func get_history() -> Array:
	var records: Array = (GameState.get_value("expedition_log", []) as Array).duplicate(true)
	records.reverse()
	return records.slice(0, 20)

func get_remaining_seconds(expedition: Dictionary) -> int:
	return maxi(0, int(expedition.get("ends_at", 0)) - int(Time.get_unix_time_from_system()))

func start_expedition(region_id: String, mode_id: String) -> Dictionary:
	if _transaction_active: return _error("busy")
	var region: Dictionary = _definition("regions", region_id)
	var mode: Dictionary = _definition("modes", mode_id)
	if region.is_empty() or mode.is_empty(): return _error("unavailable")
	if not bool(get_region_state(region_id).get("unlocked", false)): return _error("locked")
	var active: Array = _active_records()
	if active.size() >= get_slot_limit(): return _error("no_slot")
	var pool: Array[String] = _species_pool(region)
	if pool.is_empty(): return _error("unavailable")
	var cost: Dictionary = get_expedition_cost(region_id, mode_id)
	if not EconomySystem.can_afford("repticash", int(cost["cash"])): return _error("not_enough_cash")
	var resource_biome: String = str(cost["resource_biome_id"])
	for resource in ["food", "water"]:
		if ReptileSystem.get_biome_resource_current(resource_biome, resource) < int(cost[resource]):
			return _error("not_enough_" + resource)
	var before: Dictionary = GameState.state.duplicate(true)
	var next: Dictionary = before.duplicate(true)
	var counter: int = int(next.get("expedition_counter", 0)) + 1
	var id := "expedition_%08d" % counter
	var now: int = int(Time.get_unix_time_from_system())
	var duration: int = maxi(1, int(mode.get("duration_seconds", 1800)))
	var species_id: String = _pick_species(pool)
	var kind: String = _roll(get_reward_kind_chances(), ["egg", "reptile"])
	var rarity: String = _roll(get_mode_chances(mode_id), RARITIES)
	var reward: Dictionary = {"kind": kind, "species_id": species_id, "rarity": rarity, "id": id + "_" + kind}
	if kind == "reptile": reward["sex"] = "female" if _rng.randf() < 0.5 else "male"
	var record: Dictionary = {
		"id": id, "region_id": region_id, "mode_id": mode_id, "started_at": now,
		"ends_at": now + duration, "duration_seconds": duration, "cost": cost.duplicate(true), "reward": reward
	}
	active.append(record)
	next["expeditions"] = active
	next["expedition_counter"] = counter
	next["repticash"] = float(next.get("repticash", 0)) - float(cost["cash"])
	var resources: Dictionary = next.get("biome_resources", {})
	var supplies: Dictionary = resources.get(resource_biome, {})
	for resource in ["food", "water"]:
		supplies[resource + "_current"] = int(supplies.get(resource + "_current", 0)) - int(cost[resource])
	resources[resource_biome] = supplies
	next["biome_resources"] = resources
	if not _commit(next, before): return _error("save_failed")
	EconomySystem.currency_changed.emit("repticash", EconomySystem.get_currency())
	var public: Dictionary = _public_record(record)
	expedition_started.emit(public)
	_notify_event("expedition_started", {"expedition_id": id, "region_id": region_id, "mode_id": mode_id, "duration_seconds": duration})
	return {"success": true, "expedition_id": id, "expedition": public}

func claim_expedition(expedition_id: String) -> Dictionary:
	if _transaction_active: return _error("busy")
	var active: Array = _active_records()
	var record: Dictionary = {}
	var index := -1
	for i in range(active.size()):
		if str((active[i] as Dictionary).get("id", "")) == expedition_id:
			record = active[i]
			index = i
			break
	if index < 0: return _error("already_claimed")
	if get_remaining_seconds(record) > 0: return _error("not_ready")
	var reward: Dictionary = (record.get("reward", {}) as Dictionary).duplicate(true)
	var species_id: String = str(reward.get("species_id", ""))
	var kind: String = str(reward.get("kind", ""))
	var rarity: String = str(reward.get("rarity", ""))
	if ReptileSystem.get_reptile(species_id).is_empty() or kind not in ["egg", "reptile"] or not RARITIES.has(rarity): return _error("unavailable")
	var before: Dictionary = GameState.state.duplicate(true)
	var next: Dictionary = before.duplicate(true)
	var now: int = int(Time.get_unix_time_from_system())
	# The persisted ledger and reward are committed together, before any signal.
	active.remove_at(index)
	next["expeditions"] = active
	record["claimed_at"] = now
	record["state"] = "claimed"
	var history: Array = (next.get("expedition_log", []) as Array).duplicate(true)
	history.append(record)
	next["expedition_log"] = history.slice(maxi(0, history.size() - 20))
	if kind == "egg":
		var storage: Dictionary = (next.get("incubator_storage", {}) as Dictionary).duplicate(true)
		var eggs: Array = (storage.get("eggs", []) as Array).duplicate(true)
		eggs.append({
			"egg_id": str(reward["id"]), "reptile_id": species_id, "rarity": rarity,
			"source": "expedition", "expedition_id": expedition_id, "created_at": now,
			"in_container": false, "container_index": -1,
			"incubation_time_hours": IncubationSystem.get_incubation_time_hours(species_id),
			"visual_asset": "res://assets/art/incubator/eggs/egg.png"
		})
		storage["eggs"] = eggs
		next["incubator_storage"] = storage
	else:
		var animal: Dictionary = GameState.get_default_animal_instance(str(reward["id"]))
		var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(species_id, rarity)
		animal.merge({"reptile_id": species_id, "species_id": species_id, "variant_id": str(variant.get("id", species_id + "_" + rarity)), "rarity": rarity, "sex": str(reward.get("sex", "female")), "source": "expedition", "expedition_id": expedition_id, "created_at": now}, true)
		var animals: Dictionary = (next.get("owned_reptile_instances", {}) as Dictionary).duplicate(true)
		animals[str(reward["id"])] = animal
		next["owned_reptile_instances"] = animals
		var discovered: Dictionary = (next.get("discovered_variants", {}) as Dictionary).duplicate(true)
		discovered[str(animal["variant_id"])] = true
		next["discovered_variants"] = discovered
	if not _commit(next, before): return _error("save_failed")
	if kind == "egg":
		QuestSystem.notify_event("incubator_egg_obtained", {"amount": 1, "source": "expedition"})
	else:
		AchievementSystem.notify_progress_changed()
	expedition_claimed.emit(record.duplicate(true))
	_notify_event("expedition_claimed", {"expedition_id": expedition_id, "region_id": str(record["region_id"]), "mode_id": str(record["mode_id"]), "reward_kind": kind, "species_id": species_id, "rarity": rarity})
	return {"success": true, "expedition_id": expedition_id, "reward": reward, "expedition": record.duplicate(true)}

func _commit(next: Dictionary, before: Dictionary) -> bool:
	_transaction_active = true
	GameState.state = next
	var saved: bool = SaveSystem.save_game()
	if not saved: GameState.state = before
	_transaction_active = false
	if saved:
		GameState.state_changed.emit()
		expeditions_changed.emit()
	return saved

func _public_record(record: Dictionary) -> Dictionary:
	var public: Dictionary = record.duplicate(true)
	public.erase("reward")
	public["remaining_seconds"] = get_remaining_seconds(record)
	public["state"] = "ready" if public["remaining_seconds"] == 0 else "running"
	return public

func _active_records() -> Array:
	return (GameState.get_value("expeditions", []) as Array).duplicate(true)

func _definition(collection: String, id: String) -> Dictionary:
	for entry: Dictionary in _config.get(collection, []):
		if str(entry.get("id", "")) == id: return entry.duplicate(true)
	return {}

func _species_pool(region: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for species in region.get("species_pool", []):
		if not ReptileSystem.get_reptile(str(species)).is_empty(): result.append(str(species))
	return result

func _species_discovered(species_id: String) -> bool:
	for rarity in RARITIES:
		var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(species_id, rarity)
		if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))): return true
	return false

func _pick_species(pool: Array[String]) -> String:
	var weights: Dictionary = {}
	for species_id in pool: weights[species_id] = 1 if _species_discovered(species_id) else maxi(1, int(_config.get("undiscovered_species_weight", 4)))
	return _roll(weights, pool)

func _roll(weights: Dictionary, order: Array) -> String:
	var total := 0.0
	for id in order: total += maxf(0.0, float(weights.get(id, 0)))
	if total <= 0.0: return str(order[0])
	var roll: float = _rng.randf() * total
	var cumulative := 0.0
	for id in order:
		cumulative += maxf(0.0, float(weights.get(id, 0)))
		if roll < cumulative: return str(id)
	return str(order.back())

func _error(reason: String) -> Dictionary:
	return {"success": false, "reason": reason, "error_key": "expeditions.error_" + reason}

func _notify_event(event: String, payload: Dictionary) -> void:
	QuestSystem.notify_event(event, payload)
