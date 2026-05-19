extends CanvasLayer

signal onboarding_finished
signal onboarding_task_changed(task_id: String)

const TASKS_PATH := "res://data/onboarding_tasks.json"
const MODAL_BACKGROUND_PATH := "res://assets/art/ui/small_design/blank_card_background.png"
const BOTTOM_NAV_HEIGHT := 226.157092875
const BUBBLE_SIZE := Vector2(108, 108)

var tasks: Array = []
var modal_root: Control
var bubble_button: Button
var bubble_dot: Control
var _claim_in_progress: bool = false
var _biome_seen: bool = false
var _bubble_allowed_on_current_screen: bool = false


func _ready() -> void:
	layer = 130
	load_tasks()
	if not GameState.language_changed.is_connected(_on_language_changed):
		GameState.language_changed.connect(_on_language_changed)
	call_deferred("_restore_or_wait")


func load_tasks() -> bool:
	var file: FileAccess = FileAccess.open(TASKS_PATH, FileAccess.READ)
	if file == null:
		push_warning("OnboardingSystem: missing tasks file " + TASKS_PATH)
		tasks = []
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("OnboardingSystem: malformed tasks file " + TASKS_PATH)
		tasks = []
		return false

	tasks = parsed as Array
	tasks.sort_custom(func(a: Variant, b: Variant) -> bool:
		if typeof(a) != TYPE_DICTIONARY or typeof(b) != TYPE_DICTIONARY:
			return false
		return int((a as Dictionary).get("order", 0)) < int((b as Dictionary).get("order", 0))
	)
	return true


func notify_event(event_type: String, payload: Dictionary = {}) -> void:
	_ensure_state()
	if event_type == "screen_opened":
		_update_screen_context(str(payload.get("screen", "")))
		if str(payload.get("screen", "")) == "biome":
			_biome_seen = true
			_try_start_onboarding()

	for alias in _get_event_aliases(event_type, payload):
		_increment_event_counter(str(alias))

	_refresh_active_completion()
	_update_bubble()
	_save_state()


func _update_screen_context(screen_id: String) -> void:
	match screen_id:
		"biome", "shop", "quests", "workers", "upgrades", "achievements", "gallery":
			_bubble_allowed_on_current_screen = true
		_:
			_bubble_allowed_on_current_screen = false
	_update_bubble()


func reset_onboarding(show_now: bool = true) -> void:
	GameState.set_value("onboarding_state", GameState.get_default_onboarding_state())
	_claim_in_progress = false
	_close_modal()
	_update_bubble()
	_save_state()
	if show_now:
		_biome_seen = true
		_try_start_onboarding()


func complete_onboarding() -> void:
	var state: Dictionary = _get_state()
	state["welcome_seen"] = true
	state["active_task_id"] = ""
	state["active_task_accepted"] = false
	state["active_task_completed"] = false
	state["bubble_visible"] = false
	state["onboarding_finished"] = true
	_set_state(state)
	_close_modal()
	_update_bubble()
	_save_state()
	onboarding_finished.emit()


func start_onboarding() -> void:
	reset_onboarding(true)


func _restore_or_wait() -> void:
	_ensure_state()
	if _should_disable_for_progressed_save():
		complete_onboarding()
		return
	_restore_active_bubble_if_needed()
	_update_bubble()


func _restore_active_bubble_if_needed() -> void:
	var state: Dictionary = _get_state()
	if bool(state.get("onboarding_finished", false)):
		return
	if str(state.get("active_task_id", "")).is_empty():
		return
	if not bool(state.get("active_task_accepted", false)):
		state["active_task_accepted"] = true
	state["bubble_visible"] = true
	_set_state(state)


func _try_start_onboarding() -> void:
	_ensure_state()
	if _should_disable_for_progressed_save():
		complete_onboarding()
		return

	var state: Dictionary = _get_state()
	if bool(state.get("onboarding_finished", false)):
		return
	if not bool(state.get("welcome_seen", false)):
		_show_welcome_window()
		return

	var active_task_id: String = str(state.get("active_task_id", ""))
	if active_task_id.is_empty():
		_show_next_task_window()
	elif bool(state.get("active_task_accepted", false)):
		state["bubble_visible"] = true
		_set_state(state)
		_refresh_active_completion()
		_update_bubble()
	else:
		_show_task_window(_get_task(active_task_id))


