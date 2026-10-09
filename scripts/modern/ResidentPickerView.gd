extends Control
## Full-screen resident/home cards. Moves require a source-aware confirmation;
## the system validates and saves the assignment as one transaction.

signal closed
signal assignment_completed(instance_id: String, biome_id: String, result: Dictionary)
signal toast_requested(message: String)
signal shop_requested
signal home_requested(biome_id: String)

const T := preload("res://scripts/modern/SanctuaryTheme.gd")
const P := preload("res://scripts/modern/PrototypeUiKit.gd")
const TouchScroll := preload("res://scripts/modern/TouchScrollContainer.gd")
const CARD_ART := "res://assets/art/modern/species_card_frame_v2.png"

var target_habitat_id := ""
var instance_id := ""
var biome_id := "green_meadow"
var safe_insets := Vector4.ZERO
var _grid: GridContainer
var _summary: Label
var _notice: Label
var _query := ""
var _confirm_layer: Control
var _pending_move: Dictionary = {}
var _busy := false
var _biomes: Array = []


func _ready() -> void:
	name = "ResidentPicker"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = T.make_theme()
	var definitions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/biomes.json"))
	if definitions is Array: _biomes = definitions
	_build()
	_render_cards()


func _id(value: Variant) -> String:
	return "" if value == null else str(value)


func _animal_name(animal: Dictionary) -> String:
	var custom: String = str(animal.get("custom_name", "")).strip_edges()
	if not custom.is_empty(): return custom
	return T.localized(str(ReptileSystem.get_reptile(str(animal.get("reptile_id", ""))).get("name_key", "")))


func _habitat_name(habitat: Dictionary) -> String:
	return T.localized(ReptileSystem.get_habitat_type_label_key(str(habitat.get("habitat_type", "grass")))) + " #%d" % int(habitat.get("slot_index", 1))


func _habitat_art(habitat: Dictionary) -> String:
	return "res://assets/art/modern/terrarium_%s_%d.png" % [ReptileSystem.normalize_habitat_type(str(habitat.get("habitat_type", "grass"))), ReptileSystem.normalize_habitat_level(habitat.get("habitat_level", 1))]


