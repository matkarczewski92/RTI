extends Control

const AssetPaths = preload("res://scripts/helpers/AssetPaths.gd")

var _earned_amount: int = 0

func _ready() -> void:
	hide()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if EconomySystem.has_signal("offline_income_calculated"):
		EconomySystem.offline_income_calculated.connect(_on_offline_income)
		
	_build_ui()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
		
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = LocalizationSystem.tr_key("ui.offline_income_title") if LocalizationSystem.has_method("tr_key") else "Offline income"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var msg = Label.new()
	msg.text = LocalizationSystem.tr_key("ui.offline_income_message") if LocalizationSystem.has_method("tr_key") else "While you were away:"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)
	
	var time_lbl = Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_lbl)
	
	var chest_icon = TextureRect.new()
	if AssetPaths.has_method("load_texture"):
		chest_icon.texture = AssetPaths.load_texture("res://assets/art/ui/icons/menu/chest.png")
	chest_icon.custom_minimum_size = Vector2(80, 80)
	chest_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(chest_icon)
	
	var amount_lbl = Label.new()
	amount_lbl.name = "AmountLabel"
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.add_theme_font_size_override("font_size", 22)
	amount_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	vbox.add_child(amount_lbl)
	
	var btn = Button.new()
	btn.text = LocalizationSystem.tr_key("ui.claim") if LocalizationSystem.has_method("tr_key") else "Claim"
	btn.custom_minimum_size = Vector2(180, 50)
	btn.pressed.connect(_on_collect_pressed)
	vbox.add_child(btn)

func _on_offline_income(amount: int, time_away: int) -> void:
	_earned_amount = amount
	
	var time_lbl = find_child("TimeLabel", true, false)
	if time_lbl:
		var h = time_away / 3600
		var m = (time_away % 3600) / 60
		var s = time_away % 60
		time_lbl.text = ("%dh " % h if h > 0 else "") + ("%dm " % m if m > 0 else "") + "%ds" % s
		
	var amt_lbl = find_child("AmountLabel", true, false)
	if amt_lbl:
		amt_lbl.text = "+ R$ " + str(amount)
		
	show()

func _on_collect_pressed() -> void:
	if EconomySystem.has_method("claim_offline_income"):
		EconomySystem.claim_offline_income()
	queue_free()