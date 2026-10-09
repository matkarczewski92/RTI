extends PanelContainer

const UiKit = preload("res://scripts/modern/PrototypeUiKit.gd")

signal shop_requested(resource_id: String)
signal context_back_requested

const HUD_ART: Texture2D = preload("res://assets/prototype/art/ui/prototype/hud_topbar_empty_v3.png")
const CONTEXT_BACK_ART: Texture2D = preload("res://assets/prototype/art/ui/habitat/profile_back_medallion.png")
const HUD_VIEWPORT_WIDTH_RATIO := 0.972
const HUD_HEIGHT_TO_WIDTH_RATIO := 0.137
const HUD_MIN_HEIGHT := 99.0
const HUD_MAX_HEIGHT := 104.0

# Each source piece is cropped separately and rendered at its authored aspect
# ratio. This prevents the level medallion and resource plaques from being
# widened by tall/narrow phone safe areas.
const LEVEL_REGION := Rect2(0, 0, 238, 280)
const COIN_REGION := Rect2(218, 26, 424, 190)
const XP_REGION := Rect2(642, 26, 362, 190)
const FOOD_REGION := Rect2(1010, 26, 370, 190)
const WATER_REGION := Rect2(1380, 26, 395, 190)

var _level_art: TextureRect
var _level_label: Label
var _currency_label: Label
var _food_label: Label
var _water_label: Label
var _xp_label: Label
var _xp_bar: ProgressBar
var _resource_buttons: Dictionary = {}
var _biome_id := "green_meadow"
var _context_back_button: Button
var _context_back_mode := false


func _ready() -> void:
	custom_minimum_size.y = HUD_MIN_HEIGHT
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = false
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_build()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_hud_width):
		viewport.size_changed.connect(_sync_hud_width)
	var game_state := _game_state()
	var refresh_callable := Callable(self, "refresh")
	if game_state != null and game_state.has_signal("state_changed") and not game_state.is_connected("state_changed", refresh_callable):
		game_state.connect("state_changed", refresh_callable)
	if game_state != null and game_state.has_signal("language_changed"):
		game_state.connect("language_changed", func(_language: String) -> void: refresh())
	_sync_hud_width.call_deferred()
	_apply_context_mode()
	refresh()


func set_biome(biome_id: String) -> void:
	_biome_id = biome_id if biome_id in ["green_meadow", "dry_prairie"] else "green_meadow"
	refresh()


func set_context_back(enabled: bool) -> void:
	_context_back_mode = enabled
	_apply_context_mode()


func is_context_back_enabled() -> bool:
	return _context_back_mode


