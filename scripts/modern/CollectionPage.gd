extends VBoxContainer
## The real 22-species atlas and owned animals, dressed in the approved card art.

signal details_requested(instance_id: String)
signal toast_requested(message: String)
signal refresh_requested
signal nursery_requested
signal shop_requested

const T = preload("res://scripts/modern/SanctuaryTheme.gd")
const P = preload("res://scripts/modern/PrototypeUiKit.gd")
const BLACK_KEY = preload("res://assets/prototype/shaders/black_key.gdshader")
const ART := "res://assets/prototype/art/ui/collection/"
const RARITIES: Array[String] = ["common", "rare", "ultra_rare", "exceptional"]
var tab := "journal"
var biome_id := "all"
var rarity_filter := "all"
var query := ""
var _content: VBoxContainer
var _grid: GridContainer
var _summary: Label
var _search: LineEdit
var _signature_value := ""
var _refresh_queued := false
var _modal_layer: CanvasLayer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content = T.column(10)
	add_child(_content)
	_rebuild()


func _exit_tree() -> void:
	_close_modal()


func refresh() -> void:
	if _refresh_queued or not is_instance_valid(_content):
		return
	_refresh_queued = true
	call_deferred("_refresh_now")


func _refresh_now() -> void:
	_refresh_queued = false
	if is_inside_tree() and _signature() != _signature_value:
		_rebuild()


func _signature() -> String:
	return str([GameState.get_language(), tab, biome_id, rarity_filter, GameState.get_value("discovered_variants", {}), GameState.get_value("owned_reptile_instances", {})])


func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _rebuild() -> void:
	_clear(_content)
	var header: HBoxContainer = T.row(10)
	_content.add_child(header)
	var sign: TextureRect = T.texture(ART + "atlas_title_v2.png", Vector2(0, 134))
	sign.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sign.size_flags_stretch_ratio = 1.8
	header.add_child(sign)
	var progress: VBoxContainer = T.column(5)
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(progress)
	var discovered: int = 0
	var variants: int = 0
	for species: Variant in ReptileSystem.reptiles:
		var count: int = _discovered_count(str(species.get("id", "")))
		discovered += 1 if count > 0 else 0
		variants += count
	progress.add_child(T.label(T.text("SPECIES DISCOVERED", "ODKRYTE GATUNKI"), 23, P.CREAM))
	progress.add_child(T.label("%d / %d" % [discovered, ReptileSystem.reptiles.size()], 37, P.GOLD))
	progress.add_child(T.progress(100.0 * variants / maxf(1, ReptileSystem.reptiles.size() * 4), P.LEAF_LIGHT))
	progress.add_child(T.label(T.text("Variants: ", "Odmiany: ") + str(variants) + " / " + str(ReptileSystem.reptiles.size() * 4), 22, P.CREAM))
	var tabs: HBoxContainer = T.row(8)
	_content.add_child(tabs)
	tabs.add_child(_button(T.text("FIELD ATLAS", "ATLAS ODMIAN"), _select_tab.bind("journal"), tab == "journal", 25))
	tabs.add_child(_button(T.text("MY REPTILES", "MOJE GADY"), _select_tab.bind("owned"), tab == "owned", 25))
	var filters: HBoxContainer = T.row(5)
	_content.add_child(filters)
	filters.add_child(_button(T.text("ALL", "WSZYSTKIE"), _set_rarity.bind("all"), rarity_filter == "all", 21))
	for rarity in RARITIES:
		filters.add_child(_button(T.rarity_name(rarity).to_upper(), _set_rarity.bind(rarity), rarity_filter == rarity, 21))
	var search_row: HBoxContainer = T.row(8)
	_content.add_child(search_row)
	_search = LineEdit.new()
	_search.placeholder_text = T.text("Search species or name…", "Szukaj gatunku lub imienia…")
	_search.text = query
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.custom_minimum_size.y = 58
	_search.add_theme_font_size_override("font_size", 25)
	_search.text_changed.connect(_set_query)
	search_row.add_child(_search)
	var biome := OptionButton.new()
	biome.custom_minimum_size = Vector2(183, 58)
	biome.add_theme_font_size_override("font_size", 24)
	var biome_values: Array[String] = ["all", "green_meadow", "dry_prairie"]
	for id in biome_values:
		biome.add_item(T.text("All regions", "Wszystkie regiony") if id == "all" else T.localized("biome." + id + ".name"))
	biome.select(maxi(0, biome_values.find(biome_id)))
	biome.item_selected.connect(func(index: int) -> void: biome_id = biome_values[index]; _render_results())
	search_row.add_child(biome)
	_summary = T.label("", 21, P.CREAM)
	_content.add_child(_summary)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 10)
	_content.add_child(_grid)
	_render_results()
	_signature_value = _signature()