func _place(parent: Control, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.anchor_left = rect.position.x
	child.anchor_top = rect.position.y
	child.anchor_right = rect.end.x
	child.anchor_bottom = rect.end.y
	child.offset_left = 0
	child.offset_top = 0
	child.offset_right = 0
	child.offset_bottom = 0


func _copy(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 25, color: Color = P.CREAM, lines: int = 1) -> Label:
	var label: Label = T.label(copy, font_size, color)
	label.name = node_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if lines > 1 else TextServer.AUTOWRAP_OFF
	label.max_lines_visible = lines
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = copy
	_place(parent, label, rect)
	return label


func _paper() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", T.Controls.parchment())
	return panel


func _paper_label(copy: String, font_size: int = 24) -> Label:
	var label: Label = T.label(copy, font_size, P.INK)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	return label


func _build() -> void:
	var background: TextureRect = T.texture("res://assets/art/modern/sanctuary_background.png", Vector2.ZERO)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_place(self, background, Rect2(0, 0, 1, 1))
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.03, 0.015, 0.64)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(self, shade, Rect2(0, 0, 1, 1))
	var margin := MarginContainer.new()
	_place(self, margin, Rect2(0, 0, 1, 1))
	for pair in [["left", safe_insets.x + 24], ["right", safe_insets.z + 24], ["top", safe_insets.y + 18], ["bottom", safe_insets.w + 18]]:
		margin.add_theme_constant_override("margin_" + str(pair[0]), int(pair[1]))
	var outer: VBoxContainer = T.column(12)
	margin.add_child(outer)
	var heading: HBoxContainer = T.row(12)
	outer.add_child(heading)
	var title: Label = T.label(T.text("CHOOSE A RESIDENT", "WYBIERZ MIESZKAŃCA") if instance_id.is_empty() else T.text("CHOOSE A TERRARIUM", "WYBIERZ TERRARIUM"), 36, P.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close: Button = T.button("×", func() -> void: closed.emit(), "secondary")
	close.name = "ClosePicker"
	close.custom_minimum_size = Vector2(68, 64)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.tooltip_text = T.text("Close", "Zamknij")
	heading.add_child(close)
	var intro: PanelContainer = _paper()
	intro.name = "TargetPreview"
	outer.add_child(intro)
	var row: HBoxContainer = T.row(18)
	intro.add_child(row)
	var animal: Dictionary = ReptileSystem.get_owned_reptile_instances().get(instance_id, {})
	var target: Dictionary = ReptileSystem.get_habitat_state(target_habitat_id)
	var preview: TextureRect = T.texture(_habitat_art(target) if instance_id.is_empty() else ReptileSystem.get_owned_animal_image_path(animal), Vector2(148, 144))
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(preview)
	var copy: VBoxContainer = T.column(5)
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(copy)
	copy.add_child(_paper_label(_habitat_name(target) if instance_id.is_empty() else _animal_name(animal), 31))
	copy.add_child(_paper_label(T.localized("biome." + biome_id + ".name"), 24))
	copy.add_child(_paper_label(T.text("Choose a reptile below. Moving an existing resident asks for confirmation.", "Wybierz gada poniżej. Przeniesienie obecnego mieszkańca wymaga potwierdzenia.") if instance_id.is_empty() else T.text("Choose a home below. Occupied and unfinished terrariums remain visible.", "Wybierz dom poniżej. Zajęte i nieukończone terraria pozostają widoczne."), 22))
	var search := LineEdit.new()
	search.name = "ResidentSearch"
	search.custom_minimum_size.y = 58
	search.placeholder_text = T.text("Search name or species…", "Szukaj imienia lub gatunku…") if instance_id.is_empty() else T.text("Search terrarium…", "Szukaj terrarium…")
	search.add_theme_font_size_override("font_size", 25)
	search.text_changed.connect(func(value: String) -> void: _query = value; _render_cards())
	outer.add_child(search)
	_summary = T.label("", 23, P.CREAM)
	outer.add_child(_summary)
	_notice = T.label("", 24, T.GOLD)
	_notice.name = "PickerNotice"
	_notice.visible = false
	outer.add_child(_notice)
	var scroll: ScrollContainer = TouchScroll.new()
	scroll.name = "ResidentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var content: VBoxContainer = T.column(12)
	scroll.add_child(content)
	_grid = GridContainer.new()
	_grid.name = "ResidentGrid"
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 18)
	content.add_child(_grid)
	var footer: Button = T.button(T.text("Find more reptiles in the shop", "Znajdź więcej gadów w sklepie") if instance_id.is_empty() else T.text("Build a new terrarium", "Zbuduj nowe terrarium"), func() -> void:
		if instance_id.is_empty(): shop_requested.emit()
		else: home_requested.emit(biome_id), "secondary")
	content.add_child(footer)
	var clearance := Control.new()
	clearance.custom_minimum_size.y = 28
	clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(clearance)


func _status(animal: Dictionary) -> String:
	var home_id: String = _id(animal.get("habitat_id"))
	if not home_id.is_empty():
		var home: Dictionary = ReptileSystem.get_habitat_state(home_id)
		if home.is_empty(): return T.text("Assigned home unavailable", "Przypisany dom niedostępny")
		return T.text("In terrarium: ", "W terrarium: ") + _habitat_name(home)
	if str(animal.get("breeding_state", "none")) == "breeding":
		return T.text("In the breeding chamber", "W komorze rozrodu")
	return T.text("Waiting for a home", "Czeka na swój dom")


