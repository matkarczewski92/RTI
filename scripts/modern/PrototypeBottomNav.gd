extends PanelContainer

const UiKit = preload("res://scripts/modern/PrototypeUiKit.gd")

signal tab_selected(tab_id: String)

const FRAME: Texture2D = preload("res://assets/prototype/art/ui/prototype/bottom_nav_five_empty_v2.png")
const ICON_ATLAS: Texture2D = preload("res://assets/prototype/art/ui/prototype/bottom_nav_icons_v2.png")
const BLACK_KEY_SHADER: Shader = preload("res://assets/prototype/shaders/black_key.gdshader")
const NAV_HEIGHT_TO_WIDTH_RATIO := 0.166
const NAV_MIN_HEIGHT := 130.0
const NAV_MAX_HEIGHT := 140.0
const ICON_REGIONS: Array[Rect2] = [
	# Tight, non-overlapping crops. The previous LAB region began inside the
	# CENTER art and ended inside COLLECTION, exposing both neighbours.
	Rect2(48.0, 72.0, 496.0, 584.0),
	Rect2(566.0, 72.0, 304.0, 584.0),
	Rect2(914.0, 72.0, 386.0, 584.0),
	Rect2(1346.0, 72.0, 350.0, 584.0),
	Rect2(1738.0, 72.0, 396.0, 584.0),
]

const TABS: Array[Dictionary] = [
	{"id": "home", "en": "SANCTUARY", "pl": "SANKTUARIUM", "icon_index": 0},
	{"id": "nursery", "en": "NURSERY", "pl": "INKUBATOR", "icon_index": 1},
	{"id": "collection", "en": "COLLECTION", "pl": "KOLEKCJA", "icon_index": 2},
	{"id": "world", "en": "WORLD", "pl": "ŚWIAT", "icon_index": 3},
	{"id": "shop", "en": "SHOP", "pl": "SKLEP", "icon_index": 4},
]

var _buttons: Dictionary = {}
var _labels: Dictionary = {}
var _icons: Dictionary = {}
var _badges: Dictionary = {}
var _badge_labels: Dictionary = {}
var _selected_id := "home"
var _frame: TextureRect
var _row: HBoxContainer


func _ready() -> void:
	custom_minimum_size.y = NAV_MIN_HEIGHT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var frame := TextureRect.new()
	_frame = frame
	frame.anchor_left = 0.030
	frame.anchor_top = 0.0
	frame.anchor_right = 0.970
	frame.anchor_bottom = 0.0
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_atlas := AtlasTexture.new()
	frame_atlas.atlas = FRAME
	frame_atlas.region = Rect2(40.0, 0.0, 1575.0, 278.0)
	frame_atlas.filter_clip = true
	frame.texture = frame_atlas
	add_child(frame)

	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var row := HBoxContainer.new()
	_row = row
	row.anchor_left = 0.041
	row.anchor_top = 0.06
	row.anchor_right = 0.959
	row.anchor_bottom = 1.02
	row.add_theme_constant_override("separation", 0)
	overlay.add_child(row)

	for tab: Dictionary in TABS:
		var button := Button.new()
		button.text = ""
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2.ZERO
		_apply_empty_button(button)
		var tab_id := str(tab["id"])
		button.pressed.connect(_on_tab_pressed.bind(tab_id))

		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 2
		content.offset_top = -13
		content.offset_right = -2
		content.offset_bottom = -13
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", -19)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := _make_atlas_icon(int(tab["icon_index"]))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content.add_child(icon)
		var label := UiKit.make_label(str(tab["en"]), 23, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		label.add_theme_font_override("font", UiKit.bold_font())
		label.add_theme_constant_override("outline_size", 3)
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(label)
		button.add_child(content)

		var badge_data := _make_badge()
		button.add_child(badge_data[0] as Control)
		row.add_child(button)
		_buttons[tab_id] = button
		_labels[tab_id] = label
		_icons[tab_id] = icon
		_badges[tab_id] = badge_data[0]
		_badge_labels[tab_id] = badge_data[1]

	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_nav_geometry):
		viewport.size_changed.connect(_sync_nav_geometry)
	_sync_nav_geometry.call_deferred()
	GameState.language_changed.connect(func(_language: String) -> void: refresh_language())
	refresh_language()
	set_selected(_selected_id)


func _make_atlas_icon(index: int) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = ICON_ATLAS
	atlas.region = ICON_REGIONS[index]
	atlas.filter_clip = true
	var icon := TextureRect.new()
	icon.texture = atlas
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = BLACK_KEY_SHADER
	material.set_shader_parameter("threshold", 0.004)
	material.set_shader_parameter("feather", 0.018)
	icon.material = material
	return icon


