extends Control

signal biome_map_requested

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")
const TOP_BAR_SCENE := preload("res://scenes/ui/TopBar.tscn")
const BOTTOM_NAV_SCENE := preload("res://scenes/ui/BottomNav.tscn")

const BACKGROUND_PATH := "res://assets/art/biomes/incubator_background.png"
const TOP_BAR_ART_PATH := "res://assets/art/ui/top_bar_incubation.png"
const BOTTOM_MENU_ART_PATH := "res://assets/art/ui/bottom_menu_incubation.png"
const INCUBATOR_CONFIG_PATH := "res://data/incubator.json"
const INCUBATOR_LAYOUT_PATH := "res://data/incubator_layout.json"

const PLUS_ICON_PATH := "res://assets/art/icons/icon_plus.png"
const CONNECTION_IN_PROGRESS_PATH := "res://assets/art/incubator/in_progress_icons/incubation_connection_in_progress.png"
const INCUBATION_IN_PROGRESS_PATH := "res://assets/art/incubator/in_progress_icons/incubation_in_progress.png"

const EGG_PATH := "res://assets/art/incubator/eggs/egg.png"
const EGG_SHOP_COMMON_PATH := "res://assets/art/incubator/eggs/shop_egg_common.png"
const EGG_SHOP_RARE_PATH := "res://assets/art/incubator/eggs/shop_egg_rare.png"
const EGG_SHOP_ULTRA_RARE_PATH := "res://assets/art/incubator/eggs/shop_egg_ultra_rare.png"
const EGG_SHOP_EXCEPTIONAL_PATH := "res://assets/art/incubator/eggs/shop_egg_exceptional.png"

const LAYOUT_REF_W := 720.0
const LAYOUT_REF_H := 1280.0
const PLAY_AREA_REF_TOP := 84.0   # TOP_BAR_HEIGHT in reference pixels
const TOP_BAR_HEIGHT := 84
const BOTTOM_MENU_HEIGHT := 172

const SLOT_HITBOX := Vector2(120.0, 120.0)
const SLOT_ICON := Vector2(80.0, 80.0)

var _config: Dictionary = {}
var _layout: Dictionary = {}
var _breeding_slot_nodes: Dictionary = {}    # index (int) → Control
var _incubation_slot_nodes: Dictionary = {}  # index (int) → Control

var _storage_overlay: Control
var _select_overlay: Control
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: SceneTreeTimer
var _tick_timer: Timer

# Selection flow
var _select_step: int = 0
var _select_chamber_index: int = -1
var _selected_instance_a: String = ""
var _selected_instance_b: String = ""
var _select_reptile_id_filter: String = ""
var _select_sex_filter: String = ""


func _ready() -> void:
	_load_config()
	_load_incubator_layout()
	_build_layout()
	_start_tick_timer()
	if not GameState.language_changed.is_connected(_on_language_changed):
		GameState.language_changed.connect(_on_language_changed)


func _load_config() -> void:
	_config = {"breeding_chambers": 6, "incubation_containers": 6}
	var file := FileAccess.open(INCUBATOR_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) == TYPE_DICTIONARY:
		_config = data as Dictionary


func _load_incubator_layout() -> void:
	_layout = {}
	var file := FileAccess.open(INCUBATOR_LAYOUT_PATH, FileAccess.READ)
	if file == null:
		push_warning("IncubatorView: incubator_layout.json not found, using fallback.")
		_layout = _get_fallback_layout()
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) == TYPE_DICTIONARY:
		var section: Variant = (data as Dictionary).get("incubator", null)
		if typeof(section) == TYPE_DICTIONARY:
			_layout = section as Dictionary
			return
	push_warning("IncubatorView: incubator_layout.json malformed, using fallback.")
	_layout = _get_fallback_layout()


