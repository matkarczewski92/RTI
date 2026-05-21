extends Control

signal habitat_pressed(habitat_id: String)
signal speedup_pressed(habitat_id: String)

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const EMPTY_TEXTURE_PATH := "res://assets/art/habitats/habitat_slot_empty.png"
const PURCHASED_EMPTY_TEXTURE_PATH := "res://assets/art/habitats/habitat_slot_purchased_empty.png"
const IN_PROGRESS_TEXTURE_PATH := "res://assets/art/habitats/in_progress.png"
const PLUS_ICON_PATH := "res://assets/art/icons/icon_plus.png"
const ALERT_ICON_PATH := "res://assets/art/ui/icons/menu/alert.png"
const INCOME_PROGRESS_VERTICAL_OFFSET := 64

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
var speedup_button: Button
var occupied_icon_path := ""
var empty_texture_path: String = EMPTY_TEXTURE_PATH
var purchased_texture_path := PURCHASED_EMPTY_TEXTURE_PATH
var hide_empty_background: bool = false
var needs_attention := false
var income_progress_value := 0.0
var is_upgrading := false
var speedup_available := false
var speedup_tooltip := ""
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
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	reptile_icon.offset_left = -51
	reptile_icon.offset_top = -63
	reptile_icon.offset_right = 51
	reptile_icon.offset_bottom = 39
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
	alert_icon.offset_top = -10
	alert_icon.offset_right = 20
	alert_icon.offset_bottom = 30
	visual_root.add_child(alert_icon)

	income_progress = ProgressBar.new()
	income_progress.name = "IncomeProgress"
	income_progress.anchor_left = 0.5
	income_progress.anchor_top = 0.0
	income_progress.anchor_right = 0.5
	income_progress.anchor_bottom = 0.0
	income_progress.offset_left = -52
	income_progress.offset_top = -26 + INCOME_PROGRESS_VERTICAL_OFFSET
	income_progress.offset_right = 52
	income_progress.offset_bottom = -10 + INCOME_PROGRESS_VERTICAL_OFFSET
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
	upgrade_label.offset_left = -110
	upgrade_label.offset_top = 18
	upgrade_label.offset_right = 110
	upgrade_label.offset_bottom = 100
	upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_label.add_theme_font_size_override("font_size", 22)
	upgrade_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	upgrade_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	upgrade_label.add_theme_constant_override("shadow_offset_x", 1)
	upgrade_label.add_theme_constant_override("shadow_offset_y", 1)
	upgrade_label.add_theme_constant_override("shadow_outline_size", 2)
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

	speedup_button = Button.new()
	speedup_button.name = "SpeedUpButton"
	speedup_button.text = ""
	speedup_button.icon = AssetPaths.load_texture(SpeedUpService.get_icon_path())
	speedup_button.expand_icon = true
	speedup_button.flat = true
	speedup_button.focus_mode = Control.FOCUS_NONE
	speedup_button.visible = false
	speedup_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var su_normal := StyleBoxFlat.new()
	su_normal.bg_color = Color(0, 0, 0, 0)
	su_normal.set_corner_radius_all(8)
	var su_hover := StyleBoxFlat.new()
	su_hover.bg_color = Color(1.0, 0.78, 0.20, 0.18)
	su_hover.set_corner_radius_all(8)
	var su_pressed := StyleBoxFlat.new()
	su_pressed.bg_color = Color(1.0, 0.65, 0.12, 0.28)
	su_pressed.set_corner_radius_all(8)
	speedup_button.add_theme_stylebox_override("normal", su_normal)
	speedup_button.add_theme_stylebox_override("hover", su_hover)
	speedup_button.add_theme_stylebox_override("pressed", su_pressed)
	speedup_button.pressed.connect(func() -> void: speedup_pressed.emit(habitat_id))
	add_child(speedup_button)


func _refresh_visuals() -> void:
	if background == null:
		return

	var texture_path := empty_texture_path
	if is_upgrading:
		texture_path = purchased_texture_path if not purchased_texture_path.is_empty() else IN_PROGRESS_TEXTURE_PATH
	elif slot_state == STATE_PURCHASED_EMPTY or slot_state == STATE_OCCUPIED:
		texture_path = purchased_texture_path if not purchased_texture_path.is_empty() else PURCHASED_EMPTY_TEXTURE_PATH

	_apply_state_geometry()
	if hide_empty_background and slot_state == STATE_NOT_PURCHASED:
		background.visible = false
		fallback_panel.visible = false
	else:
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
	if speedup_button != null:
		speedup_button.visible = is_upgrading and speedup_available and speedup_button.icon != null
		speedup_button.tooltip_text = speedup_tooltip
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


