extends Control

signal play_pressed

var title_label: Label
var play_button: Button
var language_button: Button
var settings_button: Button


func _ready() -> void:
	_build_layout()
	_localize()
	GameState.language_changed.connect(_on_language_changed)


func _build_layout() -> void:
	var background := PanelContainer.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 140)
	margin.add_theme_constant_override("margin_bottom", 140)
	background.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	layout.add_child(title_label)

	play_button = Button.new()
	play_button.custom_minimum_size = Vector2(0, 72)
	play_button.pressed.connect(func() -> void: play_pressed.emit())
	layout.add_child(play_button)

	language_button = Button.new()
	language_button.custom_minimum_size = Vector2(0, 64)
	language_button.pressed.connect(_toggle_language)
	layout.add_child(language_button)

	settings_button = Button.new()
	settings_button.custom_minimum_size = Vector2(0, 64)
	layout.add_child(settings_button)


func _localize() -> void:
	title_label.text = LocalizationSystem.tr_key("game.title")
	play_button.text = LocalizationSystem.tr_key("button.play")
	language_button.text = LocalizationSystem.tr_key("button.language")
	settings_button.text = LocalizationSystem.tr_key("button.settings")


func _toggle_language() -> void:
	var next_language := "en" if GameState.get_language() == "pl" else "pl"
	LocalizationSystem.set_language(next_language)
	SaveSystem.save_game()


func _on_language_changed(_language: String) -> void:
	_localize()
