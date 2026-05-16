extends Control

signal biome_selected(biome_id: String)
signal back_pressed

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const BACKGROUND_PATH := "res://assets/art/ui/biomes/biomes_background.png"
const BACK_BUTTON_PATH := "res://assets/art/ui/biomes/back.png"
const TITLE_PL_PATH := "res://assets/art/ui/biomes/biome_map_title_pl.png"
const TITLE_EN_PATH := "res://assets/art/ui/biomes/biome_map_title_en.png"
const GREEN_MEADOW_PL_PATH := "res://assets/art/ui/biomes/green_meadow_pl.png"
const GREEN_MEADOW_EN_PATH := "res://assets/art/ui/biomes/green_meadow_en.png"
const DRY_PRAIRIE_PL_PATH := "res://assets/art/ui/biomes/dry_praire_pl.png"
const DRY_PRAIRIE_EN_PATH := "res://assets/art/ui/biomes/dry_praire_en.png"
const DRY_PRAIRIE_PL_UNLOCK_PATH := "res://assets/art/ui/biomes/dry_praire_pl_unlock.png"
const DRY_PRAIRIE_EN_UNLOCK_PATH := "res://assets/art/ui/biomes/dry_praire_en_unlock.png"
const INCUBATOR_PL_PATH := "res://assets/art/ui/biomes/incubator_pl.png"
const INCUBATOR_EN_PATH := "res://assets/art/ui/biomes/incubator_en.png"
const INCUBATOR_PL_UNLOCK_PATH := "res://assets/art/ui/biomes/incubator_pl_unlock.png"
const INCUBATOR_EN_UNLOCK_PATH := "res://assets/art/ui/biomes/incubator_en_unlock.png"

const GREEN_MEADOW_ID := "green_meadow"
const REFERENCE_SIZE := Vector2(941, 1672)
const BACK_CENTER := Vector2(105, 122)
const BACK_SIZE := Vector2(122, 121)
const TITLE_CENTER := Vector2(489, 248)
const TITLE_SIZE := Vector2(720, 220)
const GREEN_CARD_CENTER := Vector2(470, 566)
const GREEN_CARD_SIZE := Vector2(830, 300)
const DRY_CARD_CENTER := Vector2(470, 945)
const DRY_CARD_SIZE := Vector2(830, 300)
const NEW_CARD_CENTER := Vector2(470, 1264)
const NEW_CARD_SIZE := Vector2(830, 280)
const TOAST_REFERENCE_Y := 1524.0

var background: TextureRect
var ui_layer: Control
var back_button: TextureButton
var title_banner: TextureRect
var title_fallback: Label
var green_meadow_button: TextureButton
var dry_prairie_button: TextureButton
var incubator_button: TextureButton
var toast_panel: PanelContainer
var toast_label: Label
var toast_timer: SceneTreeTimer


func _ready() -> void:
	_build_layout()
	_refresh_language_assets()
	if not GameState.language_changed.is_connected(_on_language_changed):
		GameState.language_changed.connect(_on_language_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and ui_layer != null:
		_layout_controls()


func _build_layout() -> void:
	background = TextureRect.new()
	background.name = "BiomeMapBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = AssetPaths.load_texture(BACKGROUND_PATH)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	ui_layer = Control.new()
	ui_layer.name = "BiomeMapControls"
	ui_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_layer)

	back_button = _make_texture_button("BackButton", Callable(self, "_on_back_pressed"))

	title_banner = TextureRect.new()
	title_banner.name = "TitleBanner"
	title_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(title_banner)

	title_fallback = _make_fallback_label("TitleFallbackLabel")
	title_banner.add_child(title_fallback)

	green_meadow_button = _make_texture_button("GreenMeadowButton", Callable(self, "_on_green_meadow_pressed"))
	_add_fallback_label(green_meadow_button, "GreenMeadowFallbackLabel")

	dry_prairie_button = _make_texture_button("DryPrairieButton", Callable(self, "_on_dry_prairie_pressed"))
	_add_fallback_label(dry_prairie_button, "DryPrairieFallbackLabel")

	incubator_button = _make_texture_button("IncubatorButton", Callable(self, "_on_incubator_pressed"))
	_add_fallback_label(incubator_button, "IncubatorFallbackLabel")

	_build_toast()
	_layout_controls()


