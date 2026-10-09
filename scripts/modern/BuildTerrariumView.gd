extends Control
## A visual habitat picker. Purchasing remains in SanctuaryApp._build_habitat.
signal closed
signal build_requested(habitat_type: String)
signal route_requested(route: String)
signal shop_requested(resource_id: String)

const T := preload("res://scripts/modern/SanctuaryTheme.gd")
const TopBar := preload("res://scripts/modern/PrototypeTopBar.gd")
const BottomNav := preload("res://scripts/modern/PrototypeBottomNav.gd")
const ART := "res://assets/prototype/art/ui/habitat/"
const TYPES := ["grass", "sand", "jungle", "stone"]
const INK := Color("382006")

var biome_id := "green_meadow"
var region_name := ""
var has_build_slot := true
var safe_insets := Vector4(0, 8, 0, 10)
var terrarium_path: Callable
var habitat_name: Callable
var black_key: Callable
var _buttons: Dictionary = {}
var _cost_labels: Dictionary = {}
var _time_labels: Dictionary = {}
var _cards: Dictionary = {}
var _images: Dictionary = {}
var _grid: GridContainer
var _nav: Control
var _status: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	refresh()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(refresh)
	add_child(timer)


func _place(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.end.x
	control.anchor_bottom = rect.end.y


func _art(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var image := T.texture(path, Vector2.ZERO)
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(image)
	_place(image, rect)
	return image


func _caption(parent: Node, value: String, rect: Rect2, font_size: int = 25, paper: bool = false) -> Label:
	var label := T.label(value, font_size, INK if paper else T.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if paper:
		label.add_theme_constant_override("outline_size", 0)
		label.add_theme_constant_override("shadow_offset_y", 0)
	parent.add_child(label)
	_place(label, rect)
	return label


func _name(type: String) -> String:
	return habitat_name.call(type) if habitat_name.is_valid() else T.localized(ReptileSystem.get_habitat_type_label_key(type))


func _build() -> void:
	var background := _art(self, "res://assets/art/modern/sanctuary_background.png", Rect2(0, 0, 1, 1))
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var margin := MarginContainer.new()
	add_child(margin)
	_place(margin, Rect2(0, 0, 1, 1))
	for entry in [["left", safe_insets.x], ["top", safe_insets.y], ["right", safe_insets.z], ["bottom", safe_insets.w]]:
		margin.add_theme_constant_override("margin_" + str(entry[0]), int(entry[1]))
	var layout := T.column(0)
	margin.add_child(layout)
	var top := TopBar.new()
	layout.add_child(top)
	top.set_context_back(true)
	top.set_biome(biome_id)
	top.context_back_requested.connect(func(): closed.emit())
	top.shop_requested.connect(func(resource: String): shop_requested.emit(resource))
	var scroll := preload("res://scripts/modern/TouchScrollContainer.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var column := T.column(4)
	scroll.add_child(column)
	var heading := Control.new()
	heading.custom_minimum_size.y = 168
	column.add_child(heading)
	_art(heading, ART + "wood_plaque_profile_clean.png", Rect2(0.025, 0, 0.95, 0.96))
	_caption(heading, T.text("BUILD A TERRARIUM", "ZBUDUJ TERRARIUM"), Rect2(0.12, 0.13, 0.76, 0.40), 41)
	_caption(heading, region_name, Rect2(0.15, 0.54, 0.70, 0.22), 25)
	var tip := T.label(T.text("Choose the right home for your reptile. A matching habitat earns full income.", "Wybierz dom pasujący do gada. Dopasowane siedlisko zapewnia pełny dochód."), 24)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tip_margin := MarginContainer.new()
	tip_margin.add_theme_constant_override("margin_left", 38)
	tip_margin.add_theme_constant_override("margin_right", 38)
	tip_margin.add_theme_constant_override("margin_bottom", 14)
	column.add_child(tip_margin)
	tip_margin.add_child(tip)
	var grid_margin := MarginContainer.new()
	grid_margin.add_theme_constant_override("margin_left", 12)
	grid_margin.add_theme_constant_override("margin_right", 12)
	column.add_child(grid_margin)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 10)
	grid_margin.add_child(_grid)
	for type in TYPES: _add_choice(type)
	_status = T.label("", 24, T.GOLD)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size.y = 54
	column.add_child(_status)
	var nav_clearance := Control.new()
	nav_clearance.custom_minimum_size.y = 38
	nav_clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(nav_clearance)
	_nav = BottomNav.new()
	_nav.set_selected("home")
	layout.add_child(_nav)
	_nav.tab_selected.connect(func(route: String): route_requested.emit(route))


func _add_choice(type: String) -> void:
	var card := PanelContainer.new()
	card.name = "HabitatChoice_" + type
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", T.Controls.parchment())
	_grid.add_child(card)
	_cards[type] = card
	var contents := T.column(10)
	card.add_child(contents)
	var title := T.label(_name(type), 30, INK)
	title.name = "HabitatName"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 0)
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.max_lines_visible = 1
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.tooltip_text = _name(type)
	contents.add_child(title)
	var path: String = terrarium_path.call(type, 1) if terrarium_path.is_valid() else ReptileSystem.get_habitat_texture_path(type, 1)
	var image := T.texture(path, Vector2(0, 230))
	image.name = "TerrariumPreview"
	contents.add_child(image)
	# Modern previews already carry alpha; keying black would erase their frame.
	if black_key.is_valid() and not path.begins_with("res://assets/art/modern/"):
		black_key.call(image)
	_images[type] = image
	var time := T.label("", 22, INK)
	time.name = "BuildDuration"
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time.add_theme_constant_override("outline_size", 0)
	time.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	contents.add_child(time)
	_time_labels[type] = time
	var button := T.button("", func() -> void: build_requested.emit(type))
	button.name = "Build_" + type
	button.add_theme_font_size_override("font_size", 26)
	button.custom_minimum_size.y = 80
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(button)
	_buttons[type] = button


func refresh() -> void:
	if not is_inside_tree() or _buttons.is_empty(): return
	var price := EconomySystem.get_next_habitat_price(biome_id)
	var can_buy := has_build_slot and EconomySystem.can_afford("repticash", price)
	var duration := ReptileSystem.get_habitat_build_duration_seconds(biome_id)
	for type in TYPES:
		var button: Button = _buttons[type]
		# Keep the localized habitat name in the actionable control for screen
		# readers and the existing first-session integration tests.
		button.text = "%s · %d R$" % [_name(type), price]
		button.disabled = not can_buy
		button.tooltip_text = T.text("Build ", "Zbuduj: ") + _name(type) + " · %d R$" % price
		_time_labels[type].text = T.text("Build time", "Czas budowy") + " · " + T.time(duration)
	if not has_build_slot:
		_status.text = T.text("All habitat spaces in this region are already used.", "Wszystkie miejsca na siedliska w tym regionie są już zajęte.")
	elif not can_buy:
		_status.text = T.text("You need %d R$ to build this home.", "Do budowy potrzebujesz %d R$.") % price
	else:
		_status.text = T.text("Build a home, then choose its resident.", "Zbuduj dom, a potem wybierz jego mieszkańca.")
