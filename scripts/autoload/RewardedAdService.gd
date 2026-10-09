extends Node
## RewardedAdService - central rewarded ad bridge.
##
## Modes are controlled by res://data/rewarded_ads.json:
## - mock_ads_enabled=true: local/editor simulation only.
## - mock_ads_enabled=false, test_mode=true: Android Google test rewarded ad.
## - mock_ads_enabled=false, test_mode=false: production ad id from config.

signal ad_reward_earned
signal ad_failed(error_key: String)

const CONFIG_PATH := "res://data/rewarded_ads.json"
const GOOGLE_TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const PRODUCTION_DISABLED_VALUE := "DISABLED_SEE_NOTES"
const LOAD_METHOD_NAMES := ["load_rewarded_ad", "load_rewarded", "load_rewarded_video", "loadRewardedAd"]
const SHOW_METHOD_NAMES := ["show_rewarded_ad", "show_rewarded", "show_rewarded_video", "showRewardedAd"]
const DIAGNOSTIC_METHOD_NAMES := ["load_rewarded_ad", "show_rewarded_ad", "loadRewardedAd", "showRewardedAd", "is_ad_loaded", "is_initialized"]

var _config: Dictionary = {}
var _admob_cfg: Dictionary = {}

var _mock_ads_enabled: bool = false
var _mock_ads_success_delay_seconds: float = 0.5
var _mock_ads_force_failure: bool = false
var _mock_ads_failure_error_key: String = "rewarded_speedup_error_ad_failed"
var _test_mode: bool = true
var _mode_name: String = "google_test"
var _ad_unit_id: String = GOOGLE_TEST_REWARDED_ID
var _current_placement: String = "speedup"
var _loading_placement: String = ""
var _loaded_placement: String = ""

var _is_loading: bool = false
var _is_showing: bool = false
var _ad_loaded: bool = false
var _request_active: bool = false
var _pending_show_after_load: bool = false
var _reward_earned_for_request: bool = false
var _reward_callback_fired: bool = false

var _on_reward_cb: Callable = Callable()
var _on_error_cb: Callable = Callable()

var _admob: Object = null


func _ready() -> void:
	_load_config()
	_try_connect_plugin()
	_log_startup_state()
	if _can_use_plugin(false):
		_load_ad(false, "speedup")


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("RewardedAdService: rewarded_ads.json not found; using safe defaults.")
		_select_mode_and_ad_unit()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("RewardedAdService: rewarded_ads.json malformed; using safe defaults.")
		_select_mode_and_ad_unit()
		return

	var root: Dictionary = parsed as Dictionary
	var ads: Variant = root.get("rewarded_ads", {})
	if typeof(ads) == TYPE_DICTIONARY:
		_config = ads as Dictionary
		_mock_ads_enabled = bool(_config.get("mock_ads_enabled", _mock_ads_enabled))
		_mock_ads_success_delay_seconds = max(0.0, float(_config.get("mock_ads_success_delay_seconds", _mock_ads_success_delay_seconds)))
		_mock_ads_force_failure = bool(_config.get("mock_ads_force_failure", _mock_ads_force_failure))
		_mock_ads_failure_error_key = str(_config.get("mock_ads_failure_error_key", _mock_ads_failure_error_key))
		_test_mode = bool(_config.get("test_mode", _test_mode))
		var admob_val: Variant = _config.get("admob", {})
		if typeof(admob_val) == TYPE_DICTIONARY:
			_admob_cfg = admob_val as Dictionary

	_select_mode_and_ad_unit()


func _select_mode_and_ad_unit() -> void:
	# Both APK debug and editor sessions must use Google's demo inventory.
	_test_mode = _test_mode or OS.is_debug_build()
	if _mock_ads_enabled:
		_mode_name = "mock"
	elif _test_mode:
		_mode_name = "google_test"
	else:
		_mode_name = "production"

	if _test_mode or _mock_ads_enabled:
		_ad_unit_id = _get_ad_unit_id_for_placement("speedup")
		return

	_ad_unit_id = _get_ad_unit_id_for_placement("speedup")


func _normalize_placement(placement: String) -> String:
	match placement:
		"resources":
			return "resources"
		_:
			return "speedup"