func _show_welcome_window() -> void:
	_close_modal()
	modal_root = _make_modal_root("OnboardingWelcome")
	var column: VBoxContainer = _make_modal_column(Vector2(620, 460))
	column.add_child(_make_title_label(LocalizationSystem.tr_key("onboarding.welcome.title")))
	column.add_child(_make_body_label(LocalizationSystem.tr_key("onboarding.welcome.body")))

	var next_button: Button = _make_action_button("onboarding.next", Color(0.32, 0.58, 0.22, 1.0))
	next_button.pressed.connect(func() -> void:
		var state: Dictionary = _get_state()
		state["welcome_seen"] = true
		_set_state(state)
		_save_state()
		_show_next_task_window()
	)
	column.add_child(next_button)


func _show_next_task_window() -> void:
	var next_task: Dictionary = _get_next_unresolved_task()
	if next_task.is_empty():
		complete_onboarding()
		return

	var state: Dictionary = _get_state()
	state["active_task_id"] = str(next_task.get("id", ""))
	state["active_task_accepted"] = true
	state["active_task_completed"] = false
	state["bubble_visible"] = false
	_set_state(state)
	_refresh_active_completion()
	_update_bubble()
	_save_state()
	onboarding_task_changed.emit(str(next_task.get("id", "")))
	_show_task_window(next_task)


func _show_task_window(task: Dictionary) -> void:
	if task.is_empty():
		_show_next_task_window()
		return

	var task_id: String = str(task.get("id", ""))
	var current_state: Dictionary = _get_state()
	if str(current_state.get("active_task_id", "")) == task_id and not bool(current_state.get("active_task_accepted", false)):
		current_state["active_task_accepted"] = true
		_set_state(current_state)
	_refresh_active_completion()
	_close_modal()
	modal_root = _make_modal_root("OnboardingTask")
	var column: VBoxContainer = _make_modal_column(Vector2(660, 640))

	column.add_child(_make_title_label(_resolve_text(str(task.get("title_key", "")))))
	column.add_child(_make_body_label(_resolve_text(str(task.get("body_key", "")))))

	var action: Label = _make_body_label(LocalizationSystem.tr_key("onboarding.task_prefix") + " " + _resolve_text(str(task.get("action_key", ""))))
	action.add_theme_color_override("font_color", Color(0.28, 0.20, 0.10, 1.0))
	column.add_child(action)

	var progress: Dictionary = _get_task_progress(task)
	var progress_label: Label = _make_small_label(LocalizationSystem.tr_key("onboarding.progress")
		.replace("{current}", str(int(progress.get("current", 0))))
		.replace("{target}", str(int(progress.get("target", 1)))))
	column.add_child(progress_label)

	var reward_label: Label = _make_small_label(LocalizationSystem.tr_key("onboarding.reward") + " " + _format_reward(task))
	reward_label.add_theme_color_override("font_color", Color(0.10, 0.36, 0.14, 1.0))
	column.add_child(reward_label)

	var state: Dictionary = _get_state()
	var completed: bool = bool(state.get("active_task_completed", false))

	if completed:
		var claim_button: Button = _make_action_button("onboarding.claim_reward", Color(0.32, 0.58, 0.22, 1.0))
		claim_button.disabled = _claim_in_progress
		claim_button.pressed.connect(func() -> void:
			_claim_active_reward()
		)
		column.add_child(claim_button)
	else:
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		column.add_child(row)

		var minimize_button: Button = _make_action_button("onboarding.minimize", Color(0.46, 0.35, 0.18, 1.0))
		minimize_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		minimize_button.pressed.connect(func() -> void:
			_minimize_active_task()
		)
		row.add_child(minimize_button)

		if bool(task.get("skippable", true)):
			var skip_button: Button = _make_action_button("onboarding.skip", Color(0.64, 0.25, 0.16, 1.0))
			skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			skip_button.pressed.connect(func() -> void:
				_skip_active_task()
			)
			row.add_child(skip_button)


