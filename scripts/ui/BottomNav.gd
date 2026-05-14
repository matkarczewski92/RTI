extends Control

signal nav_pressed(item_id: String)

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const ICON_SIZE: Vector2 = Vector2(126, 126)
const ITEMS: Array[Dictionary] = [
	{
		"id": "biome",
		"label_key": "nav.biome",
		"icon_path": "res://assets/art/ui/icons/menu/biome.png",
		"active": true
	},
	{
		"id": "animals",
		"label_key": "nav.animals",
		"icon_path": "res://assets/art/ui/icons/menu/animals.png",
		"active": false
	},
	{
		"id": "shop",
		"label_key": "nav.shop",
		"icon_path": "res://assets/art/ui/icons/menu/shop.png",
		"active": false
	},
	{
		"id": "quests",
		"label_key": "nav.quests",
		"icon_path": "res://assets/art/ui/icons/menu/quests.png",
		"active": false
	},
	{
		"id": "upgrades",
		"label_key": "nav.upgrades",
		"icon_path": "res://assets/art/ui/icons/menu/upgrades.png",
		"active": false
	}
]

var active_item_id: String = "biome"


func _ready() -> void:
	_build_layout()
	GameState.language_changed.connect(func(_language: String) -> void: _localize())


func _build_layout() -> void:
	custom_minimum_size = Vector2(0, 176)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_bar_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	margin.add_child(row)

	for item in ITEMS:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		row.add_child(_make_nav_item(item as Dictionary))

	_localize()


func _make_nav_item(item: Dictionary) -> Control:
	var button: Button = Button.new()
	button.name = str(item.get("id", "nav_item"))
	button.set_meta("localization_key", str(item.get("label_key", "")))
	button.set_meta("item_id", str(item.get("id", "")))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 166)
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void:
		var pressed_item_id: String = str(button.get_meta("item_id", ""))
		set_active_item(pressed_item_id)
		nav_pressed.emit(pressed_item_id)
	)
	button.add_theme_stylebox_override("normal", _make_item_style(bool(item.get("active", false))))
	button.add_theme_stylebox_override("hover", _make_item_style(true))
	button.add_theme_stylebox_override("pressed", _make_item_style(true))

	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 0)
	button.add_child(content)

	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = ICON_SIZE
	icon.texture = AssetPaths.load_texture(str(item.get("icon_path", "")))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	if icon.texture == null:
		push_warning("Bottom nav icon missing for " + str(item.get("id", "unknown")) + ". Showing text-only fallback.")

	var label: Label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.10, 0.07, 0.04, 1.0))
	content.add_child(label)

	return button


func set_active_item(item_id: String) -> void:
	active_item_id = item_id
	if get_child_count() == 0:
		return

	var panel: PanelContainer = get_child(0) as PanelContainer
	var margin: MarginContainer = panel.get_child(0) as MarginContainer
	var row: HBoxContainer = margin.get_child(0) as HBoxContainer
	for item in row.get_children():
		var button: Button = item as Button
		if button == null:
			continue

		var is_active: bool = str(button.get_meta("item_id", "")) == active_item_id
		button.add_theme_stylebox_override("normal", _make_item_style(is_active))


func _localize() -> void:
	var panel: PanelContainer = get_child(0) as PanelContainer
	var margin: MarginContainer = panel.get_child(0) as MarginContainer
	var row: HBoxContainer = margin.get_child(0) as HBoxContainer
	for item in row.get_children():
		var button: Button = item as Button
		if button == null:
			continue

		var localization_key: String = str(button.get_meta("localization_key", button.name))
		var label: Node = button.get_node_or_null("Content/Label")
		if label is Label:
			(label as Label).text = LocalizationSystem.tr_key(localization_key)


func _make_bar_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_color = Color(1.0, 1.0, 1.0, 0.0)
	return style


func _make_item_style(active: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.95, 0.60, 0.22) if active else Color(1.0, 1.0, 1.0, 0.0)
	style.set_corner_radius_all(12)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