func _button(copy: String, callback: Callable, selected: bool = false, font_size: int = 24) -> Button:
	var button: Button = T.button(copy, callback, "secondary")
	button.custom_minimum_size.y = 52
	P.apply_button(button, "green" if selected else "wood", font_size)
	for state in ["normal", "hover", "pressed"]:
		var skin: StyleBox = button.get_theme_stylebox(state).duplicate()
		skin.set_content_margin(SIDE_LEFT, 7)
		skin.set_content_margin(SIDE_RIGHT, 7)
		button.add_theme_stylebox_override(state, skin)
	return button


func _select_tab(value: String) -> void:
	tab = value
	_rebuild()


func _set_rarity(value: String) -> void:
	rarity_filter = value
	_rebuild()


func _set_query(value: String) -> void:
	query = value
	_render_results()


func _discovered_count(species_id: String) -> int:
	var count := 0
	for rarity in RARITIES:
		var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(species_id, rarity)
		if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))):
			count += 1
	return count


func _featured_rarity(species_id: String) -> String:
	if rarity_filter != "all":
		return rarity_filter
	for index in range(RARITIES.size() - 1, -1, -1):
		var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(species_id, RARITIES[index])
		if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))):
			return RARITIES[index]
	return "common"


func _matches(species: Dictionary, custom_name: String = "") -> bool:
	if biome_id != "all" and str(species.get("biome_id", "")) != biome_id:
		return false
	var searchable: String = T.localized(str(species.get("name_key", ""))) + " " + custom_name
	return query.strip_edges().is_empty() or query.to_lower() in searchable.to_lower()


func _render_results() -> void:
	if not is_instance_valid(_grid):
		return
	_clear(_grid)
	var count := 0
	if tab == "owned":
		for value: Variant in ReptileSystem.get_owned_reptile_instances().values():
			var instance: Dictionary = value
			var species: Dictionary = ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))
			if not _matches(species, str(instance.get("custom_name", ""))):
				continue
			if rarity_filter != "all" and str(instance.get("rarity", "common")) != rarity_filter:
				continue
			_grid.add_child(_owned_card(instance, species))
			count += 1
	else:
		for value: Variant in ReptileSystem.reptiles:
			var species: Dictionary = value
			if _matches(species):
				_grid.add_child(_species_card(species))
				count += 1
	_summary.text = (T.text("Animals: ", "Zwierzęta: ") if tab == "owned" else T.text("Species: ", "Gatunki: ")) + str(count)
	if count == 0:
		_summary.text += T.text(" · No matching animals yet.", " · Brak pasujących zwierząt.")
		if tab == "owned" and ReptileSystem.get_owned_reptile_count() == 0:
			_grid.add_child(_button(T.text("Visit the shop", "Odwiedź sklep"), func() -> void: shop_requested.emit(), true))
	elif count < _grid.columns:
		# GridContainer expands only populated columns. Reserve the missing slots
		# so a first reptile has the same card proportions as a larger collection.
		for index in range(count, _grid.columns):
			var empty := Control.new()
			empty.name = "EmptyCollectionSlot" + str(index)
			empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_grid.add_child(empty)
	_signature_value = _signature()


