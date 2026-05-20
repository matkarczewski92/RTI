extends Control

signal closed
signal reset_completed

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const SETTINGS_ICON_PATH := "res://assets/art/ui/icons/menu/settings.png"
const MUSIC_ICON_PATH := "res://assets/art/ui/icons/menu/music.png"
const SFX_ICON_PATH := "res://assets/art/ui/icons/menu/sfx.png"
const VIBRATION_ICON_PATH := "res://assets/art/ui/icons/menu/vibration.png"
const ALERT_ICON_PATH := "res://assets/art/ui/icons/menu/alert.png"
const APP_VERSION := "v0.1 MVP"

var title_label: Label
var language_label: Label
var polish_button: Button
var english_button: Button
var reset_button: Button
var version_label: Label
var privacy_title_label: Label
var privacy_body_label: Label
var privacy_button: Button
var toggle_labels: Dictionary = {}
var toggle_status_labels: Dictionary = {}
var toggle_buttons: Dictionary = {}
var reset_confirmation_modal: Control
var missing_icon_warnings: Dictionary = {}


func _ready() -> void:
	z_index = 300
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_refresh_from_state()
	if not GameState.language_changed.is_connected(_on_language_changed):
		GameState.language_changed.connect(_on_language_changed)


func _build_layout() -> void:
	var overlay := ColorRect.new()
	overlay.name = "SettingsDimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.68)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel_w := 560.0
	var panel_h := 1025.0
	var vp := get_viewport_rect().size
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = (vp.x - panel_w) * 0.5
	panel.offset_top = (vp.y - panel_h) * 0.5
	panel.offset_right = (vp.x + panel_w) * 0.5
	panel.offset_bottom = (vp.y + panel_h) * 0.5
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	header.add_child(_make_icon(SETTINGS_ICON_PATH, Vector2(46, 46)))

	title_label = _make_label("", 28, Color(0.17, 0.11, 0.06, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(52, 52)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(_close)
	_style_button(close_button, Color(0.65, 0.20, 0.14, 1.0), Color(0.75, 0.26, 0.18, 1.0), Color(0.50, 0.14, 0.10, 1.0))
	header.add_child(close_button)

	column.add_child(_make_separator())

	language_label = _make_label("", 20, Color(0.22, 0.15, 0.08, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	column.add_child(language_label)

	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 10)
	column.add_child(language_row)

	polish_button = _make_action_button("", Callable(self, "_set_language").bind("pl"))
	polish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_row.add_child(polish_button)

	english_button = _make_action_button("", Callable(self, "_set_language").bind("en"))
	english_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_row.add_child(english_button)

	column.add_child(_make_toggle_row("music_enabled", "settings.music", MUSIC_ICON_PATH))
	column.add_child(_make_toggle_row("sfx_enabled", "settings.sfx", SFX_ICON_PATH))
	column.add_child(_make_toggle_row("vibration_enabled", "settings.vibration", VIBRATION_ICON_PATH))

	reset_button = _make_action_button("", Callable(self, "_show_reset_confirmation"))
	_style_button(reset_button, Color(0.67, 0.26, 0.16, 1.0), Color(0.77, 0.32, 0.20, 1.0), Color(0.52, 0.18, 0.11, 1.0))
	reset_button.custom_minimum_size = Vector2(0, 58)
	column.add_child(reset_button)

	version_label = _make_label("", 16, Color(0.34, 0.26, 0.16, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(version_label)

	column.add_child(_make_separator())

	privacy_button = _make_action_button("", Callable(self, "_show_privacy_placeholder"))
	privacy_button.custom_minimum_size = Vector2(0, 50)
	column.add_child(privacy_button)

	privacy_title_label = _make_label("", 18, Color(0.22, 0.15, 0.08, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	column.add_child(privacy_title_label)

	privacy_body_label = _make_label("", 14, Color(0.38, 0.30, 0.20, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	privacy_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(privacy_body_label)

	column.add_child(_make_separator())

	var dev_label := _make_label("DEV", 13, Color(0.55, 0.18, 0.08, 0.75), HORIZONTAL_ALIGNMENT_LEFT)
	column.add_child(dev_label)

	var dev_row := HBoxContainer.new()
	dev_row.add_theme_constant_override("separation", 8)
	column.add_child(dev_row)

	var dev_input := LineEdit.new()
	dev_input.name = "DevInput"
	dev_input.placeholder_text = "command..."
	dev_input.custom_minimum_size = Vector2(0, 48)
	dev_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dev_input.add_theme_font_size_override("font_size", 14)
	dev_row.add_child(dev_input)

	var dev_result := _make_label("", 13, Color(0.20, 0.50, 0.18, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	dev_result.name = "DevResult"
	column.add_child(dev_result)

	var dev_accept := Button.new()
	dev_accept.text = "OK"
	dev_accept.custom_minimum_size = Vector2(64, 48)
	dev_accept.focus_mode = Control.FOCUS_NONE
	_style_button(dev_accept, Color(0.22, 0.38, 0.60, 1.0), Color(0.28, 0.46, 0.72, 1.0), Color(0.16, 0.28, 0.48, 1.0))
	dev_accept.pressed.connect(func() -> void:
		var msg := _execute_dev_command(dev_input.text)
		dev_result.text = msg
		dev_input.text = ""
	)
	dev_input.text_submitted.connect(func(text: String) -> void:
		var msg := _execute_dev_command(text)
		dev_result.text = msg
		dev_input.text = ""
	)
	dev_row.add_child(dev_accept)


func _make_toggle_row(setting_key: String, label_key: String, icon_path: String) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _make_row_style())
	row.custom_minimum_size = Vector2(0, 70)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	hbox.add_child(_make_icon(icon_path, Vector2(44, 44)))

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 2)
	hbox.add_child(text_column)

	var label := _make_label("", 18, Color(0.18, 0.12, 0.07, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	text_column.add_child(label)

	var status := _make_label("", 13, Color(0.40, 0.31, 0.20, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	text_column.add_child(status)

	var toggle := CheckButton.new()
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.toggled.connect(func(enabled: bool) -> void:
		_set_bool_setting(setting_key, enabled)
	)
	hbox.add_child(toggle)

	toggle_labels[setting_key] = {"label": label, "key": label_key}
	toggle_status_labels[setting_key] = status
	toggle_buttons[setting_key] = toggle
	return row


func _set_language(language: String) -> void:
	LocalizationSystem.set_language(language)
	_save_settings()
	_refresh_from_state()


func _set_bool_setting(setting_key: String, enabled: bool) -> void:
	GameState.set_setting(setting_key, enabled)
	_apply_placeholder_setting_hook(setting_key, enabled)
	_save_settings()
	_refresh_from_state()


func _apply_placeholder_setting_hook(setting_key: String, enabled: bool) -> void:
	var audio_system: Node = get_node_or_null("/root/AudioSystem")
	if audio_system == null:
		return
	if setting_key == "music_enabled" and audio_system.has_method("set_music_enabled"):
		audio_system.call("set_music_enabled", enabled)
	elif setting_key == "sfx_enabled" and audio_system.has_method("set_sfx_enabled"):
		audio_system.call("set_sfx_enabled", enabled)


func _save_settings() -> void:
	if has_node("/root/SaveSystem"):
		SaveSystem.save_game()


func _refresh_from_state() -> void:
	var settings: Dictionary = GameState.get_settings()
	title_label.text = LocalizationSystem.tr_key("settings.title")
	language_label.text = LocalizationSystem.tr_key("settings.language")
	polish_button.text = LocalizationSystem.tr_key("settings.polish")
	english_button.text = LocalizationSystem.tr_key("settings.english")
	reset_button.text = LocalizationSystem.tr_key("settings.reset_game")
	version_label.text = LocalizationSystem.tr_key("settings.version") + ": " + APP_VERSION
	privacy_button.text = LocalizationSystem.tr_key("settings.privacy_policy")
	privacy_title_label.text = LocalizationSystem.tr_key("settings.privacy_policy")
	privacy_body_label.text = LocalizationSystem.tr_key("settings.privacy_placeholder")

	_style_language_button(polish_button, GameState.get_language() == "pl")
	_style_language_button(english_button, GameState.get_language() == "en")

	for setting_key in toggle_labels.keys():
		var label_data: Dictionary = toggle_labels.get(setting_key, {})
		var label: Label = label_data.get("label", null) as Label
		if label != null:
			label.text = LocalizationSystem.tr_key(str(label_data.get("key", "")))
		var enabled: bool = bool(settings.get(setting_key, true))
		var status: Label = toggle_status_labels.get(setting_key, null) as Label
		if status != null:
			status.text = LocalizationSystem.tr_key("settings.on" if enabled else "settings.off")
		var toggle: CheckButton = toggle_buttons.get(setting_key, null) as CheckButton
		if toggle != null:
			toggle.set_pressed_no_signal(enabled)


func _show_privacy_placeholder() -> void:
	_show_message_modal("settings.privacy_policy", "settings.privacy_placeholder")


func _show_message_modal(title_key: String, message_key: String) -> void:
	var modal := _make_overlay_modal("SettingsMessageModal")
	var column := _make_centered_modal_column(modal, Vector2(430, 240))
	column.add_child(_make_label(LocalizationSystem.tr_key(title_key), 22, Color(0.17, 0.11, 0.06, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	var message := _make_label(LocalizationSystem.tr_key(message_key), 15, Color(0.30, 0.22, 0.14, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	column.add_child(_make_action_button(LocalizationSystem.tr_key("ui.ok"), func() -> void:
		modal.queue_free()
	))


func _show_reset_confirmation() -> void:
	_close_reset_confirmation()
	reset_confirmation_modal = _make_overlay_modal("SettingsResetConfirmation")
	var column := _make_centered_modal_column(reset_confirmation_modal, Vector2(450, 390))

	column.add_child(_make_icon(ALERT_ICON_PATH, Vector2(74, 74)))
	column.add_child(_make_label(LocalizationSystem.tr_key("save.reset_title"), 24, Color(0.17, 0.11, 0.06, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	var message := _make_label(LocalizationSystem.tr_key("save.reset_message"), 15, Color(0.30, 0.22, 0.14, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)

	var confirm := _make_action_button(LocalizationSystem.tr_key("save.reset_confirm"), func() -> void:
		set_meta("closing_for_reset", true)
		SaveSystem.reset_game()
		_close_reset_confirmation()
		_close()
		reset_completed.emit()
	)
	_style_button(confirm, Color(0.67, 0.26, 0.16, 1.0), Color(0.77, 0.32, 0.20, 1.0), Color(0.52, 0.18, 0.11, 1.0))
	column.add_child(confirm)

	column.add_child(_make_action_button(LocalizationSystem.tr_key("save.reset_cancel"), _close_reset_confirmation))


func _close_reset_confirmation() -> void:
	if reset_confirmation_modal == null:
		return
	reset_confirmation_modal.queue_free()
	reset_confirmation_modal = null


func _make_overlay_modal(modal_name: String) -> Control:
	var modal := Control.new()
	modal.name = modal_name
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.z_index = z_index + 10
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)

	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.04, 0.70)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(overlay)
	return modal


func _make_centered_modal_column(modal: Control, min_size: Vector2) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 28
	center.offset_right = -28
	center.offset_top = 80
	center.offset_bottom = -80
	modal.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", _make_panel_style())
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
	return column


func _close() -> void:
	_close_reset_confirmation()
	closed.emit()
	queue_free()


func _on_language_changed(_language: String) -> void:
	if is_inside_tree():
		_refresh_from_state()


func _make_icon(icon_path: String, icon_size: Vector2) -> Control:
	var center := CenterContainer.new()
	center.custom_minimum_size = icon_size
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var texture := AssetPaths.load_texture(icon_path)
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(icon)
	else:
		_warn_missing_icon(icon_path)
	return center


func _warn_missing_icon(icon_path: String) -> void:
	if missing_icon_warnings.has(icon_path):
		return
	missing_icon_warnings[icon_path] = true
	push_warning("Settings icon missing: " + icon_path)


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.clip_text = false
	return label


func _make_action_button(text: String, pressed_callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(pressed_callable)
	_style_button(button, Color(0.32, 0.58, 0.22, 1.0), Color(0.40, 0.68, 0.28, 1.0), Color(0.24, 0.46, 0.16, 1.0))
	return button


func _style_language_button(button: Button, active: bool) -> void:
	if active:
		_style_button(button, Color(0.35, 0.64, 0.24, 1.0), Color(0.43, 0.74, 0.30, 1.0), Color(0.25, 0.50, 0.18, 1.0))
	else:
		_style_button(button, Color(0.56, 0.39, 0.20, 1.0), Color(0.66, 0.47, 0.24, 1.0), Color(0.43, 0.28, 0.14, 1.0))


func _style_button(button: Button, normal: Color, hover: Color, pressed: Color) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(normal))
	button.add_theme_stylebox_override("hover", _make_button_style(hover))
	button.add_theme_stylebox_override("pressed", _make_button_style(pressed))
	button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.86, 1.0))
	button.add_theme_color_override("font_shadow_color", Color(0.12, 0.07, 0.03, 0.95))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 2)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.90, 0.76, 0.98)
	style.border_color = Color(0.45, 0.30, 0.14, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 12
	return style


func _make_row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.96, 0.84, 0.72)
	style.border_color = Color(0.55, 0.36, 0.16, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.20, 0.13, 0.06, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _execute_dev_command(command: String) -> String:
	var cmd := command.strip_edges()
	if cmd == "add_1000_exp":
		GameState.set_value("xp", float(GameState.get_value("xp", 0)) + 1000.0)
		GameState.state_changed.emit()
		return "+1000 XP"
	elif cmd == "add_5000_exp":
		GameState.set_value("xp", float(GameState.get_value("xp", 0)) + 5000.0)
		GameState.state_changed.emit()
		return "+5000 XP"
	elif cmd == "add_50000_exp":
		GameState.set_value("xp", float(GameState.get_value("xp", 0)) + 50000.0)
		GameState.state_changed.emit()
		return "+50000 XP"
	elif cmd == "add_1000_money":
		GameState.set_value("repticash", float(GameState.get_value("repticash", 0)) + 1000.0)
		GameState.state_changed.emit()
		return "+1000 repticash"
	elif cmd == "add_5000_money":
		GameState.set_value("repticash", float(GameState.get_value("repticash", 0)) + 5000.0)
		GameState.state_changed.emit()
		return "+5000 repticash"
	elif cmd == "add_500000_money":
		GameState.set_value("repticash", float(GameState.get_value("repticash", 0)) + 500000.0)
		GameState.state_changed.emit()
		return "+500000 repticash"
	elif cmd == "skip_all_build_in_progress":
		var habitats: Variant = GameState.get_value("habitats", {})
		if typeof(habitats) == TYPE_DICTIONARY:
			for habitat_id in (habitats as Dictionary).keys():
				var h: Variant = (habitats as Dictionary)[habitat_id]
				if typeof(h) != TYPE_DICTIONARY:
					continue
				var hd := h as Dictionary
				if bool(hd.get("is_building", false)):
					hd["build_finish_at"] = 1
				if bool(hd.get("is_upgrading", false)):
					hd["upgrade_finish_at"] = 1
		var reptile_system: Node = get_node_or_null("/root/ReptileSystem")
		if reptile_system != null and reptile_system.has_method("apply_time_updates"):
			reptile_system.call("apply_time_updates", false)
		GameState.state_changed.emit()
		return "Build skipped"
	elif cmd == "skip_pairings":
		var chambers_val: Variant = GameState.get_value("breeding_chambers", {})
		if typeof(chambers_val) == TYPE_DICTIONARY:
			for ckey in (chambers_val as Dictionary).keys():
				var cv: Variant = (chambers_val as Dictionary)[ckey]
				if typeof(cv) != TYPE_DICTIONARY:
					continue
				var cd: Dictionary = cv as Dictionary
				if str(cd.get("state", "")) == "breeding":
					cd["ends_at"] = 1
					(chambers_val as Dictionary)[ckey] = cd
			GameState.set_value("breeding_chambers", chambers_val)
		var rs: Node = get_node_or_null("/root/ReptileSystem")
		if rs != null and rs.has_method("apply_time_updates"):
			rs.call("apply_time_updates", false)
		GameState.state_changed.emit()
		return "Pairings skipped"
	elif cmd == "skip_incubations" or cmd == "skip_all_incubations":
		var is_node: Node = get_node_or_null("/root/IncubationSystem")
		if is_node != null and is_node.has_method("skip_all_incubations"):
			is_node.call("skip_all_incubations")
		SaveSystem.save_game()
		GameState.state_changed.emit()
		return "Incubations skipped"
	elif cmd == "skip_all_connections":
		var chambers_val: Variant = GameState.get_value("breeding_chambers", {})
		if typeof(chambers_val) == TYPE_DICTIONARY:
			var chambers: Dictionary = chambers_val as Dictionary
			for ckey in chambers.keys():
				var cv: Variant = chambers.get(ckey)
				if typeof(cv) != TYPE_DICTIONARY:
					continue
				var cd: Dictionary = cv as Dictionary
				if str(cd.get("state", "")) == "breeding":
					cd["ends_at"] = 1
					chambers[ckey] = cd
			GameState.set_value("breeding_chambers", chambers)
		var bs: Node = get_node_or_null("/root/BreedingSystem")
		if bs != null and bs.has_method("tick_chambers"):
			bs.call("tick_chambers")
		SaveSystem.save_game()
		GameState.state_changed.emit()
		return "Connections skipped"
	elif cmd == "reset_onboarding":
		var onboarding_reset: Node = get_node_or_null("/root/OnboardingSystem")
		if onboarding_reset != null and onboarding_reset.has_method("reset_onboarding"):
			onboarding_reset.call("reset_onboarding", true)
			return "Onboarding reset"
		return "Onboarding unavailable"
	elif cmd == "complete_onboarding":
		var onboarding_complete: Node = get_node_or_null("/root/OnboardingSystem")
		if onboarding_complete != null and onboarding_complete.has_method("complete_onboarding"):
			onboarding_complete.call("complete_onboarding")
			return "Onboarding completed"
		return "Onboarding unavailable"
	elif cmd == "start_onboarding":
		var onboarding_start: Node = get_node_or_null("/root/OnboardingSystem")
		if onboarding_start != null and onboarding_start.has_method("start_onboarding"):
			onboarding_start.call("start_onboarding")
			return "Onboarding started"
		return "Onboarding unavailable"
	elif cmd.is_empty():
		return ""
	return "Unknown: " + cmd


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	return separator
