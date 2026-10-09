extends CanvasLayer
## Native, localized level celebration; no text baked into images.
const T := preload("res://scripts/modern/SanctuaryTheme.gd")
var _is_showing := false
var _title: Label
var _description: Label
var _reward: Label
var _continue: Button

func _ready() -> void:
	layer = 100
	visible = false
	_build_ui()
	EconomySystem.player_level_up.connect(_on_level_up)

func _build_ui() -> void:
	var root := Control.new()
	root.theme = T.make_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.07, 0.05, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]:
		margins.add_theme_constant_override("margin_" + edge, 48)
	root.add_child(margins)
	var panel := T.card()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margins.add_child(panel)
	var column := T.column(22)
	panel.add_child(column)
	column.add_child(T.texture("res://assets/art/modern/nursery_egg.png", Vector2(0, 240)))
	_title = T.label("", 44, T.GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_description = T.label("", 26)
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_description)
	_reward = T.label("", 30, T.ACCENT)
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_reward)
	_continue = T.button("", _on_continue)
	column.add_child(_continue)

func _on_level_up(_levels: Array, reward: float) -> void:
	_is_showing = true
	_title.text = T.text("Level %d", "Poziom %d") % int(GameState.get_value("player_level", 1))
	_description.text = T.text("Your sanctuary is growing.", "Twoja hodowla się rozwija.")
	if int(GameState.get_value("player_level", 1)) == 2:
		_description.text = T.text("Your nursery is open! A welcome egg is waiting for you.", "Inkubator jest otwarty! Czeka na Ciebie powitalne jajo.")
	_reward.text = "+%s ReptiCash" % T.amount(reward)
	_continue.text = T.text("Continue", "Kontynuuj")
	visible = true

func _on_continue() -> void:
	_is_showing = false
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_continue()
		get_viewport().set_input_as_handled()