func _make_texture_button(button_name: String, pressed_callable: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.name = button_name
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.pressed.connect(pressed_callable)
	ui_layer.add_child(button)
	return button


func _make_fallback_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.visible = false
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.10, 0.06, 0.03, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _add_fallback_label(button: TextureButton, label_name: String) -> Label:
	var label := _make_fallback_label(label_name)
	label.offset_left = 24
	label.offset_right = -24
	label.offset_top = 20
	label.offset_bottom = -20
	button.add_child(label)
	return label


func _build_toast() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "BiomeFeedbackToast"
	toast_panel.visible = false
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel", _make_toast_style())
	ui_layer.add_child(toast_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	toast_panel.add_child(margin)

	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.add_theme_color_override("font_color", Color.WHITE)
	margin.add_child(toast_label)


func _layout_controls() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale: float = min(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	var origin := (viewport_size - REFERENCE_SIZE * scale) * 0.5

	_position_control(back_button, BACK_CENTER, BACK_SIZE, origin, scale)
	_position_control(title_banner, TITLE_CENTER, TITLE_SIZE, origin, scale)
	_position_control(green_meadow_button, GREEN_CARD_CENTER, GREEN_CARD_SIZE, origin, scale)
	_position_control(dry_prairie_button, DRY_CARD_CENTER, DRY_CARD_SIZE, origin, scale)
	_position_control(incubator_button, NEW_CARD_CENTER, NEW_CARD_SIZE, origin, scale)

	title_fallback.add_theme_font_size_override("font_size", max(22, int(round(42.0 * scale))))
	_layout_button_fallback(green_meadow_button, 30, scale)
	_layout_button_fallback(dry_prairie_button, 28, scale)
	_layout_button_fallback(incubator_button, 28, scale)
	_layout_toast(origin, scale, viewport_size)


func _position_control(control: Control, reference_center: Vector2, reference_size: Vector2, origin: Vector2, scale: float) -> void:
	var scaled_size := reference_size * scale
	control.position = origin + (reference_center - reference_size * 0.5) * scale
	control.size = scaled_size
	control.custom_minimum_size = scaled_size


func _layout_button_fallback(button: TextureButton, base_font_size: int, scale: float) -> void:
	var fallback := _get_button_fallback(button)
	if fallback == null:
		return
	fallback.add_theme_font_size_override("font_size", max(18, int(round(float(base_font_size) * scale))))


func _layout_toast(origin: Vector2, scale: float, viewport_size: Vector2) -> void:
	var toast_width: float = min(viewport_size.x - 48.0, 650.0 * scale)
	var toast_size := Vector2(toast_width, 74.0 * scale)
	toast_panel.size = toast_size
	toast_panel.position = Vector2(
		(viewport_size.x - toast_width) * 0.5,
		min(viewport_size.y - toast_size.y - 24.0, origin.y + TOAST_REFERENCE_Y * scale)
	)
	toast_label.add_theme_font_size_override("font_size", max(14, int(round(20.0 * scale))))


func _refresh_language_assets() -> void:
	var is_polish := GameState.get_language() == "pl"

	var dry_req_level: int = _get_biome_unlock_level("dry_prairie")
	var current_level: int = int(GameState.get_value("level", 1))
	var dry_prairie_unlocked: bool = dry_req_level <= 0 or current_level >= dry_req_level
	var dry_prairie_asset: String
	if dry_prairie_unlocked:
		dry_prairie_asset = DRY_PRAIRIE_PL_UNLOCK_PATH if is_polish else DRY_PRAIRIE_EN_UNLOCK_PATH
	else:
		dry_prairie_asset = DRY_PRAIRIE_PL_PATH if is_polish else DRY_PRAIRIE_EN_PATH

	_set_texture_rect(title_banner, TITLE_PL_PATH if is_polish else TITLE_EN_PATH, title_fallback, "biome.map_title", "Biome Map")
	_set_button_texture(green_meadow_button, GREEN_MEADOW_PL_PATH if is_polish else GREEN_MEADOW_EN_PATH, "biome.green_meadow", "Green Meadow")
	_set_button_texture(dry_prairie_button, dry_prairie_asset, "biome.dry_prairie", "Dry Prairie")
	var incubator_req_level: int = _get_biome_unlock_level("incubator")
	var incubator_unlocked: bool = incubator_req_level <= 0 or current_level >= incubator_req_level
	var incubator_asset: String
	if incubator_unlocked:
		incubator_asset = INCUBATOR_PL_UNLOCK_PATH if is_polish else INCUBATOR_EN_UNLOCK_PATH
	else:
		incubator_asset = INCUBATOR_PL_PATH if is_polish else INCUBATOR_EN_PATH
	_set_button_texture(incubator_button, incubator_asset, "biome.incubator", "Incubator")
	_set_button_texture(back_button, BACK_BUTTON_PATH, "", "")

	back_button.tooltip_text = _localized_text("button.back", "Back")
	green_meadow_button.tooltip_text = _localized_text("biome.green_meadow", "Green Meadow")
	dry_prairie_button.tooltip_text = _localized_text("biome.dry_prairie", "Dry Prairie")
	incubator_button.tooltip_text = _localized_text("biome.incubator", "Incubator")


func _set_texture_rect(rect: TextureRect, texture_path: String, fallback_label: Label, fallback_key: String, fallback_text: String) -> void:
	var texture := AssetPaths.load_texture(texture_path)
	rect.texture = texture
	fallback_label.text = _localized_text(fallback_key, fallback_text)
	fallback_label.visible = texture == null


func _set_button_texture(button: TextureButton, texture_path: String, fallback_key: String, fallback_text: String) -> void:
	var texture := AssetPaths.load_texture(texture_path)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_disabled = texture

	var fallback_label := _get_button_fallback(button)
	if fallback_label != null:
		fallback_label.text = _localized_text(fallback_key, fallback_text)
		fallback_label.visible = texture == null


func _get_button_fallback(button: TextureButton) -> Label:
	for child in button.get_children():
		if child is Label and String(child.name).ends_with("FallbackLabel"):
			return child as Label
	return null


func _localized_text(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var text := LocalizationSystem.tr_key(key)
	if text.is_empty() or text == key:
		return fallback
	return text


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_green_meadow_pressed() -> void:
	biome_selected.emit(GREEN_MEADOW_ID)


func _on_dry_prairie_pressed() -> void:
	var req_level: int = _get_biome_unlock_level("dry_prairie")
	var current_level: int = int(GameState.get_value("level", 1))
	if req_level <= 0 or current_level >= req_level:
		biome_selected.emit("dry_prairie")
	else:
		_show_feedback("biome.locked_level_message", "Reach level " + str(req_level) + " to unlock!")


func _get_biome_unlock_level(target_biome_id: String) -> int:
	var file := FileAccess.open("res://data/biomes.json", FileAccess.READ)
	if file == null:
		return 0
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_ARRAY:
		return 0
	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str(entry.get("id", "")) == target_biome_id:
			var req: Variant = entry.get("unlock_requirements", {})
			if typeof(req) == TYPE_DICTIONARY:
				return int((req as Dictionary).get("level", 0))
	return 0


func _on_incubator_pressed() -> void:
	var req_level: int = _get_biome_unlock_level("incubator")
	var current_level: int = int(GameState.get_value("level", 1))
	if req_level <= 0 or current_level >= req_level:
		biome_selected.emit("incubator")
	else:
		_show_feedback("incubator.locked_message", "The Incubator unlocks at level 10.")


func _on_language_changed(_language: String) -> void:
	_refresh_language_assets()


func _show_feedback(message_key: String, fallback: String) -> void:
	toast_label.text = _localized_text(message_key, fallback)
	toast_panel.visible = true
	toast_panel.modulate = Color.WHITE
	toast_timer = get_tree().create_timer(2.25)
	var active_timer := toast_timer
	active_timer.timeout.connect(func() -> void:
		if toast_timer != active_timer:
			return
		toast_panel.visible = false
	)


func _make_toast_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.04, 0.86)
	style.border_color = Color(0.89, 0.68, 0.30, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(14)
	return style
