extends Control

signal biome_selected(biome_id: String)

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const BIOMES_PATH := "res://data/biomes.json"
const LOCKED_ICON_PATH := "res://assets/art/ui/icons/menu/locked.png"
const LOCKED_ICON_SIZE := Vector2(32, 32)

var list: VBoxContainer


func _ready() -> void:
	_build_layout()
	_populate_biomes()
	GameState.language_changed.connect(func(_language: String) -> void: _populate_biomes())


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 80)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title := Label.new()
	title.text = LocalizationSystem.tr_key("screen.biome_map")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	layout.add_child(title)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	layout.add_child(list)


func _populate_biomes() -> void:
	for child in list.get_children():
		child.queue_free()

	for biome in _load_biomes():
		var biome_id: String = str(biome.get("id", ""))
		var unlocked_biomes: Array = GameState.get_value("unlocked_biomes", []) as Array
		var is_unlocked := unlocked_biomes.has(biome_id)
		list.add_child(_make_biome_button(biome_id, LocalizationSystem.tr_key(str(biome.get("name_key", biome_id))), is_unlocked))


func _make_biome_button(biome_id: String, biome_name: String, is_unlocked: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	button.disabled = not is_unlocked
	button.focus_mode = Control.FOCUS_NONE
	if is_unlocked:
		button.pressed.connect(func() -> void: biome_selected.emit(biome_id))

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 18
	content.offset_right = -18
	content.offset_top = 12
	content.offset_bottom = -12
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	if not is_unlocked:
		content.add_child(_make_fixed_icon(LOCKED_ICON_PATH, LOCKED_ICON_SIZE, "LOCK"))

	var name_label := Label.new()
	name_label.text = biome_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 18)
	content.add_child(name_label)

	if not is_unlocked:
		var status_label := Label.new()
		status_label.text = LocalizationSystem.tr_key("status.locked")
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_label.add_theme_font_size_override("font_size", 14)
		content.add_child(status_label)

	return button


func _make_fixed_icon(texture_path: String, icon_size: Vector2, fallback_text: String) -> Control:
	var icon_box := CenterContainer.new()
	icon_box.custom_minimum_size = icon_size
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texture: Texture2D = AssetPaths.load_texture(texture_path)
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.text = fallback_text
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback.add_theme_font_size_override("font_size", 10)
		icon_box.add_child(fallback)

	return icon_box


func _load_biomes() -> Array:
	var file: FileAccess = FileAccess.open(BIOMES_PATH, FileAccess.READ)
	if file == null:
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []

	return parsed as Array