func _disabled_reason(animal: Dictionary, habitat_id: String) -> String:
	if animal.is_empty(): return T.text("Reptile unavailable", "Zwierzę niedostępne")
	if _id(animal.get("habitat_id")) == habitat_id and not habitat_id.is_empty():
		return T.text("Already lives here", "Już tutaj mieszka")
	if str(animal.get("breeding_state", "none")) == "breeding":
		return T.text("Breeding in progress", "Trwa rozmnażanie")
	var target: Dictionary = ReptileSystem.get_habitat_state(habitat_id)
	if target.is_empty() or not bool(target.get("purchased", false)):
		return T.text("Terrarium unavailable", "Terrarium niedostępne")
	var target_biome: String = str(target.get("biome_id", ""))
	if target_biome not in GameState.get_value("unlocked_biomes", []):
		for definition: Dictionary in _biomes:
			if str(definition.get("id", "")) == target_biome:
				var level: int = int(definition.get("unlock_requirements", {}).get("level", 1))
				if int(GameState.get_value("level", 1)) < level:
					return T.text("Region unlocks at level %d", "Region od poziomu %d") % level
	if target_biome != biome_id or not ReptileSystem.is_reptile_available_in_biome(str(animal.get("reptile_id", "")), target_biome):
		return T.text("Needs a different region", "Wymaga innego regionu")
	if bool(target.get("is_building", false)): return T.text("Under construction", "W trakcie budowy")
	if bool(target.get("is_upgrading", false)): return T.text("Upgrade in progress", "W trakcie ulepszania")
	if not ReptileSystem.get_reptile_for_habitat(habitat_id).is_empty():
		return T.text("Terrarium occupied", "Terrarium zajęte")
	return ""


func _frame(parent: Control) -> Control:
	var surface := Control.new()
	surface.name = "CardSurface"
	surface.custom_minimum_size.y = 410
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(surface)
	var image: TextureRect = T.texture(CARD_ART, Vector2.ZERO)
	image.name = "CardFrame"
	_place(surface, image, Rect2(0, 0, 1, 1))
	var aspect: float = float(image.texture.get_height()) / float(image.texture.get_width())
	surface.resized.connect(func() -> void: surface.custom_minimum_size.y = ceilf(surface.size.x * aspect))
	return surface


func _rarity(surface: Control, rarity: String) -> void:
	var ribbon := PanelContainer.new()
	ribbon.name = "RarityRibbon"
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent: Color = P.rarity_color(rarity)
	ribbon.add_theme_stylebox_override("panel", T.style(accent.darkened(0.5), 6, accent, 3))
	_place(surface, ribbon, Rect2(0.16, 0.52, 0.68, 0.084))
	var text: Label = T.label(T.rarity_name(rarity).to_upper(), 22, P.CREAM)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ribbon.add_child(text)


func _animal_card(animal: Dictionary) -> Control:
	var id: String = str(animal.get("instance_id", ""))
	var card: VBoxContainer = T.column(7)
	card.name = "Resident_" + id
	card.set_meta("instance_id", id)
	var surface: Control = _frame(card)
	_copy(surface, "CardName", _animal_name(animal), Rect2(0.17, 0.06, 0.66, 0.105), 27)
	_place(surface, T.texture(ReptileSystem.get_owned_animal_image_path(animal), Vector2.ZERO), Rect2(0.105, 0.185, 0.79, 0.315))
	_rarity(surface, str(animal.get("rarity", "common")))
	var sex: PanelContainer = T.sex_badge(str(animal.get("sex", "")), true)
	_place(surface, sex, Rect2(0.20, 0.625, 0.60, 0.10))
	_copy(surface, "Level", T.text("Level %d", "Poziom %d") % ReptileSystem.get_reptile_level(animal), Rect2(0.17, 0.735, 0.66, 0.06), 24, P.GOLD)
	_copy(surface, "HomeStatus", _status(animal), Rect2(0.14, 0.81, 0.72, 0.12), 23, P.CREAM, 2)
	var reason: String = _disabled_reason(animal, target_habitat_id)
	var source: String = _id(animal.get("habitat_id"))
	var action: Button = T.button(T.text("Move here", "Przenieś tutaj") if not source.is_empty() else T.text("Choose resident", "Wybierz mieszkańca"), _select.bind(id, target_habitat_id))
	action.name = "SelectResident"
	action.disabled = not reason.is_empty()
	action.custom_minimum_size.y = 62
	card.add_child(action)
	var reason_label: Label = T.label(reason, 22, T.GOLD)
	reason_label.name = "DisabledReason"
	reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_label.custom_minimum_size.y = 32
	card.add_child(reason_label)
	card.set_meta("disabled_reason", reason)
	return card