func _get_fallback_layout() -> Dictionary:
	return {
		"breeding_chambers": [
			{"id": 1, "x": 140, "y": 185}, {"id": 2, "x": 565, "y": 185},
			{"id": 3, "x": 140, "y": 360}, {"id": 4, "x": 565, "y": 360},
			{"id": 5, "x": 140, "y": 535}, {"id": 6, "x": 565, "y": 535}
		],
		"incubation_containers": [
			{"id": 1, "x": 140, "y": 720}, {"id": 2, "x": 565, "y": 720},
			{"id": 3, "x": 140, "y": 895}, {"id": 4, "x": 565, "y": 895},
			{"id": 5, "x": 140, "y": 1060}, {"id": 6, "x": 565, "y": 1060}
		]
	}


func _start_tick_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)


func _build_layout() -> void:
	_breeding_slot_nodes = {}
	_incubation_slot_nodes = {}
	_add_background()
	_add_top_bar()
	_add_bottom_nav()
	_add_play_area()
	_add_storage_overlay()
	_add_select_overlay()
	_add_toast()


func _rebuild_layout() -> void:
	_load_incubator_layout()
	for child in get_children():
		if child is Timer:
			continue
		child.queue_free()
	_storage_overlay = null
	_select_overlay = null
	_toast_panel = null
	_toast_label = null
	_toast_timer = null
	_select_step = 0
	_breeding_slot_nodes = {}
	_incubation_slot_nodes = {}
	_build_layout()


# ─── Background ────────────────────────────────────────────────────────

func _add_background() -> void:
	var bg := TextureRect.new()
	bg.name = "IncubatorBackground"
	bg.texture = AssetPaths.load_texture(BACKGROUND_PATH)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	if bg.texture == null:
		var fallback := ColorRect.new()
		fallback.color = Color(0.15, 0.10, 0.07, 1.0)
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fallback)
		move_child(fallback, 0)


func _add_top_bar() -> void:
	var top_bar: Control = TOP_BAR_SCENE.instantiate() as Control
	top_bar.name = "TopBar"
	if "art_path" in top_bar:
		top_bar.art_path = TOP_BAR_ART_PATH
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = TOP_BAR_HEIGHT
	add_child(top_bar)


func _add_bottom_nav() -> void:
	var bottom_nav: Control = BOTTOM_NAV_SCENE.instantiate() as Control
	bottom_nav.name = "BottomNav"
	if "art_path" in bottom_nav:
		bottom_nav.art_path = BOTTOM_MENU_ART_PATH
	bottom_nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_nav.offset_top = -BOTTOM_MENU_HEIGHT
	bottom_nav.offset_bottom = 0
	if bottom_nav.has_signal("nav_pressed"):
		bottom_nav.connect("nav_pressed", Callable(self, "_on_nav_pressed"))
	add_child(bottom_nav)


# ─── Play area with anchor-positioned slots ────────────────────────────

func _add_play_area() -> void:
	var play_area := Control.new()
	play_area.name = "PlayArea"
	play_area.anchor_left = 0.0
	play_area.anchor_top = 0.0
	play_area.anchor_right = 1.0
	play_area.anchor_bottom = 1.0
	play_area.offset_top = TOP_BAR_HEIGHT
	play_area.offset_bottom = -BOTTOM_MENU_HEIGHT
	play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(play_area)

	var play_ref_h: float = LAYOUT_REF_H - PLAY_AREA_REF_TOP - float(BOTTOM_MENU_HEIGHT)

	var breeding_defs: Array = _layout.get("breeding_chambers", []) as Array
	var incubation_defs: Array = _layout.get("incubation_containers", []) as Array

	# Section label: Breeding Chambers
	if breeding_defs.size() > 0:
		var first_y: float = float((breeding_defs[0] as Dictionary).get("y", 185))
		_add_section_label(play_area, "incubator.breeding_chambers", "Breeding Chambers",
			360.0, first_y - 46.0, play_ref_h)

	# Breeding chamber slots
	for i in range(breeding_defs.size()):
		var def: Variant = breeding_defs[i]
		if typeof(def) == TYPE_DICTIONARY:
			var node := _add_slot(play_area, def as Dictionary, i, "breeding", play_ref_h)
			_breeding_slot_nodes[i] = node

	# Section label: Incubation Containers
	if incubation_defs.size() > 0:
		var first_y: float = float((incubation_defs[0] as Dictionary).get("y", 720))
		_add_section_label(play_area, "incubator.incubation_containers", "Incubation Containers",
			360.0, first_y - 46.0, play_ref_h)

	# Incubation container slots
	for i in range(incubation_defs.size()):
		var def: Variant = incubation_defs[i]
		if typeof(def) == TYPE_DICTIONARY:
			var node := _add_slot(play_area, def as Dictionary, i, "incubation", play_ref_h)
			_incubation_slot_nodes[i] = node