func _get_ad_unit_id_for_placement(placement: String) -> String:
	var normalized_placement: String = _normalize_placement(placement)
	if _test_mode or _mock_ads_enabled:
		return str(_admob_cfg.get("test_rewarded_ad_unit_id", GOOGLE_TEST_REWARDED_ID))

	var field_name: String = "production_speedup_rewarded_ad_unit_id"
	if normalized_placement == "resources":
		field_name = "production_resources_rewarded_ad_unit_id"

	var fallback_field := "production_rewarded_ad_unit_id"
	var prod_id: String = str(_admob_cfg.get(field_name, _admob_cfg.get(fallback_field, PRODUCTION_DISABLED_VALUE)))
	if prod_id.is_empty() or prod_id == PRODUCTION_DISABLED_VALUE:
		push_warning("RewardedAdService: " + field_name + " is disabled in config.")
		return ""
	return prod_id


func _try_connect_plugin() -> void:
	if _mock_ads_enabled:
		return
	if not OS.has_feature("android"):
		return
	if not Engine.has_singleton("AdMob"):
		_log("[AdMobRuntime] _try_connect_plugin: Engine.has_singleton(\"AdMob\") = false — plugin not registered at runtime. Likely causes: stale APK (rebuild+reinstall), Gradle build disabled, or ServiceLoader packaging failure.")
		return

	_admob = Engine.get_singleton("AdMob")
	if _has_plugin_method("configure_test_devices"):
		var device_ids := PackedStringArray()
		var configured: Variant = _admob_cfg.get("test_device_ids", [])
		if configured is Array:
			for device_id: Variant in configured:
				device_ids.append(str(device_id))
		_admob.call("configure_test_devices", ",".join(device_ids))
	_log("[AdMobRuntime] _try_connect_plugin: singleton acquired — _admob null=" + str(_admob == null))
	_connect_plugin_signals()


func _connect_plugin_signals() -> void:
	_safe_connect_any_signal(["rewarded_ad_loaded", "rewarded_video_loaded", "rewarded_loaded"], Callable(self, "_on_ad_loaded"))
	_safe_connect_any_signal(["rewarded_ad_failed_to_load", "rewarded_video_failed_to_load", "rewarded_failed_to_load"], Callable(self, "_on_ad_failed_to_load"))
	_safe_connect_any_signal(["rewarded_ad_closed", "rewarded_video_closed", "rewarded_closed", "rewarded_ad_dismissed"], Callable(self, "_on_ad_closed"))
	_safe_connect_any_signal(["rewarded_user_earned_reward", "user_earned_reward", "rewarded", "rewarded_ad_rewarded"], Callable(self, "_on_user_earned_reward"))
	_safe_connect_any_signal(["rewarded_ad_failed_to_show", "rewarded_video_failed_to_show", "rewarded_failed_to_show"], Callable(self, "_on_ad_failed_to_show"))
	_safe_connect_any_signal(["rewarded_ad_showed", "rewarded_ad_opened", "rewarded_video_opened"], Callable(self, "_on_ad_showed"))


func _safe_connect_any_signal(signal_names: Array, callable: Callable) -> void:
	if _admob == null:
		return
	for signal_name_value in signal_names:
		var signal_name: String = str(signal_name_value)
		if _admob.has_signal(signal_name) and not _admob.is_connected(signal_name, callable):
			_admob.connect(signal_name, callable)
			_log("connected plugin signal: " + signal_name)


func get_mode_name() -> String:
	return _mode_name


func get_selected_ad_unit_id(placement: String = "speedup") -> String:
	return _get_ad_unit_id_for_placement(placement)


func is_rewarded_ad_available(_placement: String = "speedup") -> bool:
	if _mock_ads_enabled:
		return not _request_active and not _is_showing
	if not _can_use_plugin(false):
		return false
	return not _request_active and not _is_showing


func is_ad_loading_or_showing() -> bool:
	return _request_active or _is_showing