func _minimize_active_task() -> void:
	var state: Dictionary = _get_state()
	if str(state.get("active_task_id", "")).is_empty():
		return

	state["active_task_accepted"] = true
	state["bubble_visible"] = true
	_set_state(state)
	_refresh_active_completion()
	_close_modal()
	_update_bubble()
	_save_state()


func _skip_active_task() -> void:
	var state: Dictionary = _get_state()
	var task_id: String = str(state.get("active_task_id", ""))
	if task_id.is_empty():
		_show_next_task_window()
		return

	var skipped: Array = state.get("skipped_task_ids", []) as Array
	if not skipped.has(task_id):
		skipped.append(task_id)
	state["skipped_task_ids"] = skipped
	state["active_task_id"] = ""
	state["active_task_accepted"] = false
	state["active_task_completed"] = false
	state["bubble_visible"] = false
	_set_state(state)
	_update_bubble()
	_save_state()
	_show_next_task_window()


func _claim_active_reward() -> void:
	if _claim_in_progress:
		return
	_claim_in_progress = true

	var state: Dictionary = _get_state()
	var task_id: String = str(state.get("active_task_id", ""))
	var task: Dictionary = _get_task(task_id)
	var claimed: Array = state.get("claimed_task_ids", []) as Array
	if task.is_empty() or claimed.has(task_id) or not bool(state.get("active_task_completed", false)):
		_claim_in_progress = false
		_update_bubble()
		return

	_grant_reward(task)
	claimed.append(task_id)
	state["claimed_task_ids"] = claimed

	var completed: Array = state.get("completed_task_ids", []) as Array
	if not completed.has(task_id):
		completed.append(task_id)
	state["completed_task_ids"] = completed

	state["active_task_id"] = ""
	state["active_task_accepted"] = false
	state["active_task_completed"] = false
	state["bubble_visible"] = false
	_set_state(state)
	_claim_in_progress = false
	_update_bubble()
	_save_state()
	_show_next_task_window()


func _grant_reward(task: Dictionary) -> void:
	var reward_value: Variant = task.get("reward", {})
	if typeof(reward_value) != TYPE_DICTIONARY:
		return
	var reward: Dictionary = reward_value as Dictionary
	var coins: float = float(reward.get("coins", 0.0))
	var xp: float = float(reward.get("xp", 0.0))
	if coins > 0.0:
		EconomySystem.add_currency("repticash", coins)
	if xp > 0.0:
		EconomySystem.add_currency("xp", xp)


func _refresh_active_completion() -> void:
	var state: Dictionary = _get_state()
	if not bool(state.get("active_task_accepted", false)):
		return

	var task: Dictionary = _get_task(str(state.get("active_task_id", "")))
	if task.is_empty():
		return

	var progress: Dictionary = _get_task_progress(task)
	if int(progress.get("current", 0)) >= int(progress.get("target", 1)):
		_mark_active_completed()


func _mark_active_completed() -> void:
	var state: Dictionary = _get_state()
	state["active_task_completed"] = true
	state["bubble_visible"] = true
	_set_state(state)


func _get_task_progress(task: Dictionary) -> Dictionary:
	var event_id: String = str(task.get("completion_event", ""))
	var target: int = max(1, int(task.get("completion_amount", 1)))
	var current: int = min(_get_current_amount(event_id), target)
	return {"current": current, "target": target}


func _get_current_amount(event_id: String) -> int:
	match event_id:
		"manual":
			return 1
		"habitat_bought":
			return max(_get_event_counter(event_id), _get_purchased_habitat_count())
		"reptile_owned", "reptile_bought":
			return max(_get_event_counter(event_id), ReptileSystem.get_owned_reptile_count())
		"reptile_assigned":
			return max(_get_event_counter(event_id), _get_assigned_reptile_count())
		_:
			return _get_event_counter(event_id)


func _increment_event_counter(event_id: String) -> void:
	if event_id.is_empty():
		return
	var state: Dictionary = _get_state()
	var counters: Dictionary = state.get("event_counters", {}) as Dictionary
	counters[event_id] = int(counters.get(event_id, 0)) + 1
	state["event_counters"] = counters
	_set_state(state)


