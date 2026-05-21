extends Node
## SpeedUpService - central rewarded-ad speed-up logic for timer processes.

signal speedup_applied(target_type: String, target_id: String, reduced_by_seconds: int)

const CONFIG_PATH := "res://data/rewarded_ads.json"

var _config: Dictionary = {}
var _rewards: Array = []
var _icon_path: String = "res://assets/art/ui/icons/speed_up_ico.png"
var _icon_width: int = 64
var _icon_height: int = 64
var _show_above_minutes: int = 30
var _cooldown_seconds: float = 3.0

var _cooldowns: Dictionary = {}


func _ready() -> void:
	_load_config()


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("SpeedUpService: rewarded_ads.json not found.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SpeedUpService: rewarded_ads.json malformed.")
		return

	var root: Dictionary = parsed as Dictionary
	var ads: Variant = root.get("rewarded_ads", {})
	if typeof(ads) != TYPE_DICTIONARY:
		return

	_config = ads as Dictionary
	_icon_path = str(_config.get("speed_up_icon_path", _icon_path))
	_icon_width = int(_config.get("speed_up_icon_width", _icon_width))
	_icon_height = int(_config.get("speed_up_icon_height", _icon_height))
	_show_above_minutes = int(_config.get("show_only_above_minutes", _show_above_minutes))
	_cooldown_seconds = float(_config.get("button_cooldown_seconds", _cooldown_seconds))
	var rewards_val: Variant = _config.get("rewards", [])
	if typeof(rewards_val) == TYPE_ARRAY:
		_rewards = rewards_val as Array


func get_icon_path() -> String:
	return _icon_path


func get_icon_size() -> Vector2:
	return Vector2(_icon_width, _icon_height)


func should_show_button(remaining_seconds: int) -> bool:
	return remaining_seconds > _show_above_minutes * 60


func is_on_cooldown(target_type: String, target_id: String) -> bool:
	var key: String = target_type + ":" + target_id
	var until: float = float(_cooldowns.get(key, 0.0))
	return Time.get_unix_time_from_system() < until


func calculate_reduce_seconds(remaining_seconds: int) -> int:
	var remaining_minutes: float = float(remaining_seconds) / 60.0
	for reward_val in _rewards:
		if typeof(reward_val) != TYPE_DICTIONARY:
			continue
		var reward: Dictionary = reward_val as Dictionary
		var min_exc: float = float(reward.get("min_remaining_minutes_exclusive", 0))
		var max_inc_val: Variant = reward.get("max_remaining_minutes_inclusive", null)
		var max_inc: float = 9999999.0 if max_inc_val == null else float(max_inc_val)
		if remaining_minutes > min_exc and remaining_minutes <= max_inc:
			return int(reward.get("reduce_by_minutes", 30)) * 60
	return 0


func format_reduce_time(reduce_seconds: int, language: String) -> String:
	var minutes: int = int(reduce_seconds / 60)
	if minutes < 60:
		return str(minutes) + " min"
	var hours: int = int(minutes / 60)
	if language == "pl":
		return str(hours) + " godz."
	return str(hours) + " h"


func request_speedup(
	target_type: String,
	target_id: String,
	confirmation_parent: Control,
	on_success: Callable,
	on_error: Callable
) -> void:
	var remaining: int = get_remaining_seconds(target_type, target_id)
	if remaining <= _show_above_minutes * 60:
		_call_error(on_error, "rewarded_speedup_error_ad_unavailable")
		return

	if is_on_cooldown(target_type, target_id):
		_call_error(on_error, "rewarded_speedup_error_ad_unavailable")
		return

	if RewardedAdService.is_ad_loading_or_showing():
		_call_error(on_error, "rewarded_speedup_error_ad_unavailable")
		return

	var reduce_seconds: int = calculate_reduce_seconds(remaining)
	if reduce_seconds <= 0:
		_call_error(on_error, "rewarded_speedup_error_ad_unavailable")
		return

	_show_confirmation(target_type, target_id, reduce_seconds, confirmation_parent, on_success, on_error)


