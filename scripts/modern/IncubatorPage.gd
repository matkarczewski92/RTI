extends VBoxContainer
## Nursery presentation. All ownership, timers and transactions stay in the game systems.

signal toast_requested(message: String)
signal refresh_requested
signal details_requested(instance_id: String)

const T = preload("res://scripts/modern/SanctuaryTheme.gd")
const RARITIES: Array[String] = ["common", "rare", "ultra_rare", "exceptional"]
const EGG_ART := "res://assets/prototype/art/ui/lab/egg_common_v2.png"
const LAB_ART := "res://assets/prototype/art/ui/lab/"
const PARENT_ART := "res://assets/prototype/habitats/tropical/background.png"
const INK := Color("432b12")
const INK_MUTED := Color("765323")
const HEARTS = preload("res://scripts/modern/BreedingHearts.gd")

var _tab: int = 0
var _body: VBoxContainer
var _heading: VBoxContainer
var _tabs: Array[Button] = []
var _incubator_grid: GridContainer
var _humidity_overview: Label
var _female_id := ""
var _male_id := ""
var _long_pairing := false
var _chamber_index := 0
var _shop_species := ""
var _timer_labels: Array[Dictionary] = []
var _price_buttons: Array[Dictionary] = []
var _cooldown_labels: Array[Dictionary] = []
var _state_signature := ""
var _refresh_queued := false
var _dialog_layer: CanvasLayer
var _dialog_column: VBoxContainer
var _selected_eggs: Array = []
var _egg_checks: Array[CheckBox] = []
var _load_button: Button
var _load_hint: Label
var _busy := false
var _config: Dictionary = {}


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/incubator.json"))
	if parsed is Dictionary:
		_config = parsed
	if IncubationSystem.has_method("ensure_starter_egg"):
		IncubationSystem.call("ensure_starter_egg")
	var heading_stage := PanelContainer.new()
	heading_stage.custom_minimum_size.y = 76
	heading_stage.add_theme_stylebox_override("panel", T.Controls.skin("wood"))
	add_child(heading_stage)
	_heading = T.column(0)
	_heading.alignment = BoxContainer.ALIGNMENT_CENTER
	heading_stage.add_child(_heading)
	_heading.add_child(_lab_label("", 34))
	var tabs := T.row(6)
	tabs.name = "NurseryTabs"
	add_child(tabs)
	for index in range(4):
		var tab: Button = _lab_button("", _select_tab.bind(index), "wood", 22)
		tab.custom_minimum_size.y = 64
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tab)
		_tabs.append(tab)
	_body = T.column(12)
	add_child(_body)
	resized.connect(_update_columns)
	var tick: Timer = Timer.new()
	tick.wait_time = 1.0
	tick.timeout.connect(_tick)
	add_child(tick)
	tick.start()
	_rebuild()


func _exit_tree() -> void:
	if is_instance_valid(_dialog_layer):
		_dialog_layer.queue_free()


func refresh() -> void:
	if _body == null or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_if_changed")


func _refresh_if_changed() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	if _signature() != _state_signature:
		_rebuild()
	_update_live_values()


func _signature() -> String:
	var chambers: Dictionary = BreedingSystem.get_chambers()
	var containers: Dictionary = IncubationSystem.get_containers()
	var parts: Array = [GameState.get_language(), _tab, GameState.get_value("upgrade_levels", {})]
	for key: Variant in chambers.keys():
		var chamber: Dictionary = chambers[key]
		parts.append([key, chamber.get("state", ""), chamber.get("ends_at", 0)])
	for key: Variant in containers.keys():
		var container: Dictionary = containers[key]
		parts.append([key, container.get("state", ""), container.get("egg_instance_ids", [])])
	parts.append(IncubationSystem.get_available_storage_eggs())
	parts.append(BreedingSystem.get_storage().get("reptiles", []))
	for instance: Variant in ReptileSystem.get_owned_reptile_instances().values():
		if instance is Dictionary:
			parts.append([instance.get("instance_id", ""), instance.get("custom_name", ""), instance.get("breeding_state", ""), instance.get("breeding_cooldown_until", 0)])
	return str(parts)


func _tick() -> void:
	if not is_visible_in_tree():
		return
	_refresh_if_changed()


func _select_tab(index: int) -> void:
	_tab = index
	_rebuild()


func _rebuild() -> void:
	for child: Node in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_timer_labels.clear()
	_price_buttons.clear()
	_cooldown_labels.clear()
	var tab_names: Array[String] = [T.text("Incubation", "Inkubacja"), T.text("Breeding", "Hodowla"), T.text("Egg shop", "Jaja"), T.text("Upgrades", "Ulepszenia")]
	var titles: Array[String] = [T.text("INCUBATOR HUB", "CENTRUM INKUBACJI"), T.text("BREEDING LAB", "LABORATORIUM HODOWLI"), T.text("EGG SHOP", "SKLEP Z JAJAMI"), T.text("LAB UPGRADES", "ULEPSZENIA LABORATORIUM")]
	(_heading.get_child(0) as Label).text = titles[_tab]
	for index in range(_tabs.size()):
		_tabs[index].text = tab_names[index]
		_tabs[index].modulate = Color.WHITE
		_tabs[index].toggle_mode = true
		_tabs[index].set_pressed_no_signal(index == _tab)
		T.Controls.apply(_tabs[index], "green" if index == _tab else "wood")
		_compact_button(_tabs[index])
	match _tab:
		0: _build_incubation()
		1: _build_breeding()
		2: _build_shop()
		3: _build_upgrades()
	_state_signature = _signature()
	_update_columns()
	_update_live_values()


