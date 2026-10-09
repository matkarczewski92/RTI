extends RefCounted
## Shared visual language. All dimensions use the 720-wide portrait canvas.

const BG := Color("101f1d")
const SURFACE := Color("1b3029")
const SURFACE_LIGHT := Color("294137")
const TEXT := Color("f5edd9")
const MUTED := Color("ccbea0")
const ACCENT := Color("c8e58b")
const GOLD := Color("e6bb6a")
const BLUE := Color("8dc6d9")
const PURPLE := Color("bfa0e6")
const DANGER := Color("eea89d")
const FONT_PATH := "res://assets/prototype/fonts/BarlowCondensed-SemiBold.ttf"
const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")
const Controls := preload("res://scripts/modern/IllustratedControls.gd")

static func text(en: String, pl: String) -> String:
	var state: Node = Engine.get_main_loop().root.get_node_or_null("GameState")
	return pl if state != null and state.get_language() == "pl" else en

static func localized(key: String) -> String:
	var service: Node = Engine.get_main_loop().root.get_node_or_null("LocalizationSystem")
	return service.tr_key(key) if service != null else key

static func style(color: Color = SURFACE, radius: int = 22, border: Color = Color.TRANSPARENT, padding: int = 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(1 if border.a > 0 else 0)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = load(FONT_PATH)
	theme.default_font_size = 27
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_color", "OptionButton", TEXT)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_shadow_color", "Label", Color("000000a0"))
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_color("font_outline_color", "Label", Color("241305"))
	theme.set_constant("outline_size", "Label", 2)
	theme.set_color("font_shadow_color", "Button", Color("00000090"))
	theme.set_constant("shadow_offset_y", "Button", 2)
	theme.set_color("font_outline_color", "Button", Color("241305"))
	theme.set_constant("outline_size", "Button", 3)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_stylebox("normal", "LineEdit", Controls.skin("wood", "input"))
	theme.set_stylebox("focus", "LineEdit", Controls.skin("wood", "pressed"))
	for type in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			theme.set_stylebox(state, type, Controls.skin("wood", state))
		theme.set_color("font_disabled_color", type, Color("c5beaa"))
		theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_stylebox("panel", "PopupMenu", Controls.skin("wood"))
	theme.set_stylebox("hover", "PopupMenu", Controls.skin("green"))
	theme.set_icon("arrow", "OptionButton", load("res://assets/art/modern/icons/chevron_down.svg"))
	theme.set_constant("arrow_margin", "OptionButton", 20)
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_constant("v_separation", "PopupMenu", 22)
	theme.set_stylebox("grabber", "VScrollBar", style(Color("55715b"), 4, Color.TRANSPARENT, 4))
	theme.set_stylebox("scroll", "VScrollBar", style(Color.TRANSPARENT, 4, Color.TRANSPARENT, 4))
	return theme

static func label(text: String, font_size: int = 24, color: Color = TEXT) -> Label:
	var n := Label.new()
	n.text = text
	n.add_theme_font_size_override("font_size", font_size)
	n.add_theme_color_override("font_color", color)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

static func button(text: String, callback: Callable, kind: String = "primary") -> Button:
	var n := Button.new()
	n.text = text
	n.custom_minimum_size.y = 80
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.add_theme_font_size_override("font_size", 28)
	n.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Controls.apply(n, "green" if kind == "primary" else ("red" if kind == "danger" else "wood"))
	if callback.is_valid():
		n.pressed.connect(callback)
	return n

static func card() -> PanelContainer:
	var n := PanelContainer.new()
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.add_theme_stylebox_override("panel", wood_panel())
	return n

static func wood_panel() -> StyleBoxTexture:
	return Controls.wood_panel()

static func row(separation: int = 12) -> HBoxContainer:
	var n := HBoxContainer.new()
	n.add_theme_constant_override("separation", separation)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return n

static func column(separation: int = 16) -> VBoxContainer:
	var n := VBoxContainer.new()
	n.add_theme_constant_override("separation", separation)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return n

static func texture(path: String, min_size: Vector2) -> TextureRect:
	var n := TextureRect.new()
	n.texture = AssetPaths.load_texture(path)
	n.custom_minimum_size = min_size
	n.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	n.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

static func icon(name: String, size: int = 28) -> TextureRect:
	var path: String = {"coin": "currency", "food": "food", "water": "water", "clock": "clock", "book": "collection", "star": "xp", "heart": "actions/care"}.get(name, "")
	if not path.is_empty(): return texture("res://assets/prototype/art/icons/" + path + ".png", Vector2(size, size))
	return texture("res://assets/art/modern/icons/" + name + ".svg", Vector2(size, size))

static func progress(value: float, accent: Color = ACCENT) -> ProgressBar:
	var n := ProgressBar.new()
	n.custom_minimum_size.y = 12
	n.show_percentage = false
	n.value = value
	n.add_theme_stylebox_override("background", style(BG, 6, Color.TRANSPARENT, 0))
	n.add_theme_stylebox_override("fill", style(accent, 6, Color.TRANSPARENT, 0))
	return n

static func title(text: String, subtitle: String = "") -> VBoxContainer:
	var n := column(5)
	n.add_child(label(text, 38))
	if not subtitle.is_empty():
		n.add_child(label(subtitle, 23, MUTED))
	return n

static func sex_badge(sex: String, compact: bool = false) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "SexBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size.y = 36 if compact else 48
	var accent := Color("ffbfe3") if sex == "female" else Color("a8e3ff")
	var skin := style(Color("20160bf5"), 9, accent.darkened(0.30), 0)
	skin.content_margin_left = 8 if compact else 14
	skin.content_margin_right = 8 if compact else 14
	skin.content_margin_top = 2 if compact else 5
	skin.content_margin_bottom = 2 if compact else 5
	badge.add_theme_stylebox_override("panel", skin)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(center)
	var contents := row(6)
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(contents)
	if sex in ["female", "male"]:
		contents.add_child(texture("res://assets/art/modern/icons/" + sex + ".svg", Vector2(24, 24) if compact else Vector2(30, 30)))
	var copy := label(text("Female", "Samica") if sex == "female" else text("Male", "Samiec") if sex == "male" else text("Unknown", "Nieznana"), 22 if compact else 28, accent)
	copy.name = "SexLabel"
	copy.autowrap_mode = TextServer.AUTOWRAP_OFF
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	contents.add_child(copy)
	badge.set_meta("sex", sex)
	return badge

static func amount(value: float) -> String:
	if value >= 1000000.0:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000.0:
		return "%.1fk" % (value / 1000.0)
	return str(int(value))

static func time(seconds: float) -> String:
	var total := maxi(0, int(ceil(seconds)))
	if total >= 3600:
		return "%dh %02dm" % [total / 3600, (total % 3600) / 60]
	return "%dm %02ds" % [total / 60, total % 60]

static func rarity_color(rarity: String) -> Color:
	return {"common": MUTED, "rare": BLUE, "ultra_rare": PURPLE, "exceptional": GOLD}.get(rarity, MUTED)

static func animal_path(animal: Dictionary) -> String:
	var system: Node = Engine.get_main_loop().root.get_node_or_null("ReptileSystem")
	return system.get_owned_animal_image_path(animal) if system != null else ""

static func rarity_name(rarity: String) -> String:
	match rarity:
		"rare": return text("Rare", "Rzadki")
		"ultra_rare": return text("Ultra rare", "Bardzo rzadki")
		"exceptional": return text("Exceptional", "Wyjątkowy")
	return text("Common", "Zwykły")