func _show_confirmation(
	target_type: String,
	target_id: String,
	reduce_seconds: int,
	parent: Control,
	on_success: Callable,
	on_error: Callable
) -> void:
	var lang: String = GameState.get_language()
	var reduce_text: String = format_reduce_time(reduce_seconds, lang)
	var modal_parent: Control = _get_confirmation_modal_parent(parent)

	var modal := Control.new()
	modal.name = "SpeedUpConfirmModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.z_index = 200
	modal_parent.add_child(modal)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.50)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 36
	center.offset_right = -36
	modal.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(645, 390)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.13, 0.10, 0.06, 0.97)
	pstyle.border_color = Color(0.80, 0.65, 0.20, 0.95)
	pstyle.set_border_width_all(4)
	pstyle.set_corner_radius_all(18)
	pstyle.content_margin_left = 34
	pstyle.content_margin_right = 34
	pstyle.content_margin_top = 30
	pstyle.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", pstyle)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)

	var title_lbl := Label.new()
	title_lbl.text = LocalizationSystem.tr_key("rewarded_speedup_title")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 33)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35, 1.0))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_lbl)

	var msg_template: String = LocalizationSystem.tr_key("rewarded_speedup_message")
	var msg_lbl := Label.new()
	msg_lbl.text = msg_template.replace("{time}", reduce_text)
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.add_theme_font_size_override("font_size", 24)
	msg_lbl.add_theme_color_override("font_color", Color(0.90, 0.84, 0.70, 1.0))
	msg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(msg_lbl)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)

	var cancel_btn := Button.new()
	cancel_btn.text = LocalizationSystem.tr_key("rewarded_speedup_cancel")
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel_btn.add_theme_font_size_override("font_size", 24)
	cancel_btn.custom_minimum_size = Vector2(0, 72)
	actions.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = LocalizationSystem.tr_key("rewarded_speedup_confirm")
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.focus_mode = Control.FOCUS_NONE
	confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	confirm_btn.add_theme_font_size_override("font_size", 24)
	confirm_btn.custom_minimum_size = Vector2(0, 72)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.22, 0.52, 0.20, 1.0)
	confirm_style.border_color = Color(0.35, 0.75, 0.30, 0.90)
	confirm_style.set_border_width_all(2)
	confirm_style.set_corner_radius_all(8)
	confirm_style.content_margin_left = 10
	confirm_style.content_margin_right = 10
	confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	actions.add_child(confirm_btn)

	cancel_btn.pressed.connect(func() -> void:
		if is_instance_valid(modal):
			modal.queue_free()
	)

	confirm_btn.pressed.connect(func() -> void:
		if not is_instance_valid(modal):
			return
		confirm_btn.disabled = true
		cancel_btn.disabled = true
		_start_ad(target_type, target_id, reduce_seconds, modal, on_success, on_error)
	)


func _get_confirmation_modal_parent(parent: Control) -> Control:
	if is_instance_valid(parent):
		var scene: Node = parent.get_tree().current_scene
		if scene is Control:
			return scene as Control
	return parent


func _start_ad(
	target_type: String,
	target_id: String,
	reduce_seconds: int,
	modal: Control,
	on_success: Callable,
	on_error: Callable
) -> void:
	var reward_callback := func() -> void:
		if is_instance_valid(modal):
			modal.queue_free()
		_set_cooldown(target_type, target_id)
		if apply_speedup(target_type, target_id, reduce_seconds):
			if on_success.is_valid():
				on_success.call()
		else:
			_call_error(on_error, "rewarded_speedup_error_ad_unavailable")

	var error_callback := func(error_key: String) -> void:
		if is_instance_valid(modal):
			modal.queue_free()
		_set_cooldown(target_type, target_id)
		_call_error(on_error, error_key)

	RewardedAdService.show_rewarded_ad("speedup", reward_callback, error_callback)


func apply_speedup(target_type: String, target_id: String, reduce_seconds: int) -> bool:
	var applied: bool = false
	match target_type:
		"habitat_build":
			applied = _apply_habitat_speedup(target_id, reduce_seconds, true)
		"habitat_upgrade":
			applied = _apply_habitat_speedup(target_id, reduce_seconds, false)
		"incubator_pairing":
			applied = _apply_breeding_speedup(target_id, reduce_seconds)
		"egg_incubation":
			applied = _apply_incubation_speedup(target_id, reduce_seconds)
		_:
			applied = false

	if not applied:
		return false

	SaveSystem.save_game()
	speedup_applied.emit(target_type, target_id, reduce_seconds)
	return true


