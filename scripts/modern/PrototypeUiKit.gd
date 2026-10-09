
extends RefCounted

const FONT_SEMIBOLD_PATH := "res://assets/prototype/fonts/BarlowCondensed-SemiBold.ttf"
const FONT_BOLD_PATH := "res://assets/prototype/fonts/BarlowCondensed-Bold.ttf"
const Controls := preload("res://scripts/modern/IllustratedControls.gd")

const CREAM := Color("#fff2c7")
const INK := Color("#2a1608")
const WOOD_DARK := Color("#271509")
const WOOD := Color("#563014")
const WOOD_LIGHT := Color("#8b5424")
const PARCHMENT := Color("#e8c987")
const PARCHMENT_LIGHT := Color("#f7dfaa")
const LEAF := Color("#4e8d16")
const LEAF_LIGHT := Color("#83c52d")
const GOLD := Color("#ffc83d")
const GOLD_DARK := Color("#9a5b0d")
const BLUE := Color("#26a9dd")
const RED := Color("#d64b2f")
const PURPLE := Color("#9a4ac8")

static var _font_semibold: FontFile
static var _font_bold: FontFile


static func semibold_font() -> FontFile:
	if _font_semibold == null:
		_font_semibold = _load_dynamic_font(FONT_SEMIBOLD_PATH)
	return _font_semibold


static func bold_font() -> FontFile:
	if _font_bold == null:
		_font_bold = _load_dynamic_font(FONT_BOLD_PATH)
	return _font_bold


static func _load_dynamic_font(path: String) -> FontFile:
	# ResourceLoader resolves imported .fontdata in exported Android packages.
	var font := ResourceLoader.load(path) as FontFile
	if font == null:
		push_error("Unable to load UI font %s" % path)
	return font


static func panel_style(
	fill: Color,
	border: Color = WOOD_DARK,
	border_width: int = 5,
	radius: int = 20,
	shadow: bool = true
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	if shadow:
		style.shadow_color = Color(0.03, 0.015, 0.005, 0.65)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 5)
	return style


static func button_style(kind: String, pressed: bool = false) -> StyleBoxTexture:
	return Controls.skin(kind, "pressed" if pressed else "normal")


static func apply_button(button: Button, kind: String = "green", font_size: int = 28) -> Button:
	Controls.apply(button, kind)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color("#241305"))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_font_override("font", semibold_font())
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size.y = max(button.custom_minimum_size.y, 70.0)
	button.focus_mode = Control.FOCUS_NONE
	return button


static func make_label(
	text: String,
	font_size: int = 28,
	color: Color = CREAM,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", semibold_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#1b0e05"))
	label.add_theme_constant_override("outline_size", 4)
	return label


static func make_title(text: String, font_size: int = 48) -> Label:
	var label := make_label(text, font_size, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_override("font", bold_font())
	label.add_theme_color_override("font_outline_color", WOOD_DARK)
	label.add_theme_constant_override("outline_size", 8)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func apply_progress_bar(bar: ProgressBar, fill: Color = LEAF_LIGHT) -> ProgressBar:
	var background := panel_style(Color("#24160c"), Color("#6f431e"), 3, 12, false)
	background.content_margin_left = 0
	background.content_margin_right = 0
	background.content_margin_top = 0
	background.content_margin_bottom = 0
	var foreground := panel_style(fill, fill.lightened(0.2), 2, 11, false)
	foreground.content_margin_left = 0
	foreground.content_margin_right = 0
	foreground.content_margin_top = 0
	foreground.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)
	bar.add_theme_font_override("font", semibold_font())
	bar.add_theme_font_size_override("font_size", 22)
	bar.add_theme_color_override("font_color", Color.WHITE)
	bar.add_theme_color_override("font_outline_color", INK)
	bar.add_theme_constant_override("outline_size", 4)
	bar.custom_minimum_size.y = 34
	return bar


static func make_icon(path: String, size: Vector2 = Vector2(52, 52)) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):
		icon.texture = load(path)
	return icon


static func rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return BLUE
		"ultra_rare":
			return PURPLE
		"exceptional":
			return GOLD
		_:
			return Color("#a8a596")


static func rarity_label(rarity: String) -> String:
	return rarity.replace("_", " ").capitalize()


static func compact_number(value: float) -> String:
	var absolute := absf(value)
	if absolute >= 1_000_000_000.0:
		return "%.2fB" % (value / 1_000_000_000.0)
	if absolute >= 1_000_000.0:
		return "%.2fM" % (value / 1_000_000.0)
	if absolute >= 1_000.0:
		return "%.2fK" % (value / 1_000.0)
	return str(int(round(value)))


static func clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()