func _add_section_label(parent: Control, key: String, fallback: String,
		x_ref: float, y_ref: float, play_ref_h: float) -> void:
	var ax := x_ref / LAYOUT_REF_W
	var ay := clampf((y_ref - PLAY_AREA_REF_TOP) / play_ref_h, 0.0, 1.0)

	var label := Label.new()
	label.text = _localized_text(key, fallback)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = ax
	label.anchor_top = ay
	label.anchor_right = ax
	label.anchor_bottom = ay
	label.offset_left = -240.0
	label.offset_right = 240.0
	label.offset_top = -14.0
	label.offset_bottom = 14.0
	parent.add_child(label)


func _add_slot(parent: Control, slot_def: Dictionary, index: int,
		slot_type: String, play_ref_h: float) -> Control:
	var x_ref := float(slot_def.get("x", 360))
	var y_ref := float(slot_def.get("y", 640))

	var ax := x_ref / LAYOUT_REF_W
	var ay := (y_ref - PLAY_AREA_REF_TOP) / play_ref_h

	var container := Control.new()
	container.name = slot_type + "_slot_" + str(index)
	container.anchor_left = ax
	container.anchor_top = ay
	container.anchor_right = ax
	container.anchor_bottom = ay
	container.offset_left = -SLOT_HITBOX.x * 0.5
	container.offset_top = -SLOT_HITBOX.y * 0.5
	container.offset_right = SLOT_HITBOX.x * 0.5
	container.offset_bottom = SLOT_HITBOX.y * 0.5
	parent.add_child(container)

	# Visible icon (centered in hitbox)
	var icon := TextureRect.new()
	icon.name = "SlotIcon"
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -SLOT_ICON.x * 0.5
	icon.offset_top = -SLOT_ICON.y * 0.5
	icon.offset_right = SLOT_ICON.x * 0.5
	icon.offset_bottom = SLOT_ICON.y * 0.5
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	# Small label below icon (timer / status)
	var timer_label := Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 11)
	timer_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.76, 1.0))
	timer_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.90))
	timer_label.add_theme_constant_override("shadow_offset_x", 1)
	timer_label.add_theme_constant_override("shadow_offset_y", 1)
	timer_label.anchor_left = 0.0
	timer_label.anchor_top = 1.0
	timer_label.anchor_right = 1.0
	timer_label.anchor_bottom = 1.0
	timer_label.offset_top = 2.0
	timer_label.offset_bottom = 20.0
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(timer_label)

	# Invisible hit button covering the full hitbox
	var hit_btn := Button.new()
	hit_btn.name = "HitButton"
	hit_btn.flat = true
	hit_btn.focus_mode = Control.FOCUS_NONE
	hit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	var blank := StyleBoxFlat.new()
	blank.bg_color = Color(0, 0, 0, 0)
	hit_btn.add_theme_stylebox_override("normal", blank)
	hit_btn.add_theme_stylebox_override("hover", blank)
	hit_btn.add_theme_stylebox_override("pressed", blank)
	hit_btn.add_theme_stylebox_override("focus", blank)
	hit_btn.pressed.connect(func() -> void: _on_slot_pressed(index, slot_type))
	container.add_child(hit_btn)

	_refresh_slot(container, index, slot_type)
	return container


# ─── Slot visual refresh ───────────────────────────────────────────────