func _apply_habitat_speedup(habitat_id: String, reduce_seconds: int, is_build: bool) -> bool:
	var habitats_val: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_val) != TYPE_DICTIONARY:
		return false

	var habitats: Dictionary = (habitats_val as Dictionary).duplicate(true)
	var hab_val: Variant = habitats.get(habitat_id, null)
	if typeof(hab_val) != TYPE_DICTIONARY:
		return false

	var hab: Dictionary = (hab_val as Dictionary).duplicate(true)
	var now: int = int(Time.get_unix_time_from_system())

	if is_build:
		if not bool(hab.get("is_building", false)):
			return false
		var build_finish: int = int(hab.get("build_finish_at", 0))
		if build_finish <= 0:
			return false
		hab["build_finish_at"] = max(now - 1, build_finish - reduce_seconds)
	else:
		if not bool(hab.get("is_upgrading", false)):
			return false
		var upgrade_finish: int = int(hab.get("upgrade_finish_at", 0))
		if upgrade_finish <= 0:
			return false
		hab["upgrade_finish_at"] = max(now - 1, upgrade_finish - reduce_seconds)

	habitats[habitat_id] = hab
	GameState.set_value("habitats", habitats)
	ReptileSystem.apply_time_updates(false, false)
	return true


func _apply_breeding_speedup(chamber_key: String, reduce_seconds: int) -> bool:
	BreedingSystem.tick_chambers()
	var chambers_val: Variant = GameState.get_value("breeding_chambers", {})
	if typeof(chambers_val) != TYPE_DICTIONARY:
		return false

	var chambers: Dictionary = (chambers_val as Dictionary).duplicate(true)
	var ch_val: Variant = chambers.get(chamber_key, null)
	if typeof(ch_val) != TYPE_DICTIONARY:
		return false

	var chamber: Dictionary = (ch_val as Dictionary).duplicate(true)
	if str(chamber.get("state", "")) != "breeding":
		return false

	var now: int = int(Time.get_unix_time_from_system())
	var ends_at: int = int(chamber.get("ends_at", 0))
	if ends_at <= 0:
		return false

	chamber["ends_at"] = max(now - 1, ends_at - reduce_seconds)
	chambers[chamber_key] = chamber
	GameState.set_value("breeding_chambers", chambers)
	BreedingSystem.tick_chambers()
	return true


func _apply_incubation_speedup(container_key: String, reduce_seconds: int) -> bool:
	if IncubationSystem.has_method("apply_speedup_to_container"):
		return bool(IncubationSystem.call("apply_speedup_to_container", int(container_key), reduce_seconds))

	var containers_val: Variant = GameState.get_value("incubation_containers", {})
	if typeof(containers_val) != TYPE_DICTIONARY:
		return false

	var containers: Dictionary = (containers_val as Dictionary).duplicate(true)
	var cv: Variant = containers.get(container_key, null)
	if typeof(cv) != TYPE_DICTIONARY:
		return false

	var container: Dictionary = (cv as Dictionary).duplicate(true)
	if str(container.get("state", "")) != "running":
		return false

	var completed: int = int(container.get("active_seconds_completed", 0))
	var required: int = int(container.get("required_active_seconds", 0))
	if required <= 0:
		return false

	container["active_seconds_completed"] = min(completed + reduce_seconds, required)
	if int(container.get("active_seconds_completed", 0)) >= required:
		var now: int = int(Time.get_unix_time_from_system())
		container["state"] = "ready_to_hatch"
		container["ready_at"] = now
		container["completed_at"] = now

	containers[container_key] = container
	GameState.set_value("incubation_containers", containers)
	return true


func get_remaining_seconds(target_type: String, target_id: String) -> int:
	match target_type:
		"habitat_build":
			return ReptileSystem.get_habitat_build_remaining_seconds(target_id)
		"habitat_upgrade":
			return ReptileSystem.get_habitat_upgrade_remaining_seconds(target_id)
		"incubator_pairing":
			var chambers: Dictionary = BreedingSystem.get_chambers()
			var ch_val: Variant = chambers.get(target_id, null)
			if typeof(ch_val) != TYPE_DICTIONARY:
				return 0
			return BreedingSystem.get_breeding_remaining_seconds(ch_val as Dictionary)
		"egg_incubation":
			var container: Dictionary = IncubationSystem.get_container(int(target_id))
			if container.is_empty():
				return 0
			return IncubationSystem.get_remaining_seconds(container)
	return 0


func _set_cooldown(target_type: String, target_id: String) -> void:
	var key: String = target_type + ":" + target_id
	_cooldowns[key] = Time.get_unix_time_from_system() + _cooldown_seconds


func _call_error(on_error: Callable, error_key: String) -> void:
	if on_error.is_valid():
		on_error.call(error_key)
