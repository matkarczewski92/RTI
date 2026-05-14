extends Node

signal currency_changed(currency_id: String, amount: Variant)
signal income_progress_updated(progress: float, time_left: int)
signal income_tick(amount: float)
signal offline_income_calculated(amount: float, seconds: int)
signal offline_income_claimed(amount: float)

const ECONOMY_PATH := "res://data/economy.json"
const INCOME_TICK_SECONDS := 60.0
const MAX_OFFLINE_SECONDS := 14400
const MIN_OFFLINE_SECONDS := 30

var economy_data: Dictionary = {}
var income_elapsed_seconds: float = 0.0
var income_timer: Timer


func _ready() -> void:
	load_economy_data()
	_start_active_income_timer()
	call_deferred("_initialize_offline_income")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_last_active_timestamp()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_calculate_offline_income_on_resume()


func load_economy_data() -> bool:
	var file: FileAccess = FileAccess.open(ECONOMY_PATH, FileAccess.READ)
	if file == null:
		economy_data = {}
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		economy_data = {}
		return false

	economy_data = parsed as Dictionary
	return true


func get_currency(currency_id: String = "repticash") -> Variant:
	return GameState.get_value(currency_id, 0)


func add_currency(currency_id: String, amount: float) -> void:
	if amount <= 0:
		return

	var new_amount: Variant = float(get_currency(currency_id)) + amount
	GameState.set_value(currency_id, new_amount)
	currency_changed.emit(currency_id, new_amount)


func can_afford(currency_id: String, amount: int) -> bool:
	return float(get_currency(currency_id)) >= float(amount)