func show_rewarded_ad(
	placement_or_callback: Variant = "speedup",
	callback_on_reward: Callable = Callable(),
	callback_on_error: Callable = Callable()
) -> void:
	var placement: String = "speedup"
	var reward_cb: Callable = callback_on_reward
	var error_cb: Callable = callback_on_error
	if typeof(placement_or_callback) == TYPE_STRING:
		placement = _normalize_placement(str(placement_or_callback))
	elif typeof(placement_or_callback) == TYPE_CALLABLE:
		reward_cb = placement_or_callback
		error_cb = callback_on_reward
	else:
		_call_error(error_cb, "rewarded_speedup_error_ad_unavailable")
		return

	if _request_active or _is_showing:
		_call_error(error_cb, "rewarded_speedup_error_ad_unavailable")
		return

	_current_placement = placement
	_ad_unit_id = _get_ad_unit_id_for_placement(placement)
	_on_reward_cb = reward_cb
	_on_error_cb = error_cb
	_request_active = true
	_pending_show_after_load = false
	_reward_earned_for_request = false
	_reward_callback_fired = false

	_log("show_rewarded_ad requested; placement=" + _current_placement + "; mode=" + _mode_name + "; ad_unit_id=" + _format_ad_unit(_ad_unit_id))

	if _mock_ads_enabled:
		_simulate_ad()
		return

	if not OS.has_feature("android"):
		_report_active_error("rewarded_speedup_error_sdk_unavailable")
		return

	if not _can_use_plugin(true):
		_report_active_error("rewarded_speedup_error_sdk_unavailable")
		return

	if _ad_unit_id.is_empty():
		_report_active_error("rewarded_speedup_error_ad_unavailable")
		return

	if _ad_loaded and _loaded_placement == _current_placement:
		_show_ad_now()
		return

	_pending_show_after_load = true
	if _is_loading:
		_log("ad load already in progress for placement=" + _loading_placement + "; active request placement=" + _current_placement)
		return
	_load_ad(true, _current_placement)


func _load_ad(for_active_request: bool = false, placement: String = "speedup") -> void:
	var normalized_placement: String = _normalize_placement(placement)
	var ad_unit_id: String = _get_ad_unit_id_for_placement(normalized_placement)
	if not _can_use_plugin(false):
		if for_active_request:
			_report_active_error("rewarded_speedup_error_sdk_unavailable")
		return
	if ad_unit_id.is_empty():
		if for_active_request:
			_report_active_error("rewarded_speedup_error_ad_unavailable")
		return
	if _is_loading:
		return

	_ad_unit_id = ad_unit_id
	_loading_placement = normalized_placement
	_is_loading = true
	_ad_loaded = false
	_loaded_placement = ""
	if for_active_request:
		_pending_show_after_load = true
	_log("ad load started; placement=" + _loading_placement + "; mode=" + _mode_name + "; ad_unit_id=" + _format_ad_unit(_ad_unit_id))

	var started: bool = _call_load_method()
	if not started:
		_is_loading = false
		_loading_placement = ""
		_ad_loaded = false
		if for_active_request:
			_report_active_error("rewarded_speedup_error_sdk_unavailable")
		else:
			_log("ad load failed to start; SDK/plugin method unavailable")


func _has_java_method_on_plugin(plugin: Object, method_name: String) -> bool:
	if plugin == null:
		return false
	if not plugin.has_method("has_java_method"):
		return false
	return bool(plugin.call("has_java_method", StringName(method_name)))


func _has_method_on_plugin(plugin: Object, method_name: String) -> bool:
	if plugin == null:
		return false
	return plugin.has_method(method_name) or _has_java_method_on_plugin(plugin, method_name)


func _has_plugin_method(method_name: String) -> bool:
	return _has_method_on_plugin(_admob, method_name)


func _has_any_plugin_method(method_names: Array) -> bool:
	for method_name_value in method_names:
		if _has_plugin_method(str(method_name_value)):
			return true
	return false


func _call_load_method() -> bool:
	if _admob == null:
		return false
	if _has_plugin_method("load_rewarded_ad"):
		_admob.call("load_rewarded_ad", _ad_unit_id)
		return true
	if _has_plugin_method("load_rewarded"):
		_admob.call("load_rewarded", _ad_unit_id)
		return true
	if _has_plugin_method("load_rewarded_video"):
		_admob.call("load_rewarded_video")
		return true
	if _has_plugin_method("loadRewardedAd"):
		_admob.call("loadRewardedAd", _ad_unit_id)
		return true
	return false


func _show_ad_now() -> void:
	if not _can_use_plugin(true):
		_report_active_error("rewarded_speedup_error_sdk_unavailable")
		return

	_log("ad show started; placement=" + _current_placement)
	_is_showing = true
	_ad_loaded = false
	_loaded_placement = ""
	_pending_show_after_load = false

	var show_result: Variant = null
	var called: bool = false
	if _has_plugin_method("show_rewarded_ad"):
		show_result = _admob.call("show_rewarded_ad")
		called = true
	elif _has_plugin_method("show_rewarded"):
		show_result = _admob.call("show_rewarded")
		called = true
	elif _has_plugin_method("show_rewarded_video"):
		show_result = _admob.call("show_rewarded_video")
		called = true
	elif _has_plugin_method("showRewardedAd"):
		show_result = _admob.call("showRewardedAd")
		called = true

	if not called or (typeof(show_result) == TYPE_BOOL and not bool(show_result)):
		_log("ad show failed")
		_is_showing = false
		_report_active_error("rewarded_speedup_error_ad_failed")