func _refresh_slot(container: Control, index: int, slot_type: String) -> void:
	var icon: TextureRect = container.get_node_or_null("SlotIcon") as TextureRect
	var timer_label: Label = container.get_node_or_null("TimerLabel") as Label
	if icon == null or timer_label == null:
		return

	if slot_type == "incubation":
		icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
		icon.modulate = Color.WHITE
		timer_label.text = ""
		return

	# Breeding chamber
	var chambers: Dictionary = BreedingSystem.get_chambers()
	var val: Variant = chambers.get(str(index), null)
	if val == null or typeof(val) != TYPE_DICTIONARY:
		icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
		icon.modulate = Color.WHITE
		timer_label.text = ""
		return

	var chamber: Dictionary = val as Dictionary
	var state: String = str(chamber.get("state", "empty"))
	match state:
		"breeding":
			icon.texture = AssetPaths.load_texture(CONNECTION_IN_PROGRESS_PATH)
			icon.modulate = Color.WHITE
			var secs: int = BreedingSystem.get_breeding_remaining_seconds(chamber)
			timer_label.text = _format_countdown(secs)
		"ready":
			icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
			icon.modulate = Color(0.50, 1.0, 0.55, 1.0)
			timer_label.text = _localized_text("incubator.breeding_ready", "Ready!")
		"failed":
			icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
			icon.modulate = Color(1.0, 0.45, 0.40, 1.0)
			timer_label.text = _localized_text("incubator.breeding_failed", "Failed")
		_:
			icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
			icon.modulate = Color.WHITE
			timer_label.text = ""


func _refresh_all_slots() -> void:
	for index in _breeding_slot_nodes.keys():
		var node: Variant = _breeding_slot_nodes.get(index)
		if typeof(node) == TYPE_OBJECT and is_instance_valid(node as Control):
			_refresh_slot(node as Control, index, "breeding")
	for index in _incubation_slot_nodes.keys():
		var node: Variant = _incubation_slot_nodes.get(index)
		if typeof(node) == TYPE_OBJECT and is_instance_valid(node as Control):
			_refresh_slot(node as Control, index, "incubation")


# ─── Slot press handler ────────────────────────────────────────────────

func _on_slot_pressed(index: int, slot_type: String) -> void:
	if slot_type == "incubation":
		_show_toast("incubator.coming_soon", "This feature will be added in a later stage.")
		return

	var chambers: Dictionary = BreedingSystem.get_chambers()
	var val: Variant = chambers.get(str(index), null)
	if val == null or typeof(val) != TYPE_DICTIONARY:
		_show_select_step_1(index)
		return

	var state: String = str((val as Dictionary).get("state", "empty"))
	if state == "ready" or state == "failed":
		var result: Dictionary = BreedingSystem.collect_breeding(index)
		if bool(result.get("success", false)):
			var egg_count: int = int(result.get("egg_count", 0))
			var succeeded: bool = bool(result.get("succeeded", false))
			if succeeded and egg_count > 0:
				if egg_count == 1:
					_show_toast("incubator.egg_collected_one", "Collected 1 egg!")
				else:
					_show_toast_raw(
						_localized_text("incubator.eggs_collected", "Collected {count} eggs!").replace("{count}", str(egg_count))
					)
			else:
				_show_toast("incubator.breeding_failed", "Breeding failed — no eggs.")
			_refresh_all_slots()
	elif state == "breeding":
		_show_toast("incubator.breeding_in_progress", "Breeding In Progress")


# ─── Storage overlay ───────────────────────────────────────────────────

