extends VBoxContainer
## Illustrated world map with real expedition costs, timers, odds and discoveries.

signal toast_requested(message: String)
signal refresh_requested
signal details_requested(instance_id: String)

const T = preload("res://scripts/modern/SanctuaryTheme.gd")
const ART := "res://assets/prototype/art/ui/world/"
const MAP_ART := ART + "expedition_map.png"
const EGG_ART := "res://assets/art/modern/nursery_egg.png"
const INK := Color("38200c")
const DIM := Color("6c471f")
const CREAM := Color("fff0bd")
const MAP_RECTS: Array[Rect2] = [Rect2(0.16, 0.08, 0.30, 0.16), Rect2(0.61, 0.15, 0.27, 0.16), Rect2(0.15, 0.29, 0.31, 0.17), Rect2(0.58, 0.41, 0.31, 0.18), Rect2(0.14, 0.54, 0.29, 0.16), Rect2(0.52, 0.665, 0.30, 0.17)]
const MAP_LABELS: Array[Rect2] = [Rect2(0.12, 0.20, 0.38, 0.08), Rect2(0.55, 0.26, 0.38, 0.08), Rect2(0.11, 0.414, 0.40, 0.085), Rect2(0.54, 0.52, 0.38, 0.08), Rect2(0.10, 0.65, 0.40, 0.09), Rect2(0.49, 0.786, 0.40, 0.08)]
const RARITIES: Array[String] = ["common", "rare", "ultra_rare", "exceptional"]

var _content: VBoxContainer
var _signature_value := ""
var _refresh_queued := false
var _active_widgets: Array[Dictionary] = []
var _modal_layer: CanvasLayer
var _modal_content: VBoxContainer
var _modal_title: Label
var _region_id := ""
var _mode_id := ""
var _launch_button: Button
var _availability: Label
var _busy := false
var _plan_region_id := "green_meadow"
var _plan_content: VBoxContainer
var _region_buttons: Dictionary = {}


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 22)
	_content = T.column(7)
	add_child(_content)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()
	_rebuild()


func _exit_tree() -> void:
	if is_instance_valid(_modal_layer):
		_modal_layer.queue_free()


func refresh() -> void:
	if _content == null or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_if_needed")


func _tick() -> void:
	if is_visible_in_tree():
		_refresh_if_needed()


func _refresh_if_needed() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	if _signature() != _signature_value:
		_rebuild()
	_update_live()


func _signature() -> String:
	var result: Array = [GameState.get_language(), GameState.get_value("level", 1)]
	for expedition: Variant in ExpeditionSystem.get_active_expeditions():
		result.append([expedition.get("id", ""), expedition.get("state", ""), ExpeditionSystem.get_remaining_seconds(expedition) <= 0])
	for entry: Variant in ExpeditionSystem.get_history():
		result.append(entry.get("id", ""))
	return str(result)


func _localized(data: Dictionary, field: String = "name") -> String:
	return str(data.get(field + "_pl" if GameState.get_language() == "pl" else field + "_en", data.get(field + "_en", data.get("id", ""))))


func _region(id: String) -> Dictionary:
	for value: Variant in ExpeditionSystem.get_regions():
		if value is Dictionary and str(value.get("id", "")) == id:
			return value
	return {}


func _mode(id: String) -> Dictionary:
	for value: Variant in ExpeditionSystem.get_modes():
		if value is Dictionary and str(value.get("id", "")) == id:
			return value
	return {}


func _card(parent: Node, heading: String = "", subtitle: String = "") -> VBoxContainer:
	var panel: PanelContainer = _panel("parchment", 32)
	parent.add_child(panel)
	var column: VBoxContainer = T.column(14)
	panel.add_child(column)
	if not heading.is_empty():
		column.add_child(_label(heading, 28))
	if not subtitle.is_empty():
		column.add_child(_label(subtitle, 21, DIM))
	return column


func _skin(kind: String, content_margin: float = 32) -> StyleBox:
	# Both authored skins use fixed-size corners and stretch only their plain
	# center. A landscape expedition frame must never be squeezed into a ribbon.
	var style: StyleBoxTexture = T.Controls.skin("wood") if kind == "wood" else T.Controls.parchment()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, content_margin if kind == "wood" else maxf(content_margin, style.get_content_margin(side)))
	return style