func _get_event_counter(event_id: String) -> int:
	var state: Dictionary = _get_state()
	var counters_value: Variant = state.get("event_counters", {})
	if typeof(counters_value) != TYPE_DICTIONARY:
		return 0
	return int((counters_value as Dictionary).get(event_id, 0))


func _get_event_aliases(event_type: String, payload: Dictionary) -> Array[String]:
	var result: Array[String] = []
	match event_type:
		"habitat_purchased":
			result.append("habitat_bought")
		"reptile_purchased":
			result.append("reptile_bought")
			result.append("reptile_owned")
		"reptile_assigned":
			result.append("reptile_assigned")
		"care_action_success":
			result.append("any_reptile_care_action")
			var action_id: String = str(payload.get("action", ""))
			if action_id == "feed":
				result.append("reptile_fed")
			elif action_id == "water":
				result.append("reptile_watered")
			elif action_id == "clean":
				result.append("reptile_cleaned")
			elif action_id == "play":
				result.append("reptile_played")
		"screen_opened":
			match str(payload.get("screen", "")):
				"shop":
					result.append("shop_opened")
				"quests":
					result.append("tasks_opened")
				"upgrades":
					result.append("upgrades_opened")
				"achievements":
					result.append("achievements_opened")
				"gallery":
					result.append("gallery_opened")
		_:
			result.append(event_type)
	return result


func _update_bubble() -> void:
	var state: Dictionary = _get_state()
	var should_show: bool = (
		_bubble_allowed_on_current_screen
		and
		not bool(state.get("onboarding_finished", false))
		and bool(state.get("bubble_visible", false))
		and bool(state.get("active_task_accepted", false))
		and not str(state.get("active_task_id", "")).is_empty()
	)

	if not should_show:
		if bubble_button != null:
			bubble_button.queue_free()
			bubble_button = null
			bubble_dot = null
		return

	if bubble_button == null:
		bubble_button = Button.new()
		bubble_button.name = "OnboardingBubble"
		bubble_button.text = "?"
		bubble_button.custom_minimum_size = BUBBLE_SIZE
		bubble_button.focus_mode = Control.FOCUS_NONE
		bubble_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		bubble_button.add_theme_font_size_override("font_size", 72)
		bubble_button.add_theme_stylebox_override("normal", _make_bubble_style(Color(0.88, 0.63, 0.24, 0.96)))
		bubble_button.add_theme_stylebox_override("hover", _make_bubble_style(Color(0.96, 0.72, 0.30, 1.0)))
		bubble_button.add_theme_stylebox_override("pressed", _make_bubble_style(Color(0.70, 0.46, 0.16, 1.0)))
		bubble_button.pressed.connect(_on_bubble_pressed)
		add_child(bubble_button)

		bubble_dot = _make_bubble_dot()
		bubble_button.add_child(bubble_dot)

	_position_bubble()
	bubble_button.tooltip_text = LocalizationSystem.tr_key("onboarding.bubble_tooltip")
	if bubble_dot != null:
		bubble_dot.visible = bool(state.get("active_task_completed", false))


func _position_bubble() -> void:
	if bubble_button == null:
		return
	bubble_button.anchor_left = 1.0
	bubble_button.anchor_top = 1.0
	bubble_button.anchor_right = 1.0
	bubble_button.anchor_bottom = 1.0
	bubble_button.offset_left = -(BUBBLE_SIZE.x + 24.0)
	bubble_button.offset_right = -24.0
	bubble_button.offset_top = -(BOTTOM_NAV_HEIGHT + BUBBLE_SIZE.y + 22.0)
	bubble_button.offset_bottom = -(BOTTOM_NAV_HEIGHT + 22.0)


func _on_bubble_pressed() -> void:
	var task: Dictionary = _get_task(str(_get_state().get("active_task_id", "")))
	_show_task_window(task)


