extends Control

signal closed

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const MONEY_ICON_PATH := "res://assets/art/icons/icon_repticash.png"
const FOOD_ICON_PATH := "res://assets/art/ui/icons/menu/food.png"
const WATER_ICON_PATH := "res://assets/art/ui/icons/menu/water.png"

var biome_id: String = GameState.DEFAULT_BIOME_ID

var _counter_label: Label
var _feedback_label: Label
var _option_buttons: Dictionary = {}
var _option_labels: Dictionary = {}
var _limit_overlay: Control
var _limit_overlay_label: Label
var _countdown_timer: Timer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_layout()
	_connect_service_signals()
	_refresh_state()


func set_biome_id(value: String) -> void:
	biome_id = value if not value.is_empty() else GameState.DEFAULT_BIOME_ID


func _build_layout() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.01, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 34.0
	center.offset_right = -34.0
	center.offset_top = 132.0
	center.offset_bottom = -176.0
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(800.0, 760.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 36)
	panel_margin.add_theme_constant_override("margin_right", 36)
	panel_margin.add_theme_constant_override("margin_top", 30)
	panel_margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(panel_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel_margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	column.add_child(header)

	var title := Label.new()
	title.text = LocalizationSystem.tr_key("resource_ads_title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.36, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.01, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(62.0, 58.0)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_font_size_override("font_size", 26)
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.42, 0.17, 0.10, 0.98), Color(0.82, 0.55, 0.28, 0.95)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.54, 0.22, 0.13, 1.0), Color(0.95, 0.68, 0.36, 1.0)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.30, 0.11, 0.07, 1.0), Color(0.70, 0.42, 0.20, 1.0)))
	close_button.pressed.connect(_close)
	header.add_child(close_button)

	_counter_label = Label.new()
	_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter_label.add_theme_font_size_override("font_size", 28)
	_counter_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.63, 1.0))
	column.add_child(_counter_label)

	var content_holder := Control.new()
	content_holder.custom_minimum_size = Vector2(0.0, 515.0)
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content_holder)

	var options := VBoxContainer.new()
	options.name = "ResourceAdOptions"
	options.set_anchors_preset(Control.PRESET_FULL_RECT)
	options.add_theme_constant_override("separation", 18)
	content_holder.add_child(options)

	options.add_child(_make_option_button("money", MONEY_ICON_PATH, "resource_ads_money_option"))
	options.add_child(_make_option_button("food", FOOD_ICON_PATH, "resource_ads_food_option"))
	options.add_child(_make_option_button("water", WATER_ICON_PATH, "resource_ads_water_option"))

	_feedback_label = Label.new()
	_feedback_label.custom_minimum_size = Vector2(0.0, 72.0)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.add_theme_font_size_override("font_size", 24)
	_feedback_label.add_theme_color_override("font_color", Color(0.95, 0.83, 0.58, 1.0))
	column.add_child(_feedback_label)

	_limit_overlay = Control.new()
	_limit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_limit_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	content_holder.add_child(_limit_overlay)

	var overlay_bg := ColorRect.new()
	overlay_bg.color = Color(0.02, 0.015, 0.01, 0.78)
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_limit_overlay.add_child(overlay_bg)

	var overlay_center := Control.new()
	overlay_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_center.offset_left = 42.0
	overlay_center.offset_right = -42.0
	_limit_overlay.add_child(overlay_center)

	_limit_overlay_label = Label.new()
	_limit_overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_limit_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_limit_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_limit_overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_limit_overlay_label.add_theme_font_size_override("font_size", 32)
	_limit_overlay_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48, 1.0))
	overlay_center.add_child(_limit_overlay_label)

	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.autostart = true
	_countdown_timer.timeout.connect(_refresh_state)
	add_child(_countdown_timer)


func _make_option_button(action_id: String, icon_path: String, text_key: String) -> Button:
	var button := Button.new()
	button.name = action_id.capitalize() + "RewardButton"
	button.text = ""
	button.custom_minimum_size = Vector2(0.0, 132.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.30, 0.20, 0.10, 0.98), Color(0.78, 0.58, 0.25, 0.95)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.38, 0.26, 0.13, 1.0), Color(0.95, 0.70, 0.30, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.22, 0.14, 0.08, 1.0), Color(0.64, 0.43, 0.18, 1.0)))
	button.pressed.connect(func() -> void:
		_on_option_pressed(action_id)
	)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	button.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(86.0, 86.0)
	icon.texture = AssetPaths.load_texture(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var label := Label.new()
	label.text = _format_resource_ad_text(LocalizationSystem.tr_key(text_key), action_id)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 27)
	label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.72, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.01, 0.90))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	_option_buttons[action_id] = button
	_option_labels[action_id] = label
	return button