func _place(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0


func _lab_label(copy: String, font_size: int = 24, color: Color = T.TEXT) -> Label:
	var label: Label = T.label(copy, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("180c04"))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_constant_override("shadow_offset_y", 0)
	var font_path := "res://assets/prototype/fonts/BarlowCondensed-Bold.ttf"
	if ResourceLoader.exists(font_path):
		label.add_theme_font_override("font", load(font_path))
	return label


func _ink_label(copy: String, font_size: int = 24, color: Color = INK) -> Label:
	var label: Label = _lab_label(copy, font_size, color)
	var font_path := "res://assets/prototype/fonts/BarlowCondensed-SemiBold.ttf"
	if ResourceLoader.exists(font_path): label.add_theme_font_override("font", load(font_path))
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _lab_button(copy: String, callback: Callable, kind: String = "green", font_size: int = 23) -> Button:
	var button: Button = T.button(copy, callback)
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size", font_size)
	T.Controls.apply(button, kind)
	_compact_button(button)
	var font_path := "res://assets/prototype/fonts/BarlowCondensed-Bold.ttf"
	if ResourceLoader.exists(font_path): button.add_theme_font_override("font", load(font_path))
	return button


func _compact_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := button.get_theme_stylebox(state).duplicate() as StyleBoxTexture
		skin.content_margin_left = 10
		skin.content_margin_right = 10
		skin.content_margin_top = 8
		skin.content_margin_bottom = 10
		button.add_theme_stylebox_override(state, skin)


func _parchment(parent: Node, separation: int = 8, _tall: bool = false) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", T.Controls.parchment())
	parent.add_child(panel)
	var column: VBoxContainer = T.column(separation)
	panel.add_child(column)
	return column


func _egg_art(rarity: String) -> String:
	return LAB_ART + "egg_" + (rarity if RARITIES.has(rarity) else "common") + "_v2.png"


func _update_columns() -> void:
	if is_instance_valid(_incubator_grid):
		_incubator_grid.columns = 2


func _card(parent: Node, heading: String = "", subtitle: String = "") -> VBoxContainer:
	var panel: PanelContainer = T.card()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var content: VBoxContainer = T.column(14)
	panel.add_child(content)
	if not heading.is_empty():
		content.add_child(T.label(heading, 28))
	if not subtitle.is_empty():
		content.add_child(T.label(subtitle, 21, T.MUTED))
	return content


func _species_name(species_id: String) -> String:
	var data: Dictionary = ReptileSystem.get_reptile(species_id)
	var key: String = str(data.get("name_key", ""))
	return LocalizationSystem.tr_key(key) if not key.is_empty() else species_id.capitalize()


func _instance_name(instance: Dictionary) -> String:
	var custom: String = str(instance.get("custom_name", ""))
	return custom if not custom.is_empty() else _species_name(str(instance.get("reptile_id", instance.get("species_id", ""))))


func _rarity_name(rarity: String) -> String:
	return LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(rarity))


func _quality_name(quality: String) -> String:
	match quality:
		"standard": return T.text("Standard", "Standardowe")
		"improved": return T.text("Improved", "Ulepszone")
		"rare": return T.text("Rare", "Rzadkie")
		"elite": return T.text("Elite", "Elitarne")
	return quality.capitalize()


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare": return T.BLUE
		"ultra_rare": return T.PURPLE
		"exceptional": return T.GOLD
	return T.ACCENT


func _instance_row(parent: Node, instance: Dictionary, portrait_size: float = 90) -> void:
	var row: HBoxContainer = T.row(16)
	parent.add_child(row)
	row.add_child(T.texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2(portrait_size, portrait_size)))
	var copy: VBoxContainer = T.column(5)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(T.label(_instance_name(instance), 25))
	var rarity: String = str(instance.get("rarity", "common"))
	copy.add_child(T.sex_badge(str(instance.get("sex", "female")), true))
	copy.add_child(T.label(_rarity_name(rarity), 22, _rarity_color(rarity)))
	copy.add_child(T.label(T.text("Level ", "Poziom ") + str(ReptileSystem.get_reptile_level(instance)), 19, T.MUTED))
	var condition: float = (float(instance.get("happiness", 100)) + float(instance.get("hunger", 100)) + float(instance.get("hydration", 100)) + float(instance.get("cleanliness", 100))) / 4.0
	copy.add_child(T.label(T.text("Condition · ", "Kondycja · ") + ("%.0f%%" % condition), 19, T.MUTED))


func _slot_indices(saved: Dictionary, base_count: int) -> Array[int]:
	var indices: Array[int] = []
	for index in range(base_count):
		indices.append(index)
	for key: Variant in saved.keys():
		var index: int = int(str(key))
		if index >= 0 and not indices.has(index):
			indices.append(index)
	indices.sort()
	return indices


func _build_incubation() -> void:
	var eggs: Array = IncubationSystem.get_available_storage_eggs()
	var containers: Dictionary = IncubationSystem.get_containers()
	var indices: Array[int] = _slot_indices(containers, int(_config.get("incubation_containers", 6)))
	var active := 0
	var ready := 0
	var humidity := 0.0
	for value: Variant in containers.values():
		var state: String = str(value.get("state", "empty"))
		if state in ["loaded", "running", "paused_low_humidity"]:
			active += 1
			humidity += float(value.get("humidity_percent", 100.0))
		elif state == "ready_to_hatch": ready += 1
	_body.add_child(_lab_label(T.text("%d CHAMBERS  /  %d ACTIVE  /  %d READY", "KOMORY: %d  /  AKTYWNE: %d  /  GOTOWE: %d") % [indices.size(), active, ready], 23, T.GOLD))
	_incubator_grid = GridContainer.new()
	_incubator_grid.columns = 2
	_incubator_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_incubator_grid.add_theme_constant_override("h_separation", 6)
	_incubator_grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(_incubator_grid)
	for index in indices:
		var container: Dictionary = containers.get(str(index), {})
		_build_container(index, container)
	var dashboard: VBoxContainer = _parchment(_body)
	dashboard.add_child(_ink_label(T.text("NURSERY OVERVIEW", "POD OPIEKĄ LABORATORIUM"), 28))
	var stats: HBoxContainer = T.row(16)
	dashboard.add_child(stats)
	for entry in [[T.text("EGG BASKET", "KOSZYK JAJ"), str(eggs.size())], [T.text("TRAY CAPACITY", "JAJ W KOMORZE"), str(IncubationSystem.get_max_eggs_per_container())], [T.text("HUMIDITY", "WILGOTNOŚĆ"), "%.0f%%" % (humidity / active) if active > 0 else "—"]]:
		var stat: VBoxContainer = T.column(2)
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(stat)
		stat.add_child(_ink_label(str(entry[0]), 20, INK_MUTED))
		var value: Label = _ink_label(str(entry[1]), 32, Color("315117"))
		stat.add_child(value)
		if entry[0] == T.text("HUMIDITY", "WILGOTNOŚĆ"):
			_humidity_overview = value
	dashboard.add_child(_ink_label(T.text("Humidity below 50% pauses incubation. Add water to continue; eggs stay safe.", "Wilgotność poniżej 50% wstrzymuje inkubację. Uzupełnij wodę, aby ją wznowić. Jaja pozostają bezpieczne."), 21, INK_MUTED))
	for egg_value: Variant in eggs:
		if str(egg_value.get("source", "")) == "starter":
			dashboard.add_child(_ink_label(T.text("WELCOME EGG: choose any empty chamber. Your first discovery takes 1 minute.", "POWITALNE JAJO: wybierz pustą komorę. Pierwsze odkrycie za 1 minutę."), 23, Color("37521c")))
			break


