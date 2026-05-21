extends Node
## ResourceAdService - optional rewarded-ad resource refill flow.

signal resource_ad_limit_changed(used: int, limit: int)
signal resource_reward_granted(action_id: String)

const CONFIG_PATH := "res://data/rewarded_ads.json"
const DEFAULT_ADD_RESOURCES_ICON_PATH := "res://assets/art/ui/icons/add_resources_ico.png"
const WINDOW_STARTED_KEY := "resource_ads_window_started_at"
const USED_COUNT_KEY := "resource_ads_used_count"
const REWARD_TIMESTAMPS_KEY := "resource_ads_reward_timestamps"

const ERROR_KEY_MAP := {
	"rewarded_speedup_error_no_internet": "resource_ads_error_no_internet",
	"rewarded_speedup_error_ad_unavailable": "resource_ads_error_ad_unavailable",
	"rewarded_speedup_error_ad_failed": "resource_ads_error_ad_failed",
	"rewarded_speedup_error_sdk_unavailable": "resource_ads_error_sdk_unavailable",
	"rewarded_speedup_error_closed_without_reward": "resource_ads_error_closed_without_reward"
}

var _config: Dictionary = {}
var _add_resources_icon_path: String = DEFAULT_ADD_RESOURCES_ICON_PATH
var _add_resources_icon_width: int = 96
var _add_resources_icon_height: int = 96
var _limit_count: int = 5
var _limit_window_hours: int = 24
var _money_reward_amount: int = 1000

var _request_active: bool = false
var _reward_callback_fired: bool = false
var _pending_action_id: String = ""