func spend_currency(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true

	if not can_afford(currency_id, amount):
		return false

	var new_amount: Variant = float(get_currency(currency_id)) - float(amount)
	GameState.set_value(currency_id, new_amount)
	currency_changed.emit(currency_id, new_amount)
	return true


func get_total_assigned_income_per_min() -> float:
	return ReptileSystem.get_total_assigned_income_per_min()


func get_income_progress() -> float:
	return clamp(income_elapsed_seconds / INCOME_TICK_SECONDS, 0.0, 1.0)


func get_income_time_left() -> int:
	return int(ceil(max(0.0, INCOME_TICK_SECONDS - income_elapsed_seconds)))


func get_pending_offline_income() -> float:
	return float(GameState.get_value("pending_offline_income", 0.0))


func get_pending_offline_seconds() -> int:
	return int(GameState.get_value("pending_offline_seconds", 0))


func has_pending_offline_income() -> bool:
	return bool(GameState.get_value("offline_claim_available", false)) and get_pending_offline_income() > 0.0


func save_last_active_timestamp() -> void:
	GameState.set_value("last_active_timestamp", Time.get_unix_time_from_system())
	SaveSystem.save_game()


func claim_offline_income() -> float:
	if not has_pending_offline_income():
		return 0.0

	var amount: float = get_pending_offline_income()
	add_currency("repticash", amount)
	var now: float = Time.get_unix_time_from_system()
	GameState.set_value("pending_offline_income", 0.0)
	GameState.set_value("pending_offline_seconds", 0)
	GameState.set_value("offline_claim_available", false)
	GameState.set_value("last_offline_claim_timestamp", now)
	GameState.set_value("last_active_timestamp", now)
	SaveSystem.save_game()
	offline_income_claimed.emit(amount)
	return amount


func _start_active_income_timer() -> void:
	if income_timer != null and is_instance_valid(income_timer):
		return

	income_timer = Timer.new()
	income_timer.name = "ActiveIncomeTimer"
	income_timer.wait_time = 1.0
	income_timer.autostart = true
	income_timer.timeout.connect(_on_active_income_timer_timeout)
	add_child(income_timer)


func _on_active_income_timer_timeout() -> void:
	income_elapsed_seconds += 1.0
	if income_elapsed_seconds >= INCOME_TICK_SECONDS:
		_pay_active_income()
		income_elapsed_seconds = 0.0

	income_progress_updated.emit(get_income_progress(), get_income_time_left())


func _pay_active_income() -> void:
	var total_income: float = get_total_assigned_income_per_min()
	if total_income <= 0.0:
		return

	add_currency("repticash", total_income)
	SaveSystem.save_game()
	income_tick.emit(total_income)


func _initialize_offline_income() -> void:
	_migrate_offline_state()
	_calculate_offline_income_on_resume()


func _migrate_offline_state() -> void:
	var now: float = Time.get_unix_time_from_system()
	var changed := false

	if GameState.get_value("last_active_timestamp", null) == null:
		GameState.set_value("last_active_timestamp", now)
		changed = true
	if GameState.get_value("pending_offline_income", null) == null:
		GameState.set_value("pending_offline_income", 0.0)
		changed = true
	if GameState.get_value("pending_offline_seconds", null) == null:
		GameState.set_value("pending_offline_seconds", 0)
		changed = true
	if GameState.get_value("offline_claim_available", null) == null:
		GameState.set_value("offline_claim_available", false)
		changed = true
	if GameState.get_value("last_offline_claim_timestamp", null) == null:
		GameState.set_value("last_offline_claim_timestamp", 0)
		changed = true

	if changed:
		SaveSystem.save_game()


func _calculate_offline_income_on_resume() -> void:
	_migrate_offline_state()
	if has_pending_offline_income():
		offline_income_calculated.emit(get_pending_offline_income(), get_pending_offline_seconds())
		return

	var now: float = Time.get_unix_time_from_system()
	var last_active: float = float(GameState.get_value("last_active_timestamp", now))
	if last_active <= 0.0:
		GameState.set_value("last_active_timestamp", now)
		SaveSystem.save_game()
		return

	var offline_seconds: int = int(max(0.0, now - last_active))
	var effective_seconds: int = int(min(offline_seconds, MAX_OFFLINE_SECONDS))
	if effective_seconds < MIN_OFFLINE_SECONDS:
		GameState.set_value("last_active_timestamp", now)
		SaveSystem.save_game()
		return

	var total_income_per_min: float = get_total_assigned_income_per_min()
	if total_income_per_min <= 0.0:
		_clear_pending_offline_income(now)
		return

	var raw_reward: float = total_income_per_min * (float(effective_seconds) / 60.0)
	var reward: float = float(round(raw_reward))
	if reward <= 0.0:
		_clear_pending_offline_income(now)
		return

	GameState.set_value("pending_offline_income", reward)
	GameState.set_value("pending_offline_seconds", effective_seconds)
	GameState.set_value("offline_claim_available", true)
	GameState.set_value("last_active_timestamp", now)
	SaveSystem.save_game()
	offline_income_calculated.emit(reward, effective_seconds)


func _clear_pending_offline_income(now: float) -> void:
	GameState.set_value("pending_offline_income", 0.0)
	GameState.set_value("pending_offline_seconds", 0)
	GameState.set_value("offline_claim_available", false)
	GameState.set_value("last_active_timestamp", now)
	SaveSystem.save_game()


func get_purchased_habitat_count(biome_id: String) -> int:
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return 0

	var habitats: Dictionary = habitats_value as Dictionary
	var count: int = 0
	for habitat_key in habitats.keys():
		var habitat_value: Variant = habitats.get(habitat_key)
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = habitat_value as Dictionary
		if str(habitat.get("biome_id", "")) == biome_id and bool(habitat.get("purchased", false)):
			count += 1

	return count


func get_next_habitat_price(biome_id: String, total_habitat_count: int = -1) -> int:
	var purchased_count: int = get_purchased_habitat_count(biome_id)
	if total_habitat_count > -1 and purchased_count >= total_habitat_count:
		return -1

	var price_sequence: Array = _get_habitat_price_sequence(biome_id)
	if price_sequence.is_empty():
		return _get_fallback_habitat_price(purchased_count)

	var price_index: int = int(min(purchased_count, price_sequence.size() - 1))
	return int(price_sequence[price_index])


func _get_habitat_price_sequence(biome_id: String) -> Array:
	var sequences_value: Variant = economy_data.get("habitat_purchase_prices", {})
	if typeof(sequences_value) != TYPE_DICTIONARY:
		return []

	var sequences: Dictionary = sequences_value as Dictionary
	var sequence_value: Variant = sequences.get(biome_id, [])
	if typeof(sequence_value) != TYPE_ARRAY:
		return []

	return sequence_value as Array


func _get_fallback_habitat_price(purchased_count: int) -> int:
	return 100 + (int(max(purchased_count, 0)) * 50)
