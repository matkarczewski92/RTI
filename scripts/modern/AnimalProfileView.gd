extends Control
## Presentation only. The application owns every care, rename and habitat mutation.

signal closed
signal care_requested(action: String)
signal rename_requested(value: String)
signal move_requested
signal assign_requested
signal sell_requested
signal upgrade_requested
signal route_requested(route: String)
signal shop_requested(resource_id: String)

const T := preload("res://scripts/modern/SanctuaryTheme.gd")
const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")
const TopBar := preload("res://scripts/modern/PrototypeTopBar.gd")
const BottomNav := preload("res://scripts/modern/PrototypeBottomNav.gd")
const ART := "res://assets/prototype/art/ui/habitat/"
const ICONS := "res://assets/prototype/art/icons/"
const INK := Color("382006")
const NAME_FONT := preload("res://assets/prototype/fonts/BreeSerif-Regular.ttf")
const NEEDS := [
	["hunger", "feed", "food", "Food", "Pokarm", "Feed", "Nakarm", "eda72b"],
	["hydration", "water", "water", "Water", "Woda", "Water", "Napój", "30b8e1"],
	["cleanliness", "clean", "clean", "Cleanliness", "Czystość", "Clean", "Posprzątaj", "87b43a"],
	["happiness", "play", "happy", "Happiness", "Szczęście", "Play", "Pobaw się", "a0bd35"]
]

var instance_id := ""
var terrarium_path: Callable
var black_key: Callable
var biome_id := "green_meadow"
var selected_route := "home"
var safe_insets := Vector4(0, 8, 0, 10)
var _top: Control
var _nav: Control
var _scroll: ScrollContainer
var _body: VBoxContainer
var _hero: Control
var _hero_stage: Control
var _hero_plaque: TextureRect
var _rarity_art: TextureRect
var _level_art: TextureRect
var _edit_art: TextureRect
var _edit_button: Button
var _habitat_art: TextureRect
var _resident: TextureRect
var _title: Label
var _rarity: Label
var _sex: PanelContainer
var _level: Label
var _needs: Dictionary = {}
var _care_buttons: Dictionary = {}
var _care_status: Dictionary = {}
var _income: Label
var _xp_text: Label
var _xp_bar: ProgressBar
var _upgrade_panel: Control
var _upgrade_preview: TextureRect
var _habitat_level: Label
var _upgrade_copy: Label
var _upgrade_button: Button
var _upgrade_progress: ProgressBar
var _rename: LineEdit
var _management: VBoxContainer
var _move_button: Button
var _assign_button: Button
var _sell_button: Button
var _loaded_habitat_path := ""
var _loaded_animal_path := ""


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
	control.set_offset(SIDE_LEFT, 0)
	control.set_offset(SIDE_TOP, 0)
	control.set_offset(SIDE_RIGHT, 0)
	control.set_offset(SIDE_BOTTOM, 0)


