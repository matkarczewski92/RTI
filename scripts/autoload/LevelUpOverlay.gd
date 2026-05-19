extends CanvasLayer

const IMG_PL := "res://assets/art/ui/lvl_up_pl.png"
const IMG_EN := "res://assets/art/ui/lvl_up_en.png"

var _is_showing: bool = false
var _image_rect: TextureRect
var _wrapper: Control


func _ready() -> void:
	layer = 100
	visible = false
	_build_ui()
	EconomySystem.player_level_up.connect(_on_level_up)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	_wrapper = Control.new()
	_wrapper.custom_minimum_size = Vector2(360, 440)
	_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_wrapper)

	_image_rect = TextureRect.new()
	_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wrapper.add_child(_image_rect)

	# Transparent hitbox over the whole image. The art already contains the button.
	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_continue)
	_wrapper.add_child(btn)


func _on_level_up(_levels: Array, _reward: float) -> void:
	if _is_showing:
		return
	_show()


func _show() -> void:
	_is_showing = true

	var lang: String = LocalizationSystem.get_language()
	var path: String = IMG_PL if lang == "pl" else IMG_EN

	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null and path != IMG_EN:
		push_warning("LevelUpOverlay: missing asset at %s, using EN fallback" % path)
		if ResourceLoader.exists(IMG_EN):
			tex = load(IMG_EN) as Texture2D
	if tex == null:
		push_warning("LevelUpOverlay: all level-up assets missing, skipping overlay")
		_is_showing = false
		return

	_image_rect.texture = tex

	var vp := get_viewport()
	if vp != null:
		var vp_size: Vector2 = vp.get_visible_rect().size
		var img_size: Vector2 = tex.get_size()
		if img_size.x > 0 and img_size.y > 0:
			var scale_f: float = min(vp_size.x * 0.85 / img_size.x, vp_size.y * 0.85 / img_size.y)
			scale_f *= 0.60
			_wrapper.custom_minimum_size = img_size * scale_f

	visible = true


func _on_continue() -> void:
	if not _is_showing:
		return
	_is_showing = false
	visible = false
