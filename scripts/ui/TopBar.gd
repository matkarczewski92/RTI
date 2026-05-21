extends Control

signal settings_pressed

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const TOP_BAR_ART_PATH := "res://assets/art/ui/top_bar.png"
const SETTINGS_ICON_PATH := "res://assets/art/ui/icons/menu/settings.png"
const TOP_BAR_HEIGHT := 150.722775
const SETTINGS_BUTTON_SIZE_RATIO := Vector2(0.145, 0.45)
const SETTINGS_BUTTON_CENTER_RATIO := Vector2(1.0 - 0.05 - SETTINGS_BUTTON_SIZE_RATIO.x * 0.5, 0.22)

var art_path: String = ""
var biome_id: String = "green_meadow"
var top_bar_ui_positions: Dictionary = {}

var cash_label: Label
var xp_label: Label
var level_label: Label
var food_label: Label
var water_label: Label


func _ready() -> void:
	_build_layout()
	_refresh()
	EconomySystem.currency_changed.connect(func(_currency_id: String, _amount: Variant) -> void: _refresh())
	GameState.state_changed.connect(_refresh)


func _build_layout() -> void:
	custom_minimum_size = Vector2(0, TOP_BAR_HEIGHT)

	var art := TextureRect.new()
	art.name = "TopBarArt"
	art.texture = AssetPaths.load_texture(art_path if not art_path.is_empty() else TOP_BAR_ART_PATH)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.offset_top = 10
	art.offset_bottom = 10
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	cash_label = _make_value_label(26, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(cash_label)
	_position_relative(cash_label, _label_center("cash", 0.155, 0.65), _label_size("cash", 0.140, 0.34))

	xp_label = _make_value_label(26, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(xp_label)
	_position_relative(xp_label, _label_center("xp", 0.375, 0.65), _label_size("xp", 0.145, 0.34))

	food_label = _make_value_label(26, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(food_label)
	_position_relative(food_label, _label_center("food", 0.595, 0.65), _label_size("food", 0.125, 0.34))

	water_label = _make_value_label(26, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(water_label)
	_position_relative(water_label, _label_center("water", 0.805, 0.65), _label_size("water", 0.120, 0.34))

	level_label = _make_value_label(26, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(level_label)
	_position_relative(level_label, _label_center("level", 0.935, 0.72), _label_size("level", 0.075, 0.34))

	var settings_button := TextureButton.new()
	settings_button.name = "SettingsButton"
	settings_button.texture_normal = AssetPaths.load_texture(SETTINGS_ICON_PATH)
	settings_button.texture_hover = settings_button.texture_normal
	settings_button.texture_pressed = settings_button.texture_normal
	settings_button.ignore_texture_size = true
	settings_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	settings_button.tooltip_text = LocalizationSystem.tr_key("settings.title")
	settings_button.pressed.connect(func() -> void: settings_pressed.emit())
	add_child(settings_button)
	_position_relative(settings_button, SETTINGS_BUTTON_CENTER_RATIO, SETTINGS_BUTTON_SIZE_RATIO)
	if settings_button.texture_normal == null:
		var fallback := Label.new()
		fallback.text = "S"
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback.add_theme_font_size_override("font_size", 14)
		fallback.add_theme_color_override("font_color", Color(1.0, 0.97, 0.86, 1.0))
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		settings_button.add_child(fallback)


func _refresh() -> void:
	cash_label.text = _format_amount(float(GameState.get_value("repticash", 0)))
	xp_label.text = _format_amount(float(GameState.get_value("xp", 0)))
	level_label.text = str(GameState.get_value("level", 1))
	if has_node("/root/ReptileSystem"):
		var rs: Node = get_node("/root/ReptileSystem")
		food_label.text = str(rs.call("get_biome_resource_current", biome_id, "food")) + "/" + str(rs.call("get_biome_resource_max", biome_id, "food"))
		water_label.text = str(rs.call("get_biome_resource_current", biome_id, "water")) + "/" + str(rs.call("get_biome_resource_max", biome_id, "water"))
	else:
		food_label.text = str(int(GameState.get_value("food_current", 0))) + "/" + str(int(GameState.get_value("food_max", 100)))
		water_label.text = str(int(GameState.get_value("water_current", 0))) + "/" + str(int(GameState.get_value("water_max", 100)))


func _make_value_label(font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.90, 0.78, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.025, 0.01, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _label_center(key: String, default_cx: float, default_cy: float) -> Vector2:
	if top_bar_ui_positions.has(key):
		var pos: Dictionary = top_bar_ui_positions[key] as Dictionary
		return Vector2(float(pos.get("cx", default_cx)), float(pos.get("cy", default_cy)))
	return Vector2(default_cx, default_cy)


func _label_size(key: String, default_sw: float, default_sh: float) -> Vector2:
	if top_bar_ui_positions.has(key):
		var pos: Dictionary = top_bar_ui_positions[key] as Dictionary
		return Vector2(float(pos.get("sw", default_sw)), float(pos.get("sh", default_sh)))
	return Vector2(default_sw, default_sh)


func _position_relative(control: Control, center_ratio: Vector2, size_ratio: Vector2) -> void:
	control.anchor_left = center_ratio.x - size_ratio.x * 0.5
	control.anchor_top = center_ratio.y - size_ratio.y * 0.5
	control.anchor_right = center_ratio.x + size_ratio.x * 0.5
	control.anchor_bottom = center_ratio.y + size_ratio.y * 0.5
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _format_amount(value: float) -> String:
	var formatted: String = ""
	if is_equal_approx(value, round(value)):
		formatted = str(int(round(value)))
	else:
		formatted = "%.1f" % value

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
