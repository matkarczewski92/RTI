extends Control

signal nav_pressed(item_id: String)

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const BOTTOM_MENU_ART_PATH := "res://assets/art/ui/bottom_menu.png"
const BOTTOM_NAV_HEIGHT := 226.157092875

# Ustaw na true żeby zobaczyć kolorowe nakładki z numerami przycisków.
# Wyłącz (false) po potwierdzeniu, że kliknięcia trafiają poprawnie.
const DEBUG_NAV := false

var art_path: String = ""

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
var _quest_badge: Control = null


func _ready() -> void:
	_build_layout()


func update_quest_badge(has_claimable: bool) -> void:
	if _quest_badge != null:
		_quest_badge.visible = has_claimable


func _make_quest_badge_dot() -> Control:
	var badge: Control = Control.new()
	badge.name = "QuestBadge"
	badge.anchor_left = 0.55
	badge.anchor_top = 0.12
	badge.anchor_right = 0.55
	badge.anchor_bottom = 0.12
	badge.offset_right = 26.4
	badge.offset_bottom = 26.4
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false

	var circle: Panel = Panel.new()
	circle.set_anchors_preset(Control.PRESET_FULL_RECT)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.10, 0.10, 1.0)
	style.set_corner_radius_all(13)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 4
	style.border_color = Color(1.0, 1.0, 1.0, 0.85)
	style.set_border_width_all(2)
	circle.add_theme_stylebox_override("panel", style)
	badge.add_child(circle)

	return badge


func _build_layout() -> void:
	custom_minimum_size = Vector2(0, BOTTOM_NAV_HEIGHT)

	var art := TextureRect.new()
	art.name = "BottomMenuArt"
	art.texture = AssetPaths.load_texture(art_path if not art_path.is_empty() else BOTTOM_MENU_ART_PATH)
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


const _DEBUG_COLORS: Array = [
	Color(1.0, 0.0, 0.0, 0.40),
	Color(0.0, 0.85, 0.0, 0.40),
	Color(0.1, 0.4, 1.0, 0.40),
	Color(1.0, 0.85, 0.0, 0.40),
	Color(0.0, 0.90, 0.90, 0.40),
	Color(0.90, 0.0, 0.90, 0.40),
]

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

	if str(item.get("id", "")) == "quests":
		_quest_badge = _make_quest_badge_dot()
		button.add_child(_quest_badge)

	if DEBUG_NAV:
		var base_col: Color = _DEBUG_COLORS[index % _DEBUG_COLORS.size()]
		var dbg := StyleBoxFlat.new()
		dbg.bg_color = Color(base_col.r, base_col.g, base_col.b, 0.25)
		dbg.border_color = base_col
		dbg.set_border_width_all(4)
		button.add_theme_stylebox_override("normal", dbg)
		button.add_theme_stylebox_override("hover", dbg)
		button.add_theme_stylebox_override("pressed", dbg)

		var lbl := Label.new()
		lbl.text = str(index + 1)
		lbl.anchor_left = 0.5
		lbl.anchor_top = 0.5
		lbl.anchor_right = 0.5
		lbl.anchor_bottom = 0.5
		lbl.offset_left = -20.0
		lbl.offset_top = -18.0
		lbl.offset_right = 20.0
		lbl.offset_bottom = 18.0
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lbl)
	else:
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


func _make_item_style(_active: bool) -> StyleBoxFlat:
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