func _art(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var image := T.texture(path, Vector2.ZERO)
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(image)
	_place(image, rect)
	return image


func _paper_label(value: String, font_size: int = 24) -> Label:
	var label := T.label(value, font_size, INK)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _center_label(parent: Node, value: String, rect: Rect2, font_size: int = 28) -> Label:
	var label := T.label(value, font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	_place(label, rect)
	return label


func _blank_button(callback: Callable) -> Button:
	var button := Button.new()
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", T.style(Color.TRANSPARENT, 12, T.GOLD, 0))
	button.pressed.connect(callback)
	return button


func _sheet(height: float, path: String = "profile_parchment_panel_clean.png") -> Control:
	var panel := PanelContainer.new()
	panel.name = "ProfileSheet"
	panel.custom_minimum_size.y = height
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", T.Controls.skin("wood") if path == "profile_care_tray.png" else T.Controls.parchment())
	_body.add_child(panel)
	return panel


func _build() -> void:
	var backdrop := _art(self, "res://assets/art/modern/sanctuary_background.png", Rect2(0, 0, 1, 1))
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.015, 0.22)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_place(shade, Rect2(0, 0, 1, 1))
	var safe := MarginContainer.new()
	add_child(safe)
	_place(safe, Rect2(0, 0, 1, 1))
	for entry in [["left", safe_insets.x], ["top", safe_insets.y], ["right", safe_insets.z], ["bottom", safe_insets.w]]:
		safe.add_theme_constant_override("margin_" + str(entry[0]), int(entry[1]))
	var layout := T.column(0)
	safe.add_child(layout)
	_top = TopBar.new()
	layout.add_child(_top)
	_top.set_context_back(true)
	_top.set_biome(biome_id)
	_top.context_back_requested.connect(func(): closed.emit())
	_top.shop_requested.connect(func(resource: String): shop_requested.emit(resource))
	_scroll = preload("res://scripts/modern/TouchScrollContainer.gd").new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(_scroll)
	_body = T.column(8)
	_scroll.add_child(_body)
	_build_hero()
	_build_needs()
	_build_care()
	_build_progress()
	_build_upgrade()
	_build_management()
	var nav_clearance := Control.new()
	nav_clearance.custom_minimum_size.y = 38
	nav_clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(nav_clearance)
	_nav = BottomNav.new()
	_nav.set_selected(selected_route)
	layout.add_child(_nav)
	_nav.tab_selected.connect(func(route: String): route_requested.emit(route))


func _build_hero() -> void:
	_hero = Control.new()
	_hero.custom_minimum_size.y = 646
	_hero.resized.connect(_layout_hero)
	_body.add_child(_hero)
	_hero_stage = Control.new()
	_hero.add_child(_hero_stage)
	_habitat_art = _art(_hero_stage, "", Rect2(0.064, 0.065, 0.873, 0.865))
	_habitat_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_resident = _art(_hero_stage, "", Rect2(0.12, 0.22, 0.76, 0.69))
	if black_key.is_valid(): black_key.call(_resident)
	_art(_hero_stage, ART + "terrarium_open_frame_clean.png", Rect2(0, 0, 1, 1))
	_hero_plaque = _art(_hero, ART + "wood_plaque_profile_clean.png", Rect2())
	_title = _center_label(_hero, "", Rect2(), 34)
	_title.add_theme_font_override("font", NAME_FONT)
	_title.max_lines_visible = 2
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_rarity_art = _art(_hero, ART + "profile_rarity_ribbon.png", Rect2())
	_rarity = _center_label(_hero, "", Rect2(), 24)
	_rarity.autowrap_mode = TextServer.AUTOWRAP_OFF
	_sex = T.sex_badge("")
	_hero.add_child(_sex)
	_level_art = _art(_hero, ART + "profile_level_badge.png", Rect2())
	_level = _center_label(_hero, "", Rect2(), 24)
	_level.autowrap_mode = TextServer.AUTOWRAP_OFF
	_edit_art = _art(_hero, ART + "profile_edit_medallion.png", Rect2())
	_edit_button = _blank_button(func():
		_scroll.ensure_control_visible(_rename)
		_rename.grab_focus())
	_edit_button.tooltip_text = T.text("Give your reptile a name", "Nadaj imię swojemu gadowi")
	_hero.add_child(_edit_button)
	_layout_hero.call_deferred()


func _layout_hero() -> void:
	if not is_instance_valid(_edit_button): return
	var factor := _hero.size.x / 720.0
	_hero.custom_minimum_size.y = 646.0 * factor
	# Every authored ornament has a box of its natural aspect ratio. Text has
	# its own bounded area, independent of the decoration's transparent padding.
	var parts := [
		[_hero_stage, Rect2(18, 190, 684, 456)],
		[_hero_plaque, Rect2(64, 0, 592, 592.0 * 530.0 / 1761.0)],
		[_title, Rect2(140, 27, 440, 96)],
		[_rarity_art, Rect2(108, 145, 296, 296.0 * 221.0 / 1024.0)],
		[_rarity, Rect2(126, 157, 260, 36)],
		[_sex, Rect2(430, 153, 170, 50)],
		[_level_art, Rect2(608, 34, 106, 106)],
		[_level, Rect2(632, 63, 58, 60)],
		[_edit_art, Rect2(6, 34, 106, 106.0 * 595.0 / 597.0)],
		[_edit_button, Rect2(6, 34, 106, 106)]
	]
	for part in parts:
		var control: Control = part[0]
		var rect: Rect2 = part[1]
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		control.position = rect.position * factor
		control.size = rect.size * factor


func _build_needs() -> void:
	var panel := _sheet(210)
	var grid := GridContainer.new()
	grid.name = "NeedsGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 12)
	panel.add_child(grid)
	for info in NEEDS:
		var row := T.row(8)
		grid.add_child(row)
		var icon_path: String = ICONS + str(info[2]) + ".png"
		if info[1] == "clean": icon_path = ICONS + "actions/clean.png"
		row.add_child(T.texture(icon_path, Vector2(43, 52)))
		var column := T.column(2)
		row.add_child(column)
		column.add_child(_paper_label(T.text(info[3], info[4]), 23))
		var bar := T.progress(0, Color(info[7]))
		bar.custom_minimum_size = Vector2(0, 28)
		bar.add_theme_stylebox_override("background", T.style(Color("58441f"), 7, Color("9c7734"), 0))
		bar.add_theme_stylebox_override("fill", T.style(Color(info[7]), 6, Color("665216"), 0))
		column.add_child(bar)
		var amount := _center_label(bar, "", Rect2(0, 0, 1, 1), 21)
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		_needs[info[0]] = {"bar": bar, "amount": amount}


func _build_care() -> void:
	var tray := _sheet(184, "profile_care_tray.png")
	var row := T.row(8)
	tray.add_child(row)
	for info in NEEDS:
		var action: String = info[1]
		var button := Button.new()
		button.pressed.connect(func(): care_requested.emit(action))
		button.name = "Care_" + action
		button.text = T.text(info[5], info[6])
		button.custom_minimum_size.y = 158
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 23)
		T.Controls.apply(button, "red" if action == "feed" else "blue" if action == "water" else "green")
		# Keep the semantic caption for accessibility; the visible native labels
		# have reserved rows beneath the undistorted icon.
		for color in ["font_color", "font_disabled_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color, Color.TRANSPARENT)
		button.add_theme_constant_override("outline_size", 0)
		row.add_child(button)
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		_place(margin, Rect2(0, 0, 1, 1))
		for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 12)
		var column := T.column(1)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(column)
		var art_id: String = "care" if action == "play" else action
		var icon := T.texture(ICONS + "actions/" + art_id + ".png", Vector2(0, 74))
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(icon)
		var caption := T.label(button.text, 23)
		caption.name = "CareCaption"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption.clip_text = true
		column.add_child(caption)
		var status := T.label("", 18)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.autowrap_mode = TextServer.AUTOWRAP_OFF
		status.clip_text = true
		column.add_child(status)
		_care_buttons[action] = button
		_care_status[action] = status


