extends RefCounted
## Shared nine-slice skins: corners and bevels retain their size on narrow filters.
const GREEN := "res://assets/prototype/art/ui/habitat/profile_upgrade_button.png"
const WOOD := "res://assets/art/modern/button_wood_v1.png"
const PARCHMENT := "res://assets/art/modern/parchment_panel_v2.png"
const WOOD_PANEL := "res://assets/art/modern/wood_panel.png"
static var _textures: Dictionary = {}

static func _texture(path: String) -> Texture2D:
	if _textures.has(path): return _textures[path]
	var source := load(path) as Texture2D
	if source == null: return null
	# Render-scale a cached copy. Keep the authored PNG/import untouched.
	var pixels := source.get_image()
	if pixels.is_compressed(): pixels.decompress()
	var height := 256 if path in [PARCHMENT, WOOD_PANEL] else 96 if path == GREEN else 64
	var width := maxi(1, roundi(float(pixels.get_width()) * height / pixels.get_height()))
	pixels.resize(width, height, Image.INTERPOLATE_LANCZOS)
	var result := ImageTexture.create_from_image(pixels)
	_textures[path] = result
	return result

static func parchment() -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = _texture(PARCHMENT)
	# The illustrated corners retain their original aspect; only the straight
	# edges and quiet paper centre accommodate the content's natural height.
	result.texture_margin_left = 56
	result.texture_margin_right = 56
	result.texture_margin_top = 64
	result.texture_margin_bottom = 64
	result.content_margin_left = 32
	result.content_margin_right = 32
	result.content_margin_top = 44
	result.content_margin_bottom = 44
	return result

static func wood_panel() -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = _texture(WOOD_PANEL)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(side, 56)
	result.content_margin_left = 30
	result.content_margin_right = 30
	result.content_margin_top = 56
	result.content_margin_bottom = 56
	return result

static func skin(kind: String = "wood", state: String = "normal") -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = _texture(GREEN if kind == "green" else WOOD)
	result.texture_margin_left = 30 if kind == "green" else 24
	result.texture_margin_right = 30 if kind == "green" else 24
	result.texture_margin_top = 22 if kind == "green" else 12
	result.texture_margin_bottom = 24 if kind == "green" else 12
	result.content_margin_left = 24
	result.content_margin_right = 24
	result.content_margin_top = 12
	result.content_margin_bottom = 14
	var tint := Color.WHITE
	if kind == "red": tint = Color(1.0, 0.52, 0.38)
	elif kind == "blue": tint = Color(0.57, 0.80, 1.0)
	elif kind == "purple": tint = Color(0.82, 0.57, 1.0)
	elif kind == "gold": tint = Color(1.0, 0.91, 0.56)
	if state == "hover": tint = tint.lightened(0.12)
	elif state == "pressed":
		tint = tint.darkened(0.26)
		result.content_margin_top = 15
		result.content_margin_bottom = 11
	elif state == "disabled": tint = Color(0.47, 0.46, 0.38)
	elif state == "input": tint = Color(0.58, 0.61, 0.49)
	result.modulate_color = tint
	return result

static func apply(button: Button, kind: String = "wood") -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, skin(kind, state))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("fff2d2"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("ffe3aa"))
	button.add_theme_color_override("font_disabled_color", Color("c5beaa"))
	button.add_theme_color_override("font_outline_color", Color("241305"))
	button.add_theme_constant_override("outline_size", 3)