func _add_storage_overlay() -> void:
	_storage_overlay = Control.new()
	_storage_overlay.name = "StorageOverlay"
	_storage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_storage_overlay.visible = false
	_storage_overlay.z_index = 100
	add_child(_storage_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_storage_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "StoragePanel"
	panel.anchor_left = 0.04
	panel.anchor_top = 0.10
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.92
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.12, 0.08, 0.05, 0.97)
	pstyle.border_color = Color(0.70, 0.52, 0.25, 0.95)
	pstyle.set_border_width_all(3)
	pstyle.set_corner_radius_all(16)
	pstyle.content_margin_left = 16
	pstyle.content_margin_right = 16
	pstyle.content_margin_top = 16
	pstyle.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", pstyle)
	_storage_overlay.add_child(panel)

	var outer := VBoxContainer.new()
	outer.name = "StorageOuter"
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)

	var title := Label.new()
	title.text = _localized_text("incubator.storage", "Storage")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)

	var sep := HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "StorageScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "StorageContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	_make_scroll_safe(content)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(close_row)

	var close_btn := Button.new()
	close_btn.text = _localized_text("button.back", "Back")
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(140, 44)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: _storage_overlay.visible = false)
	close_row.add_child(close_btn)


func _populate_storage_overlay() -> void:
	if _storage_overlay == null:
		return
	var content: VBoxContainer = _storage_overlay.get_node_or_null(
		"StoragePanel/StorageOuter/StorageScroll/StorageContent") as VBoxContainer
	if content == null:
		return
	for child in content.get_children():
		child.queue_free()

	var storage: Dictionary = BreedingSystem.get_storage()
	var reptiles: Array = storage.get("reptiles", []) as Array
	var eggs: Array = storage.get("eggs", []) as Array

	if reptiles.size() == 0 and eggs.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = _localized_text("incubator.storage_empty", "Storage is empty.")
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50, 1.0))
		empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(empty_lbl)
		return

	if reptiles.size() > 0:
		_add_storage_header(content, "incubator.storage_reptiles", "Reptiles")
		for entry in reptiles:
			if typeof(entry) == TYPE_DICTIONARY:
				content.add_child(_make_storage_reptile_row(entry as Dictionary))

	if eggs.size() > 0:
		_add_storage_header(content, "incubator.storage_eggs", "Eggs")
		for entry in eggs:
			if typeof(entry) == TYPE_DICTIONARY:
				content.add_child(_make_storage_egg_row(entry as Dictionary))


func _add_storage_header(parent: VBoxContainer, key: String, fallback: String) -> void:
	var lbl := Label.new()
	lbl.text = _localized_text(key, fallback)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.50, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)


func _make_storage_reptile_row(entry: Dictionary) -> Control:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)

	var instance_id: String = str(entry.get("instance_id", ""))
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var display_name: String = instance_id
	var rarity_text: String = ""
	if instances.has(instance_id):
		var iv: Variant = instances.get(instance_id)
		if typeof(iv) == TYPE_DICTIONARY:
			var inst: Dictionary = iv as Dictionary
			rarity_text = _localized_rarity(str(inst.get("rarity", "common")))
			var cn: String = str(inst.get("custom_name", ""))
			if not cn.is_empty():
				display_name = cn
			else:
				var rd: Dictionary = ReptileSystem.get_reptile(str(inst.get("reptile_id", "")))
				display_name = str(rd.get("name_key", instance_id))

	var lbl := Label.new()
	lbl.text = display_name + ((" (" + rarity_text + ")") if not rarity_text.is_empty() else "")
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.75, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)

	var btn := Button.new()
	btn.text = _localized_text("incubator.return_to_pool", "Return")
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(90, 32)
	btn.add_theme_font_size_override("font_size", 11)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void:
		BreedingSystem.return_reptile_from_storage(instance_id)
		_populate_storage_overlay()
	)
	hbox.add_child(btn)
	return hbox


func _make_storage_egg_row(entry: Dictionary) -> Control:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rarity: String = str(entry.get("rarity", "common"))
	var reptile_id: String = str(entry.get("reptile_id", ""))
	var rd: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var species_name: String = str(rd.get("name_key", reptile_id))
	var lbl := Label.new()
	lbl.text = species_name + " — " + _localized_rarity(rarity)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", _rarity_color(rarity))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)
	return hbox


# ─── Reptile selection overlay ─────────────────────────────────────────