func _build_progress() -> void:
	var panel := _sheet(154)
	var row := T.row(18)
	panel.add_child(row)
	var income_group := T.row(10)
	row.add_child(income_group)
	income_group.add_child(T.texture(ICONS + "currency.png", Vector2(54, 54)))
	_income = _paper_label("", 24)
	_income.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	income_group.add_child(_income)
	var xp_group := T.column(8)
	xp_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(xp_group)
	_xp_text = _paper_label("", 23)
	xp_group.add_child(_xp_text)
	_xp_bar = T.progress(0, Color("9670d6"))
	_xp_bar.custom_minimum_size.y = 22
	xp_group.add_child(_xp_bar)


func _build_upgrade() -> void:
	_upgrade_panel = _sheet(222)
	var row := T.row(12)
	_upgrade_panel.add_child(row)
	_upgrade_preview = T.texture("", Vector2(128, 126))
	row.add_child(_upgrade_preview)
	if black_key.is_valid(): black_key.call(_upgrade_preview)
	var copy := T.column(4)
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(copy)
	_habitat_level = _paper_label("", 25)
	copy.add_child(_habitat_level)
	_upgrade_copy = _paper_label("", 21)
	copy.add_child(_upgrade_copy)
	var action := T.column(8)
	action.custom_minimum_size.x = 210
	action.size_flags_horizontal = Control.SIZE_SHRINK_END
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(action)
	_upgrade_button = T.button("", func(): upgrade_requested.emit())
	_upgrade_button.custom_minimum_size = Vector2(210, 96)
	_upgrade_button.add_theme_font_size_override("font_size", 25)
	action.add_child(_upgrade_button)
	_upgrade_progress = T.progress(0, T.GOLD)
	_upgrade_progress.custom_minimum_size.y = 12
	_upgrade_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(_upgrade_progress)


