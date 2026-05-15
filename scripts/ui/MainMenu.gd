extends Control

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const PL_ICON_PATH := "res://assets/art/ui/icons/menu/pl.png"
const EN_ICON_PATH := "res://assets/art/ui/icons/menu/eng.png"
const ALERT_ICON_PATH := "res://assets/art/ui/icons/menu/alert.png"
const LANGUAGE_ICON_SIZE := Vector2(36, 36)
const ALERT_ICON_SIZE := Vector2(72, 72)

signal play_pressed

var title_label: Label
var play_button: Button
var language_label: Label
var polish_button: Button
var english_button: Button
var settings_button: Button
var reset_modal: Control


func _ready() -> void:
	_build_layout()
	_localize()
	GameState.language_changed.connect(_on_language_changed)


func _build_layout() -> void:
	var background := PanelContainer.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 140)
	margin.add_theme_constant_override("margin_bottom", 140)
	background.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	layout.add_child(title_label)

	play_button = Button.new()
	play_button.custom_minimum_size = Vector2(0, 72)
	play_button.pressed.connect(func() -> void: play_pressed.emit())
	layout.add_child(play_button)

	var language_panel := VBoxContainer.new()
	language_panel.add_theme_constant_override("separation", 8)
	layout.add_child(language_panel)

	language_label = Label.new()
	language_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	language_label.add_theme_font_size_override("font_size", 18)
	language_panel.add_child(language_label)

	var language_row := HBoxContainer.new()
	language_row.alignment = BoxContainer.ALIGNMENT_CENTER
	language_row.add_theme_constant_override("separation", 12)
	language_panel.add_child(language_row)

	polish_button = _make_language_button("pl", PL_ICON_PATH, "PL")
	language_row.add_child(polish_button)

	english_button = _make_language_button("en", EN_ICON_PATH, "EN")
	language_row.add_child(english_button)

	settings_button = Button.new()
	settings_button.custom_minimum_size = Vector2(0, 64)
	settings_button.pressed.connect(_show_reset_confirmation_popup)
	layout.add_child(settings_button)


func _localize() -> void:
	title_label.text = LocalizationSystem.tr_key("game.title")
	play_button.text = LocalizationSystem.tr_key("button.play")
	language_label.text = LocalizationSystem.tr_key("settings.language")
	polish_button.tooltip_text = LocalizationSystem.tr_key("settings.polish")
	english_button.tooltip_text = LocalizationSystem.tr_key("settings.english")
	settings_button.text = LocalizationSystem.tr_key("button.settings")
	_refresh_language_buttons()


func _make_language_button(language: String, icon_path: String, fallback_text: String) -> Button:
	var button := Button.new()
	button.name = language + "LanguageButton"
	button.custom_minimum_size = Vector2(96, 58)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = ""
	button.pressed.connect(func() -> void:
		LocalizationSystem.set_language(language)
	)

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	button.add_child(content)

	var texture := AssetPaths.load_texture(icon_path)
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = LANGUAGE_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
	else:
		push_warning("Language icon missing: " + icon_path)

	var label := Label.new()
	label.name = "FallbackLabel"
	label.text = fallback_text
	label.visible = texture == null
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	content.add_child(label)

	return button


func _refresh_language_buttons() -> void:
	var language := GameState.get_language()
	_set_language_button_active(polish_button, language == "pl")
	_set_language_button_active(english_button, language == "en")


func _set_language_button_active(button: Button, active: bool) -> void:
	var color := Color(0.36, 0.62, 0.28, 0.98) if active else Color(0.92, 0.86, 0.70, 0.92)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)


func _on_language_changed(_language: String) -> void:
	_localize()


func _show_reset_confirmation_popup() -> void:
	_close_reset_modal()
	reset_modal = Control.new()
	reset_modal.name = "ResetConfirmationModal"
	reset_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	reset_modal.z_index = 50
	add_child(reset_modal)

	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.04, 0.66)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reset_modal.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 28
	center.offset_right = -28
	center.offset_top = 80
	center.offset_bottom = -80
	reset_modal.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 360)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var alert_texture := AssetPaths.load_texture(ALERT_ICON_PATH)
	if alert_texture != null:
		var icon := TextureRect.new()
		icon.texture = alert_texture
		icon.custom_minimum_size = ALERT_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(icon)

	var title := Label.new()
	title.text = LocalizationSystem.tr_key("save.reset_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)

	var message := Label.new()
	message.text = LocalizationSystem.tr_key("save.reset_message")
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 16)
	column.add_child(message)

	var confirm_button := Button.new()
	confirm_button.text = LocalizationSystem.tr_key("save.reset_confirm")
	confirm_button.custom_minimum_size = Vector2(0, 54)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.68, 0.22, 0.16, 1.0)))
	confirm_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.78, 0.28, 0.20, 1.0)))
	confirm_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.54, 0.16, 0.12, 1.0)))
	confirm_button.pressed.connect(func() -> void:
		SaveSystem.reset_game()
		_close_reset_modal()
		_localize()
	)
	column.add_child(confirm_button)

	var cancel_button := Button.new()
	cancel_button.text = LocalizationSystem.tr_key("save.reset_cancel")
	cancel_button.custom_minimum_size = Vector2(0, 48)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.pressed.connect(_close_reset_modal)
	column.add_child(cancel_button)


func _close_reset_modal() -> void:
	if reset_modal == null:
		return
	reset_modal.queue_free()
	reset_modal = null


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