func _build_container(index: int, container: Dictionary) -> void:
	var state: String = str(container.get("state", "empty"))
	var card := T.column(4)
	card.name = "Incubator_" + str(index)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_incubator_grid.add_child(card)
	var panel := Control.new()
	panel.name = "ChamberArt"
	panel.custom_minimum_size.y = 410
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(panel)
	panel.resized.connect(func() -> void: panel.custom_minimum_size.y = panel.size.x * 1402.0 / 1122.0)
	var chamber: TextureRect = T.texture("res://assets/art/modern/incubator_chamber_v2.png", Vector2.ZERO)
	chamber.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place(chamber, 0, 0, 1, 1)
	panel.add_child(chamber)
	var accent: Color = T.BLUE if state == "running" else T.GOLD if state == "paused_low_humidity" else T.DANGER if state == "failed_dry" else T.ACCENT if state == "ready_to_hatch" else T.MUTED
	var state_name: String
	match state:
		"loaded": state_name = T.text("LOADED", "JAJA GOTOWE")
		"running": state_name = T.text("RUNNING", "INKUBACJA")
		"paused_low_humidity": state_name = T.text("LOW HUMIDITY", "BRAK WODY")
		"ready_to_hatch": state_name = T.text("READY TO HATCH", "GOTOWE")
		"failed_dry": state_name = T.text("OLD DRY BATCH", "WYSCHNIĘTE")
		_: state_name = T.text("EMPTY", "PUSTA")
	var banner: Label = _lab_label(str(index + 1) + ". " + state_name, 24, accent)
	_place(banner, 0.08, 0.025, 0.92, 0.105)
	panel.add_child(banner)
	if state != "empty":
		var rarity := "common"
		var ids: Array = container.get("egg_instance_ids", [])
		for value: Variant in BreedingSystem.get_storage().get("eggs", []):
			if ids.has(str(value.get("egg_id", ""))):
				rarity = str(value.get("rarity", "common"))
				break
		var egg: TextureRect = T.texture(_egg_art(rarity), Vector2.ZERO)
		_place(egg, 0.19, 0.27, 0.81, 0.60)
		panel.add_child(egg)
		if state == "failed_dry": egg.modulate = Color("8e897f")
	else:
		var empty: Label = _lab_label(T.text("NO EGGS\nLOADED", "BRAK JAJ"), 25, T.MUTED)
		_place(empty, 0.14, 0.31, 0.86, 0.56)
		panel.add_child(empty)
	var status: Label = _lab_label("", 22)
	status.name = "ChamberStatus"
	_place(status, 0.08, 0.64, 0.92, 0.72)
	panel.add_child(status)
	var humidity: Label = _lab_label("", 20, T.BLUE)
	humidity.name = "ChamberHumidity"
	_place(humidity, 0.07, 0.725, 0.93, 0.785)
	panel.add_child(humidity)
	var progress: ProgressBar = T.progress(0, accent)
	progress.name = "ChamberProgress"
	progress.custom_minimum_size.y = 7
	_place(progress, 0.12, 0.795, 0.88, 0.81)
	panel.add_child(progress)
	progress.visible = state != "empty"
	_timer_labels.append({"type": "incubation", "index": index, "label": status, "progress": progress, "humidity": humidity, "compact": true})
	var actions: VBoxContainer = T.column(4)
	card.add_child(actions)
	match state:
		"empty":
			actions.add_child(_lab_button(T.text("CHOOSE EGGS", "WYBIERZ JAJA"), _show_egg_selector.bind(index)))
		"loaded":
			actions.add_child(_lab_button(T.text("START", "ROZPOCZNIJ"), _start_loaded.bind(index)))
		"running", "paused_low_humidity":
			var water_button: Button = _lab_button(T.text("WATER", "DOLEJ WODY"), _water.bind(index), "blue")
			water_button.custom_minimum_size.y = 54
			actions.add_child(water_button)
			_timer_labels[-1]["water_button"] = water_button
			if state == "running" and SpeedUpService.should_show_button(IncubationSystem.get_remaining_seconds(container)):
				var speed: Button = _lab_button(T.text("AD: SPEED UP", "REKLAMA: SZYBCIEJ"), _speedup.bind("egg_incubation", index), "blue", 20)
				speed.custom_minimum_size.y = 54
				actions.add_child(speed)
		"ready_to_hatch":
			actions.add_child(_lab_button(T.text("HATCH", "WYKLUJ"), _hatch.bind(index)))
		"failed_dry":
			actions.add_child(_lab_button(T.text("CLEAR", "OPRÓŻNIJ"), _clear_failed.bind(index), "red"))
	# The main action occupies the painted lower plaque. Optional actions flow
	# below the card, so running trays never squash their artwork to fit buttons.
	if actions.get_child_count() > 0:
		var primary := actions.get_child(0) as Button
		actions.remove_child(primary)
		panel.add_child(primary)
		primary.name = "ChamberAction"
		_place(primary, 0.08, 0.825, 0.92, 0.955)
	if state != "empty":
		actions.add_child(_lab_button(T.text("DETAILS", "SZCZEGÓŁY"), _show_container_details.bind(index), "wood", 22))


func _show_container_details(index: int) -> void:
	var container: Dictionary = IncubationSystem.get_container(index)
	var content: VBoxContainer = _open_dialog(T.text("Chamber ", "Komora ") + str(index + 1), _species_name(str(container.get("species_id", ""))))
	content.add_child(T.texture(_egg_art("common"), Vector2(0, 240)))
	content.add_child(T.label(str(container.get("egg_count", 0)) + T.text(" eggs of this species", " jaj tego gatunku"), 28))
	content.add_child(T.label(T.text("Time remaining: ", "Pozostały czas: ") + T.time(IncubationSystem.get_remaining_seconds(container)), 24))
	content.add_child(T.label(T.text("Humidity: ", "Wilgotność: ") + "%.0f%%" % float(container.get("humidity_percent", 100)), 24, T.BLUE))
	if str(container.get("state", "")) == "loaded":
		content.add_child(T.button(T.text("Return eggs to basket", "Odłóż jaja do koszyka"), func() -> void:
			_cancel_loaded(index)
			_close_dialog(), "secondary"))