func _make_bubble_dot() -> Control:
	var dot: Control = Control.new()
	dot.anchor_left = 1.0
	dot.anchor_top = 0.0
	dot.anchor_right = 1.0
	dot.anchor_bottom = 0.0
	dot.offset_left = -29.0
	dot.offset_top = -1.0
	dot.offset_right = -3.0
	dot.offset_bottom = 28.0
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.visible = false

	var circle: Panel = Panel.new()
	circle.set_anchors_preset(Control.PRESET_FULL_RECT)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.12, 0.08, 1.0)
	style.border_color = Color(1.0, 0.92, 0.48, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	circle.add_theme_stylebox_override("panel", style)
	dot.add_child(circle)
	return dot


func _make_modal_root(root_name: String) -> Control:
	var root: Control = Control.new()
	root.name = root_name
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.04, 0.58)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	return root


func _make_modal_column(min_size: Vector2) -> VBoxContainer:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 30
	center.offset_right = -30
	center.offset_top = 80
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT + 40.0)
	modal_root.add_child(center)

	var panel: Control = Control.new()
	panel.custom_minimum_size = min_size
	center.add_child(panel)

	var background: TextureRect = TextureRect.new()
	background.texture = load(MODAL_BACKGROUND_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	return column


func _make_title_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.17, 0.11, 0.06, 1.0))
	return label


func _make_body_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.30, 0.22, 0.14, 1.0))
	return label


func _make_small_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.34, 0.25, 0.13, 1.0))
	return label


func _make_action_button(label_key: String, color: Color) -> Button:
	var button: Button = Button.new()
	button.text = LocalizationSystem.tr_key(label_key)
	button.custom_minimum_size = Vector2(0, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_button_style(color))
	button.add_theme_stylebox_override("hover", _make_button_style(color.lightened(0.10)))
	button.add_theme_stylebox_override("pressed", _make_button_style(color.darkened(0.14)))
	button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.86, 1.0))
	button.add_theme_color_override("font_shadow_color", Color(0.12, 0.07, 0.03, 0.95))
	button.add_theme_constant_override("shadow_offset_y", 2)
	return button


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.20, 0.13, 0.06, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_bubble_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _make_button_style(color)
	style.set_corner_radius_all(28)
	style.border_color = Color(0.33, 0.21, 0.08, 0.85)
	style.set_border_width_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 8
	return style


func _close_modal() -> void:
	if modal_root == null:
		return
	modal_root.queue_free()
	modal_root = null


func _get_next_unresolved_task() -> Dictionary:
	var state: Dictionary = _get_state()
	var completed: Array = state.get("completed_task_ids", []) as Array
	var skipped: Array = state.get("skipped_task_ids", []) as Array
	var claimed: Array = state.get("claimed_task_ids", []) as Array
	for task_value in tasks:
		if typeof(task_value) != TYPE_DICTIONARY:
			continue
		var task: Dictionary = task_value as Dictionary
		var task_id: String = str(task.get("id", ""))
		if task_id.is_empty() or completed.has(task_id) or skipped.has(task_id) or claimed.has(task_id):
			continue
		return task
	return {}


func _get_task(task_id: String) -> Dictionary:
	if task_id.is_empty():
		return {}
	for task_value in tasks:
		if typeof(task_value) == TYPE_DICTIONARY and str((task_value as Dictionary).get("id", "")) == task_id:
			return task_value as Dictionary
	return {}


func _format_reward(task: Dictionary) -> String:
	var reward_value: Variant = task.get("reward", {})
	if typeof(reward_value) != TYPE_DICTIONARY:
		return "-"
	var reward: Dictionary = reward_value as Dictionary
	var pieces: Array[String] = []
	var coins: int = int(reward.get("coins", 0))
	var xp: int = int(reward.get("xp", 0))
	if coins > 0:
		pieces.append(LocalizationSystem.tr_key("currency.repticash") + " " + str(coins))
	if xp > 0:
		pieces.append(str(xp) + " XP")
	return _join_text(pieces, " + ") if not pieces.is_empty() else "-"


func _resolve_text(key: String) -> String:
	var text: String = LocalizationSystem.tr_key(key)
	text = text.replace("{incubator_unlock_level}", str(_get_incubator_unlock_level()))
	text = text.replace("{happiness_income_threshold}", _format_percent(_get_happiness_income_threshold()))
	text = text.replace("{habitat_mismatch_penalty}", _format_habitat_mismatch_penalty())
	return text