func _habitat_card(habitat: Dictionary, animal: Dictionary) -> Control:
	var id: String = str(habitat.get("habitat_id", ""))
	var card: VBoxContainer = T.column(7)
	card.name = "Home_" + id
	card.set_meta("habitat_id", id)
	var surface: Control = _frame(card)
	_copy(surface, "CardName", _habitat_name(habitat), Rect2(0.17, 0.06, 0.66, 0.105), 27)
	_place(surface, T.texture(_habitat_art(habitat), Vector2.ZERO), Rect2(0.10, 0.19, 0.80, 0.42))
	_copy(surface, "Level", T.text("Terrarium level %d", "Poziom terrarium: %d") % int(habitat.get("habitat_level", 1)), Rect2(0.15, 0.645, 0.70, 0.065), 25, P.GOLD)
	var resident: Dictionary = ReptileSystem.get_reptile_for_habitat(id)
	var status: String = T.text("Ready for a resident", "Gotowe na mieszkańca") if resident.is_empty() else T.text("Resident: ", "Mieszkaniec: ") + _animal_name(resident)
	var reason: String = _disabled_reason(animal, id)
	_copy(surface, "HomeStatus", status, Rect2(0.17, 0.85, 0.66, 0.08), 22)
	var action: Button = T.button(T.text("Choose this home", "Wybierz ten dom"), _select.bind(instance_id, id))
	action.name = "SelectHome"
	action.disabled = not reason.is_empty()
	action.custom_minimum_size.y = 62
	card.add_child(action)
	var reason_label: Label = T.label(reason, 22, T.GOLD)
	reason_label.name = "DisabledReason"
	reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_label.custom_minimum_size.y = 32
	card.add_child(reason_label)
	card.set_meta("disabled_reason", reason)
	return card


func _render_cards() -> void:
	if not is_instance_valid(_grid): return
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var count := 0
	var available := 0
	var animals: Dictionary = ReptileSystem.get_owned_reptile_instances()
	if instance_id.is_empty():
		var candidates: Array = animals.values()
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_ready: bool = _disabled_reason(a, target_habitat_id).is_empty()
			var b_ready: bool = _disabled_reason(b, target_habitat_id).is_empty()
			if a_ready != b_ready: return a_ready
			return _animal_name(a).naturalnocasecmp_to(_animal_name(b)) < 0)
		for animal: Dictionary in candidates:
			var species: Dictionary = ReptileSystem.get_reptile(str(animal.get("reptile_id", "")))
			var searchable: String = _animal_name(animal) + " " + T.localized(str(species.get("name_key", "")))
			if not _query.strip_edges().is_empty() and _query.strip_edges().to_lower() not in searchable.to_lower(): continue
			_grid.add_child(_animal_card(animal))
			count += 1
			if _disabled_reason(animal, target_habitat_id).is_empty(): available += 1
	else:
		var homes: Array = GameState.get_value("habitats", {}).values()
		homes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("slot_index", 0)) < int(b.get("slot_index", 0)))
		for habitat: Dictionary in homes:
			if str(habitat.get("biome_id", "")) != biome_id or not bool(habitat.get("purchased", false)): continue
			if not _query.strip_edges().is_empty() and _query.strip_edges().to_lower() not in _habitat_name(habitat).to_lower(): continue
			_grid.add_child(_habitat_card(habitat, animals.get(instance_id, {})))
			count += 1
			if _disabled_reason(animals.get(instance_id, {}), str(habitat.get("habitat_id", ""))).is_empty(): available += 1
	_summary.text = T.text("Choices: %d · Available now: %d", "Do wyboru: %d · Dostępne teraz: %d") % [count, available]
	if count == 1:
		var empty := Control.new()
		empty.name = "EmptyPickerSlot"
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grid.add_child(empty)


func _show_notice(copy: String) -> void:
	_notice.text = copy
	_notice.visible = not copy.is_empty()
	toast_requested.emit(copy)


