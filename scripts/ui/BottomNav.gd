extends Control

signal nav_pressed(item_id: String)

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const BOTTOM_MENU_ART_PATH := "res://assets/art/ui/bottom_menu.png"
const BOTTOM_NAV_HEIGHT := 172.0
const ITEMS: Array[Dictionary] = [
	{
		"id": "map",
		"active": false
	},
	{
		"id": "biome",
		"active": true
	},
	{
		"id": "animals",
		"active": false
	},
	{
		"id": "shop",
		"active": false
	},
	{
		"id": "quests",
		"active": false
	},
	{
		"id": "upgrades",
		"active": false
	}
]

var active_item_id: String = "biome"


func _ready() -> void:
	_build_layout()


func _build_layout() -> void:
	custom_minimum_size = Vector2(0, BOTTOM_NAV_HEIGHT)

	var art := TextureRect.new()
	art.name = "BottomMenuArt"
	art.texture = AssetPaths.load_texture(BOTTOM_MENU_ART_PATH)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	for index in range(ITEMS.size()):
		var item: Variant = ITEMS[index]
		if typeof(item) != TYPE_DICTIONARY:
			continue

		add_child(_make_nav_item(item as Dictionary, index))


func _make_nav_item(item: Dictionary, index: int) -> Control:
	var button: Button = Button.new()
	button.name = str(item.get("id", "nav_item"))
	button.set_meta("item_id", str(item.get("id", "")))
	button.anchor_left = float(index) / float(ITEMS.size())
	button.anchor_top = 0.0
	button.anchor_right = float(index + 1) / float(ITEMS.size())
	button.anchor_bottom = 1.0
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
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

	return button


func set_active_item(item_id: String) -> void:
	active_item_id = item_id
	for item in get_children():
		var button: Button = item as Button
		if button == null:
			continue

		var is_active: bool = str(button.get_meta("item_id", "")) == active_item_id
		button.add_theme_stylebox_override("normal", _make_item_style(is_active))


func _localize() -> void:
	pass


func _make_bar_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_color = Color(1.0, 1.0, 1.0, 0.0)
	return style


func _make_item_style(active: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_color = Color(1.0, 1.0, 1.0, 0.0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
