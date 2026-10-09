extends Node
## FirebaseAnalyticsService - small Android bridge wrapper for Firebase Analytics.

signal gameplay_event_recorded(event_name: String, params: Dictionary)

const STARTUP_EVENT_NAME := "godot_app_ready"
const GAMEPLAY_EVENT_NAMES := [
	"screen_opened", "habitat_purchased", "reptile_purchased", "reptile_assigned",
	"care_action_success", "variant_discovered", "offline_income_claimed",
	"incubator_entered", "incubator_egg_obtained", "incubator_breeding_started",
	"incubator_breeding_collected", "incubator_incubation_started",
	"incubator_container_watered", "incubator_hatched", "expedition_started", "expedition_claimed"
]
const ANALYTICS_PARAMETER_KEYS := [
	"screen", "biome_id", "reptile_id", "species_id", "rarity", "quality_id",
	"action", "source", "amount", "price", "count", "egg_count", "is_long",
	"succeeded", "running_count", "previous_state", "new_state", "task_id",
	"quest_id", "upgrade_id", "level", "target_type", "reduced_seconds",
	"action_id", "variant_id", "region_id", "mode_id", "expedition_id", "reward_kind", "duration_seconds"
]

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
	call_deferred("_connect_gameplay_signals")


func is_available() -> bool:
	return _plugin != null


func log_event(event_name: String, params: Dictionary = {}) -> void:
	if not is_available():
		return
	if not _has_plugin_method("log_event"):
		return
	var params_json := JSON.stringify(params)
	_plugin.call("log_event", event_name, params_json)


func log_gameplay_event(event_name: String, params: Dictionary = {}) -> void:
	# No animal names, user identifiers, raw saves or arbitrary nested payloads.
	var safe_params: Dictionary = {
		"player_level": int(GameState.get_value("level", 1)),
		"onboarding_track": int(GameState.get_value("onboarding_track_version", 1))
	}
	for key in ANALYTICS_PARAMETER_KEYS:
		if not params.has(key):
			continue
		var value: Variant = params[key]
		if value is bool:
			safe_params[key] = 1 if value else 0
		elif value is int or value is float:
			safe_params[key] = value
		elif value is String:
			safe_params[key] = value.left(100)
	# This signal is also an inspectable local diagnostic. It does not claim
	# delivery to Firebase when the native Android plugin is unavailable.
	gameplay_event_recorded.emit(event_name, safe_params.duplicate(true))
	log_event(event_name, safe_params)


func _connect_gameplay_signals() -> void:
	QuestSystem.gameplay_event_recorded.connect(_on_gameplay_event)
	QuestSystem.quest_claimed.connect(func(quest_id: String) -> void:
		log_gameplay_event("quest_reward_claimed", {"quest_id": quest_id}))
	EconomySystem.player_level_changed.connect(func(level: int) -> void:
		log_gameplay_event("player_level_reached", {"level": level}))
	UpgradeSystem.upgrade_purchased.connect(func(upgrade_id: String, level: int) -> void:
		log_gameplay_event("upgrade_purchased", {"upgrade_id": upgrade_id, "level": level}))
	IncubatorUpgradeSystem.upgrade_purchased.connect(func(upgrade_id: String, level: int) -> void:
		log_gameplay_event("nursery_upgrade_purchased", {"upgrade_id": upgrade_id, "level": level}))
	OnboardingSystem.onboarding_finished.connect(func() -> void:
		if int(GameState.get_value("onboarding_track_version", 1)) >= 2:
			log_gameplay_event("tutorial_completed"))
	ResourceAdService.resource_reward_granted.connect(func(action_id: String) -> void:
		log_gameplay_event("ad_resource_reward_received", {"action_id": action_id}))
	SpeedUpService.speedup_applied.connect(func(target_type: String, _target_id: String, seconds: int) -> void:
		log_gameplay_event("ad_speedup_reward_received", {"target_type": target_type, "reduced_seconds": seconds}))


func _on_gameplay_event(event_name: String, payload: Dictionary) -> void:
	if not GAMEPLAY_EVENT_NAMES.has(event_name):
		return
	var params: Dictionary = payload.duplicate(true)
	if event_name == "incubator_hatched":
		var rarities: Array = payload.get("rarities", []) as Array
		for rarity in ["exceptional", "ultra_rare", "rare", "common"]:
			if rarities.has(rarity):
				params["rarity"] = rarity
				break
	log_gameplay_event(event_name, params)


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
