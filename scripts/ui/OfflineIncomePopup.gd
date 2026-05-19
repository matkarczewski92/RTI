extends CanvasLayer

const OFFLINE_REWARD_BG_PATH := "res://assets/art/ui/offline_reward.png"
const OFFLINE_REWARD_REF_SIZE := Vector2(1086, 1448)
const OFFLINE_REWARD_VIEWPORT_MAX_RATIO := Vector2(0.598, 0.572)
const OFFLINE_TITLE_RECT := Rect2(172, 416, 742, 110)
const OFFLINE_MESSAGE_RECT := Rect2(260, 555, 566, 108)
const OFFLINE_TIME_LABEL_RECT := Rect2(354, 704, 300, 74)
const OFFLINE_TIME_VALUE_RECT := Rect2(666, 704, 210, 74)
const OFFLINE_REWARD_LABEL_RECT := Rect2(354, 840, 300, 74)
const OFFLINE_REWARD_VALUE_RECT := Rect2(666, 840, 210, 74)
const OFFLINE_CAP_RECT := Rect2(270, 930, 546, 34)
const OFFLINE_CLAIM_TEXT_RECT := Rect2(364, 1210, 360, 92)
const OFFLINE_CLAIM_HITBOX_RECT := Rect2(268, 958, 552, 300)
const OFFLINE_TITLE_FONT_SIZE := 72
const OFFLINE_MESSAGE_FONT_SIZE := 38
const OFFLINE_ROW_LABEL_FONT_SIZE := 42
const OFFLINE_ROW_VALUE_FONT_SIZE := 50
const OFFLINE_CAP_FONT_SIZE := 24
const OFFLINE_CLAIM_FONT_SIZE := 58

var overlay: Control
var panel: Control
var background: TextureRect
var title_label: Label
var message_label: Label
var time_label: Label
var time_value_label: Label
var reward_label: Label
var reward_value_label: Label
var cap_label: Label
var claim_text_label: Label
var claim_hitbox: Button
var _panel_scale: float = 1.0