func _panel(kind: String, content_margin: float = 32) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_meta("world_frame", true)
	panel.add_theme_stylebox_override("panel", _skin(kind, content_margin))
	return panel


func _label(copy: String, font_size: int = 24, color: Color = INK) -> Label:
	var label: Label = T.label(copy, font_size, color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	return label


func _rarity_color(rarity: String) -> Color:
	return {"common": Color("395126"), "rare": Color("17667a"), "ultra_rare": Color("6c3388"), "exceptional": Color("934408")}.get(rarity, INK)


func _ribbon(copy: String, font_size: int = 23) -> PanelContainer:
	var panel: PanelContainer = _panel("wood", 10 if font_size <= 24 else 14)
	var label: Label = _label(copy, font_size, CREAM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_shadow_color", Color("211004"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(label)
	return panel


func _compact_button(copy: String, callback: Callable, selected: bool = false, font_size: int = 22) -> Button:
	var button := T.button(copy, callback, "primary" if selected else "secondary")
	button.custom_minimum_size.y = 54
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin: StyleBox = button.get_theme_stylebox(state).duplicate()
		skin.set_content_margin(SIDE_LEFT, 5)
		skin.set_content_margin(SIDE_RIGHT, 5)
		skin.set_content_margin(SIDE_TOP, 8)
		skin.set_content_margin(SIDE_BOTTOM, 8)
		button.add_theme_stylebox_override(state, skin)
	return button


func _set_bounds(control: Control, bounds: Rect2) -> void:
	control.anchor_left = bounds.position.x
	control.anchor_top = bounds.position.y
	control.anchor_right = bounds.end.x
	control.anchor_bottom = bounds.end.y
	control.offset_left = 0
	control.offset_right = 0
	control.offset_top = 0
	control.offset_bottom = 0


func _rebuild() -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_active_widgets.clear()
	_content.add_child(_ribbon(T.text("WORLD / EXPEDITIONS", "ŚWIAT / WYPRAWY"), 34))
	var active: Array = ExpeditionSystem.get_active_expeditions()
	_build_map()
	_content.add_child(_ribbon(T.text("ACTIVE EXPEDITIONS", "AKTYWNE WYPRAWY") + "  " + str(active.size()) + " / " + str(ExpeditionSystem.get_slot_limit()), 26))
	if not active.is_empty():
		for value: Variant in active:
			_build_active(value)
	else:
		var intro: VBoxContainer = _card(_content, T.text("Your team is ready", "Twoja ekipa jest gotowa"))
		intro.add_child(_label(T.text("Choose a region on the map. Your explorers will return with an egg or an animal.", "Wybierz region na mapie. Twoja ekipa wróci z jajem lub zwierzęciem."), 23, DIM))
	_build_history()
	_signature_value = _signature()
	_update_live()


func _build_map() -> void:
	var board: HBoxContainer = T.row(6)
	_content.add_child(board)
	var map_stage := Control.new()
	map_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_stage.size_flags_stretch_ratio = 1.14
	map_stage.custom_minimum_size = Vector2(0, 730)
	board.add_child(map_stage)
	var map := Control.new()
	map_stage.add_child(map)
	var fit_map: Callable = func() -> void:
		var map_size := Vector2(map_stage.size.x, map_stage.size.x * 1672.0 / 941.0)
		map.size = map_size
		map.position = Vector2(0, maxf(0, (map_stage.size.y - map_size.y) * 0.5))
	map_stage.resized.connect(fit_map)
	fit_map.call_deferred()
	var landscape: TextureRect = T.texture(MAP_ART, Vector2.ZERO)
	landscape.name = "WorldMapArtwork"
	landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map.add_child(landscape)
	_region_buttons.clear()
	var regions: Array = ExpeditionSystem.get_regions()
	for index in range(regions.size()):
		var region: Dictionary = regions[index]
		var id: String = str(region.get("id", ""))
		var state: Dictionary = ExpeditionSystem.get_region_state(id)
		var unlocked: bool = bool(state.get("unlocked", false))
		var button := Button.new()
		button.name = "Region_" + id
		button.tooltip_text = _localized(region)
		button.accessibility_name = _localized(region)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for style_name in ["normal", "disabled"]:
			button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
		for style_name in ["hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(style_name, _portal_outline(Color("ffe48c")))
		button.pressed.connect(_show_region.bind(id))
		map.add_child(button)
		_set_bounds(button, MAP_RECTS[index])
		_region_buttons[id] = button
		var plaque := PanelContainer.new()
		plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var plaque_skin: StyleBoxTexture = T.Controls.skin("wood")
		for side in [SIDE_LEFT, SIDE_RIGHT]: plaque_skin.set_content_margin(side, 8)
		for side in [SIDE_TOP, SIDE_BOTTOM]: plaque_skin.set_content_margin(side, 4)
		plaque.add_theme_stylebox_override("panel", plaque_skin)
		map.add_child(plaque)
		_set_bounds(plaque, MAP_LABELS[index])
		var text: VBoxContainer = T.column(0)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plaque.add_child(text)
		var title: Label = _label(_map_name(id, region).to_upper(), 18, CREAM)
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_child(title)
		var count: int = int(state.get("species_count", 0))
		var found: int = count - int(state.get("undiscovered_species_count", count))
		var caption: String = "★ %d / %d" % [found, count] if unlocked else T.text("LEVEL ", "POZIOM ") + str(state.get("unlock_level", 1))
		var hint: Label = _label(caption, 16, Color("f9d678") if unlocked else Color("d7c29e"))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_child(hint)
	var plan: PanelContainer = _panel("parchment", 32)
	plan.name = "ExpeditionPlan"
	plan.custom_minimum_size.x = 286
	plan.size_flags_stretch_ratio = 1.0
	board.add_child(plan)
	_plan_content = T.column(7)
	plan.add_child(_plan_content)
	_render_plan()


func _portal_outline(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = T.style(Color(0, 0, 0, 0.02), 200, color, 0)
	style.draw_center = false
	style.set_border_width_all(3)
	return style


func _region_art(id: String) -> Texture2D:
	if not ResourceLoader.exists(MAP_ART):
		return null
	var regions: Array = ExpeditionSystem.get_regions()
	for index in range(regions.size()):
		if str(regions[index].get("id", "")) != id:
			continue
		var source: Texture2D = load(MAP_ART)
		var bounds: Rect2 = MAP_RECTS[index]
		bounds.position += Vector2(0.04, 0.01)
		bounds.size -= Vector2(0.08, 0.035)
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = Rect2(bounds.position * source.get_size(), bounds.size * source.get_size())
		return atlas
	return null


func _map_name(id: String, region: Dictionary) -> String:
	# Short map plaques stay readable; dialogs retain each region's full name.
	if id == "rainforest_canopy":
		return T.text("Rainforest canopy", "Korony lasu")
	if id == "mangrove_swamps":
		return T.text("Mangrove swamps", "Namorzyny")
	return _localized(region)


func _render_plan() -> void:
	if not is_instance_valid(_plan_content):
		return
	for child: Node in _plan_content.get_children():
		_plan_content.remove_child(child)
		child.queue_free()
	if _mode_id.is_empty():
		_mode_id = "scout"
	var region: Dictionary = _region(_plan_region_id)
	var state: Dictionary = ExpeditionSystem.get_region_state(_plan_region_id)
	for id: Variant in _region_buttons:
		var button: Button = _region_buttons[id]
		button.add_theme_stylebox_override("normal", _portal_outline(Color("ffe063")) if str(id) == _plan_region_id else StyleBoxEmpty.new())
	var title: PanelContainer = _ribbon(_localized(region).to_upper(), 24)
	_plan_content.add_child(title)
	var scenic := TextureRect.new()
	scenic.texture = _region_art(_plan_region_id)
	scenic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scenic.custom_minimum_size.y = 110
	scenic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plan_content.add_child(scenic)
	_plan_content.add_child(_label(_localized(region, "description"), 19, INK))
	_plan_content.add_child(_ribbon(T.text("EXPEDITION DURATION", "CZAS WYPRAWY"), 18))
	var durations: HBoxContainer = T.row(5)
	_plan_content.add_child(durations)
	for mode: Variant in ExpeditionSystem.get_modes():
		var mode_id: String = str(mode.get("id", ""))
		var minutes: int = int(mode.get("duration_seconds", 0)) / 60
		var copy: String = str(minutes) + " MIN" if minutes < 60 else str(minutes / 60) + " H"
		var duration: Button = _compact_button(copy, _select_plan_mode.bind(mode_id), mode_id == _mode_id)
		durations.add_child(duration)
	var costs: Dictionary = ExpeditionSystem.get_expedition_cost(_plan_region_id, _mode_id)
	var cost_row: HBoxContainer = T.row(9)
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_plan_content.add_child(cost_row)
	for item in [["coin", "cash"], ["food", "food"], ["water", "water"]]:
		cost_row.add_child(T.icon(str(item[0]), 21))
		var cost: Label = _label(T.amount(float(costs.get(item[1], 0))), 21)
		cost.autowrap_mode = TextServer.AUTOWRAP_OFF
		cost.size_flags_horizontal = Control.SIZE_FILL
		cost_row.add_child(cost)
	_plan_content.add_child(_ribbon(T.text("POSSIBLE DISCOVERIES", "MOŻLIWE ODKRYCIA"), 18))
	var discovery: HBoxContainer = T.row(10)
	_plan_content.add_child(discovery)
	var kind_chances: Dictionary = ExpeditionSystem.get_reward_kind_chances()
	for item in [["egg", T.text("Egg ", "Jajo ") + "%.0f%%" % float(kind_chances.get("egg", 0))], ["heart", T.text("Animal ", "Zwierzę ") + "%.0f%%" % float(kind_chances.get("reptile", 0))]]:
		var col: VBoxContainer = T.column(2)
		discovery.add_child(col)
		col.add_child(T.icon(str(item[0]), 33))
		var caption: Label = _label(str(item[1]), 20)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(caption)
	_plan_content.add_child(_ribbon(T.text("RARITY CHANCES", "SZANSE RZADKOŚCI"), 18))
	var odds := GridContainer.new()
	odds.columns = 2
	odds.add_theme_constant_override("h_separation", 5)
	odds.add_theme_constant_override("v_separation", 3)
	_plan_content.add_child(odds)
	var chances: Dictionary = ExpeditionSystem.get_mode_chances(_mode_id)
	for rarity in RARITIES:
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_stylebox_override("panel", T.style(Color("efcf8b"), 4, Color("936025"), 4))
		var chance: Label = _label(T.rarity_name(rarity) + " %.0f%%" % float(chances.get(rarity, 0)), 18, _rarity_color(rarity))
		chance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(chance)
		odds.add_child(box)
	_plan_content.add_child(_ribbon(T.text("SAMPLE REPTILES", "PRZYKŁADOWE GATUNKI"), 18))
	var samples: HBoxContainer = T.row(5)
	_plan_content.add_child(samples)
	var pool: Array = region.get("species_pool", [])
	for index in range(mini(3, pool.size())):
		var reptile: Dictionary = ReptileSystem.get_reptile(str(pool[index]))
		var sample := PanelContainer.new()
		sample.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sample.add_theme_stylebox_override("panel", T.style(Color("3d421c"), 6, Color("ae7d2d"), 3))
		samples.add_child(sample)
		var portrait_path: String = ReptileSystem.get_owned_animal_image_path({"reptile_id": str(pool[index]), "variant_id": reptile.get("default_variant_id", ""), "rarity": "common"})
		var portrait: TextureRect = T.texture(portrait_path, Vector2(0, 66))
		sample.tooltip_text = LocalizationSystem.tr_key(str(reptile.get("name_key", "")))
		sample.add_child(portrait)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plan_content.add_child(spacer)
	var prepare: Button = _compact_button(T.text("PREPARE EXPEDITION", "PRZYGOTUJ WYPRAWĘ") if bool(state.get("unlocked", false)) else T.text("LEVEL ", "POZIOM ") + str(state.get("unlock_level", 1)), _show_region.bind(_plan_region_id), true)
	prepare.custom_minimum_size.y = 58
	_plan_content.add_child(prepare)


func _select_plan_mode(id: String) -> void:
	_mode_id = id
	_render_plan()



func _build_active(expedition: Dictionary) -> void:
	var id: String = str(expedition.get("id", ""))
	var region: Dictionary = _region(str(expedition.get("region_id", "")))
	var mode: Dictionary = _mode(str(expedition.get("mode_id", "")))
	var panel: PanelContainer = _panel("parchment", 32)
	panel.name = "ActiveExpedition_" + id
	_content.add_child(panel)
	var row: HBoxContainer = T.row(12)
	panel.add_child(row)
	var scenic := TextureRect.new()
	scenic.texture = _region_art(str(expedition.get("region_id", "")))
	scenic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scenic.custom_minimum_size = Vector2(106, 106)
	scenic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(scenic)
	var content: VBoxContainer = T.column(4)
	row.add_child(content)
	content.add_child(_label(_localized(region).to_upper(), 27))
	content.add_child(_label(_localized(mode), 21, DIM))
	var time_label: Label = _label("", 24, Color("3f6119"))
	content.add_child(time_label)
	var progress: ProgressBar = T.progress(0, INK)
	content.add_child(progress)
	var claim: Button = T.button(T.text("Discover what returned", "Odkryj znalezisko"), _claim.bind(id))
	claim.custom_minimum_size.y = 56
	claim.add_theme_font_size_override("font_size", 24)
	content.add_child(claim)
	_active_widgets.append({"id": id, "label": time_label, "progress": progress, "button": claim})


func _build_history() -> void:
	var history: Array = ExpeditionSystem.get_history()
	if history.is_empty():
		return
	var entries: VBoxContainer = _card(_content, T.text("Explorer’s journal", "Dziennik odkrywcy"), T.text("Your last 20 discoveries", "Twoje ostatnie 20 znalezisk"))
	for index in range(mini(20, history.size())):
		var entry: Dictionary = history[index]
		var reward: Dictionary = entry.get("reward", {})
		var row: HBoxContainer = T.row(14)
		entries.add_child(row)
		row.add_child(T.icon("egg" if str(reward.get("kind", "egg")) == "egg" else "heart", 32))
		var copy: VBoxContainer = T.column(5)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		copy.add_child(_label(_reward_name(reward), 23, _rarity_color(str(reward.get("rarity", "common")))))
		var elapsed: int = maxi(0, int(Time.get_unix_time_from_system()) - int(entry.get("claimed_at", 0)))
		copy.add_child(_label(_localized(_region(str(entry.get("region_id", "")))) + " · " + T.time(elapsed) + T.text(" ago", " temu"), 18, DIM))


func _reward_name(reward: Dictionary) -> String:
	var species: Dictionary = ReptileSystem.get_reptile(str(reward.get("species_id", "")))
	var name: String = LocalizationSystem.tr_key(str(species.get("name_key", "")))
	return T.text("Egg · ", "Jajo · ") + name if str(reward.get("kind", "egg")) == "egg" else name


func _show_region(id: String) -> void:
	_region_id = id
	_plan_region_id = id
	var modes: Array = ExpeditionSystem.get_modes()
	if _mode_id.is_empty() and not modes.is_empty():
		_mode_id = str(modes[0].get("id", ""))
	_render_plan()
	_open_modal(_localized(_region(id)))
	_render_region_details()


func _render_region_details() -> void:
	if not is_instance_valid(_modal_content):
		return
	for child: Node in _modal_content.get_children():
		_modal_content.remove_child(child)
		child.queue_free()
	_launch_button = null
	_availability = null
	var region: Dictionary = _region(_region_id)
	var state: Dictionary = ExpeditionSystem.get_region_state(_region_id)
	_modal_content.add_child(_label(_localized(region, "description"), 24, DIM))
	var count: int = int(state.get("species_count", (region.get("species_pool", []) as Array).size()))
	var undiscovered: int = int(state.get("undiscovered_species_count", count))
	_modal_content.add_child(_label(T.text("Species to find: ", "Gatunki do odkrycia: ") + str(count) + " · " + str(undiscovered) + T.text(" new to your collection", " nowych w twojej kolekcji"), 22, INK))
	var kind_rates: Dictionary = ExpeditionSystem.get_reward_kind_chances()
	_modal_content.add_child(_label(T.text("Every trip finds one reward: ", "Każda wyprawa przynosi jedną nagrodę: ") + str(kind_rates.get("egg", 85)) + T.text("% egg / ", "% jajo / ") + str(kind_rates.get("reptile", 15)) + T.text("% animal. Species are drawn from this region.", "% zwierzę. Gatunek pochodzi z tego regionu."), 21, DIM))
	_modal_content.add_child(_label(T.text("Choose the pace", "Wybierz tempo"), 28, INK))
	for value: Variant in ExpeditionSystem.get_modes():
		var mode: Dictionary = value
		var mode_id: String = str(mode.get("id", ""))
		var selected: bool = mode_id == _mode_id
		var choice: Button = T.button(_localized(mode) + " · " + T.time(float(mode.get("duration_seconds", 0))), _choose_mode.bind(mode_id), "secondary")
		choice.toggle_mode = true
		choice.set_pressed_no_signal(selected)
		_modal_content.add_child(choice)
		if selected:
			_modal_content.add_child(_label(_localized(mode, "description"), 20, DIM))
	var odds: VBoxContainer = _card(_modal_content, T.text("Your discovery’s rarity", "Rzadkość znaleziska"))
	var rates: Dictionary = ExpeditionSystem.get_mode_chances(_mode_id)
	for rarity in RARITIES:
		var row: HBoxContainer = T.row(8)
		odds.add_child(row)
		var rarity_label: Label = _label(T.rarity_name(rarity), 20, _rarity_color(rarity))
		rarity_label.custom_minimum_size.x = 165
		rarity_label.size_flags_horizontal = Control.SIZE_FILL
		row.add_child(rarity_label)
		var bar: ProgressBar = T.progress(float(rates.get(rarity, 0)), _rarity_color(rarity))
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		var probability: Label = _label("%.0f%%" % float(rates.get(rarity, 0)), 21)
		probability.custom_minimum_size.x = 60
		probability.size_flags_horizontal = Control.SIZE_FILL
		probability.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(probability)
	var cost: Dictionary = ExpeditionSystem.get_expedition_cost(_region_id, _mode_id)
	var provisions: VBoxContainer = _card(_modal_content, T.text("Pack for the trail", "Przygotuj zapasy"))
	var resources: HBoxContainer = T.row(18)
	provisions.add_child(resources)
	for item in [["coin", "cash"], ["food", "food"], ["water", "water"]]:
		var resource: HBoxContainer = T.row(8)
		resource.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resources.add_child(resource)
		resource.add_child(T.icon(str(item[0]), 28))
		resource.add_child(_label(T.amount(float(cost.get(item[1], 0))), 24, INK))
	provisions.add_child(_label(T.text("Food and water come from Green Meadow’s reserves.", "Jedzenie i woda pochodzą z zapasów Zielonej Łąki."), 19, DIM))
	_availability = _label("", 21, DIM)
	_modal_content.add_child(_availability)
	_launch_button = T.button(T.text("Set off on an expedition", "Wyrusz na wyprawę"), _launch)
	_modal_content.add_child(_launch_button)
	_update_modal_availability()


func _choose_mode(id: String) -> void:
	_mode_id = id
	_render_plan()
	_render_region_details()


func _update_modal_availability() -> void:
	if not is_instance_valid(_launch_button) or not is_instance_valid(_availability):
		return
	var state: Dictionary = ExpeditionSystem.get_region_state(_region_id)
	var cost: Dictionary = ExpeditionSystem.get_expedition_cost(_region_id, _mode_id)
	var biome: String = str(cost.get("resource_biome_id", "green_meadow"))
	var unlocked: bool = bool(state.get("unlocked", false))
	var room: bool = ExpeditionSystem.get_active_expeditions().size() < ExpeditionSystem.get_slot_limit()
	var cash: bool = EconomySystem.can_afford("repticash", int(cost.get("cash", 0)))
	var food: bool = ReptileSystem.get_biome_resource_current(biome, "food") >= int(cost.get("food", 0))
	var water: bool = ReptileSystem.get_biome_resource_current(biome, "water") >= int(cost.get("water", 0))
	_launch_button.disabled = not unlocked or not room or not cash or not food or not water or _busy
	if not unlocked:
		_availability.text = T.text("This region opens at level ", "Ten region otwiera się na poziomie ") + str(state.get("unlock_level", 1)) + "."
	elif not room:
		_availability.text = T.text("Your teams are already exploring. Collect a finished expedition to free a slot.", "Wszystkie ekipy są na szlaku. Odbierz zakończoną wyprawę, aby zwolnić miejsce.")
	elif not cash or not food or not water:
		var missing: Array[String] = []
		if not cash: missing.append(T.text("cash", "monety"))
		if not food: missing.append(T.text("food", "jedzenie"))
		if not water: missing.append(T.text("water", "wodę"))
		_availability.text = T.text("Restock before setting off: ", "Przed wyruszeniem uzupełnij: ") + ", ".join(missing) + "."
	else:
		_availability.text = T.text("Supplies are ready. Your expedition continues while you are away.", "Zapasy są gotowe. Wyprawa trwa również po zamknięciu gry.")


func _update_live() -> void:
	var by_id: Dictionary = {}
	for expedition: Variant in ExpeditionSystem.get_active_expeditions():
		by_id[str(expedition.get("id", ""))] = expedition
	for item: Dictionary in _active_widgets:
		var expedition: Dictionary = by_id.get(str(item.get("id", "")), {})
		var time_label: Label = item.get("label")
		var progress: ProgressBar = item.get("progress")
		var claim: Button = item.get("button")
		if not is_instance_valid(time_label) or not is_instance_valid(progress) or not is_instance_valid(claim):
			continue
		var remaining: int = ExpeditionSystem.get_remaining_seconds(expedition)
		var duration: int = maxi(1, int(expedition.get("duration_seconds", 1)))
		var ready: bool = remaining <= 0
		time_label.text = T.text("Your explorers have returned", "Twoja ekipa wróciła") if ready else T.text("Returns in ", "Powrót za ") + T.time(remaining)
		progress.value = clampf(100.0 * (1.0 - float(remaining) / duration), 0, 100)
		claim.disabled = not ready
		claim.visible = ready
	_update_modal_availability()


func _launch() -> void:
	if _busy:
		return
	_busy = true
	var result: Dictionary = ExpeditionSystem.start_expedition(_region_id, _mode_id)
	_busy = false
	if bool(result.get("success", false)):
		_close_modal()
		toast_requested.emit(T.text("Your explorers are on their way.", "Twoja ekipa wyruszyła na szlak."))
		refresh_requested.emit()
		refresh()
	else:
		_show_error(result)
		_update_modal_availability()


func _claim(id: String) -> void:
	if _busy:
		return
	_busy = true
	var result: Dictionary = ExpeditionSystem.claim_expedition(id)
	_busy = false
	if not bool(result.get("success", false)):
		_show_error(result)
		return
	refresh_requested.emit()
	refresh()
	var reward: Dictionary = result.get("reward", {})
	_open_modal(T.text("A discovery from the wild", "Odkrycie z dzikiej krainy"), true)
	var rarity: String = str(reward.get("rarity", "common"))
	var is_egg: bool = str(reward.get("kind", "egg")) == "egg"
	var portrait: String = EGG_ART
	if not is_egg:
		var owned: Dictionary = ReptileSystem.get_owned_reptile_instances().get(str(reward.get("id", "")), {})
		portrait = ReptileSystem.get_owned_animal_image_path(owned)
	_modal_content.add_child(T.texture(portrait, Vector2(0, 320)))
	var title: Label = _label(_reward_name(reward), 31)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_content.add_child(title)
	var rarity_label: Label = _label(T.rarity_name(rarity), 27, _rarity_color(rarity))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_content.add_child(rarity_label)
	_modal_content.add_child(_label(T.text("Your egg is waiting in the nursery’s basket. Incubate it to meet the animal inside.", "Jajo czeka w koszyku wylęgarni. Rozpocznij inkubację, aby poznać jego mieszkańca.") if is_egg else T.text("Your new animal is in the collection. Give it a habitat and help it settle in.", "Nowe zwierzę jest już w kolekcji. Przydziel mu siedlisko i pomóż się zadomowić."), 24, DIM))
	if not is_egg:
		_modal_content.add_child(T.button(T.text("Meet your animal", "Poznaj swoje zwierzę"), _inspect_animal.bind(str(reward.get("id", "")))))


func _inspect_animal(id: String) -> void:
	_close_modal()
	details_requested.emit(id)


func _show_error(result: Dictionary) -> void:
	var message: String
	match str(result.get("reason", "")):
		"locked": message = T.text("Reach the region’s required level first.", "Najpierw osiągnij poziom wymagany przez ten region.")
		"no_slot": message = T.text("All your teams are exploring. Collect a finished expedition first.", "Wszystkie ekipy są na szlaku. Najpierw odbierz zakończoną wyprawę.")
		"not_enough_cash": message = T.text("You need more coins for this expedition.", "Brakuje monet na tę wyprawę.")
		"not_enough_food": message = T.text("Restock food in Green Meadow before setting off.", "Przed wyruszeniem uzupełnij jedzenie na Zielonej Łące.")
		"not_enough_water": message = T.text("Restock water in Green Meadow before setting off.", "Przed wyruszeniem uzupełnij wodę na Zielonej Łące.")
		"not_ready": message = T.text("Your explorers are still on the trail.", "Twoja ekipa jest jeszcze na szlaku.")
		"already_claimed": message = T.text("This discovery is already in your collection.", "To znalezisko jest już w twojej kolekcji.")
		"save_failed": message = T.text("The expedition could not be saved. Nothing was spent; please try again.", "Nie udało się zapisać wyprawy. Niczego nie wydano — spróbuj ponownie.")
		_: message = T.text("This expedition cannot proceed yet. Check supplies, level and available teams.", "Wyprawa nie może jeszcze wyruszyć. Sprawdź zapasy, poziom i dostępność ekip.")
	toast_requested.emit(message)


func _open_modal(title: String, compact: bool = false) -> void:
	_close_modal(false)
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 40
	get_tree().root.add_child(_modal_layer)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.025, 0.06, 0.045, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(shade)
	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 64)
	_modal_layer.add_child(margins)
	var panel: PanelContainer = _panel("parchment", 32)
	panel.name = "ExpeditionDialog"
	panel.theme = T.make_theme()
	margins.add_child(panel)
	if compact:
		# A single discovery should sit close to its actions, while the same
		# scroll container still protects long localized reward descriptions.
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fit_reward: Callable = func() -> void:
			panel.custom_minimum_size.y = minf(900.0, maxf(0.0, margins.size.y - 128.0))
		margins.resized.connect(fit_reward)
		fit_reward.call_deferred()
	var outer: VBoxContainer = T.column(18)
	panel.add_child(outer)
	_modal_title = _label(title, 35, INK)
	outer.add_child(_modal_title)
	var scroll: ScrollContainer = preload("res://scripts/modern/TouchScrollContainer.gd").new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_modal_content = T.column(16)
	_modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_modal_content)
	outer.add_child(T.button(T.text("Close", "Zamknij"), _close_modal, "secondary"))


func _close_modal(clear_selection: bool = true) -> void:
	if is_instance_valid(_modal_layer):
		_modal_layer.queue_free()
	_modal_layer = null
	_modal_content = null
	_launch_button = null
	_availability = null
	if clear_selection:
		_region_id = ""


func dismiss_overlay() -> bool:
	if not is_instance_valid(_modal_layer):
		return false
	_close_modal()
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and dismiss_overlay():
		get_viewport().set_input_as_handled()
