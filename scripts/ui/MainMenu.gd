extends Control

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")
const LayoutScale := preload("res://scripts/helpers/LayoutScale.gd")

const WELCOME_BACKGROUND_PATH := "res://assets/art/ui/welcome_screen/welcome_screen.png"
const PLAY_PL_PATH := "res://assets/art/ui/welcome_screen/play_orange_pl.png"
const PLAY_EN_PATH := "res://assets/art/ui/welcome_screen/play_orange_en.png"
const SETTINGS_PL_PATH := "res://assets/art/ui/welcome_screen/settings_pl.png"
const SETTINGS_EN_PATH := "res://assets/art/ui/welcome_screen/settings_en.png"
const LANGUAGE_PL_PATH := "res://assets/art/ui/welcome_screen/pl.png"
const LANGUAGE_EN_PATH := "res://assets/art/ui/welcome_screen/en.png"
const SETTINGS_MODAL_SCRIPT := preload("res://scripts/ui/SettingsModal.gd")

const REFERENCE_SIZE := Vector2(1080.0, 1920.0)
const PLAY_CENTER := Vector2(539.4, 1022.0)
const PLAY_SIZE := Vector2(677.2, 218.2)
const POLISH_CENTER := Vector2(378.7, 1327.5)
const ENGLISH_CENTER := Vector2(702.4, 1327.5)
const LANGUAGE_SIZE := Vector2(304.1, 227.4)
const SETTINGS_CENTER := Vector2(539.4, 1522.7)
const SETTINGS_SIZE := Vector2(470.6, 135.5)

signal play_pressed

const VERSION_STRING := "v. 0.1.0 - pre-release-beta"

var background: TextureRect
var ui_layer: Control
var play_button: TextureButton
var polish_button: TextureButton
var english_button: TextureButton
var settings_button: TextureButton
var settings_modal: Control
var version_label: Label


func _ready() -> void:
	_build_layout()
	_refresh_language_assets()
	if not GameState.language_changed.is_connected(_on_language_changed):
		GameState.language_changed.connect(_on_language_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and ui_layer != null:
		_layout_buttons()


func _build_layout() -> void:
	background = TextureRect.new()
	background.name = "WelcomeBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = AssetPaths.load_texture(WELCOME_BACKGROUND_PATH)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	ui_layer = Control.new()
	ui_layer.name = "WelcomeControls"
	ui_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_layer)

	play_button = _make_texture_button("PlayButton", Callable(self, "_on_play_pressed"))
	_add_fallback_label(play_button, "PlayFallbackLabel")

	polish_button = _make_texture_button("PolishButton", Callable(self, "_on_language_pressed").bind("pl"))

	english_button = _make_texture_button("EnglishButton", Callable(self, "_on_language_pressed").bind("en"))

	settings_button = _make_texture_button("SettingsButton", Callable(self, "_open_existing_settings_flow"))
	_add_fallback_label(settings_button, "SettingsFallbackLabel")

	version_label = Label.new()
	version_label.name = "VersionLabel"
	version_label.text = VERSION_STRING
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version_label.anchor_left = 0.0
	version_label.anchor_right = 1.0
	version_label.anchor_top = 1.0
	version_label.anchor_bottom = 1.0
	version_label.offset_top = -48.0
	version_label.offset_bottom = -8.0
	version_label.add_theme_font_size_override("font_size", 24)
	version_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	version_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	version_label.add_theme_constant_override("shadow_offset_x", 1)
	version_label.add_theme_constant_override("shadow_offset_y", 1)
	version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(version_label)

	_layout_buttons()


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