func _build_breeding() -> void:
	var owned: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var female: Dictionary = owned.get(_female_id, {})
	var male: Dictionary = owned.get(_male_id, {})
	if not female.is_empty() and not BreedingSystem.is_instance_available_for_breeding(female):
		_female_id = ""
		female = {}
	if not male.is_empty() and not BreedingSystem.is_instance_available_for_breeding(male):
		_male_id = ""
		male = {}
	var parents: HBoxContainer = T.row(4)
	_body.add_child(parents)
	_parent_card(parents, female, "female")
	var heart := CenterContainer.new()
	heart.custom_minimum_size.x = 54
	heart.add_child(T.texture("res://assets/prototype/art/icons/actions/care.png", Vector2(54, 68)))
	parents.add_child(heart)
	_parent_card(parents, male, "male")
	var editor: VBoxContainer = _parchment(_body, 10, true)
	editor.add_child(_ink_label(T.text("POTENTIAL OFFSPRING", "MOŻLIWE POTOMSTWO"), 30))
	var paired: bool = not female.is_empty() and not male.is_empty()
	var prediction: Dictionary = BreedingSystem.get_predicted_breeding_odds(female, male, _long_pairing) if paired else {}
	var rates: Dictionary = prediction.get("rates", {})
	var offspring: HBoxContainer = T.row(6)
	editor.add_child(offspring)
	for rarity in RARITIES:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", T.style(Color(_rarity_color(rarity), 0.17), 7, Color("996d28"), 4))
		offspring.add_child(panel)
		var column: VBoxContainer = T.column(2)
		panel.add_child(column)
		var name_label: Label = _ink_label(_rarity_name(rarity).to_upper(), 19)
		name_label.custom_minimum_size.y = 44
		column.add_child(name_label)
		column.add_child(T.texture(_egg_art(rarity), Vector2(0, 92)))
		column.add_child(_ink_label("%.0f%%" % float(rates.get(rarity, 0)) if paired else "—", 29))
	var success: HBoxContainer = T.row(12)
	editor.add_child(success)
	for entry in [[T.text("SUCCESS CHANCE", "SZANSA POWODZENIA"), "%.0f%%" % float(prediction.get("success_chance", 0)) if paired else "—"], [T.text("EGGS ON SUCCESS", "JAJ PRZY POWODZENIU"), "1–5"]]:
		var column: VBoxContainer = T.column(0)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		success.add_child(column)
		column.add_child(_ink_label(str(entry[0]), 21))
		column.add_child(_ink_label(str(entry[1]), 38, Color("36521b")))
	editor.add_child(_ink_label(T.text("BREEDING DURATION", "CZAS HODOWLI"), 23))
	var modes: HBoxContainer = T.row(10)
	editor.add_child(modes)
	var quick: Button = _lab_button(T.time(BreedingSystem.get_fast_duration_seconds()) + "\n" + T.text("Standard", "Standard"), _set_mode.bind(false), "green" if not _long_pairing else "wood", 25)
	quick.custom_minimum_size.y = 72
	quick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quick.toggle_mode = true
	quick.set_pressed_no_signal(not _long_pairing)
	modes.add_child(quick)
	var patient: Button = _lab_button(T.time(BreedingSystem.get_long_duration_seconds()) + "\n" + T.text("Better rarity", "Lepsza rzadkość"), _set_mode.bind(true), "green" if _long_pairing else "wood", 25)
	patient.custom_minimum_size.y = 72
	patient.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	patient.toggle_mode = true
	patient.set_pressed_no_signal(_long_pairing)
	modes.add_child(patient)
	var chambers: Dictionary = BreedingSystem.get_chambers()
	var empty_indices: Array[int] = []
	for index in _slot_indices(chambers, int(_config.get("breeding_chambers", 4))):
		if str((chambers.get(str(index), {}) as Dictionary).get("state", "empty")) == "empty":
			empty_indices.append(index)
	if not empty_indices.has(_chamber_index) and not empty_indices.is_empty():
		_chamber_index = empty_indices[0]
	if not empty_indices.is_empty():
		var selection: OptionButton = _option()
		for index in empty_indices:
			selection.add_item(T.text("Breeding room ", "Komora hodowlana ") + str(index + 1), index)
			if index == _chamber_index:
				selection.select(selection.item_count - 1)
		selection.item_selected.connect(func(item: int) -> void: _chamber_index = selection.get_item_id(item))
		editor.add_child(selection)
	var start: Button = _lab_button(T.text("BREED", "ROZPOCZNIJ HODOWLĘ"), _start_breeding, "gold", 31)
	start.custom_minimum_size.y = 70
	start.disabled = not paired or empty_indices.is_empty()
	editor.add_child(start)
	if empty_indices.is_empty():
		editor.add_child(_ink_label(T.text("All breeding rooms are occupied.", "Wszystkie komory hodowlane są zajęte."), 21, INK_MUTED))
	if BreedingSystem.get_available_breeding_reptiles().is_empty():
		editor.add_child(_ink_label(T.text("Choose a female and male of the same species. Buy adults in the shop or hatch them here.", "Wybierz samicę i samca jednego gatunku. Kup rodziców w sklepie lub wykluj tutaj."), 21, INK_MUTED))
	elif paired:
		editor.add_child(_ink_label(T.text("Parents leave their habitats and rest after breeding for ", "Rodzice opuszczą siedliska. Po hodowli odpoczną przez ") + T.time(BreedingSystem.get_cooldown_seconds()) + ".", 20, INK_MUTED))
	for index in _slot_indices(chambers, int(_config.get("breeding_chambers", 4))):
		var chamber: Dictionary = chambers.get(str(index), {})
		var state: String = str(chamber.get("state", "empty"))
		if state == "empty":
			continue
		var content: VBoxContainer = _parchment(_body, 12)
		content.get_parent().name = "BreedingRoom_" + str(index)
		content.add_child(_ink_label(T.text("Breeding room ", "Komora hodowlana ") + str(index + 1), 30))
		var couple := T.row(8)
		content.add_child(couple)
		for parent_index in range(2):
			if parent_index == 1:
				var hearts := HEARTS.new()
				couple.add_child(hearts)
				hearts.set_process(state == "breeding")
			var parent_id := str(chamber.get("instance_id_a" if parent_index == 0 else "instance_id_b", ""))
			var parent_instance: Dictionary = owned.get(parent_id, {})
			if parent_instance.is_empty():
				parent_instance = {"reptile_id": chamber.get("reptile_id", ""), "rarity": chamber.get("rarity_a" if parent_index == 0 else "rarity_b", "common"), "sex": "female" if parent_index == 0 else "male"}
			var parent_column := T.column(4)
			parent_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			couple.add_child(parent_column)
			var portrait := T.texture(ReptileSystem.get_owned_animal_image_path(parent_instance), Vector2(0, 138))
			portrait.name = "ParentPortrait"
			parent_column.add_child(portrait)
			parent_column.add_child(_ink_label(_instance_name(parent_instance), 23))
			parent_column.add_child(T.sex_badge(str(parent_instance.get("sex", "female")), true))
		var time_label: Label = _ink_label("", 27, Color("36521b"))
		content.add_child(time_label)
		var progress: ProgressBar = T.progress(0, T.PURPLE)
		content.add_child(progress)
		_timer_labels.append({"type": "breeding", "index": index, "label": time_label, "progress": progress})
		if state == "ready" or state == "failed":
			content.add_child(T.button(T.text("Collect results", "Odbierz wynik"), _collect_breeding.bind(index)))
		elif SpeedUpService.should_show_button(BreedingSystem.get_breeding_remaining_seconds(chamber)):
			content.add_child(T.button(T.text("Speed up · watch an ad", "Przyspiesz · obejrzyj reklamę"), _speedup.bind("incubator_pairing", index), "secondary"))
	var resting: Array = BreedingSystem.get_storage().get("reptiles", [])
	if not resting.is_empty():
		var rest: VBoxContainer = _card(_body, T.text("Resting parents", "Odpoczywający rodzice"), T.text("Return parents to your collection, then assign them to a habitat.", "Przenieś rodziców do kolekcji, a następnie przydziel im siedlisko."))
		for entry: Variant in resting:
			if not entry is Dictionary:
				continue
			var instance_id: String = str(entry.get("instance_id", ""))
			var instance: Dictionary = owned.get(instance_id, entry)
			_instance_row(rest, instance)
			var cooldown: Label = T.label("", 20, T.MUTED)
			rest.add_child(cooldown)
			_cooldown_labels.append({"label": cooldown, "instance_id": instance_id})
			rest.add_child(T.button(T.text("Return to collection", "Przenieś do kolekcji"), _return_parent.bind(instance_id), "secondary"))