func _build() -> void:
	var overlay := Control.new()
	overlay.name = "HudOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	_level_art = _add_atlas_art(overlay, LEVEL_REGION, Rect2(0.002, -0.03, 0.142, 1.06))
	_add_atlas_art(overlay, COIN_REGION, Rect2(0.125, 0.12, 0.235, 0.76))
	_add_atlas_art(overlay, XP_REGION, Rect2(0.345, 0.12, 0.220, 0.76))
	_add_atlas_art(overlay, FOOD_REGION, Rect2(0.555, 0.12, 0.220, 0.76))
	_add_atlas_art(overlay, WATER_REGION, Rect2(0.775, 0.12, 0.223, 0.76))

	_level_label = _make_value_label("1", 31)
	_level_label.name = "LevelValue"
	_position_relative(_level_label, Rect2(0.030, 0.39, 0.090, 0.48))
	overlay.add_child(_level_label)

	_currency_label = _make_value_label("0", 23)
	_currency_label.name = "CurrencyValue"
	_position_relative(_currency_label, Rect2(0.186, 0.22, 0.116, 0.47))
	overlay.add_child(_currency_label)

	_xp_label = _make_value_label("0/600", 20)
	_xp_label.name = "ExperienceValue"
	_position_relative(_xp_label, Rect2(0.405, 0.20, 0.136, 0.36))
	overlay.add_child(_xp_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.name = "ExperienceProgress"
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 1.0
	_xp_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = UiKit.GOLD
	xp_fill.set_corner_radius_all(3)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	_position_relative(_xp_bar, Rect2(0.413, 0.565, 0.126, 0.045))
	overlay.add_child(_xp_bar)

	_food_label = _make_value_label("0", 23)
	_food_label.name = "FoodValue"
	_position_relative(_food_label, Rect2(0.619, 0.22, 0.108, 0.47))
	overlay.add_child(_food_label)

	_water_label = _make_value_label("0", 23)
	_water_label.name = "WaterValue"
	_position_relative(_water_label, Rect2(0.843, 0.22, 0.104, 0.47))
	overlay.add_child(_water_label)

	# The entire plaque is tappable while preserving the authored plus artwork.
	_add_shop_hit_target(overlay, "repticash", Rect2(0.125, 0.04, 0.220, 0.92))
	_add_shop_hit_target(overlay, "food", Rect2(0.555, 0.04, 0.220, 0.92))
	_add_shop_hit_target(overlay, "water", Rect2(0.775, 0.04, 0.223, 0.92))
	_context_back_button = _make_context_back_button()
	overlay.add_child(_context_back_button)


func _add_atlas_art(parent: Control, region: Rect2, destination: Rect2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = HUD_ART
	atlas.region = region
	atlas.filter_clip = true
	var art := TextureRect.new()
	art.texture = atlas
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_position_relative(art, destination)
	parent.add_child(art)
	return art


func _add_shop_hit_target(parent: Control, resource_id: String, rect: Rect2) -> void:
	var button := Button.new()
	button.name = "%sAddButton" % resource_id.to_pascal_case()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_position_relative(button, rect)
	button.pressed.connect(func() -> void: shop_requested.emit(resource_id))
	parent.add_child(button)
	_resource_buttons[resource_id] = button


func _make_context_back_button() -> Button:
	var button := Button.new()
	button.name = "ContextBackButton"
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "Back"
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = CONTEXT_BACK_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art)
	_position_relative(button, Rect2(0.002, -0.03, 0.150, 1.06))
	button.pressed.connect(func() -> void: context_back_requested.emit())
	return button


func _apply_context_mode() -> void:
	if is_instance_valid(_level_art):
		_level_art.visible = not _context_back_mode
	if is_instance_valid(_level_label):
		_level_label.visible = not _context_back_mode
	if is_instance_valid(_context_back_button):
		_context_back_button.visible = _context_back_mode


func _make_value_label(initial_text: String, font_size: int) -> Label:
	var label := UiKit.make_label(initial_text, font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UiKit.bold_font())
	label.add_theme_constant_override("outline_size", 3)
	return label


func _sync_hud_width() -> void:
	if not is_inside_tree():
		return
	var desired_width := get_viewport_rect().size.x * HUD_VIEWPORT_WIDTH_RATIO
	var parent_control := get_parent() as Control
	if parent_control != null and parent_control.size.x > 0.0:
		desired_width = minf(desired_width, parent_control.size.x)
	desired_width = floorf(desired_width)
	if absf(custom_minimum_size.x - desired_width) > 0.5:
		custom_minimum_size.x = desired_width
	var desired_height := clampf(desired_width * HUD_HEIGHT_TO_WIDTH_RATIO, HUD_MIN_HEIGHT, HUD_MAX_HEIGHT)
	if absf(custom_minimum_size.y - desired_height) > 0.5:
		custom_minimum_size.y = desired_height


func refresh() -> void:
	if not is_inside_tree() or not is_instance_valid(_level_label):
		return
	var game_state := _game_state()
	if game_state == null or not game_state.has_method("get_value"):
		return
	var level := maxi(1, int(GameState.get_value("player_level", 1)))
	var currency := float(EconomySystem.get_currency("repticash"))
	var xp := float(EconomySystem.get_currency("xp"))
	var level_start := EconomySystem.get_required_xp_for_level(level)
	var next_level := EconomySystem.get_next_level_required_xp(level)
	var earned := maxf(0.0, xp - float(level_start))
	var needed := maxf(1.0, float(next_level - level_start))
	var food := ReptileSystem.get_biome_resource_current(_biome_id, "food")
	var water := ReptileSystem.get_biome_resource_current(_biome_id, "water")
	var polish := GameState.get_language() == "pl"
	_level_label.text = str(level)
	_currency_label.text = _compact_number(currency)
	_food_label.text = _compact_number(food)
	_water_label.text = _compact_number(water)
	_xp_label.text = "%s/%s" % [_compact_number(earned), _compact_number(needed)]
	_xp_bar.value = clampf(earned / needed, 0.0, 1.0)
	_context_back_button.tooltip_text = "Wróć" if polish else "Back"
	(_resource_buttons["repticash"] as Button).tooltip_text = "Otwórz sklep" if polish else "Open shop"
	(_resource_buttons["food"] as Button).tooltip_text = "Uzupełnij pokarm" if polish else "Refill food"
	(_resource_buttons["water"] as Button).tooltip_text = "Uzupełnij wodę" if polish else "Refill water"


func _compact_number(value: float) -> String:
	var amount := maxf(0.0, value)
	if amount >= 1000000000.0:
		return "%.1fB" % (amount / 1000000000.0)
	if amount >= 1000000.0:
		return "%.1fM" % (amount / 1000000.0)
	if amount >= 10000.0:
		return "%.1fK" % (amount / 1000.0)
	return str(int(floor(amount)))


func _game_state() -> Node:
	return get_node_or_null("/root/GameState")


func _position_relative(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.end.x
	control.anchor_bottom = rect.end.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