func _add_fallback_label(button: TextureButton, label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.visible = false
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.07, 0.03, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	return label


func _layout_buttons() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale: float = LayoutScale.fit_scale(viewport_size, REFERENCE_SIZE)
	var origin := LayoutScale.fit_origin(viewport_size, scale, REFERENCE_SIZE)

	_position_control(play_button, PLAY_CENTER, PLAY_SIZE, origin, scale)
	_position_control(polish_button, POLISH_CENTER, LANGUAGE_SIZE, origin, scale)
	_position_control(english_button, ENGLISH_CENTER, LANGUAGE_SIZE, origin, scale)
	_position_control(settings_button, SETTINGS_CENTER, SETTINGS_SIZE, origin, scale)

	_layout_fallback_label(play_button, scale, 42)
	_layout_fallback_label(settings_button, scale, 28)

	if version_label != null:
		version_label.add_theme_font_size_override("font_size", max(14, int(round(24.0 * scale))))


func _position_control(control: Control, reference_center: Vector2, reference_size: Vector2, origin: Vector2, scale: float) -> void:
	var scaled_size := reference_size * scale
	control.position = origin + (reference_center - reference_size * 0.5) * scale
	control.size = scaled_size
	control.custom_minimum_size = scaled_size


func _layout_fallback_label(button: TextureButton, scale: float, base_font_size: int) -> void:
	var label := _get_fallback_label(button)
	if label == null:
		return
	label.add_theme_font_size_override("font_size", max(18, int(round(float(base_font_size) * scale))))


func _refresh_language_assets() -> void:
	var language := GameState.get_language()
	var is_polish := language == "pl"

	_set_button_texture(play_button, PLAY_PL_PATH if is_polish else PLAY_EN_PATH, "menu.play", "Play")
	_set_button_texture(settings_button, SETTINGS_PL_PATH if is_polish else SETTINGS_EN_PATH, "menu.settings", "Settings")
	_set_button_texture(polish_button, LANGUAGE_PL_PATH, "", "")
	_set_button_texture(english_button, LANGUAGE_EN_PATH, "", "")

	play_button.tooltip_text = _localized_text("menu.play", "Play")
	polish_button.tooltip_text = _localized_text("settings.polish", "Polish")
	english_button.tooltip_text = _localized_text("settings.english", "English")
	settings_button.tooltip_text = _localized_text("menu.settings", "Settings")

	_refresh_language_buttons()


func _set_button_texture(button: TextureButton, texture_path: String, fallback_key: String, fallback_text: String) -> void:
	var texture := AssetPaths.load_texture(texture_path)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_disabled = texture

	var fallback_label := _get_fallback_label(button)
	if fallback_label != null:
		fallback_label.text = _localized_text(fallback_key, fallback_text)
		fallback_label.visible = texture == null


func _get_fallback_label(button: TextureButton) -> Label:
	var play_fallback := button.get_node_or_null("PlayFallbackLabel") as Label
	if play_fallback != null:
		return play_fallback
	return button.get_node_or_null("SettingsFallbackLabel") as Label


func _localized_text(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var text := LocalizationSystem.tr_key(key)
	if text.is_empty() or text == key:
		return fallback
	return text


func _refresh_language_buttons() -> void:
	var language := GameState.get_language()
	_set_language_button_active(polish_button, language == "pl")
	_set_language_button_active(english_button, language == "en")


func _set_language_button_active(button: TextureButton, active: bool) -> void:
	button.modulate = Color(1.0, 1.0, 1.0, 1.0 if active else 0.65)


func _on_play_pressed() -> void:
	play_pressed.emit()


func _on_language_pressed(language: String) -> void:
	LocalizationSystem.set_language(language)
	_refresh_language_assets()


func _on_language_changed(_language: String) -> void:
	_refresh_language_assets()


func _open_existing_settings_flow() -> void:
	_show_settings_screen()


func _show_settings_screen() -> void:
	if settings_modal != null and is_instance_valid(settings_modal):
		settings_modal.move_to_front()
		return
	settings_modal = SETTINGS_MODAL_SCRIPT.new() as Control
	settings_modal.name = "SettingsModal"
	settings_modal.connect("closed", func() -> void:
		settings_modal = null
	)
	settings_modal.connect("reset_completed", func() -> void:
		settings_modal = null
		_refresh_language_assets()
	)
	add_child(settings_modal)


func _make_modal_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.90, 0.76, 0.98)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.45, 0.30, 0.14, 1.0)
	style.set_corner_radius_all(18)
	return style


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
