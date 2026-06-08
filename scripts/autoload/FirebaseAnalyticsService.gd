extends Node
## FirebaseAnalyticsService - small Android bridge wrapper for Firebase Analytics.

const STARTUP_EVENT_NAME := "godot_app_ready"

var _plugin: Object = null
var _is_android: bool = false
var _ready_logged: bool = false


func _ready() -> void:
	_is_android = OS.has_feature("android")
	_try_connect_plugin()
	_log_startup_state()
	if is_available():
		log_event(STARTUP_EVENT_NAME, {
			"godot_version": Engine.get_version_info().get("string", ""),
			"locale": OS.get_locale_language()
		})
		_ready_logged = true


func is_available() -> bool:
	return _plugin != null


func log_event(event_name: String, params: Dictionary = {}) -> void:
	if not is_available():
		return
	if not _has_plugin_method("log_event"):
		return
	var params_json := JSON.stringify(params)
	_plugin.call("log_event", event_name, params_json)


func set_user_property(property_name: String, value: String) -> void:
	if not is_available():
		return
	if _has_plugin_method("set_user_property"):
		_plugin.call("set_user_property", property_name, value)


func set_user_id(user_id: String) -> void:
	if not is_available():
		return
	if _has_plugin_method("set_user_id"):
		_plugin.call("set_user_id", user_id)


func was_startup_event_logged() -> bool:
	return _ready_logged


func _try_connect_plugin() -> void:
	if not _is_android:
		return
	if not Engine.has_singleton("FirebaseAnalytics"):
		return
	_plugin = Engine.get_singleton("FirebaseAnalytics")


func _has_plugin_method(method_name: String) -> bool:
	if _plugin == null:
		return false
	if _plugin.has_method(method_name):
		return true
	if _plugin.has_method("has_java_method"):
		return bool(_plugin.call("has_java_method", method_name))
	return false


func _log_startup_state() -> void:
	print("[FirebaseAnalyticsService] android=" + str(_is_android) + " singleton_available=" + str(_plugin != null))
	if _plugin != null and _has_plugin_method("is_initialized"):
		print("[FirebaseAnalyticsService] native_initialized=" + str(_plugin.call("is_initialized")))