func _frame(name_value: String) -> Control:
	var card := Control.new()
	card.name = name_value
	card.custom_minimum_size.y = 278
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	var frame: TextureRect = T.texture("res://assets/art/modern/species_card_frame_v2.png", Vector2.ZERO)
	frame.name = "CardFrame"
	var material := ShaderMaterial.new()
	material.shader = BLACK_KEY
	material.set_shader_parameter("threshold", 0.008)
	material.set_shader_parameter("feather", 0.025)
	frame.material = material
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(frame)
	var aspect: float = float(frame.texture.get_height()) / float(frame.texture.get_width())
	card.resized.connect(func() -> void:
		card.custom_minimum_size.y = ceilf(card.size.x * aspect))
	return card


func _place(parent: Control, child: Control, bounds: Rect2) -> void:
	parent.add_child(child)
	child.anchor_left = bounds.position.x
	child.anchor_top = bounds.position.y
	child.anchor_right = bounds.end.x
	child.anchor_bottom = bounds.end.y
	child.offset_left = 0
	child.offset_top = 0
	child.offset_right = 0
	child.offset_bottom = 0


func _copy(card: Control, copy: String, bounds: Rect2, font_size: int = 23, color: Color = P.CREAM) -> Label:
	var label: Label = T.label(copy, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.max_lines_visible = 1
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = copy
	_place(card, label, bounds)
	return label


func _card_art(card: Control, path: String, known: bool, bounds: Rect2 = Rect2(0.09, 0.20, 0.82, 0.44)) -> void:
	var portrait: TextureRect = T.texture(path, Vector2.ZERO)
	portrait.name = "Portrait"
	if not known:
		portrait.modulate = Color(0.09, 0.09, 0.08, 1)
	_place(card, portrait, bounds)
	if not known:
		var lock: TextureRect = T.texture(ART + "locked.png", Vector2.ZERO)
		_place(card, lock, Rect2(0.40, 0.34, 0.20, 0.18))


func _rarity_ribbon(card: Control, rarity: String, known: bool, bounds: Rect2 = Rect2(0.13, 0.67, 0.74, 0.115)) -> void:
	var ribbon := PanelContainer.new()
	ribbon.name = "RarityRibbon"
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent: Color = P.rarity_color(rarity) if known else Color("6d6759")
	ribbon.add_theme_stylebox_override("panel", T.style(accent.darkened(0.48), 5, accent, 3))
	_place(card, ribbon, bounds)
	var label: Label = T.label(T.rarity_name(rarity).to_upper(), 19, P.CREAM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.max_lines_visible = 1
	ribbon.add_child(label)


func _hit(card: Control, callback: Callable, accessible_name: String) -> void:
	var button := Button.new()
	button.name = "OpenCard"
	button.tooltip_text = accessible_name
	button.accessibility_name = accessible_name
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	var focus: StyleBoxFlat = T.style(Color.TRANSPARENT, 10, P.GOLD, 0)
	focus.draw_center = false
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	_place(card, button, Rect2(0, 0, 1, 1))


func _species_card(species: Dictionary) -> Control:
	var id: String = str(species.get("id", ""))
	var rarity: String = _featured_rarity(id)
	var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(id, rarity)
	var known: bool = ReptileSystem.is_variant_discovered(str(variant.get("id", "")))
	var card: Control = _frame("Species_" + id)
	_copy(card, T.localized(str(species.get("name_key", ""))), Rect2(0.18, 0.063, 0.64, 0.108), 21).name = "CardName"
	var path: String = ReptileSystem.get_owned_animal_image_path({"reptile_id": id, "rarity": rarity, "variant_id": variant.get("id", "")})
	_card_art(card, path, known)
	_rarity_ribbon(card, rarity, known)
	var progress_copy: String = (T.text("Discovered", "Odkryto") + " · %d/4" % _discovered_count(id)) if known else T.text("Not discovered", "Nie odkryto")
	_copy(card, progress_copy, Rect2(0.18, 0.85, 0.64, 0.087), 19, P.LEAF_LIGHT if known else P.CREAM).name = "CardStatus"
	_hit(card, _show_species.bind(id), T.localized(str(species.get("name_key", ""))))
	return card


func _owned_card(instance: Dictionary, species: Dictionary) -> Control:
	var id: String = str(instance.get("instance_id", ""))
	var card: Control = _frame("Owned_" + id)
	var display_name: String = str(instance.get("custom_name", "")).strip_edges()
	if display_name.is_empty():
		display_name = T.localized(str(species.get("name_key", "")))
	_copy(card, display_name, Rect2(0.18, 0.063, 0.64, 0.108), 21).name = "CardName"
	_card_art(card, ReptileSystem.get_owned_animal_image_path(instance), true, Rect2(0.09, 0.20, 0.82, 0.365))
	_rarity_ribbon(card, str(instance.get("rarity", "common")), true, Rect2(0.13, 0.58, 0.74, 0.115))
	var sex_badge: PanelContainer = T.sex_badge(str(instance.get("sex", "")), true)
	sex_badge.name = "SexBadge"
	_place(card, sex_badge, Rect2(0.18, 0.71, 0.64, 0.13))
	_copy(card, T.text("Level %d", "Poziom %d") % ReptileSystem.get_reptile_level(instance), Rect2(0.18, 0.85, 0.64, 0.09), 20, P.GOLD).name = "CardLevel"
	_hit(card, func() -> void: details_requested.emit(id), display_name)
	return card


func _show_species(id: String) -> void:
	_close_modal()
	var species: Dictionary = ReptileSystem.get_reptile(id)
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 40
	get_tree().root.add_child(_modal_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.02, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 34 if side in ["left", "right"] else 72)
	_modal_layer.add_child(margin)
	var panel: PanelContainer = T.card()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.theme = T.make_theme()
	panel.add_theme_stylebox_override("panel", T.Controls.parchment())
	margin.add_child(panel)
	var outer: VBoxContainer = T.column(15)
	panel.add_child(outer)
	outer.add_child(T.label(T.localized(str(species.get("name_key", ""))), 34, P.INK))
	outer.add_child(T.label(T.localized("biome." + str(species.get("biome_id", "")) + ".name") + " · " + T.localized(ReptileSystem.get_habitat_type_label_key(str(species.get("preferred_habitat_type", "grass")))), 24, P.INK))
	var scroll := preload("res://scripts/modern/TouchScrollContainer.gd").new()
	scroll.custom_minimum_size.y = 570
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var entries := GridContainer.new()
	entries.columns = 2
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("h_separation", 10)
	entries.add_theme_constant_override("v_separation", 10)
	scroll.add_child(entries)
	for rarity in RARITIES:
		var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(id, rarity)
		var known: bool = ReptileSystem.is_variant_discovered(str(variant.get("id", "")))
		var card: Control = _frame("Variant_" + rarity)
		entries.add_child(card)
		_copy(card, T.rarity_name(rarity), Rect2(0.18, 0.063, 0.64, 0.108), 22, P.rarity_color(rarity)).name = "CardName"
		_card_art(card, ReptileSystem.get_owned_animal_image_path({"reptile_id": id, "rarity": rarity, "variant_id": variant.get("id", "")}), known)
		_copy(card, T.text("Discovered", "Odkryto") if known else T.text("Not discovered", "Nie odkryto"), Rect2(0.18, 0.85, 0.64, 0.087), 21, P.LEAF_LIGHT if known else P.CREAM).name = "CardStatus"
	outer.add_child(T.label(T.text("Discover new variants through breeding, incubation and expeditions.", "Odkrywaj odmiany przez rozmnażanie, inkubację i wyprawy."), 24, P.INK))
	outer.add_child(_button(T.text("TO THE NURSERY", "DO WYLĘGARNI"), func() -> void: _close_modal(); nursery_requested.emit(), true, 27))
	outer.add_child(_button(T.text("Close", "Zamknij"), _close_modal, false, 27))


func _close_modal() -> void:
	if is_instance_valid(_modal_layer):
		_modal_layer.queue_free()
	_modal_layer = null


func dismiss_overlay() -> bool:
	if not is_instance_valid(_modal_layer):
		return false
	_close_modal()
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and dismiss_overlay():
		get_viewport().set_input_as_handled()
