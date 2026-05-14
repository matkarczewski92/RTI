extends Control

signal habitat_pressed(habitat_id: String)

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const EMPTY_TEXTURE_PATH := "res://assets/art/habitats/habitat_slot_empty.png"
const PURCHASED_EMPTY_TEXTURE_PATH := "res://assets/art/habitats/habitat_slot_purchased_empty.png"
const PLUS_ICON_PATH := "res://assets/art/icons/icon_plus.png"
const ALERT_ICON_PATH := "res://assets/art/ui/icons/menu/alert.png"

const STATE_NOT_PURCHASED := "not_purchased"
const STATE_PURCHASED_EMPTY := "purchased_empty"
const STATE_OCCUPIED := "occupied"

var habitat_id := ""
var slot_index := 0
var slot_state := STATE_NOT_PURCHASED
var empty_visual_size := Vector2(118, 118)
var purchased_visual_size := Vector2(248, 248)
var empty_visual_offset := Vector2.ZERO
var purchased_visual_offset := Vector2(0, -14)
var visual_root: Control
var background: TextureRect
var fallback_panel: PanelContainer
var plus_icon: TextureRect
var reptile_icon: TextureRect
var alert_icon: TextureRect
var income_progress: ProgressBar
var upgrade_label: Label
var occupied_icon_path := ""
var purchased_texture_path := PURCHASED_EMPTY_TEXTURE_PATH
var needs_attention := false
var income_progress_value := 0.0
var is_upgrading := false
var upgrade_status_text := ""
var hint_label: Label
var touch_button: Button


func _ready() -> void:
	_build_layout()
	_apply_occupied_icon_texture()
	_refresh_visuals()
	GameState.language_changed.connect(func(_language: String) -> void: _refresh_text())


func setup(new_habitat_id: String, new_slot_index: int, new_state: String) -> void:
	habitat_id = new_habitat_id
	slot_index = new_slot_index
	slot_state = new_state
	_refresh_visuals()


func set_visual_tuning(
	new_empty_size: Vector2,
	new_purchased_size: Vector2,
	new_empty_offset: Vector2,
	new_purchased_offset: Vector2
) -> void:
	empty_visual_size = new_empty_size
	purchased_visual_size = new_purchased_size
	empty_visual_offset = new_empty_offset
	purchased_visual_offset = new_purchased_offset
	_refresh_visuals()


func set_state(new_state: String) -> void:
	slot_state = new_state
	_refresh_visuals()


func _build_layout() -> void:
	custom_minimum_size = Vector2(260, 220)

	visual_root = Control.new()
	visual_root.name = "VisualRoot"
	visual_root.anchor_left = 0.5
	visual_root.anchor_top = 0.5
	visual_root.anchor_right = 0.5
	visual_root.anchor_bottom = 0.5
	add_child(visual_root)

	background = TextureRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual_root.add_child(background)

	fallback_panel = PanelContainer.new()
	fallback_panel.name = "FallbackPanel"
	fallback_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual_root.add_child(fallback_panel)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 12)
	fallback_panel.add_child(hint_label)

	plus_icon = TextureRect.new()
	plus_icon.name = "PlusIcon"
	plus_icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
	plus_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	plus_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plus_icon.anchor_left = 0.5
	plus_icon.anchor_top = 0.5
	plus_icon.anchor_right = 0.5
	plus_icon.anchor_bottom = 0.5
	plus_icon.offset_left = -19
	plus_icon.offset_top = -19
	plus_icon.offset_right = 19
	plus_icon.offset_bottom = 19
	visual_root.add_child(plus_icon)

	reptile_icon = TextureRect.new()
	reptile_icon.name = "ReptileIcon"
	reptile_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	reptile_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reptile_icon.anchor_left = 0.5
	reptile_icon.anchor_top = 0.5
	reptile_icon.anchor_right = 0.5
	reptile_icon.anchor_bottom = 0.5
	reptile_icon.offset_left = -38
	reptile_icon.offset_top = -50
	reptile_icon.offset_right = 38
	reptile_icon.offset_bottom = 26
	visual_root.add_child(reptile_icon)

	alert_icon = TextureRect.new()
	alert_icon.name = "NeedAlertIcon"
	alert_icon.texture = AssetPaths.load_texture(ALERT_ICON_PATH)
	alert_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	alert_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	alert_icon.anchor_left = 0.5
	alert_icon.anchor_top = 0.0
	alert_icon.anchor_right = 0.5
	alert_icon.anchor_bottom = 0.0
	alert_icon.offset_left = -20
	alert_icon.offset_top = -14
	alert_icon.offset_right = 20
	alert_icon.offset_bottom = 26
	visual_root.add_child(alert_icon)

	income_progress = ProgressBar.new()
	income_progress.name = "IncomeProgress"
	income_progress.anchor_left = 0.5
	income_progress.anchor_top = 0.0
	income_progress.anchor_right = 0.5
	income_progress.anchor_bottom = 0.0
	income_progress.offset_left = -52
	income_progress.offset_top = -26
	income_progress.offset_right = 52
	income_progress.offset_bottom = -10
	income_progress.min_value = 0
	income_progress.max_value = 100
	income_progress.show_percentage = false
	income_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	income_progress.modulate = Color(1.0, 1.0, 1.0, 0.96)
	var progress_background: StyleBoxFlat = StyleBoxFlat.new()
	progress_background.bg_color = Color(0.14, 0.10, 0.06, 0.48)
	progress_background.set_corner_radius_all(6)
	income_progress.add_theme_stylebox_override("background", progress_background)
	var progress_fill: StyleBoxFlat = StyleBoxFlat.new()
	progress_fill.bg_color = Color(0.28, 0.76, 0.28, 0.95)
	progress_fill.set_corner_radius_all(6)
	income_progress.add_theme_stylebox_override("fill", progress_fill)
	visual_root.add_child(income_progress)

	upgrade_label = Label.new()
	upgrade_label.name = "UpgradeLabel"
	upgrade_label.anchor_left = 0.5
	upgrade_label.anchor_top = 0.0
	upgrade_label.anchor_right = 0.5
	upgrade_label.anchor_bottom = 0.0
	upgrade_label.offset_left = -68
	upgrade_label.offset_top = 22
	upgrade_label.offset_right = 68
	upgrade_label.offset_bottom = 52
	upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_label.add_theme_font_size_override("font_size", 11)
	upgrade_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78, 1.0))
	upgrade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_root.add_child(upgrade_label)

	touch_button = Button.new()
	touch_button.name = "TouchButton"
	touch_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_button.text = ""
	touch_button.flat = true
	touch_button.focus_mode = Control.FOCUS_NONE
	touch_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	touch_button.pressed.connect(func() -> void: habitat_pressed.emit(habitat_id))
	add_child(touch_button)