func _ready() -> void:
	_load_config()
	_normalize_usage_window(false)


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("ResourceAdService: rewarded_ads.json not found; using defaults.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("ResourceAdService: rewarded_ads.json malformed; using defaults.")
		return

	var root: Dictionary = parsed as Dictionary
	var ads_value: Variant = root.get("rewarded_ads", {})
	if typeof(ads_value) != TYPE_DICTIONARY:
		return

	_config = ads_value as Dictionary
	_add_resources_icon_path = str(_config.get("add_resources_icon_path", _add_resources_icon_path))
	_add_resources_icon_width = max(1, int(_config.get("add_resources_icon_width", _add_resources_icon_width)))
	_add_resources_icon_height = max(1, int(_config.get("add_resources_icon_height", _add_resources_icon_height)))
	_limit_count = max(1, int(_config.get("resource_ads_limit_count", _limit_count)))
	_limit_window_hours = max(1, int(_config.get("resource_ads_limit_window_hours", _limit_window_hours)))
	_money_reward_amount = max(1, int(_config.get("money_reward_amount", _money_reward_amount)))


func get_add_resources_icon_path() -> String:
	return _add_resources_icon_path


func get_add_resources_icon_size() -> Vector2:
	return Vector2(_add_resources_icon_width, _add_resources_icon_height)


func get_limit_count() -> int:
	return _limit_count


func get_money_reward_amount() -> int:
	return _money_reward_amount


func get_used_count() -> int:
	_normalize_usage_window(true)
	return int(clamp(int(GameState.get_value(USED_COUNT_KEY, 0)), 0, _limit_count))


func get_seconds_until_reset() -> int:
	_normalize_usage_window(true)
	var used: int = int(GameState.get_value(USED_COUNT_KEY, 0))
	if used < _limit_count:
		return 0
	var started_at: int = int(GameState.get_value(WINDOW_STARTED_KEY, 0))
	if started_at <= 0:
		return 0
	return max(0, started_at + _get_window_seconds() - _now())


func is_limit_reached() -> bool:
	return get_used_count() >= _limit_count


func is_request_active() -> bool:
	return _request_active


func request_resource_reward(
	action_id: String,
	biome_id: String,
	on_success: Callable,
	on_error: Callable
) -> void:
	var normalized_action: String = _normalize_action_id(action_id)
	if normalized_action.is_empty():
		_call_error(on_error, "resource_ads_error_ad_failed")
		return

	_normalize_usage_window(true)
	if is_limit_reached():
		_call_error(on_error, "resource_ads_error_limit_reached")
		return

	if _request_active or RewardedAdService.is_ad_loading_or_showing():
		_call_error(on_error, "resource_ads_error_ad_unavailable")
		return

	_request_active = true
	_reward_callback_fired = false
	_pending_action_id = normalized_action

	var reward_callback := func() -> void:
		if _reward_callback_fired:
			return
		_reward_callback_fired = true
		_normalize_usage_window(true)
		if is_limit_reached():
			_finish_request()
			_call_error(on_error, "resource_ads_error_limit_reached")
			return

		var result: Dictionary = _apply_reward(normalized_action, biome_id)
		if not bool(result.get("success", false)):
			_finish_request()
			_call_error(on_error, "resource_ads_error_ad_failed")
			return

		_record_success()
		SaveSystem.save_game()
		resource_reward_granted.emit(normalized_action)
		_finish_request()
		if on_success.is_valid():
			on_success.call(result)

	var error_callback := func(error_key: String) -> void:
		_finish_request()
		_call_error(on_error, _map_error_key(error_key))

	RewardedAdService.show_rewarded_ad("resources", reward_callback, error_callback)


func _apply_reward(action_id: String, biome_id: String) -> Dictionary:
	match action_id:
		"money":
			EconomySystem.add_currency("repticash", float(_money_reward_amount))
			return {
				"success": true,
				"action_id": action_id,
				"success_key": "resource_ads_reward_money_success",
				"amount": _money_reward_amount
			}
		"food", "water":
			var target_biome_id: String = biome_id
			if target_biome_id.is_empty():
				target_biome_id = GameState.DEFAULT_BIOME_ID
			var filled_to: int = 0
			if ReptileSystem.has_method("refill_biome_resource"):
				filled_to = int(ReptileSystem.call("refill_biome_resource", target_biome_id, action_id))
			if filled_to <= 0:
				return {"success": false, "action_id": action_id}
			var success_key: String = "resource_ads_reward_food_success" if action_id == "food" else "resource_ads_reward_water_success"
			return {
				"success": true,
				"action_id": action_id,
				"success_key": success_key,
				"filled_to": filled_to,
				"biome_id": target_biome_id
			}
	return {"success": false, "action_id": action_id}


func _record_success() -> void:
	var now: int = _now()
	var started_at: int = int(GameState.get_value(WINDOW_STARTED_KEY, 0))
	var used: int = int(clamp(int(GameState.get_value(USED_COUNT_KEY, 0)), 0, _limit_count))
	var timestamps: Array = _get_reward_timestamps()

	if started_at <= 0 or used <= 0:
		started_at = now
		used = 0
		timestamps = []

	used = min(_limit_count, used + 1)
	timestamps.append(now)
	GameState.set_value(WINDOW_STARTED_KEY, started_at)
	GameState.set_value(USED_COUNT_KEY, used)
	GameState.set_value(REWARD_TIMESTAMPS_KEY, timestamps)
	resource_ad_limit_changed.emit(used, _limit_count)


func _normalize_usage_window(save_on_reset: bool) -> void:
	var started_at: int = int(GameState.get_value(WINDOW_STARTED_KEY, 0))
	var used: int = int(GameState.get_value(USED_COUNT_KEY, 0))
	if started_at > 0 and used > 0 and _now() - started_at < _get_window_seconds():
		return

	var should_reset: bool = started_at != 0 or used != 0 or _get_reward_timestamps().size() > 0
	if not should_reset:
		return

	GameState.set_value(WINDOW_STARTED_KEY, 0)
	GameState.set_value(USED_COUNT_KEY, 0)
	GameState.set_value(REWARD_TIMESTAMPS_KEY, [])
	resource_ad_limit_changed.emit(0, _limit_count)
	if save_on_reset:
		SaveSystem.save_game()


func _get_reward_timestamps() -> Array:
	var raw: Variant = GameState.get_value(REWARD_TIMESTAMPS_KEY, [])
	if typeof(raw) != TYPE_ARRAY:
		return []
	var result: Array = []
	for value in (raw as Array):
		result.append(int(value))
	return result


func _normalize_action_id(action_id: String) -> String:
	match action_id:
		"money", "food", "water":
			return action_id
		_:
			return ""


func _map_error_key(error_key: String) -> String:
	if error_key.begins_with("resource_ads_"):
		return error_key
	return str(ERROR_KEY_MAP.get(error_key, "resource_ads_error_ad_failed"))


func _call_error(on_error: Callable, error_key: String) -> void:
	if on_error.is_valid():
		on_error.call(error_key)


func _finish_request() -> void:
	_request_active = false
	_reward_callback_fired = false
	_pending_action_id = ""


func _get_window_seconds() -> int:
	return _limit_window_hours * 60 * 60


func _now() -> int:
	return int(Time.get_unix_time_from_system())