func _on_ad_loaded(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	var loaded_placement: String = _loading_placement
	_is_loading = false
	_loading_placement = ""
	_ad_loaded = true
	_loaded_placement = loaded_placement
	_log("ad load success; placement=" + _loaded_placement)
	if _pending_show_after_load and _request_active:
		if _loaded_placement == _current_placement:
			_show_ad_now()
		else:
			_log("loaded placement does not match active request; loading placement=" + _current_placement)
			_load_ad(true, _current_placement)


func _on_ad_failed_to_load(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	var failed_placement: String = _loading_placement
	_is_loading = false
	_loading_placement = ""
	_ad_loaded = false
	_loaded_placement = ""
	_log("ad load failure; placement=" + failed_placement)
	if _request_active:
		if failed_placement == _current_placement:
			_report_active_error("rewarded_speedup_error_ad_unavailable")
		else:
			_load_ad(true, _current_placement)


func _on_ad_showed(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	_log("ad show confirmed by plugin")


func _on_user_earned_reward(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	if not _request_active:
		_log("reward callback ignored; no active request")
		return
	if _reward_callback_fired:
		_log("duplicate reward callback ignored")
		return

	_reward_earned_for_request = true
	_reward_callback_fired = true
	_log("reward earned callback fired")
	ad_reward_earned.emit()
	if _on_reward_cb.is_valid():
		var reward_cb: Callable = _on_reward_cb
		_on_reward_cb = Callable()
		reward_cb.call()


func _on_ad_closed(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	_is_showing = false
	var preload_placement: String = _current_placement
	if _request_active and not _reward_earned_for_request:
		_log("ad dismissed without reward")
		_report_active_error("rewarded_speedup_error_closed_without_reward")
	else:
		_log("ad closed after reward or without active request")
		_reset_request()
	if _can_use_plugin(false):
		call_deferred("_load_ad", false, preload_placement)


func _on_ad_failed_to_show(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	_is_showing = false
	_ad_loaded = false
	_log("ad show failed")
	if _request_active:
		_report_active_error("rewarded_speedup_error_ad_failed")
	if _can_use_plugin(false):
		call_deferred("_load_ad", false, _current_placement)


func _simulate_ad() -> void:
	_log("mock ad show started; placement=" + _current_placement)
	_is_showing = true
	await get_tree().create_timer(_mock_ads_success_delay_seconds).timeout
	if not _request_active:
		return

	_is_showing = false
	if _mock_ads_force_failure:
		_log("mock ad simulated failure: " + _mock_ads_failure_error_key)
		_report_active_error(_mock_ads_failure_error_key)
		return

	_reward_earned_for_request = true
	_reward_callback_fired = true
	_log("mock reward earned callback fired")
	ad_reward_earned.emit()
	if _on_reward_cb.is_valid():
		var reward_cb: Callable = _on_reward_cb
		_on_reward_cb = Callable()
		reward_cb.call()
	_reset_request()


func _can_use_plugin(log_reason: bool) -> bool:
	if _mock_ads_enabled:
		return false
	if not OS.has_feature("android"):
		if log_reason:
			_log("SDK/plugin unavailable: not running on Android")
		return false
	if _admob == null:
		if log_reason:
			_log("SDK/plugin unavailable: Engine singleton 'AdMob' not found")
		return false
	var has_load: bool = _has_any_plugin_method(LOAD_METHOD_NAMES)
	var has_show: bool = _has_any_plugin_method(SHOW_METHOD_NAMES)
	if not has_load or not has_show:
		if log_reason:
			_log("SDK/plugin unavailable: rewarded load/show methods not found")
		return false
	return true


func _report_active_error(error_key: String) -> void:
	_log("ad error: " + error_key)
	ad_failed.emit(error_key)
	if _on_error_cb.is_valid():
		var error_cb: Callable = _on_error_cb
		_on_error_cb = Callable()
		error_cb.call(error_key)
	_reset_request()


func _call_error(callback_on_error: Callable, error_key: String) -> void:
	_log("ad error before request: " + error_key)
	ad_failed.emit(error_key)
	if callback_on_error.is_valid():
		callback_on_error.call(error_key)


func _reset_request() -> void:
	_request_active = false
	_pending_show_after_load = false
	_reward_earned_for_request = false
	_reward_callback_fired = false
	_on_reward_cb = Callable()
	_on_error_cb = Callable()


func _log_startup_state() -> void:
	var _is_android: bool = OS.has_feature("android")
	var _has_singleton: bool = Engine.has_singleton("AdMob")
	_log("[AdMobRuntime] ===== Startup Diagnostics =====")
	_log("[AdMobRuntime] OS.get_name()=" + OS.get_name() + "  android_feature=" + str(_is_android))
	_log("[AdMobRuntime] mock_ads_enabled=" + str(_mock_ads_enabled) + "  test_mode=" + str(_test_mode) + "  mode=" + _mode_name)
	_log("[AdMobRuntime] speedup_ad_unit_id=" + _format_ad_unit(_get_ad_unit_id_for_placement("speedup")))
	_log("[AdMobRuntime] resources_ad_unit_id=" + _format_ad_unit(_get_ad_unit_id_for_placement("resources")))
	_log("[AdMobRuntime] Engine.has_singleton(\"AdMob\")=" + str(_has_singleton))
	if _is_android and not _mock_ads_enabled:
		if _has_singleton:
			var _s: Object = Engine.get_singleton("AdMob")
			_log("[AdMobRuntime] singleton_object_null=" + str(_s == null))
			if _s != null:
				_log("[AdMobRuntime] has_method(load_rewarded_ad)=" + str(_s.has_method("load_rewarded_ad")) + "  has_method(show_rewarded_ad)=" + str(_s.has_method("show_rewarded_ad")))
				_log("[AdMobRuntime] has_method(loadRewardedAd)=" + str(_s.has_method("loadRewardedAd")) + "  has_method(showRewardedAd)=" + str(_s.has_method("showRewardedAd")))
				_log("[AdMobRuntime] has_java_method(load_rewarded_ad)=" + str(_has_java_method_on_plugin(_s, "load_rewarded_ad")) + "  has_java_method(show_rewarded_ad)=" + str(_has_java_method_on_plugin(_s, "show_rewarded_ad")))
				_log("[AdMobRuntime] has_java_method(loadRewardedAd)=" + str(_has_java_method_on_plugin(_s, "loadRewardedAd")) + "  has_java_method(showRewardedAd)=" + str(_has_java_method_on_plugin(_s, "showRewardedAd")))
				var _all_methods: Array = _s.get_method_list()
				var _method_names: Array = []
				var _ad_methods: Array = []
				for _m in _all_methods:
					var _mname: String = str(_m.get("name", ""))
					_method_names.append(_mname)
					if "reward" in _mname or "rewarded" in _mname or _mname in DIAGNOSTIC_METHOD_NAMES:
						_ad_methods.append(_mname)
				_method_names.sort()
				_ad_methods.sort()
				_log("[AdMobRuntime] get_method_list (all names) = " + str(_method_names))
				_log("[AdMobRuntime] get_method_list (ad-related) = " + str(_ad_methods))
		else:
			_log("[AdMobRuntime] DIAGNOSIS: singleton not found — possible causes:")
			_log("[AdMobRuntime]   1) APK on phone is a stale build made before AdMobPlugin.kt was added")
			_log("[AdMobRuntime]   2) Gradle build was disabled in export_presets.cfg when this APK was exported")
			_log("[AdMobRuntime]   3) ServiceLoader file was not packaged (check META-INF/services in APK)")
	_log("[AdMobRuntime] _admob_null=" + str(_admob == null))
	_log("[AdMobRuntime] ===== End Diagnostics =====")
	_log("mode=" + _mode_name + "; speedup_ad_unit_id=" + _format_ad_unit(_get_ad_unit_id_for_placement("speedup")) + "; resources_ad_unit_id=" + _format_ad_unit(_get_ad_unit_id_for_placement("resources")))
	if _mock_ads_enabled:
		_log("SDK/plugin availability: mock mode active")
	elif _can_use_plugin(false):
		_log("SDK/plugin availability: AdMob singleton ready")
	else:
		_log("SDK/plugin availability: unavailable")


func _log(message: String) -> void:
	print("[RewardedAdService] " + message)


func _format_ad_unit(ad_unit_id: String) -> String:
	return ad_unit_id if not ad_unit_id.is_empty() else "<none>"