func set_selected(tab_id: String) -> void:
	_selected_id = tab_id
	if not _buttons.has(tab_id):
		# Team/tasks/settings are reached from the sanctuary but have no sixth tab.
		if not _buttons.is_empty():
			for key: Variant in _buttons.keys():
				_apply_empty_button(_buttons[key] as Button)
				(_labels[key] as Label).add_theme_color_override("font_color", UiKit.CREAM)
		return
	for key: Variant in _buttons.keys():
		var button := _buttons[key] as Button
		var label := _labels[key] as Label
		if str(key) == tab_id:
			button.add_theme_stylebox_override("normal", _selection_style())
			button.add_theme_stylebox_override("hover", _selection_style())
			button.add_theme_stylebox_override("pressed", _selection_style(true))
			button.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			_apply_empty_button(button)
			button.add_theme_color_override("font_color", UiKit.CREAM)
			label.add_theme_color_override("font_color", UiKit.CREAM)


func refresh_language() -> void:
	var language := "pl" if GameState.get_language() == "pl" else "en"
	for tab: Dictionary in TABS:
		var tab_id: String = str(tab["id"])
		if _labels.has(tab_id):
			(_labels[tab_id] as Label).text = str(tab[language])
			(_buttons[tab_id] as Button).tooltip_text = str(tab[language]).capitalize()


func set_badge(tab_id: String, count: int) -> void:
	if not _buttons.has(tab_id):
		return
	var badge := _badges[tab_id] as Control
	var badge_label := _badge_labels[tab_id] as Label
	badge.visible = count > 0
	badge_label.text = "99+" if count > 99 else str(maxi(0, count))


func _on_tab_pressed(tab_id: String) -> void:
	set_selected(tab_id)
	tab_selected.emit(tab_id)


func _apply_empty_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty)
	button.focus_mode = Control.FOCUS_NONE


func _make_badge() -> Array:
	var badge := PanelContainer.new()
	badge.anchor_left = 0.73
	badge.anchor_top = -0.04
	badge.anchor_right = 0.98
	badge.anchor_bottom = 0.25
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 5
	badge.visible = false
	var style := UiKit.panel_style(Color("#53a316"), Color("#f8d343"), 3, 27, true)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	badge.add_theme_stylebox_override("panel", style)
	var label := UiKit.make_label("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_override("font", UiKit.bold_font())
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return [badge, label]


func _sync_nav_geometry() -> void:
	if not is_inside_tree():
		return
	var available_width := get_viewport_rect().size.x
	var parent_control := get_parent() as Control
	if parent_control != null and parent_control.size.x > 0.0:
		available_width = parent_control.size.x
	var desired_height := clampf(
		available_width * NAV_HEIGHT_TO_WIDTH_RATIO,
		NAV_MIN_HEIGHT,
		NAV_MAX_HEIGHT
	)
	if absf(custom_minimum_size.y - desired_height) > 0.5:
		custom_minimum_size.y = desired_height
	var compact_viewport := available_width < 467.0
	if is_instance_valid(_frame):
		# The five carved bays are one illustration. Its natural height must not
		# be enlarged independently of width to fill a tall phone's navigation.
		_frame.offset_top = 0.0
		_frame.offset_bottom = available_width * 0.94 * 278.0 / 1575.0
	if is_instance_valid(_row):
		_row.anchor_top = 0.06 if compact_viewport else -0.03
	var icon_size := clampf(available_width * 0.150, 98.0, 108.0)
	var label_size := clampi(int(round(available_width * 0.032)), 22, 25)
	var badge_size := clampi(int(round(available_width * 0.021)), 15, 18)
	for icon_value: Variant in _icons.values():
		var icon := icon_value as TextureRect
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
	for label_value: Variant in _labels.values():
		(label_value as Label).add_theme_font_size_override("font_size", label_size)
	for badge_label_value: Variant in _badge_labels.values():
		(badge_label_value as Label).add_theme_font_size_override("font_size", badge_size)


func _selection_style(pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# Active tabs use an outline/glow only. No yellow fill is painted over the
	# authored wood bay.
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("#ffe251")
	style.set_border_width_all(3 if pressed else 2)
	style.set_corner_radius_all(13)
	style.shadow_color = Color(1.0, 0.78, 0.08, 0.28)
	style.shadow_size = 1
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style