func _select(animal_id: String, habitat_id: String) -> void:
	if _busy or is_instance_valid(_confirm_layer): return
	var animal: Dictionary = ReptileSystem.get_owned_reptile_instances().get(animal_id, {})
	var reason: String = _disabled_reason(animal, habitat_id)
	if not reason.is_empty():
		_show_notice(reason)
		_render_cards()
		return
	var source: String = _id(animal.get("habitat_id"))
	if source.is_empty():
		_commit(animal_id, habitat_id, "")
	else:
		_show_move_confirmation(animal, source, habitat_id)


func _show_move_confirmation(animal: Dictionary, source: String, destination: String) -> void:
	_pending_move = {"instance_id": str(animal.get("instance_id", "")), "source": source, "destination": destination}
	_confirm_layer = Control.new()
	_confirm_layer.name = "MoveConfirmation"
	_place(self, _confirm_layer, Rect2(0, 0, 1, 1))
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.015, 0.94)
	_place(_confirm_layer, shade, Rect2(0, 0, 1, 1))
	var margin := MarginContainer.new()
	_place(_confirm_layer, margin, Rect2(0, 0, 1, 1))
	for edge in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 42)
	margin.add_theme_constant_override("margin_top", int(safe_insets.y + 36))
	margin.add_theme_constant_override("margin_bottom", int(safe_insets.w + 36))
	var panel: PanelContainer = _paper()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(panel)
	var layout: VBoxContainer = T.column(16)
	panel.add_child(layout)
	var heading: Label = _paper_label(T.text("MOVE THIS RESIDENT?", "PRZENIEŚĆ MIESZKAŃCA?"), 33)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(heading)
	layout.add_child(T.texture(ReptileSystem.get_owned_animal_image_path(animal), Vector2(0, 170)))
	var name_label: Label = _paper_label(_animal_name(animal), 29)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(name_label)
	layout.add_child(_paper_label(T.text("From: ", "Z: ") + _habitat_name(ReptileSystem.get_habitat_state(source)), 27))
	layout.add_child(_paper_label(T.text("To: ", "Do: ") + _habitat_name(ReptileSystem.get_habitat_state(destination)), 27))
	layout.add_child(_paper_label(T.text("The previous terrarium will become empty. The reptile keeps its level and progress.", "Poprzednie terrarium zostanie puste. Zwierzę zachowa poziom i postęp."), 24))
	var confirm: Button = T.button(T.text("Confirm move", "Potwierdź przeniesienie"), _confirm_move)
	confirm.name = "ConfirmMove"
	layout.add_child(confirm)
	var cancel: Button = T.button(T.text("Keep current home", "Zostaw w obecnym domu"), _cancel_move, "secondary")
	cancel.name = "CancelMove"
	layout.add_child(cancel)


func _cancel_move() -> void:
	if is_instance_valid(_confirm_layer):
		remove_child(_confirm_layer)
		_confirm_layer.queue_free()
	_confirm_layer = null
	_pending_move = {}


func _confirm_move() -> void:
	var pending: Dictionary = _pending_move.duplicate()
	_cancel_move()
	if pending.is_empty(): return
	_commit(str(pending["instance_id"]), str(pending["destination"]), str(pending["source"]))


func _commit(animal_id: String, habitat_id: String, confirmed_source: String) -> void:
	if _busy: return
	var animal: Dictionary = ReptileSystem.get_owned_reptile_instances().get(animal_id, {})
	if _id(animal.get("habitat_id")) != confirmed_source:
		_show_notice(T.text("This reptile's home changed. Please choose again.", "Dom tego zwierzęcia się zmienił. Wybierz ponownie."))
		_render_cards()
		return
	var reason: String = _disabled_reason(animal, habitat_id)
	if not reason.is_empty():
		_show_notice(reason)
		_render_cards()
		return
	_busy = true
	var result: Dictionary = ReptileSystem.assign_reptile_to_habitat(animal_id, habitat_id, biome_id) if confirmed_source.is_empty() else ReptileSystem.move_reptile_to_habitat(animal_id, habitat_id, biome_id)
	if bool(result.get("success", false)):
		assignment_completed.emit(animal_id, biome_id, result)
	else:
		_show_notice(T.localized(str(result.get("message_key", "ui.habitat_unavailable"))))
		_busy = false
		_render_cards()
