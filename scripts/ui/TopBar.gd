extends Control

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const REPTICASH_ICON_PATH := "res://assets/art/icons/icon_repticash.png"
const XP_ICON_PATH := "res://assets/art/icons/icon_xp.png"
const FOOD_ICON_PATH := "res://assets/art/ui/icons/menu/food.png"
const WATER_ICON_PATH := "res://assets/art/ui/icons/menu/water.png"

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
	custom_minimum_size = Vector2(0, 78)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var rows := VBoxContainer.new()
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 2)
	margin.add_child(rows)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	rows.add_child(row)

	_add_icon(row, REPTICASH_ICON_PATH)
	cash_label = Label.new()
	cash_label.add_theme_font_size_override("font_size", 18)
	row.add_child(cash_label)

	_add_icon(row, XP_ICON_PATH)
	xp_label = Label.new()
	xp_label.add_theme_font_size_override("font_size", 18)
	row.add_child(xp_label)

	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 18)
	row.add_child(level_label)

	var resource_row := HBoxContainer.new()
	resource_row.alignment = BoxContainer.ALIGNMENT_CENTER
	resource_row.add_theme_constant_override("separation", 12)
	rows.add_child(resource_row)

	_add_icon(resource_row, FOOD_ICON_PATH, Vector2(24, 24))
	food_label = Label.new()
	food_label.add_theme_font_size_override("font_size", 15)
	resource_row.add_child(food_label)

	_add_icon(resource_row, WATER_ICON_PATH, Vector2(24, 24))
	water_label = Label.new()
	water_label.add_theme_font_size_override("font_size", 15)
	resource_row.add_child(water_label)


func _refresh() -> void:
	cash_label.text = str(GameState.get_value("repticash", 0))
	xp_label.text = _format_amount(float(GameState.get_value("xp", 0)))
	level_label.text = LocalizationSystem.tr_key("ui.level_short") + " " + str(GameState.get_value("level", 1))
	food_label.text = str(int(GameState.get_value("food_current", 0))) + "/" + str(int(GameState.get_value("food_max", 100)))
	water_label.text = str(int(GameState.get_value("water_current", 0))) + "/" + str(int(GameState.get_value("water_max", 100)))


func _add_icon(row: HBoxContainer, texture_path: String, icon_size: Vector2 = Vector2(28, 28)) -> void:
	var icon := TextureRect.new()
	icon.texture = AssetPaths.load_texture(texture_path)
	icon.custom_minimum_size = icon_size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = icon.texture != null
	row.add_child(icon)


func _format_amount(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))

	return "%.1f" % value
