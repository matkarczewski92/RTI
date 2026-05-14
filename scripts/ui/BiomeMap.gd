extends Control

signal biome_selected(biome_id: String)

const BIOMES_PATH := "res://data/biomes.json"

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
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 88)
		button.text = LocalizationSystem.tr_key(str(biome.get("name_key", biome_id)))
		button.disabled = not is_unlocked
		if not is_unlocked:
			button.text += " - " + LocalizationSystem.tr_key("status.locked")
		button.pressed.connect(func() -> void: biome_selected.emit(biome_id))
		list.add_child(button)


func _load_biomes() -> Array:
	var file: FileAccess = FileAccess.open(BIOMES_PATH, FileAccess.READ)
	if file == null:
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []

	return parsed as Array
