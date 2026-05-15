extends CanvasLayer

const CLOCK_ICON_PATH := "res://assets/art/ui/icons/menu/clock.png"
const CURRENCY_ICON_PATH := "res://assets/art/ui/icons/menu/currency.png"
const CHEST_ICON_PATH := "res://assets/art/ui/icons/menu/chest.png"
const ACCEPT_ICON_PATH := "res://assets/art/ui/icons/menu/accept.png"

var overlay: Control
var panel: PanelContainer
var time_value_label: Label
var reward_value_label: Label
var cap_label: Label


func _ready() -> void:
	layer = 80
	_build_popup()
	hide()
	if EconomySystem.has_signal("offline_income_calculated"):
		EconomySystem.offline_income_calculated.connect(_on_offline_income_calculated)
	if EconomySystem.has_method("has_pending_offline_income") and EconomySystem.has_pending_offline_income():
		_on_offline_income_calculated(EconomySystem.get_pending_offline_income(), EconomySystem.get_pending_offline_seconds())


func _build_popup() -> void:
	overlay = Control.new()
	overlay.name = "OfflineIncomeOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var chest := _make_icon(CHEST_ICON_PATH, Vector2(78, 78))
	if chest != null:
		content.add_child(chest)

	var title := Label.new()
	title.text = _tr("offline.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.16, 0.11, 0.07, 1.0))
	content.add_child(title)

	var message := Label.new()
	message.text = _tr("offline.message")
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color(0.29, 0.22, 0.15, 1.0))
	content.add_child(message)

	content.add_child(_make_info_row(CLOCK_ICON_PATH, _tr("offline.time"), true))
	content.add_child(_make_info_row(CURRENCY_ICON_PATH, _tr("offline.reward"), false))

	cap_label = Label.new()
	cap_label.text = _tr("offline.cap_applied")
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_label.add_theme_font_size_override("font_size", 13)
	cap_label.add_theme_color_override("font_color", Color(0.48, 0.32, 0.08, 1.0))
	content.add_child(cap_label)

	var claim_block := VBoxContainer.new()
	claim_block.name = "ClaimBlock"
	claim_block.alignment = BoxContainer.ALIGNMENT_CENTER
	claim_block.add_theme_constant_override("separation", 8)
	content.add_child(claim_block)

	var claim_icon := TextureButton.new()
	claim_icon.name = "ClaimIconButton"
	claim_icon.texture_normal = _load_icon(ACCEPT_ICON_PATH)
	claim_icon.texture_hover = claim_icon.texture_normal
	claim_icon.texture_pressed = claim_icon.texture_normal
	claim_icon.custom_minimum_size = Vector2(96, 96)
	claim_icon.ignore_texture_size = true
	claim_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	claim_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	claim_icon.pressed.connect(_on_claim_pressed)
	claim_block.add_child(claim_icon)

	var claim_label := Button.new()
	claim_label.name = "ClaimLabelButton"
	claim_label.text = _tr("offline.claim")
	claim_label.flat = true
	claim_label.custom_minimum_size = Vector2(180, 34)
	claim_label.add_theme_font_size_override("font_size", 24)
	claim_label.add_theme_color_override("font_color", Color(0.16, 0.11, 0.07, 1.0))
	claim_label.add_theme_color_override("font_hover_color", Color(0.34, 0.22, 0.09, 1.0))
	claim_label.add_theme_color_override("font_pressed_color", Color(0.10, 0.32, 0.12, 1.0))
	claim_label.pressed.connect(_on_claim_pressed)
	claim_block.add_child(claim_label)


func _make_info_row(icon_path: String, label_text: String, is_time_row: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(300, 34)

	var icon := _make_icon(icon_path, Vector2(30, 30))
	if icon != null:
		row.add_child(icon)

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(125, 0)
	label.add_theme_color_override("font_color", Color(0.30, 0.22, 0.13, 1.0))
	row.add_child(label)

	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(105, 0)
	value.add_theme_color_override("font_color", Color(0.12, 0.28, 0.10, 1.0))
	row.add_child(value)

	if is_time_row:
		time_value_label = value
	else:
		reward_value_label = value

	return row


func _on_offline_income_calculated(amount: float, seconds: int) -> void:
	if amount <= 0.0 or seconds <= 0:
		return

	if time_value_label != null:
		time_value_label.text = _format_duration(seconds)
	if reward_value_label != null:
		reward_value_label.text = _tr("currency.repticash") + " " + _format_amount(amount)
	if cap_label != null:
		var max_offline_seconds: int = EconomySystem.get_max_offline_seconds() if EconomySystem.has_method("get_max_offline_seconds") else EconomySystem.MAX_OFFLINE_SECONDS
		cap_label.visible = seconds >= max_offline_seconds
		cap_label.text = _tr("ui.offline_cap_applied").replace("{time}", _format_duration(max_offline_seconds))

	show()


func _on_claim_pressed() -> void:
	if EconomySystem.has_method("claim_offline_income"):
		EconomySystem.claim_offline_income()
	hide()


func _format_duration(seconds: int) -> String:
	var safe_seconds: int = max(seconds, 0)
	var hours: int = safe_seconds / 3600
	var minutes: int = (safe_seconds % 3600) / 60
	var secs: int = safe_seconds % 60
	if hours > 0:
		return "%dh %02dm" % [hours, minutes]
	if minutes > 0:
		return "%dm %02ds" % [minutes, secs]
	return "%ds" % secs


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, round(amount)):
		return str(int(round(amount)))
	return "%.1f" % amount


func _tr(key: String) -> String:
	if has_node("/root/LocalizationSystem") and LocalizationSystem.has_method("tr_key"):
		return LocalizationSystem.tr_key(key)
	return key


func _load_icon(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Offline income icon missing: " + path)
	return null


func _make_icon(path: String, size: Vector2) -> TextureRect:
	var texture := _load_icon(path)
	if texture == null:
		return null

	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.88, 0.76, 0.98)
	style.border_color = Color(0.50, 0.32, 0.14, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	return style