func _add_select_overlay() -> void:
	_select_overlay = Control.new()
	_select_overlay.name = "SelectOverlay"
	_select_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_select_overlay.visible = false
	_select_overlay.z_index = 110
	add_child(_select_overlay)

	var dim := ColorRect.new()
	dim.name = "SelectDim"
	dim.color = Color(0.0, 0.0, 0.0, 0.70)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_select_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "SelectPanel"
	panel.anchor_left = 0.03
	panel.anchor_top = 0.08
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.94
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.11, 0.08, 0.05, 0.98)
	pstyle.border_color = Color(0.65, 0.48, 0.22, 0.95)
	pstyle.set_border_width_all(3)
	pstyle.set_corner_radius_all(14)
	pstyle.content_margin_left = 14
	pstyle.content_margin_right = 14
	pstyle.content_margin_top = 14
	pstyle.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", pstyle)
	_select_overlay.add_child(panel)

	var outer := VBoxContainer.new()
	outer.name = "SelectOuter"
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.name = "SelectTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "SelectScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "SelectList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	_make_scroll_safe(list)

	var cancel_row := HBoxContainer.new()
	cancel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cancel_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(cancel_row)

	var cancel_btn := Button.new()
	cancel_btn.name = "SelectCancel"
	cancel_btn.text = _localized_text("incubator.cancel", "Cancel")
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.custom_minimum_size = Vector2(130, 42)
	cancel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel_btn.pressed.connect(func() -> void:
		_select_step = 0
		_select_overlay.visible = false
	)
	cancel_row.add_child(cancel_btn)


func _show_select_step_1(chamber_index: int) -> void:
	_select_chamber_index = chamber_index
	_select_step = 1
	_selected_instance_a = ""
	_selected_instance_b = ""
	_select_reptile_id_filter = ""
	_select_sex_filter = ""
	_populate_select_list_step1()
	_select_overlay.visible = true


func _get_select_list() -> VBoxContainer:
	if _select_overlay == null:
		return null
	return _select_overlay.get_node_or_null("SelectPanel/SelectOuter/SelectScroll/SelectList") as VBoxContainer


func _get_select_title() -> Label:
	if _select_overlay == null:
		return null
	return _select_overlay.get_node_or_null("SelectPanel/SelectOuter/SelectTitle") as Label


func _populate_select_list_step1() -> void:
	var title := _get_select_title()
	if title != null:
		title.text = _localized_text("incubator.select_first_parent", "Select First Parent")
	var list := _get_select_list()
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()

	var candidates: Array = _get_available_instances()
	if candidates.is_empty():
		_add_list_empty(list, "incubator.no_reptiles_available", "No reptiles available.")
		return
	for inst in candidates:
		list.add_child(_make_reptile_row(inst, func(iid: String) -> void:
			_selected_instance_a = iid
			var v: Variant = ReptileSystem.get_owned_reptile_instances().get(iid, null)
			if typeof(v) == TYPE_DICTIONARY:
				var inst_d: Dictionary = v as Dictionary
				_select_reptile_id_filter = str(inst_d.get("reptile_id", ""))
				_select_sex_filter = "female" if str(inst_d.get("sex", "male")) == "male" else "male"
			_select_step = 2
			_populate_select_list_step2()
		))


func _populate_select_list_step2() -> void:
	var title := _get_select_title()
	if title != null:
		title.text = _localized_text("incubator.select_second_parent", "Select Second Parent")
	var list := _get_select_list()
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()

	var candidates: Array = _get_compatible_instances(_selected_instance_a, _select_reptile_id_filter, _select_sex_filter)
	if candidates.is_empty():
		_add_list_empty(list, "incubator.no_compatible_partner", "No compatible partner.")
		return
	for inst in candidates:
		list.add_child(_make_reptile_row(inst, func(iid: String) -> void:
			_selected_instance_b = iid
			_select_step = 3
			_populate_duration_step()
		))