func _build_management() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 24)
	_body.add_child(margin)
	_management = T.column(10)
	margin.add_child(_management)
	var row := T.row(10)
	_management.add_child(row)
	_rename = LineEdit.new()
	_rename.name = "ReptileName"
	_rename.placeholder_text = T.text("Give your reptile a name", "Nadaj imię swojemu gadowi")
	_rename.max_length = 24
	_rename.custom_minimum_size = Vector2(0, 68)
	_rename.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename.add_theme_font_size_override("font_size", 23)
	row.add_child(_rename)
	var save := T.button(T.text("Save name", "Zapisz imię"), func(): rename_requested.emit(_rename.text.strip_edges()), "secondary")
	save.custom_minimum_size = Vector2(140, 68)
	save.size_flags_horizontal = Control.SIZE_SHRINK_END
	save.add_theme_font_size_override("font_size", 23)
	row.add_child(save)
	_move_button = T.button(T.text("Move to collection", "Przenieś do kolekcji"), func(): move_requested.emit(), "secondary")
	_move_button.custom_minimum_size.y = 64
	_management.add_child(_move_button)
	_assign_button = T.button(T.text("Assign a habitat", "Przypisz siedlisko"), func(): assign_requested.emit())
	_assign_button.custom_minimum_size.y = 64
	_management.add_child(_assign_button)
	_sell_button = T.button("", func(): sell_requested.emit(), "danger")
	_sell_button.custom_minimum_size.y = 64
	_management.add_child(_sell_button)