func _refresh_visuals() -> void:
	if background == null:
		return

	var texture_path := EMPTY_TEXTURE_PATH
	if slot_state == STATE_PURCHASED_EMPTY or slot_state == STATE_OCCUPIED:
		texture_path = purchased_texture_path if not purchased_texture_path.is_empty() else PURCHASED_EMPTY_TEXTURE_PATH

	_apply_state_geometry()
	var texture: Texture2D = AssetPaths.load_texture(texture_path)
	background.texture = texture
	background.visible = texture != null
	fallback_panel.visible = texture == null
	plus_icon.visible = slot_state != STATE_OCCUPIED and not is_upgrading and plus_icon.texture != null
	_apply_occupied_icon_texture()
	reptile_icon.visible = slot_state == STATE_OCCUPIED and reptile_icon.texture != null
	if alert_icon != null:
		alert_icon.visible = slot_state == STATE_OCCUPIED and not is_upgrading and needs_attention and alert_icon.texture != null
	if income_progress != null:
		income_progress.visible = slot_state == STATE_OCCUPIED and not is_upgrading
		income_progress.value = income_progress_value * 100.0
	if upgrade_label != null:
		upgrade_label.text = upgrade_status_text
		upgrade_label.visible = is_upgrading and not upgrade_status_text.is_empty()
	_refresh_text()


func set_occupied_icon(icon_path: String) -> void:
	occupied_icon_path = icon_path
	if reptile_icon == null:
		return

	_apply_occupied_icon_texture()


func set_needs_attention(value: bool) -> void:
	needs_attention = value
	if alert_icon == null:
		return

	alert_icon.visible = slot_state == STATE_OCCUPIED and not is_upgrading and needs_attention and alert_icon.texture != null


func set_income_progress(value: float) -> void:
	income_progress_value = clamp(value, 0.0, 1.0)
	if income_progress == null:
		return

	income_progress.visible = slot_state == STATE_OCCUPIED and not is_upgrading
	income_progress.value = income_progress_value * 100.0


func set_habitat_texture(texture_path: String) -> void:
	purchased_texture_path = texture_path
	_refresh_visuals()


func set_upgrade_status(value: bool, status_text: String = "") -> void:
	is_upgrading = value
	upgrade_status_text = status_text
	_refresh_visuals()


func _apply_occupied_icon_texture() -> void:
	if reptile_icon == null:
		return

	reptile_icon.texture = AssetPaths.load_texture(occupied_icon_path) if not occupied_icon_path.is_empty() else null
	reptile_icon.visible = slot_state == STATE_OCCUPIED and reptile_icon.texture != null


func _apply_state_geometry() -> void:
	var visual_size := empty_visual_size
	var visual_offset := empty_visual_offset
	var plus_half_size := 18

	if slot_state == STATE_PURCHASED_EMPTY or slot_state == STATE_OCCUPIED:
		visual_size = purchased_visual_size
		visual_offset = purchased_visual_offset
		plus_half_size = 24

	visual_root.offset_left = -visual_size.x * 0.5 + visual_offset.x
	visual_root.offset_top = -visual_size.y * 0.5 + visual_offset.y
	visual_root.offset_right = visual_size.x * 0.5 + visual_offset.x
	visual_root.offset_bottom = visual_size.y * 0.5 + visual_offset.y

	plus_icon.offset_left = -plus_half_size
	plus_icon.offset_top = -plus_half_size
	plus_icon.offset_right = plus_half_size
	plus_icon.offset_bottom = plus_half_size


func _refresh_text() -> void:
	if hint_label == null:
		return

	if slot_state == STATE_NOT_PURCHASED:
		hint_label.text = LocalizationSystem.tr_key("ui.buy_habitat")
	elif is_upgrading:
		hint_label.text = LocalizationSystem.tr_key("habitat.upgrading")
	elif slot_state == STATE_PURCHASED_EMPTY:
		hint_label.text = LocalizationSystem.tr_key("ui.place_reptile")
	else:
		hint_label.text = LocalizationSystem.tr_key("ui.open_management")