func _populate_duration_step() -> void:
	var title := _get_select_title()
	if title != null:
		title.text = _localized_text("incubator.choose_duration", "Choose Breeding Duration")
	var list := _get_select_list()
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var ra: String = "common"
	var rb: String = "common"
	var av: Variant = instances.get(_selected_instance_a, null)
	var bv: Variant = instances.get(_selected_instance_b, null)
	if typeof(av) == TYPE_DICTIONARY:
		ra = str((av as Dictionary).get("rarity", "common"))
	if typeof(bv) == TYPE_DICTIONARY:
		rb = str((bv as Dictionary).get("rarity", "common"))

	list.add_child(_make_duration_option(
		_localized_text("incubator.fast_breeding", "Fast (24h)"),
		_localized_text("incubator.fast_bonus_info", "Standard drop rates"),
		BreedingSystem.get_drop_rates(ra, rb, false), false))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(sp)

	list.add_child(_make_duration_option(
		_localized_text("incubator.long_breeding", "Long (48h)"),
		_localized_text("incubator.long_bonus_info", "+5pp to ultra rare and exceptional"),
		BreedingSystem.get_drop_rates(ra, rb, true), true))


func _make_duration_option(title_text: String, info_text: String, rates: Dictionary, is_long: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.14, 0.10, 0.06, 0.80)
	pstyle.border_color = Color(0.60, 0.45, 0.22, 0.75)
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(8)
	pstyle.content_margin_left = 12
	pstyle.content_margin_right = 12
	pstyle.content_margin_top = 10
	pstyle.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", pstyle)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(t)

	var info := Label.new()
	info.text = info_text
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.72, 0.65, 0.50, 0.90))
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(info)

	var rt: String = _localized_text("incubator.drop_rates", "Drop rates:") + " "
	rt += "C:" + str(int(round(float(rates.get("common", 0))))) + "% "
	rt += "R:" + str(int(round(float(rates.get("rare", 0))))) + "% "
	rt += "UR:" + str(int(round(float(rates.get("ultra_rare", 0))))) + "% "
	rt += "E:" + str(int(round(float(rates.get("exceptional", 0))))) + "%"
	var rl := Label.new()
	rl.text = rt
	rl.add_theme_font_size_override("font_size", 11)
	rl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45, 0.85))
	rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rl)

	var btn := Button.new()
	btn.text = _localized_text("incubator.start_breeding", "Start Breeding")
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(func() -> void: _confirm_breeding(is_long))
	vbox.add_child(btn)
	return panel


func _confirm_breeding(is_long: bool) -> void:
	_select_overlay.visible = false
	_select_step = 0
	var result: Dictionary = BreedingSystem.start_breeding(
		_select_chamber_index, _selected_instance_a, _selected_instance_b, is_long)
	if bool(result.get("success", false)):
		_refresh_all_slots()
	else:
		_show_toast(str(result.get("error_key", "")), "Error starting breeding.")


func _add_list_empty(list: VBoxContainer, key: String, fallback: String) -> void:
	var lbl := Label.new()
	lbl.text = _localized_text(key, fallback)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(lbl)


func _make_reptile_row(inst: Dictionary, on_press: Callable) -> Control:
	var instance_id: String = str(inst.get("instance_id", ""))
	var rarity: String = str(inst.get("rarity", "common"))
	var sex: String = str(inst.get("sex", "male"))
	var custom_name: String = str(inst.get("custom_name", ""))
	var reptile_id: String = str(inst.get("reptile_id", ""))
	var rd: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var species: String = str(rd.get("name_key", reptile_id))
	var display: String = custom_name if not custom_name.is_empty() else species
	var sex_lbl: String = _localized_text("incubator.sex_male", "M") if sex == "male" else _localized_text("incubator.sex_female", "F")

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 13)
	btn.text = display + " [" + sex_lbl[0] + "] — " + _localized_rarity(rarity)
	btn.add_theme_color_override("font_color", _rarity_color(rarity))

	var cooldown: int = BreedingSystem.get_cooldown_remaining_seconds(inst)
	if cooldown > 0:
		btn.disabled = true
		btn.text += " (" + _localized_text("incubator.cooldown_label", "CD") + ": " + _format_countdown(cooldown) + ")"

	btn.pressed.connect(func() -> void: on_press.call(instance_id))
	return btn