func _parent_card(parent: Node, instance: Dictionary, sex: String) -> void:
	var panel := Control.new()
	panel.name = "Parent_" + sex
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.custom_minimum_size.y = 390
	parent.add_child(panel)
	panel.resized.connect(func() -> void: panel.custom_minimum_size.y = panel.size.x * 1402.0 / 1122.0)
	var environment: TextureRect = T.texture("res://assets/art/modern/species_card_frame_v2.png", Vector2.ZERO)
	environment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place(environment, 0, 0, 1, 1)
	panel.add_child(environment)
	var name_label: Label = _lab_label(_instance_name(instance) if not instance.is_empty() else T.text("CHOOSE A PARENT", "WYBIERZ RODZICA"), 27)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_place(name_label, 0.18, 0.045, 0.83, 0.17)
	panel.add_child(name_label)
	var sex_label := T.sex_badge(sex, true)
	_place(sex_label, 0.20, 0.18, 0.80, 0.285)
	panel.add_child(sex_label)
	if instance.is_empty():
		var space: Label = _lab_label("?", 95, T.GOLD)
		_place(space, 0.20, 0.32, 0.80, 0.71)
		panel.add_child(space)
	else:
		var animal: TextureRect = T.texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2.ZERO)
		_place(animal, 0.06, 0.37, 0.94, 0.72)
		panel.add_child(animal)
		var rarity: String = str(instance.get("rarity", "common"))
		var rarity_label: Label = _lab_label(_rarity_name(rarity).to_upper(), 22, _rarity_color(rarity))
		_place(rarity_label, 0.12, 0.29, 0.88, 0.365)
		panel.add_child(rarity_label)
		var condition: float = (float(instance.get("happiness", 100)) + float(instance.get("hunger", 100)) + float(instance.get("hydration", 100)) + float(instance.get("cleanliness", 100))) / 4.0
		var welfare: Label = _lab_label(T.text("LV. ", "POZ. ") + str(ReptileSystem.get_reptile_level(instance)) + "  ·  %.0f%%" % condition, 23, T.ACCENT)
		_place(welfare, 0.15, 0.735, 0.85, 0.81)
		panel.add_child(welfare)
	var choose: Button = _lab_button(T.text("CHOOSE", "WYBIERZ") if instance.is_empty() else T.text("CHANGE", "ZMIEŃ"), _show_parent_selector.bind(sex), "gold" if instance.is_empty() else "green", 24)
	_place(choose, 0.15, 0.83, 0.85, 0.96)
	panel.add_child(choose)


func _set_mode(is_long: bool) -> void:
	_long_pairing = is_long
	_rebuild()


func _odds(parent: Node, rates: Dictionary) -> void:
	for rarity in RARITIES:
		var row: HBoxContainer = T.row(10)
		parent.add_child(row)
		var name_label: Label = T.label(_rarity_name(rarity), 19, _rarity_color(rarity))
		name_label.custom_minimum_size.x = 155
		name_label.size_flags_horizontal = Control.SIZE_FILL
		row.add_child(name_label)
		var bar: ProgressBar = T.progress(float(rates.get(rarity, 0)), _rarity_color(rarity))
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		var percentage: Label = T.label("%.0f%%" % float(rates.get(rarity, 0)), 20)
		percentage.custom_minimum_size.x = 54
		percentage.size_flags_horizontal = Control.SIZE_FILL
		percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(percentage)


func _build_shop() -> void:
	var intro: VBoxContainer = _card(_body, T.text("Choose your next discovery", "Wybierz kolejne odkrycie"), T.text("Choose a species, then an egg quality. Rarity is rolled when the egg hatches.", "Wybierz gatunek i jakość jaja. Rzadkość jest losowana podczas wyklucia."))
	var species: Array = IncubationSystem.get_available_species_for_shop()
	if species.is_empty():
		intro.add_child(T.label(T.text("Unlock a habitat region to discover more eggs.", "Odblokuj biom, aby odkryć dostępne jaja."), 23, T.MUTED))
		return
	var ids: Array[String] = []
	for data: Variant in species:
		ids.append(str(data.get("species_id", "")))
	if not ids.has(_shop_species):
		_shop_species = ids[0]
	var select: OptionButton = _option()
	for species_id in ids:
		select.add_item(_species_name(species_id))
	select.select(ids.find(_shop_species))
	select.item_selected.connect(func(index: int) -> void:
		_shop_species = ids[index]
		_rebuild()
	)
	intro.add_child(select)
	intro.add_child(T.label(T.text("Incubation: ", "Inkubacja: ") + T.time(_species_duration(_shop_species)), 22, T.BLUE))
	var qualities: Dictionary = IncubationSystem.get_species_shop_qualities()
	for quality_value: Variant in IncubationSystem.get_quality_order():
		var quality_id: String = str(quality_value)
		var quality: Dictionary = qualities.get(quality_id, {})
		if quality.is_empty():
			continue
		var price: int = int(quality.get("price", 0))
		if IncubationSystem.has_method("get_species_egg_price"):
			price = int(IncubationSystem.call("get_species_egg_price", _shop_species, quality_id))
		var content: VBoxContainer = _card(_body)
		var row: HBoxContainer = T.row(16)
		content.add_child(row)
		row.add_child(T.texture(EGG_ART, Vector2(100, 116)))
		var copy: VBoxContainer = T.column(8)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		copy.add_child(T.label(_quality_name(quality_id), 28, T.GOLD))
		copy.add_child(T.label(_species_name(_shop_species), 22, T.MUTED))
		_odds(content, quality.get("drop_rates", {}))
		var buy: Button = T.button(T.text("Buy egg · ", "Kup jajo · ") + T.amount(price), _buy_egg.bind(_shop_species, quality_id))
		content.add_child(buy)
		_price_buttons.append({"button": buy, "cost": price})


