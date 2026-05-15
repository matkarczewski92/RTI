extends Node

signal workers_changed
signal worker_effect_applied(worker_id: String, affected_count: int)

const WORKERS_PATH := "res://data/workers.json"
const PROCESS_TICK_SECONDS := 1.0

var workers: Array = []
var worker_by_id: Dictionary = {}
var worker_timer: Timer


func _ready() -> void:
	load_data()
	call_deferred("migrate_save_state")
	call_deferred("_start_worker_timer")


func load_data() -> bool:
	var file: FileAccess = FileAccess.open(WORKERS_PATH, FileAccess.READ)
	if file == null:
		workers = []
		worker_by_id = {}
		push_warning("Missing workers data file: " + WORKERS_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		workers = []
		worker_by_id = {}
		push_warning("Invalid workers data file: " + WORKERS_PATH)
		return false

	workers = []
	worker_by_id = {}
	for worker_value in (parsed as Array):
		if typeof(worker_value) != TYPE_DICTIONARY:
			continue
		var worker: Dictionary = _normalize_worker_definition(worker_value as Dictionary)
		if str(worker.get("id", "")).is_empty():
			continue
		workers.append(worker)
		worker_by_id[str(worker.get("id", ""))] = worker

	return true


func migrate_save_state() -> bool:
	var changed := false
	var workers_state_value: Variant = GameState.get_value("workers", {})
	if typeof(workers_state_value) != TYPE_DICTIONARY:
		GameState.set_value("workers", {})
		changed = true

	var workers_state: Dictionary = GameState.get_value("workers", {}) as Dictionary
	for worker_id in workers_state.keys():
		var state_value: Variant = workers_state.get(worker_id)
		if typeof(state_value) != TYPE_DICTIONARY:
			workers_state.erase(worker_id)
			changed = true
			continue

		var state: Dictionary = state_value as Dictionary
		var normalized: Dictionary = _normalize_worker_state(str(worker_id), state)
		if normalized != state:
			workers_state[worker_id] = normalized
			changed = true

	if changed:
		GameState.set_value("workers", workers_state)
		SaveSystem.save_game()

	return changed


func get_worker_definitions(include_disabled: bool = false) -> Array:
	var result: Array = []
	for worker_value in workers:
		if typeof(worker_value) != TYPE_DICTIONARY:
			continue
		var worker: Dictionary = worker_value as Dictionary
		if not include_disabled and not bool(worker.get("enabled", true)):
			continue
		result.append(worker)
	return result


func get_worker_definition(worker_id: String) -> Dictionary:
	var value: Variant = worker_by_id.get(worker_id, {})
	if typeof(value) == TYPE_DICTIONARY:
		return value as Dictionary
	return {}


func get_worker_state(worker_id: String) -> Dictionary:
	var workers_state_value: Variant = GameState.get_value("workers", {})
	if typeof(workers_state_value) != TYPE_DICTIONARY:
		return _make_default_worker_state()

	var workers_state: Dictionary = workers_state_value as Dictionary
	var state_value: Variant = workers_state.get(worker_id, {})
	if typeof(state_value) != TYPE_DICTIONARY:
		return _make_default_worker_state()

	return _normalize_worker_state(worker_id, state_value as Dictionary)


func get_worker_level(worker_id: String) -> int:
	return int(get_worker_state(worker_id).get("level", 0))


func get_next_cost(worker_id: String) -> int:
	var worker: Dictionary = get_worker_definition(worker_id)
	if worker.is_empty():
		return -1

	var level: int = get_worker_level(worker_id)
	var max_level: int = int(worker.get("max_level", 1))
	if level >= max_level:
		return -1

	var base_cost: float = float(worker.get("base_cost", 0))
	var multiplier: float = max(1.0, float(worker.get("cost_multiplier", 1.0)))
	return int(round(base_cost * pow(multiplier, level)))


func buy_or_upgrade_worker(worker_id: String) -> Dictionary:
	var worker: Dictionary = get_worker_definition(worker_id)
	if worker.is_empty() or not bool(worker.get("enabled", true)):
		return {"success": false, "message_key": "workers.unavailable"}

	var level: int = get_worker_level(worker_id)
	var max_level: int = int(worker.get("max_level", 1))
	if level >= max_level:
		return {"success": false, "message_key": "ui.worker_max"}

	var cost: int = get_next_cost(worker_id)
	if cost > 0 and not EconomySystem.can_afford("repticash", cost):
		return {"success": false, "message_key": "ui.not_enough_currency", "cost": cost}

	if cost > 0 and not EconomySystem.spend_currency("repticash", cost):
		return {"success": false, "message_key": "ui.not_enough_currency", "cost": cost}

	var workers_state: Dictionary = GameState.get_value("workers", {}) as Dictionary
	var state: Dictionary = get_worker_state(worker_id)
	var now: int = Time.get_unix_time_from_system()
	state["level"] = level + 1
	state["last_processed_at"] = now
	workers_state[worker_id] = state
	GameState.set_value("workers", workers_state)
	SaveSystem.save_game()
	_notify_progress_changed()
	workers_changed.emit()
	return {"success": true, "worker_id": worker_id, "level": level + 1, "cost": cost}


func get_worker_interval(worker_id: String, level: int = -1) -> int:
	var worker: Dictionary = get_worker_definition(worker_id)
	if worker.is_empty():
		return 0
	if level < 0:
		level = get_worker_level(worker_id)
	if level <= 0:
		return int(worker.get("base_interval_sec", 0))

	var base_interval: int = int(worker.get("base_interval_sec", 0))
	var minimum: int = int(worker.get("min_interval_sec", base_interval))
	var reduction: int = int(worker.get("interval_reduction_per_level", 0))
	return int(max(minimum, base_interval - ((level - 1) * reduction)))


func get_worker_effect_value(worker_id: String, level: int = -1) -> float:
	var worker: Dictionary = get_worker_definition(worker_id)
	if worker.is_empty():
		return 0.0
	if level < 0:
		level = get_worker_level(worker_id)
	if level <= 0:
		return 0.0

	var effect_value: float = float(worker.get("base_effect_value", 0.0)) + (float(level - 1) * float(worker.get("effect_increase_per_level", 0.0)))
	if str(worker.get("type", "")) != "manager" and has_node("/root/UpgradeSystem"):
		var upgrade_system: Node = get_node("/root/UpgradeSystem")
		if upgrade_system.has_method("get_worker_efficiency_multiplier"):
			effect_value *= float(upgrade_system.call("get_worker_efficiency_multiplier"))

	return effect_value


func get_worker_threshold(worker_id: String) -> float:
	var worker: Dictionary = get_worker_definition(worker_id)
	if worker.is_empty():
		return 0.0
	return float(worker.get("threshold_value", 0.0))


func get_manager_income_multiplier() -> float:
	var manager_level: int = get_worker_level("worker_manager")
	if manager_level <= 0:
		return 1.0

	return 1.0 + get_worker_effect_value("worker_manager", manager_level)


func process_workers() -> bool:
	migrate_save_state()
	var now: int = Time.get_unix_time_from_system()
	var workers_state: Dictionary = GameState.get_value("workers", {}) as Dictionary
	var changed := false
	var effect_changed := false

	for worker in get_worker_definitions(false):
		var worker_id: String = str(worker.get("id", ""))
		var worker_type: String = str(worker.get("type", ""))
		if worker_type == "manager":
			continue

		var state: Dictionary = get_worker_state(worker_id)
		var level: int = int(state.get("level", 0))
		if level <= 0:
			continue

		var interval: int = get_worker_interval(worker_id, level)
		if interval <= 0:
			continue

		var last_processed_at: int = int(state.get("last_processed_at", 0))
		if last_processed_at <= 0:
			state["last_processed_at"] = now
			workers_state[worker_id] = state
			changed = true
			continue
		if now - last_processed_at < interval:
			continue

		var affected: int = _apply_worker_effect(worker_id, worker_type, level)
		state["last_processed_at"] = now
		workers_state[worker_id] = state
		changed = true
		if affected > 0:
			effect_changed = true
			worker_effect_applied.emit(worker_id, affected)

	if changed:
		GameState.set_value("workers", workers_state)
		SaveSystem.save_game()
	if effect_changed:
		workers_changed.emit()

	return effect_changed


func _start_worker_timer() -> void:
	if worker_timer != null and is_instance_valid(worker_timer):
		return

	worker_timer = Timer.new()
	worker_timer.name = "WorkerTimer"
	worker_timer.wait_time = PROCESS_TICK_SECONDS
	worker_timer.autostart = true
	worker_timer.timeout.connect(process_workers)
	add_child(worker_timer)


func _apply_worker_effect(worker_id: String, worker_type: String, level: int) -> int:
	var affected := 0
	var threshold: float = get_worker_threshold(worker_id)
	var effect_value: float = get_worker_effect_value(worker_id, level)
	if effect_value <= 0.0:
		return 0

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	for instance_id_value in instances.keys():
		var instance_id: String = str(instance_id_value)
		if ReptileSystem.apply_worker_care_effect(instance_id, worker_type, threshold, effect_value):
			affected += 1

	return affected


func _normalize_worker_definition(worker: Dictionary) -> Dictionary:
	var normalized: Dictionary = worker.duplicate(true)
	normalized["id"] = str(normalized.get("id", ""))
	normalized["name_key"] = str(normalized.get("name_key", normalized.get("id", "")))
	normalized["description_key"] = str(normalized.get("description_key", normalized.get("id", "")))
	normalized["icon_path"] = str(normalized.get("icon_path", ""))
	normalized["type"] = str(normalized.get("type", ""))
	normalized["base_cost"] = int(max(0, int(normalized.get("base_cost", 0))))
	normalized["cost_multiplier"] = float(max(1.0, float(normalized.get("cost_multiplier", 1.0))))
	normalized["max_level"] = int(max(1, int(normalized.get("max_level", 1))))
	normalized["base_interval_sec"] = int(max(0, int(normalized.get("base_interval_sec", 0))))
	normalized["min_interval_sec"] = int(max(0, int(normalized.get("min_interval_sec", 0))))
	normalized["interval_reduction_per_level"] = int(max(0, int(normalized.get("interval_reduction_per_level", 0))))
	normalized["base_effect_value"] = float(max(0.0, float(normalized.get("base_effect_value", 0.0))))
	normalized["effect_increase_per_level"] = float(max(0.0, float(normalized.get("effect_increase_per_level", 0.0))))
	normalized["threshold_value"] = float(clamp(float(normalized.get("threshold_value", 0.0)), 0.0, 100.0))
	normalized["unlocked_by_default"] = bool(normalized.get("unlocked_by_default", true))
	normalized["enabled"] = bool(normalized.get("enabled", true))
	return normalized


func _normalize_worker_state(_worker_id: String, state: Dictionary) -> Dictionary:
	var normalized: Dictionary = state.duplicate(true)
	normalized["level"] = int(max(0, int(normalized.get("level", 0))))
	normalized["last_processed_at"] = int(max(0, int(normalized.get("last_processed_at", 0))))
	return normalized


func _make_default_worker_state() -> Dictionary:
	return {
		"level": 0,
		"last_processed_at": 0
	}


func _notify_progress_changed() -> void:
	if has_node("/root/QuestSystem"):
		var quest_system: Node = get_node("/root/QuestSystem")
		if quest_system.has_method("notify_event"):
			quest_system.call("notify_event", "state_changed", {})
