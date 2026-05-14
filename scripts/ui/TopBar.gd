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
var income_progress: ProgressBar
var income_time_label: Label


func _ready() -> void:
	_build_layout()
	
	if EconomySystem.has_signal("income_progress_updated"):
		EconomySystem.income_progress_updated.connect(_on_income_progress)
	if EconomySystem.has_signal("income_tick"):
		EconomySystem.income_tick.connect(_on_income_tick)
	if EconomySystem.has_signal("offline_income_claimed"):
		EconomySystem.offline_income_claimed.connect(_on_income_tick)

	_refresh()
	EconomySystem.currency_changed.connect(func(_currency_id: String, _amount: Variant) -> void: _refresh())
	GameState.state_changed.connect(_refresh)
	
	# Dynamicznie dodajemy skrypt okienka zarobku offline, pomijając brakującą scenę
	if ResourceLoader.exists("res://scripts/ui/OfflineIncomePopup.gd"):
		var popup_script = load("res://scripts/ui/OfflineIncomePopup.gd")
		if popup_script:
			var popup = popup_script.new()
			add_child(popup)
	else:
		push_warning("OfflineIncomePopup.gd not found. Offline income popup will not appear.")


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

	var income_row := HBoxContainer.new()
	income_row.alignment = BoxContainer.ALIGNMENT_CENTER
	income_row.add_theme_constant_override("separation", 10)
	rows.add_child(income_row)

	income_progress = ProgressBar.new()
	income_progress.custom_minimum_size = Vector2(140, 12)
	income_progress.show_percentage = false
	income_row.add_child(income_progress)

	income_time_label = Label.new()
	income_time_label.add_theme_font_size_override("font_size", 14)
	income_time_label.text = "60s"
	income_row.add_child(income_time_label)


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


func _on_income_progress(progress: float, time_left: int) -> void:
	if is_instance_valid(income_progress):
		income_progress.value = progress * 100.0
	if is_instance_valid(income_time_label):
		income_time_label.text = str(time_left) + "s"


func _on_income_tick(amount: int) -> void:
	if amount <= 0:
		return
	var float_label = Label.new()
	float_label.text = "+R$ " + str(amount)
	float_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	float_label.add_theme_font_size_override("font_size", 20)
	add_child(float_label)
	float_label.global_position = cash_label.global_position + Vector2(20, 20)
	
	var tween = create_tween()
	tween.tween_property(float_label, "position:y", float_label.position.y - 40.0, 2.0)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(float_label.queue_free)