func set_empty_texture(path: String) -> void:
	empty_texture_path = path if not path.is_empty() else EMPTY_TEXTURE_PATH
	_refresh_visuals()


func set_habitat_texture(texture_path: String) -> void:
	purchased_texture_path = texture_path
	_refresh_visuals()


func set_upgrade_status(value: bool, status_text: String = "") -> void:
	is_upgrading = value
	upgrade_status_text = status_text
	_refresh_visuals()


func set_speedup_available(value: bool, tooltip: String = "") -> void:
	speedup_available = value
	speedup_tooltip = tooltip
	_refresh_visuals()


func _apply_occupied_icon_texture() -> void:
	if reptile_icon == null:
		return

	reptile_icon.texture = AssetPaths.load_texture(occupied_icon_path) if not occupied_icon_path.is_empty() else null
	reptile_icon.visible = slot_state == STATE_OCCUPIED and reptile_icon.texture != null


func set_hide_empty_background(value: bool) -> void:
	hide_empty_background = value
	_refresh_visuals()


func _apply_state_geometry() -> void:
	var visual_size := empty_visual_size
	var visual_offset := empty_visual_offset
	var plus_half_size := 18

	if slot_state == STATE_PURCHASED_EMPTY or slot_state == STATE_OCCUPIED:
		visual_size = purchased_visual_size
		visual_offset = purchased_visual_offset
		plus_half_size = 24
	elif slot_state == STATE_NOT_PURCHASED and hide_empty_background:
		visual_size = purchased_visual_size
		visual_offset = purchased_visual_offset
		plus_half_size = 36

	visual_root.offset_left = -visual_size.x * 0.5 + visual_offset.x
	visual_root.offset_top = -visual_size.y * 0.5 + visual_offset.y
	visual_root.offset_right = visual_size.x * 0.5 + visual_offset.x
	visual_root.offset_bottom = visual_size.y * 0.5 + visual_offset.y

	plus_icon.offset_left = -plus_half_size
	plus_icon.offset_top = -plus_half_size
	plus_icon.offset_right = plus_half_size
	plus_icon.offset_bottom = plus_half_size

	if touch_button != null:
		if slot_state == STATE_NOT_PURCHASED and hide_empty_background:
			touch_button.anchor_left = 0.5
			touch_button.anchor_top = 0.5
			touch_button.anchor_right = 0.5
			touch_button.anchor_bottom = 0.5
			touch_button.offset_left = -visual_size.x * 0.5 + visual_offset.x
			touch_button.offset_top = -visual_size.y * 0.5 + visual_offset.y
			touch_button.offset_right = visual_size.x * 0.5 + visual_offset.x
			touch_button.offset_bottom = visual_size.y * 0.5 + visual_offset.y
		else:
			touch_button.set_anchors_preset(Control.PRESET_FULL_RECT)
			touch_button.offset_left = 0.0
			touch_button.offset_top = 0.0
			touch_button.offset_right = 0.0
			touch_button.offset_bottom = 0.0

	if speedup_button != null:
		var icon_size: Vector2 = SpeedUpService.get_icon_size()
		icon_size.x = min(icon_size.x, visual_size.x * 0.32)
		icon_size.y = min(icon_size.y, visual_size.y * 0.32)
		var _su_dim: float = min(icon_size.x, icon_size.y)
		icon_size = Vector2(_su_dim, _su_dim)
		var center := Vector2(visual_offset.x, (-visual_size.y * 0.5 + visual_offset.y) + 100.0 + 4.0 + icon_size.y * 0.5)
		speedup_button.anchor_left = 0.5
		speedup_button.anchor_top = 0.5
		speedup_button.anchor_right = 0.5
		speedup_button.anchor_bottom = 0.5
		speedup_button.offset_left = center.x - icon_size.x * 0.5
		speedup_button.offset_top = center.y - icon_size.y * 0.5
		speedup_button.offset_right = center.x + icon_size.x * 0.5
		speedup_button.offset_bottom = center.y + icon_size.y * 0.5
		speedup_button.custom_minimum_size = icon_size


func _refresh_text() -> void:
	if hint_label == null:
		return

	if slot_state == STATE_NOT_PURCHASED:
		hint_label.text = LocalizationSystem.tr_key("ui.buy_habitat")
	elif is_upgrading:
		hint_label.text = upgrade_status_text.split("\n")[0] if not upgrade_status_text.is_empty() else LocalizationSystem.tr_key("habitat.upgrade_in_progress")
	elif slot_state == STATE_PURCHASED_EMPTY:
		hint_label.text = LocalizationSystem.tr_key("ui.place_reptile")
	else:
		hint_label.text = LocalizationSystem.tr_key("ui.open_management")