func _build_upgrades() -> void:
	_body.add_child(T.label(T.text("A calmer, more capable nursery", "Spokojniejsza, sprawniejsza wylęgarnia"), 27, T.ACCENT))
	_body.add_child(T.label(T.text("Speed upgrades apply to newly started breeding and incubation. Existing timers keep their current duration.", "Ulepszenia czasu działają na nowo rozpoczętą hodowlę i inkubację. Trwające procesy zachowują swój czas."), 21, T.MUTED))
	for value: Variant in IncubatorUpgradeSystem.get_upgrade_definitions():
		var upgrade: Dictionary = value
		var id: String = str(upgrade.get("id", ""))
		var level: int = IncubatorUpgradeSystem.get_level(id)
		var cap: int = int(upgrade.get("max_level", 5))
		var content: VBoxContainer = _card(_body, LocalizationSystem.tr_key(str(upgrade.get("name_key", ""))), LocalizationSystem.tr_key(str(upgrade.get("description_key", ""))))
		var row: HBoxContainer = T.row(14)
		content.add_child(row)
		row.add_child(T.icon("gear", 38))
		row.add_child(T.label(T.text("Level ", "Poziom ") + str(level) + " / " + str(cap), 24, T.ACCENT))
		content.add_child(T.progress(100.0 * level / maxi(1, cap)))
		var effect: float = float(upgrade.get("effect_per_level", 0.0)) * level
		var effect_text: String = T.text("Current effect: ", "Obecny efekt: ") + ("−%.0f%%" % (effect * 100.0))
		if id == "incubator_more_eggs":
			effect_text = T.text("Tray capacity: ", "Pojemność: ") + str(IncubationSystem.get_max_eggs_per_container()) + T.text(" eggs", " jaj")
		content.add_child(T.label(effect_text, 21, T.MUTED))
		var cost: int = IncubatorUpgradeSystem.get_cost(id)
		if cost < 0:
			content.add_child(T.label(T.text("Fully upgraded", "Maksymalny poziom"), 24, T.GOLD))
		else:
			var buy: Button = T.button(T.text("Upgrade · ", "Ulepsz · ") + T.amount(cost), _buy_upgrade.bind(id))
			content.add_child(buy)
			_price_buttons.append({"button": buy, "cost": cost})


func _option() -> OptionButton:
	var select: OptionButton = OptionButton.new()
	select.custom_minimum_size.y = 60
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.add_theme_font_size_override("font_size", 23)
	select.fit_to_longest_item = false
	return select


func _species_duration(species_id: String) -> int:
	var seconds: int = IncubationSystem.get_incubation_time_hours(species_id) * 3600
	return maxi(10800, int(seconds * IncubatorUpgradeSystem.get_incubation_time_multiplier()))


func _update_live_values() -> void:
	var owned: Dictionary = ReptileSystem.get_owned_reptile_instances()
	if is_instance_valid(_humidity_overview):
		var sum := 0.0
		var count := 0
		for value: Variant in IncubationSystem.get_containers().values():
			if str(value.get("state", "")) in ["loaded", "running", "paused_low_humidity"]:
				sum += float(value.get("humidity_percent", 100))
				count += 1
		_humidity_overview.text = "%.0f%%" % (sum / count) if count > 0 else "—"
	for item: Dictionary in _cooldown_labels:
		var cooldown_label: Label = item.get("label")
		if is_instance_valid(cooldown_label):
			var instance: Dictionary = owned.get(str(item.get("instance_id", "")), {})
			var remaining: int = BreedingSystem.get_cooldown_remaining_seconds(instance)
			cooldown_label.text = T.text("Ready to breed again in ", "Gotowość do hodowli za ") + T.time(remaining) if remaining > 0 else T.text("Ready to breed again", "Gotowość do kolejnej hodowli")
	for item: Dictionary in _price_buttons:
		var button: Button = item.get("button")
		if is_instance_valid(button):
			button.disabled = not EconomySystem.can_afford("repticash", int(item.get("cost", 0)))
	var chambers: Dictionary = BreedingSystem.get_chambers()
	for item: Dictionary in _timer_labels:
		var text_label: Label = item.get("label")
		var bar: ProgressBar = item.get("progress")
		if not is_instance_valid(text_label) or not is_instance_valid(bar):
			continue
		var index: int = int(item.get("index", 0))
		if str(item.get("type", "")) == "breeding":
			var chamber: Dictionary = chambers.get(str(index), {})
			var state: String = str(chamber.get("state", "empty"))
			var remaining: int = BreedingSystem.get_breeding_remaining_seconds(chamber)
			var total: int = maxi(1, int(chamber.get("ends_at", 0)) - int(chamber.get("started_at", 0)))
			text_label.text = T.text("Time remaining · ", "Pozostało · ") + T.time(remaining) if state == "breeding" else T.text("Results are ready", "Wynik jest gotowy")
			bar.value = clampf(100.0 * (1.0 - float(remaining) / total), 0.0, 100.0)
		else:
			var container: Dictionary = IncubationSystem.get_container(index)
			var state: String = str(container.get("state", "empty"))
			var compact: bool = bool(item.get("compact", false))
			var humidity: Label = item.get("humidity")
			var remaining: int = IncubationSystem.get_remaining_seconds(container)
			var required: int = maxi(1, int(container.get("required_active_seconds", 1)))
			bar.value = clampf(100.0 * float(container.get("active_seconds_completed", 0)) / required, 0.0, 100.0)
			humidity.visible = state == "running" or state == "paused_low_humidity"
			humidity.text = (T.text("WATER ", "WODA ") if compact else T.text("Humidity · ", "Wilgotność · ")) + ("%.0f%%" % float(container.get("humidity_percent", 0)))
			var water_button: Button = item.get("water_button")
			if is_instance_valid(water_button):
				water_button.disabled = state == "running" and float(container.get("humidity_percent", 0)) >= 99.5
			match state:
				"loaded": text_label.text = T.time(required) if compact else T.text("Ready to begin · ", "Gotowe do rozpoczęcia · ") + T.time(required)
				"running": text_label.text = T.time(remaining) if compact else T.text("Hatching in ", "Wyklucie za ") + T.time(remaining)
				"paused_low_humidity": text_label.text = T.text("PAUSED", "PAUZA") if compact else T.text("Paused · add water to continue", "Pauza · uzupełnij wodę")
				"ready_to_hatch":
					text_label.text = T.text("NEW LIFE!", "NOWE ŻYCIE!") if compact else T.text("A little miracle is waiting", "Mały cud już czeka")
					bar.value = 100
				"failed_dry": text_label.text = T.text("TOO DRY", "ZA SUCHO") if compact else T.text("Tray needs clearing", "Pojemnik do opróżnienia")
				_: text_label.text = ""


func _open_dialog(title: String, subtitle: String = "") -> VBoxContainer:
	_close_dialog()
	_dialog_layer = CanvasLayer.new()
	_dialog_layer.layer = 40
	get_tree().root.add_child(_dialog_layer)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.025, 0.06, 0.045, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog_layer.add_child(shade)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 64)
	_dialog_layer.add_child(margin)
	var panel: PanelContainer = T.card()
	panel.theme = T.make_theme()
	margin.add_child(panel)
	var outer: VBoxContainer = T.column(18)
	panel.add_child(outer)
	outer.add_child(T.title(title, subtitle))
	var scroll: ScrollContainer = preload("res://scripts/modern/TouchScrollContainer.gd").new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_dialog_column = T.column(16)
	_dialog_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_dialog_column)
	outer.add_child(T.button(T.text("Close", "Zamknij"), _close_dialog, "secondary"))
	return _dialog_column


func _close_dialog() -> void:
	if is_instance_valid(_dialog_layer):
		_dialog_layer.queue_free()
	_dialog_layer = null
	_dialog_column = null
	_selected_eggs.clear()
	_egg_checks.clear()
	_load_button = null
	_load_hint = null