func refresh() -> void:
	if not is_instance_valid(_title): return
	var instance: Dictionary = ReptileSystem.get_owned_reptile_instances().get(instance_id, {})
	if instance.is_empty():
		closed.emit()
		return
	var species: Dictionary = ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))
	var custom_name := str(instance.get("custom_name", ""))
	_title.text = custom_name if not custom_name.is_empty() else T.localized(str(species.get("name_key", "")))
	_rarity.text = T.rarity_name(str(instance.get("rarity", "common")))
	_rarity.add_theme_color_override("font_color", T.rarity_color(str(instance.get("rarity", "common"))).lightened(0.15))
	var sex := str(instance.get("sex", ""))
	if str(_sex.get_meta("sex", "")) != sex:
		_hero.remove_child(_sex)
		_sex.queue_free()
		_sex = T.sex_badge(sex)
		_hero.add_child(_sex)
		_layout_hero()
	_level.text = "%s\n%d" % [T.text("LvL", "Poz."), ReptileSystem.get_reptile_level(instance)]
	if not _rename.has_focus() and _rename.text != custom_name: _rename.text = custom_name
	var animal_path := T.animal_path(instance)
	if animal_path != _loaded_animal_path:
		_loaded_animal_path = animal_path
		_resident.texture = AssetPaths.load_texture(animal_path)
	for info in NEEDS:
		var need: Dictionary = _needs[info[0]]
		var value := clampf(float(instance.get(info[0], 100)), 0, 100)
		need.bar.value = value
		need.amount.text = "%d%%" % roundi(value)
		var action: String = info[1]
		var availability: Dictionary = ReptileSystem.get_care_action_availability(instance, action)
		var button: Button = _care_buttons[action]
		button.disabled = not bool(availability.get("available", false))
		button.modulate = Color.WHITE
		button.tooltip_text = T.localized(str(availability.get("message_key", ""))) if button.disabled else ""
		var status: Label = _care_status[action]
		match str(availability.get("reason", "")):
			"satisfied": status.text = T.text("Content", "Zaspokojone")
			"cooldown": status.text = T.time(float(availability.get("cooldown_remaining", 0)))
			"not_enough_food": status.text = T.text("No food", "Brak pokarmu")
			"not_enough_water": status.text = T.text("No water", "Brak wody")
			"not_assigned": status.text = T.text("Place first", "Przypisz dom")
			_: status.text = T.text("Ready", "Gotowe") if not button.disabled else ""
	var habitat_id := str(instance.get("habitat_id", "")) if instance.get("habitat_id") != null else ""
	var habitat: Dictionary = ReptileSystem.get_habitat_state(habitat_id) if not habitat_id.is_empty() else {}
	var level := int(habitat.get("habitat_level", 1))
	var habitat_type: String = habitat.get("habitat_type", ReptileSystem.get_reptile_preferred_habitat_type(str(instance.get("reptile_id", ""))))
	var path: String = terrarium_path.call(habitat_type, level) if terrarium_path.is_valid() else ReptileSystem.get_habitat_texture_path(habitat_type, level)
	if path != _loaded_habitat_path:
		_loaded_habitat_path = path
		var source := AssetPaths.load_texture(path)
		_upgrade_preview.texture = source
		if source != null:
			var interior := AtlasTexture.new()
			interior.atlas = source
			interior.region = Rect2(source.get_size() * Vector2(0.12, 0.14), source.get_size() * Vector2(0.76, 0.72))
			_habitat_art.texture = interior
	var next_xp := ReptileSystem.get_xp_to_next_reptile_level(ReptileSystem.get_reptile_level(instance))
	_xp_text.text = T.text("Reptile XP", "XP gada") + " · " + ("%d/%d" % [ReptileSystem.get_reptile_xp(instance), next_xp] if next_xp > 0 else T.text("MAX", "MAKS."))
	_xp_bar.value = 100.0 * float(ReptileSystem.get_reptile_xp(instance)) / float(next_xp) if next_xp > 0 else 100
	_income.text = T.text("Income", "Dochód") + "\n%.2f R$/min" % ReptileSystem.get_effective_animal_income_per_min(instance)
	_upgrade_panel.visible = not habitat.is_empty()
	_habitat_level.text = T.text("Habitat level", "Poziom siedliska") + "\n%d / %d" % [level, ReptileSystem.get_habitat_max_level()]
	var upgrading := bool(habitat.get("is_upgrading", false))
	var capped := level >= ReptileSystem.get_habitat_max_level()
	_upgrade_copy.text = T.text("Maximum comfort", "Pełen komfort") if capped else T.text("More income\nBetter home", "Większy dochód\nLepszy dom")
	_upgrade_button.text = T.text("Complete", "Ukończone") if capped else T.text("Upgrade", "Ulepsz") + "\n%s R$" % T.amount(ReptileSystem.get_habitat_upgrade_cost())
	_upgrade_progress.visible = upgrading
	if upgrading:
		_upgrade_button.text = T.text("Upgrading", "Ulepszanie") + "\n" + T.time(ReptileSystem.get_habitat_upgrade_remaining_seconds(habitat_id))
		var started_at := float(habitat.get("upgrade_started_at", 0))
		var duration := maxf(1, float(habitat.get("upgrade_finish_at", 0)) - started_at)
		_upgrade_progress.value = clampf((Time.get_unix_time_from_system() - started_at) / duration * 100, 0, 100)
	_upgrade_button.disabled = capped or upgrading or bool(habitat.get("is_building", false)) or not EconomySystem.can_afford("repticash", ReptileSystem.get_habitat_upgrade_cost())
	# The disabled skin already dims its illustration. Keep its caption at the
	# theme's readable contrast instead of applying a second whole-button tint.
	_upgrade_button.modulate = Color.WHITE
	_upgrade_button.tooltip_text = T.text("Your reptile stays at home while it is upgraded.", "Gad pozostaje w swoim domu podczas ulepszenia.")
	_move_button.visible = not habitat_id.is_empty()
	_assign_button.visible = true
	_assign_button.text = T.text("Choose a terrarium", "Wybierz terrarium") if habitat_id.is_empty() else T.text("Change terrarium", "Zmień terrarium")
	_sell_button.visible = habitat_id.is_empty() and str(instance.get("breeding_state", "none")) == "none"
	_sell_button.text = T.text("Sell · %s R$", "Sprzedaj · %s R$") % T.amount(ReptileSystem.calculate_sell_price(instance))
	_top.refresh()