# ─── Query helpers ─────────────────────────────────────────────────────

func _get_available_instances() -> Array:
	var result: Array = []
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	for iid in instances.keys():
		var v: Variant = instances.get(iid)
		if typeof(v) != TYPE_DICTIONARY:
			continue
		var inst: Dictionary = v as Dictionary
		if BreedingSystem.is_instance_available_for_breeding(inst):
			result.append(inst)
	return result


func _get_compatible_instances(exclude_id: String, reptile_id_filter: String, sex_filter: String) -> Array:
	var result: Array = []
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	for iid in instances.keys():
		if iid == exclude_id:
			continue
		var v: Variant = instances.get(iid)
		if typeof(v) != TYPE_DICTIONARY:
			continue
		var inst: Dictionary = v as Dictionary
		if str(inst.get("reptile_id", "")) != reptile_id_filter:
			continue
		if str(inst.get("sex", "")) != sex_filter:
			continue
		if not BreedingSystem.is_instance_available_for_breeding(inst):
			continue
		result.append(inst)
	return result


# ─── Tick ──────────────────────────────────────────────────────────────

func _on_tick() -> void:
	_refresh_all_slots()


# ─── Toast ─────────────────────────────────────────────────────────────

func _add_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "IncubatorToast"
	_toast_panel.visible = false
	_toast_panel.z_index = 200
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.04, 0.86)
	style.border_color = Color(0.89, 0.68, 0.30, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(14)
	_toast_panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_toast_panel.add_child(margin)
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_toast_label)
	add_child(_toast_panel)


func _show_toast(key: String, fallback: String) -> void:
	_show_toast_raw(_localized_text(key, fallback))


func _show_toast_raw(text: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = text
	_toast_panel.visible = true
	var vp := get_viewport_rect().size
	var w: float = min(vp.x - 48.0, 580.0)
	_toast_panel.size = Vector2(w, 70.0)
	_toast_panel.position = Vector2((vp.x - w) * 0.5, vp.y - 110.0)
	_toast_timer = get_tree().create_timer(2.5)
	var active := _toast_timer
	active.timeout.connect(func() -> void:
		if _toast_timer != active:
			return
		_toast_panel.visible = false
	)


# ─── Utility ───────────────────────────────────────────────────────────

func _make_scroll_safe(root: Control) -> void:
	if root is Button or root is OptionButton or root is CheckButton or root is HSlider or root is VSlider:
		return
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in root.get_children():
		if child is Control:
			_make_scroll_safe(child as Control)


func _format_countdown(seconds: int) -> String:
	if seconds <= 0:
		return "0:00"
	var h: int = int(seconds / 3600.0)
	var m: int = int((seconds % 3600) / 60.0)
	var s: int = seconds % 60
	if h > 0:
		return str(h) + "h " + ("%02d" % m) + "m"
	if m > 0:
		return str(m) + "m " + ("%02d" % s) + "s"
	return str(s) + "s"


func _localized_rarity(rarity: String) -> String:
	return _localized_text("rarity." + rarity, rarity)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.40, 0.70, 1.0, 1.0)
		"ultra_rare":
			return Color(0.80, 0.40, 1.0, 1.0)
		"exceptional":
			return Color(1.0, 0.80, 0.20, 1.0)
		_:
			return Color(0.85, 0.82, 0.78, 1.0)


func _localized_text(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var text := LocalizationSystem.tr_key(key)
	if text.is_empty() or text == key:
		return fallback
	return text


# ─── Nav handler ─────────────────────────────────────────────────────────

func _on_nav_pressed(item_id: String) -> void:
	match item_id:
		"map":
			biome_map_requested.emit()
		"biome":
			pass  # already in incubator, nothing to do
		"animals":
			# "Animals" slot → Incubator Storage in this biome
			if _storage_overlay != null:
				_populate_storage_overlay()
				_storage_overlay.visible = true
		_:
			_show_toast("incubator.coming_soon", "This feature will be added in a later stage.")


func _on_language_changed(_language: String) -> void:
	_rebuild_layout()