func _show_parent_selector(sex: String) -> void:
	var content: VBoxContainer = _open_dialog(T.text("Choose a parent", "Wybierz rodzica"), T.text("Same species, opposite sex. Healthy parents give better odds.", "Jeden gatunek, przeciwna płeć. Zdrowi rodzice dają lepsze szanse."))
	var other: String = _male_id if sex == "female" else _female_id
	var other_instance: Dictionary = ReptileSystem.get_owned_reptile_instances().get(other, {})
	var species_filter: String = str(other_instance.get("reptile_id", ""))
	var count := 0
	for value: Variant in BreedingSystem.get_available_breeding_reptiles():
		var instance: Dictionary = value
		if str(instance.get("sex", "")) != sex:
			continue
		var candidate: VBoxContainer = _card(content)
		_instance_row(candidate, instance, 108)
		var id: String = str(instance.get("instance_id", ""))
		var compatible: bool = species_filter.is_empty() or species_filter == str(instance.get("reptile_id", ""))
		var choose: Button = T.button(T.text("Choose parent", "Wybierz rodzica"), _choose_parent.bind(id, sex))
		choose.disabled = not compatible
		candidate.add_child(choose)
		if not compatible:
			candidate.add_child(T.label(T.text("Choose the same species as the other parent.", "Wybierz ten sam gatunek co drugi rodzic."), 19, T.MUTED))
		count += 1
	if count == 0:
		content.add_child(T.label(T.text("No eligible parents right now. Adults may be breeding or resting after a pairing.", "Brak dostępnych rodziców. Zwierzęta mogą być w trakcie hodowli lub odpoczywać po łączeniu."), 23, T.MUTED))
	if not other.is_empty():
		content.add_child(T.button(T.text("Clear both parents", "Wyczyść wybór rodziców"), _clear_parents, "secondary"))


func _choose_parent(id: String, sex: String) -> void:
	if sex == "female":
		_female_id = id
	else:
		_male_id = id
	_close_dialog()
	_rebuild()


func _clear_parents() -> void:
	_female_id = ""
	_male_id = ""
	_close_dialog()
	_rebuild()


func _show_egg_selector(index: int) -> void:
	var content: VBoxContainer = _open_dialog(T.text("Choose eggs", "Wybierz jaja"), T.text("Each tray holds one species. You choose which eggs to use.", "W pojemniku mieści się jeden gatunek. Wybierz konkretne jaja."))
	var groups: Dictionary = IncubationSystem.get_eggs_by_species()
	if groups.is_empty():
		content.add_child(T.label(T.text("Your egg basket is empty.", "Koszyk jaj jest pusty."), 24, T.MUTED))
		content.add_child(_lab_button(T.text("VISIT THE EGG SHOP", "PRZEJDŹ DO SKLEPU Z JAJAMI"), func() -> void:
			_close_dialog()
			_select_tab(2), "gold", 27))
		content.add_child(_lab_button(T.text("PAIR YOUR ANIMALS", "DOBIERZ PARĘ ZWIERZĄT"), func() -> void:
			_close_dialog()
			_select_tab(1), "green", 27))
	for key: Variant in groups.keys():
		var species: String = str(key)
		var species_eggs: Array = groups[key]
		var card: VBoxContainer = _card(content, _species_name(species), T.text("Available eggs: ", "Dostępne jaja: ") + str(species_eggs.size()))
		card.add_child(T.button(T.text("Select eggs", "Wybierz jaja"), _show_species_eggs.bind(index, species)))


func _show_species_eggs(index: int, species: String) -> void:
	var content: VBoxContainer = _open_dialog(_species_name(species), T.text("Choose up to ", "Wybierz maksymalnie ") + str(IncubationSystem.get_max_eggs_per_container()) + T.text(" eggs for this tray.", " jaj do pojemnika."))
	var eggs: Array = IncubationSystem.get_eggs_by_species().get(species, [])
	for value: Variant in eggs:
		var egg: Dictionary = value
		var id: String = str(egg.get("egg_id", egg.get("egg_instance_id", "")))
		var row: VBoxContainer = _card(content)
		var checkbox: CheckBox = CheckBox.new()
		checkbox.add_theme_font_size_override("font_size", 24)
		checkbox.custom_minimum_size.y = 60
		var quality: String = str(egg.get("offer_quality", egg.get("egg_quality_id", egg.get("quality_id", ""))))
		var title: String = _rarity_name(str(egg.get("rarity", "common")))
		if not quality.is_empty():
			title = _quality_name(quality)
		if str(egg.get("source", "")) == "starter":
			title = T.text("Welcome egg · 1 minute", "Powitalne jajo · 1 minuta")
		checkbox.text = title
		checkbox.set_meta("egg_id", id)
		checkbox.toggled.connect(_toggle_egg.bind(id))
		row.add_child(checkbox)
		_egg_checks.append(checkbox)
		if egg.has("hidden_drop_rates") or egg.has("drop_rates"):
			_odds(row, egg.get("hidden_drop_rates", egg.get("drop_rates", {})))
		var seconds: int = _species_duration(species)
		if IncubationSystem.has_method("get_egg_incubation_duration_seconds"):
			seconds = int(IncubationSystem.call("get_egg_incubation_duration_seconds", egg))
			if str(egg.get("source", "")) != "starter":
				seconds = maxi(10800, int(seconds * IncubatorUpgradeSystem.get_incubation_time_multiplier()))
		row.add_child(T.label(T.text("Incubation · ", "Inkubacja · ") + T.time(seconds), 20, T.MUTED))
	_load_hint = T.label("", 22, T.MUTED)
	content.add_child(_load_hint)
	_load_button = T.button(T.text("Begin incubation", "Rozpocznij inkubację"), _load_and_start.bind(index, species))
	content.add_child(_load_button)
	if not _egg_checks.is_empty():
		_egg_checks[0].button_pressed = true
	_update_egg_selection()


func _toggle_egg(enabled: bool, egg_id: String) -> void:
	if enabled and not _selected_eggs.has(egg_id):
		_selected_eggs.append(egg_id)
	elif not enabled:
		_selected_eggs.erase(egg_id)
	_update_egg_selection()


func _update_egg_selection() -> void:
	var cap: int = IncubationSystem.get_max_eggs_per_container()
	for checkbox in _egg_checks:
		if is_instance_valid(checkbox):
			checkbox.disabled = not checkbox.button_pressed and _selected_eggs.size() >= cap
	if is_instance_valid(_load_button):
		_load_button.disabled = _selected_eggs.is_empty() or _selected_eggs.size() > cap
	if is_instance_valid(_load_hint):
		_load_hint.text = str(_selected_eggs.size()) + " / " + str(cap) + T.text(" eggs selected. A mixed batch uses its longest incubation time.", " jaj wybranych. Partia używa najdłuższego czasu inkubacji.")


func _load_and_start(index: int, species: String) -> void:
	if _busy:
		return
	_busy = true
	var result: Dictionary = IncubationSystem.load_eggs_into_container(index, _selected_eggs.duplicate(), species)
	if bool(result.get("success", false)):
		result = IncubationSystem.start_incubation(index)
	_busy = false
	if bool(result.get("success", false)):
		_close_dialog()
	_handle_result(result, T.text("Incubation has begun.", "Inkubacja rozpoczęta."))