func _get_incubator_unlock_level() -> int:
	var file: FileAccess = FileAccess.open("res://data/biomes.json", FileAccess.READ)
	if file == null:
		return 10
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		return 10
	var biomes: Array = parsed as Array
	for biome_value in biomes:
		if typeof(biome_value) != TYPE_DICTIONARY:
			continue
		var biome: Dictionary = biome_value as Dictionary
		if str(biome.get("id", "")) != "incubator":
			continue
		var req_value: Variant = biome.get("unlock_requirements", {})
		if typeof(req_value) == TYPE_DICTIONARY:
			return max(1, int((req_value as Dictionary).get("level", 10)))
	return 10


func _get_happiness_income_threshold() -> float:
	if ReptileSystem.has_method("get_happiness_multiplier"):
		for value in range(100, -1, -1):
			if float(ReptileSystem.call("get_happiness_multiplier", value)) < 1.0:
				return float(value)
	return 50.0


func _format_habitat_mismatch_penalty() -> String:
	var multiplier: float = 0.5
	if ReptileSystem.has_method("get_habitat_match_multiplier"):
		multiplier = 0.5
	var penalty_percent: int = int(round((1.0 - multiplier) * 100.0))
	if LocalizationSystem.get_language() == "pl" and penalty_percent == 50:
		return "50% / o polowe"
	if penalty_percent == 50:
		return "50% / by half"
	return str(penalty_percent) + "%"


func _format_percent(value: float) -> String:
	return str(int(round(value))) + "%"


func _join_text(pieces: Array[String], separator: String) -> String:
	var text: String = ""
	for piece in pieces:
		if text.is_empty():
			text = piece
		else:
			text += separator + piece
	return text


func _get_purchased_habitat_count() -> int:
	var count: int = 0
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return 0
	for habitat_value in (habitats_value as Dictionary).values():
		if typeof(habitat_value) == TYPE_DICTIONARY and bool((habitat_value as Dictionary).get("purchased", false)):
			count += 1
	return count


func _get_assigned_reptile_count() -> int:
	var count: int = 0
	for instance_value in ReptileSystem.get_owned_reptile_instances().values():
		if typeof(instance_value) == TYPE_DICTIONARY and not str((instance_value as Dictionary).get("habitat_id", "")).is_empty():
			count += 1
	return count


func _should_disable_for_progressed_save() -> bool:
	var state: Dictionary = _get_state()
	if bool(state.get("welcome_seen", false)) or bool(state.get("onboarding_finished", false)):
		return false
	if not str(state.get("active_task_id", "")).is_empty():
		return false
	var completed: Array = state.get("completed_task_ids", []) as Array
	var skipped: Array = state.get("skipped_task_ids", []) as Array
	var claimed: Array = state.get("claimed_task_ids", []) as Array
	if not completed.is_empty() or not skipped.is_empty() or not claimed.is_empty():
		return false
	return int(GameState.get_value("level", 1)) > 3 or _get_purchased_habitat_count() > 0 or ReptileSystem.get_owned_reptile_count() > 0


func _ensure_state() -> void:
	var state_value: Variant = GameState.get_value("onboarding_state", {})
	if typeof(state_value) != TYPE_DICTIONARY:
		GameState.set_value("onboarding_state", GameState.get_default_onboarding_state())
		return
	GameState.set_value("onboarding_state", GameState.normalize_onboarding_state(state_value))


func _get_state() -> Dictionary:
	var state_value: Variant = GameState.get_value("onboarding_state", {})
	if typeof(state_value) != TYPE_DICTIONARY:
		return GameState.get_default_onboarding_state()
	return (state_value as Dictionary).duplicate(true)


func _set_state(state: Dictionary) -> void:
	GameState.set_value("onboarding_state", state)


func _save_state() -> void:
	if has_node("/root/SaveSystem"):
		SaveSystem.save_game()


func _on_language_changed(_language: String) -> void:
	if modal_root != null:
		var task_id: String = str(_get_state().get("active_task_id", ""))
		if task_id.is_empty() and not bool(_get_state().get("welcome_seen", false)):
			_show_welcome_window()
		elif not task_id.is_empty():
			_show_task_window(_get_task(task_id))
	_update_bubble()