func _ready() -> void:
	layer = 80
	_build_popup()
	get_viewport().size_changed.connect(_layout_popup)
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

	panel = Control.new()
	panel.name = "OfflineRewardPanel"
	overlay.add_child(panel)

	background = TextureRect.new()
	background.name = "OfflineRewardBackground"
	background.texture = _load_texture(OFFLINE_REWARD_BG_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)

	title_label = _make_ref_label(_tr("offline.title"), OFFLINE_TITLE_FONT_SIZE, Color(0.30, 0.16, 0.05, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(title_label)

	message_label = _make_ref_label(_tr("offline.message"), OFFLINE_MESSAGE_FONT_SIZE, Color(0.23, 0.13, 0.06, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(message_label)

	time_label = _make_ref_label(_tr("offline.time"), OFFLINE_ROW_LABEL_FONT_SIZE, Color(0.24, 0.13, 0.05, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(time_label)

	time_value_label = _make_ref_label("", OFFLINE_ROW_VALUE_FONT_SIZE, Color(0.10, 0.42, 0.08, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	panel.add_child(time_value_label)

	reward_label = _make_ref_label(_tr("offline.reward"), OFFLINE_ROW_LABEL_FONT_SIZE, Color(0.24, 0.13, 0.05, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(reward_label)

	reward_value_label = _make_ref_label("", OFFLINE_ROW_VALUE_FONT_SIZE, Color(0.10, 0.42, 0.08, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	panel.add_child(reward_value_label)

	cap_label = _make_ref_label("", OFFLINE_CAP_FONT_SIZE, Color(0.48, 0.32, 0.08, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	cap_label.visible = false
	panel.add_child(cap_label)

	claim_text_label = _make_ref_label(_tr("offline.claim"), OFFLINE_CLAIM_FONT_SIZE, Color(0.98, 0.94, 0.82, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	claim_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	claim_text_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.07, 0.03, 0.95))
	claim_text_label.add_theme_constant_override("shadow_offset_y", 4)
	panel.add_child(claim_text_label)

	claim_hitbox = Button.new()
	claim_hitbox.name = "ClaimHitbox"
	claim_hitbox.text = ""
	claim_hitbox.flat = true
	claim_hitbox.focus_mode = Control.FOCUS_NONE
	claim_hitbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	claim_hitbox.add_theme_stylebox_override("normal", _make_transparent_button_style())
	claim_hitbox.add_theme_stylebox_override("hover", _make_transparent_button_style())
	claim_hitbox.add_theme_stylebox_override("pressed", _make_transparent_button_style())
	claim_hitbox.pressed.connect(_on_claim_pressed)
	panel.add_child(claim_hitbox)

	_layout_popup()


func _layout_popup() -> void:
	if panel == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_panel_scale = min(
		(viewport_size.x * OFFLINE_REWARD_VIEWPORT_MAX_RATIO.x) / OFFLINE_REWARD_REF_SIZE.x,
		(viewport_size.y * OFFLINE_REWARD_VIEWPORT_MAX_RATIO.y) / OFFLINE_REWARD_REF_SIZE.y
	)
	var panel_size: Vector2 = OFFLINE_REWARD_REF_SIZE * _panel_scale
	var panel_pos: Vector2 = (viewport_size - panel_size) * 0.5
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = panel_pos.x
	panel.offset_top = panel_pos.y
	panel.offset_right = panel_pos.x + panel_size.x
	panel.offset_bottom = panel_pos.y + panel_size.y

	_set_ref_rect(title_label, OFFLINE_TITLE_RECT)
	_set_ref_rect(message_label, OFFLINE_MESSAGE_RECT)
	_set_ref_rect(time_label, OFFLINE_TIME_LABEL_RECT)
	_set_ref_rect(time_value_label, OFFLINE_TIME_VALUE_RECT)
	_set_ref_rect(reward_label, OFFLINE_REWARD_LABEL_RECT)
	_set_ref_rect(reward_value_label, OFFLINE_REWARD_VALUE_RECT)
	_set_ref_rect(cap_label, OFFLINE_CAP_RECT)
	_set_ref_rect(claim_text_label, OFFLINE_CLAIM_TEXT_RECT)
	_set_ref_rect(claim_hitbox, OFFLINE_CLAIM_HITBOX_RECT)
	_apply_ref_font_sizes()


func _set_ref_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x * _panel_scale
	control.offset_top = rect.position.y * _panel_scale
	control.offset_right = (rect.position.x + rect.size.x) * _panel_scale
	control.offset_bottom = (rect.position.y + rect.size.y) * _panel_scale


func _make_ref_label(text: String, font_size: int, color: Color, alignment: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _apply_ref_font_sizes() -> void:
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_TITLE_FONT_SIZE * _panel_scale))))
	if message_label != null:
		message_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_MESSAGE_FONT_SIZE * _panel_scale))))
	if time_label != null:
		time_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_ROW_LABEL_FONT_SIZE * _panel_scale))))
	if reward_label != null:
		reward_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_ROW_LABEL_FONT_SIZE * _panel_scale))))
	if time_value_label != null:
		time_value_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_ROW_VALUE_FONT_SIZE * _panel_scale))))
	if reward_value_label != null:
		reward_value_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_ROW_VALUE_FONT_SIZE * _panel_scale))))
	if cap_label != null:
		cap_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_CAP_FONT_SIZE * _panel_scale))))
	if claim_text_label != null:
		claim_text_label.add_theme_font_size_override("font_size", max(1, int(round(OFFLINE_CLAIM_FONT_SIZE * _panel_scale))))
		claim_text_label.add_theme_constant_override("shadow_offset_y", max(1, int(round(4.0 * _panel_scale))))


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

	_layout_popup()
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


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Offline income texture missing: " + path)
	return null


func _make_transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_color = Color(1.0, 1.0, 1.0, 0.0)
	style.set_corner_radius_all(0)
	return style