func _on_option_pressed(action_id: String) -> void:
	if ResourceAdService.is_limit_reached():
		_refresh_state()
		_set_feedback("resource_ads_error_limit_reached")
		return

	_set_all_options_disabled(true)
	_feedback_label.text = ""
	var success_callback := func(result: Dictionary) -> void:
		_set_feedback(str(result.get("success_key", "")), int(result.get("amount", 0)))
		_refresh_state()

	var error_callback := func(error_key: String) -> void:
		_set_feedback(error_key)
		_refresh_state()

	ResourceAdService.request_resource_reward(action_id, biome_id, success_callback, error_callback)
	_refresh_state()


func _refresh_state(_arg1: Variant = null, _arg2: Variant = null) -> void:
	if _counter_label == null:
		return

	var used: int = ResourceAdService.get_used_count()
	var limit: int = ResourceAdService.get_limit_count()
	var counter_template: String = LocalizationSystem.tr_key("resource_ads_counter")
	_counter_label.text = counter_template.replace("{used}", str(used)).replace("{limit}", str(limit))
	if not counter_template.contains("{limit}") and limit != 5:
		_counter_label.text = _counter_label.text.replace("/5", "/" + str(limit))

	var limit_reached: bool = ResourceAdService.is_limit_reached()
	var busy: bool = ResourceAdService.is_request_active()
	_set_all_options_disabled(limit_reached or busy)
	_refresh_dynamic_option_texts()

	if _limit_overlay != null:
		_limit_overlay.visible = limit_reached
	if limit_reached and _limit_overlay_label != null:
		var remaining_text: String = _format_time(ResourceAdService.get_seconds_until_reset())
		_limit_overlay_label.text = LocalizationSystem.tr_key("resource_ads_limit_reached").replace("{time}", remaining_text)


func _set_all_options_disabled(disabled: bool) -> void:
	for action_id in _option_buttons.keys():
		var button: Button = _option_buttons[action_id] as Button
		if button != null:
			button.disabled = disabled


func _set_feedback(key: String, amount: int = 0) -> void:
	if _feedback_label == null:
		return
	if key.is_empty():
		_feedback_label.text = ""
	else:
		_feedback_label.text = _format_resource_ad_text(LocalizationSystem.tr_key(key), "", amount)


func _refresh_dynamic_option_texts() -> void:
	var money_label: Label = _option_labels.get("money", null) as Label
	if money_label != null:
		money_label.text = _format_resource_ad_text(LocalizationSystem.tr_key("resource_ads_money_option"), "money")


func _format_resource_ad_text(text: String, action_id: String = "", amount: int = 0) -> String:
	if not text.contains("{amount}"):
		return text
	var reward_amount: int = amount
	if reward_amount <= 0 and action_id == "money":
		reward_amount = ResourceAdService.get_money_reward_amount()
	return text.replace("{amount}", _format_amount(float(reward_amount)))


func _connect_service_signals() -> void:
	if ResourceAdService.has_signal("resource_ad_limit_changed") and not ResourceAdService.resource_ad_limit_changed.is_connected(_refresh_state):
		ResourceAdService.resource_ad_limit_changed.connect(_refresh_state)


func _format_time(seconds: int) -> String:
	var safe_seconds: int = max(0, seconds)
	var total_minutes: int = int(ceil(float(safe_seconds) / 60.0))
	var hours: int = int(floor(float(total_minutes) / 60.0))
	var minutes: int = total_minutes % 60
	if hours > 0 and minutes > 0:
		return str(hours) + " h " + str(minutes) + " min"
	if hours > 0:
		return str(hours) + " h"
	return str(max(1, minutes)) + " min"


func _format_amount(amount: float) -> String:
	var formatted: String = ""
	if is_equal_approx(amount, round(amount)):
		formatted = str(int(round(amount)))
	else:
		formatted = "%.1f" % amount

	var parts: PackedStringArray = formatted.split(".", false, 1)
	var integer_part: String = parts[0]
	var sign: String = ""
	if integer_part.begins_with("-"):
		sign = "-"
		integer_part = integer_part.substr(1)

	var grouped: String = ""
	var digit_count: int = 0
	for i in range(integer_part.length() - 1, -1, -1):
		if digit_count > 0 and digit_count % 3 == 0:
			grouped = " " + grouped
		grouped = integer_part.substr(i, 1) + grouped
		digit_count += 1

	if parts.size() > 1:
		return sign + grouped + "." + parts[1]
	return sign + grouped


func _close() -> void:
	closed.emit()
	queue_free()


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.08, 0.04, 0.98)
	style.border_color = Color(0.82, 0.58, 0.22, 0.95)
	style.set_border_width_all(5)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 12
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