func _start_loaded(index: int) -> void:
	_handle_result(IncubationSystem.start_incubation(index), T.text("Incubation has begun.", "Inkubacja rozpoczęta."))


func _cancel_loaded(index: int) -> void:
	_handle_result(IncubationSystem.cancel_loaded_container(index), T.text("Eggs returned to your basket.", "Jaja wróciły do koszyka."))


func _water(index: int) -> void:
	_handle_result(IncubationSystem.water_container(index), T.text("Humidity restored. Your eggs are comfortable.", "Wilgotność uzupełniona. Jaja mają dobre warunki."))


func _clear_failed(index: int) -> void:
	_handle_result(IncubationSystem.clear_failed_container(index), T.text("The tray is ready.", "Pojemnik jest gotowy."))


func _start_breeding() -> void:
	var result: Dictionary = BreedingSystem.start_breeding(_chamber_index, _female_id, _male_id, _long_pairing)
	if bool(result.get("success", false)):
		_female_id = ""
		_male_id = ""
	_handle_result(result, T.text("Your pair has settled into the breeding room.", "Twoja para zamieszkała w komorze hodowlanej."))


func _collect_breeding(index: int) -> void:
	var result: Dictionary = BreedingSystem.collect_breeding(index)
	var message: String = T.text("No eggs this time. Your parents are resting.", "Tym razem bez jaj. Rodzice odpoczywają.")
	if bool(result.get("succeeded", false)):
		message = T.text("New eggs in your basket: ", "Nowe jaja w koszyku: ") + str(result.get("egg_count", 0))
	_handle_result(result, message)


func _return_parent(id: String) -> void:
	var success: bool = BreedingSystem.return_reptile_from_storage(id)
	_handle_result({"success": success}, T.text("Parent returned to your collection.", "Rodzic wrócił do kolekcji."))


func _buy_egg(species: String, quality: String) -> void:
	_handle_result(IncubationSystem.buy_species_egg(species, quality), T.text("Your new egg is in the basket.", "Nowe jajo jest już w koszyku."))


func _buy_upgrade(id: String) -> void:
	_handle_result(IncubatorUpgradeSystem.buy(id), T.text("Nursery upgraded.", "Wylęgarnia ulepszona."))


func _handle_result(result: Dictionary, success_message: String) -> void:
	if bool(result.get("success", false)):
		toast_requested.emit(success_message)
		refresh_requested.emit()
		refresh()
	else:
		var key: String = str(result.get("error_key", result.get("message_key", "")))
		toast_requested.emit(LocalizationSystem.tr_key(key) if not key.is_empty() else T.text("This action is unavailable now.", "Ta akcja jest teraz niedostępna."))


func _speedup(kind: String, index: int) -> void:
	SpeedUpService.request_speedup(kind, str(index), self,
		func() -> void:
			toast_requested.emit(T.text("Time saved.", "Czas skrócony."))
			refresh_requested.emit()
			refresh(),
		func(key: String) -> void: toast_requested.emit(LocalizationSystem.tr_key(key))
	)


func _hatch(index: int) -> void:
	if _busy:
		return
	_busy = true
	var result: Dictionary = IncubationSystem.hatch_batch(index)
	_busy = false
	if not bool(result.get("success", false)):
		_handle_result(result, "")
		return
	var results: Array = result.get("results", [])
	var total_xp := 0
	var hatch_xp: Dictionary = _config.get("hatch_exp", {})
	for value: Variant in results:
		if value is Dictionary:
			total_xp += int(hatch_xp.get(str(value.get("rarity", "common")), 0))
	if total_xp > 0:
		EconomySystem.add_currency("xp", total_xp)
		SaveSystem.save_game()
	refresh_requested.emit()
	refresh()
	var content: VBoxContainer = _open_dialog(T.text("Welcome to the world", "Witajcie na świecie"), T.text("A new chapter in your collection.", "Nowy rozdział twojej kolekcji."))
	if total_xp > 0:
		var reward: Label = T.label("+" + str(total_xp) + " XP", 27, T.GOLD)
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(reward)
	for value: Variant in results:
		var hatchling: Dictionary = value
		var rarity: String = str(hatchling.get("rarity", "common"))
		var card: VBoxContainer = T.column(10)
		content.add_child(card)
		if bool(hatchling.get("is_new_discovery", false)):
			var badge: Label = T.label(T.text("NEW DISCOVERY", "NOWE ODKRYCIE"), 23, T.GOLD)
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(badge)
		var reveal := Control.new()
		reveal.custom_minimum_size.y = 440
		card.add_child(reveal)
		var frame: TextureRect = T.texture(LAB_ART + "hatch_reptile_frame_ultra.png", Vector2.ZERO)
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_place(frame, 0.20, 0, 1.0, 1.0)
		reveal.add_child(frame)
		var burst: TextureRect = T.texture(LAB_ART + "hatch_egg_burst.png", Vector2.ZERO)
		_place(burst, 0, 0.26, 0.36, 0.87)
		reveal.add_child(burst)
		var portrait: TextureRect = T.texture(str(hatchling.get("portrait_path", "")), Vector2.ZERO)
		_place(portrait, 0.32, 0.17, 0.90, 0.82)
		reveal.add_child(portrait)
		var species: Label = T.label(_species_name(str(hatchling.get("species_id", ""))), 31)
		species.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(species)
		var variant: Dictionary = ReptileSystem.get_variant(str(hatchling.get("variant_id", "")))
		if not str(variant.get("name_key", "")).is_empty():
			var variant_label: Label = T.label(LocalizationSystem.tr_key(str(variant.get("name_key", ""))), 23, T.MUTED)
			variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(variant_label)
		var rarity_label: Label = T.label(_rarity_name(rarity), 24, _rarity_color(rarity))
		rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(rarity_label)
		card.add_child(T.sex_badge(str(hatchling.get("sex", "female"))))
		card.add_child(T.button(T.text("Meet your animal", "Poznaj swoje zwierzę"), _inspect_hatchling.bind(str(hatchling.get("instance_id", ""))), "secondary"))
		portrait.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(portrait, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE)
		var burst_tween: Tween = create_tween()
		burst_tween.tween_property(burst, "modulate:a", 0.55, 1.4).set_trans(Tween.TRANS_SINE)
	content.add_child(T.label(T.text("Your hatchlings are in your collection. Assign them to a habitat to help them grow.", "Młode są już w kolekcji. Przydziel im siedlisko, aby mogły się rozwijać."), 22, T.MUTED))


func _inspect_hatchling(id: String) -> void:
	_close_dialog()
	details_requested.emit(id)


func dismiss_overlay() -> bool:
	if not is_instance_valid(_dialog_layer):
		return false
	_close_dialog()
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and dismiss_overlay():
		get_viewport().set_input_as_handled()
