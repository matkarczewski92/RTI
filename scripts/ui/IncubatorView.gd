extends Control

signal biome_map_requested

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")
const TOP_BAR_SCENE := preload("res://scenes/ui/TopBar.tscn")
const BOTTOM_NAV_SCENE := preload("res://scenes/ui/BottomNav.tscn")
const SETTINGS_MODAL_SCRIPT := preload("res://scripts/ui/SettingsModal.gd")

const BACKGROUND_PATH := "res://assets/art/biomes/incubator_background.png"
const TOP_BAR_ART_PATH := "res://assets/art/ui/top_bar_incubation.png"
const BOTTOM_MENU_ART_PATH := "res://assets/art/ui/bottom_menu_incubation.png"
const INCUBATOR_CONFIG_PATH := "res://data/incubator.json"
const INCUBATOR_LAYOUT_PATH := "res://data/incubator_layout.json"

const PLUS_ICON_PATH := "res://assets/art/incubator/empty_incubation_or_connection.png"
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

const SLOT_HITBOX_PAD := 40.0   # extra px added to max(icon_size, habitat_size) for the hitbox
const SLOT_ICON_DEFAULT := 80.0
const SLOT_HABITAT_DEFAULT := 80.0

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

# Selection flow (breeding)
var _select_step: int = 0
var _select_chamber_index: int = -1
var _selected_instance_a: String = ""
var _selected_instance_b: String = ""
var _select_reptile_id_filter: String = ""
var _select_sex_filter: String = ""

# Incubation panel
var _incubation_panel: Control
var _incubation_panel_content: VBoxContainer
var _incubation_panel_title: Label
var _incubation_panel_close_btn: Button
var _incubation_panel_idx: int = -1
var _incubation_panel_step: int = 0   # 0 = species list, 1 = count pick
var _incubation_panel_species: String = ""
var _incubation_panel_count: int = 1
var _incubation_panel_available_ids: Array = []

# Egg shop
var _egg_shop_overlay: Control
var _egg_shop_content: VBoxContainer
var _hatch_results_overlay: Control

var _settings_modal: Control
var _upgrades_overlay: Control


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
	_add_incubation_panel()
	_add_egg_shop_overlay()
	_add_hatch_results_overlay()
	_add_upgrades_overlay()
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
	_incubation_panel = null
	_incubation_panel_content = null
	_incubation_panel_title = null
	_incubation_panel_close_btn = null
	_incubation_panel_idx = -1
	_incubation_panel_step = 0
	_incubation_panel_species = ""
	_incubation_panel_count = 1
	_incubation_panel_available_ids = []
	_egg_shop_overlay = null
	_hatch_results_overlay = null
	_upgrades_overlay = null
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
	if top_bar.has_signal("settings_pressed"):
		top_bar.connect("settings_pressed", Callable(self, "_show_settings_screen"))
	add_child(top_bar)


func _show_settings_screen() -> void:
	if _settings_modal != null and is_instance_valid(_settings_modal):
		_settings_modal.move_to_front()
		return
	_settings_modal = SETTINGS_MODAL_SCRIPT.new() as Control
	_settings_modal.name = "SettingsModal"
	_settings_modal.z_index = 220
	_settings_modal.connect("closed", func() -> void:
		_settings_modal = null
	)
	_settings_modal.connect("reset_completed", func() -> void:
		_settings_modal = null
	)
	add_child(_settings_modal)


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
	var icon_size := float(slot_def.get("icon_size", SLOT_ICON_DEFAULT))
	var habitat_size := float(slot_def.get("habitat_size", SLOT_HABITAT_DEFAULT))
	var hitbox_half := (icon_size + SLOT_HITBOX_PAD) * 0.5

	# Separate centers for the small icon and the habitat graphic (relative to hitbox center)
	var icon_ox := float(slot_def.get("icon_x", x_ref)) - x_ref
	var icon_oy := float(slot_def.get("icon_y", y_ref)) - y_ref
	var habitat_ox := float(slot_def.get("habitat_x", x_ref)) - x_ref
	var habitat_oy := float(slot_def.get("habitat_y", y_ref)) - y_ref

	var ax := x_ref / LAYOUT_REF_W
	var ay := (y_ref - PLAY_AREA_REF_TOP) / play_ref_h

	var container := Control.new()
	container.name = slot_type + "_slot_" + str(index)
	container.anchor_left = ax
	container.anchor_top = ay
	container.anchor_right = ax
	container.anchor_bottom = ay
	container.offset_left = -hitbox_half
	container.offset_top = -hitbox_half
	container.offset_right = hitbox_half
	container.offset_bottom = hitbox_half
	container.set_meta("icon_size", icon_size)
	container.set_meta("habitat_size", habitat_size)
	container.set_meta("icon_ox", icon_ox)
	container.set_meta("icon_oy", icon_oy)
	container.set_meta("habitat_ox", habitat_ox)
	container.set_meta("habitat_oy", habitat_oy)
	parent.add_child(container)

	# Visible icon (centered in hitbox)
	var icon := TextureRect.new()
	icon.name = "SlotIcon"
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	_apply_icon_size(icon, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	# Label centered on the habitat graphic
	var timer_label := Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.76, 1.0))
	timer_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.90))
	timer_label.add_theme_constant_override("shadow_offset_x", 1)
	timer_label.add_theme_constant_override("shadow_offset_y", 1)
	timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
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

func _apply_icon_size(icon: TextureRect, px: float, ox: float = 0.0, oy: float = 0.0) -> void:
	var h := px * 0.5
	icon.offset_left  = -h + ox
	icon.offset_top   = -h + oy
	icon.offset_right =  h + ox
	icon.offset_bottom =  h + oy


func _refresh_slot(container: Control, index: int, slot_type: String) -> void:
	var icon: TextureRect = container.get_node_or_null("SlotIcon") as TextureRect
	var timer_label: Label = container.get_node_or_null("TimerLabel") as Label
	if icon == null or timer_label == null:
		return

	var icon_size    := float(container.get_meta("icon_size",    SLOT_ICON_DEFAULT))
	var habitat_size := float(container.get_meta("habitat_size", SLOT_HABITAT_DEFAULT))
	var icon_ox      := float(container.get_meta("icon_ox",    0.0))
	var icon_oy      := float(container.get_meta("icon_oy",    0.0))
	var habitat_ox   := float(container.get_meta("habitat_ox", 0.0))
	var habitat_oy   := float(container.get_meta("habitat_oy", 0.0))

	if slot_type == "incubation":
		var containers: Dictionary = IncubationSystem.get_containers()
		var cv: Variant = containers.get(str(index), null)
		if cv == null or typeof(cv) != TYPE_DICTIONARY:
			_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
			icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
			icon.modulate = Color.WHITE
			timer_label.text = ""
			return
		var ic: Dictionary = cv as Dictionary
		var ic_state: String = str(ic.get("state", "empty"))
		match ic_state:
			"loaded":
				_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
				icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
				icon.modulate = Color(0.70, 0.88, 1.0, 1.0)
				timer_label.text = str(int(ic.get("egg_count", 0))) + " jaj"
			"running":
				_apply_icon_size(icon, habitat_size, habitat_ox, habitat_oy)
				icon.texture = AssetPaths.load_texture(INCUBATION_IN_PROGRESS_PATH)
				icon.modulate = Color.WHITE
				var rem: int = IncubationSystem.get_remaining_seconds(ic)
				timer_label.text = _format_countdown(rem)
			"paused_low_humidity":
				_apply_icon_size(icon, habitat_size, habitat_ox, habitat_oy)
				icon.texture = AssetPaths.load_texture(INCUBATION_IN_PROGRESS_PATH)
				icon.modulate = Color(1.0, 0.72, 0.20, 1.0)
				var hum: int = int(float(ic.get("humidity_percent", 0.0)))
				timer_label.text = str(hum) + "%"
			"failed_dry":
				_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
				icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
				icon.modulate = Color(1.0, 0.38, 0.32, 1.0)
				timer_label.text = _localized_text("incubation.failed_short", "Failed")
			"ready_to_hatch":
				_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
				icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
				icon.modulate = Color(0.42, 1.0, 0.52, 1.0)
				timer_label.text = _localized_text("incubation.ready_short", "Ready!")
			_:
				_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
				icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
				icon.modulate = Color.WHITE
				timer_label.text = ""
		return

	# Breeding chamber
	var chambers: Dictionary = BreedingSystem.get_chambers()
	var val: Variant = chambers.get(str(index), null)
	if val == null or typeof(val) != TYPE_DICTIONARY:
		_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
		icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
		icon.modulate = Color.WHITE
		timer_label.text = ""
		return

	var chamber: Dictionary = val as Dictionary
	var state: String = str(chamber.get("state", "empty"))
	match state:
		"breeding":
			_apply_icon_size(icon, habitat_size, habitat_ox, habitat_oy)
			icon.texture = AssetPaths.load_texture(CONNECTION_IN_PROGRESS_PATH)
			icon.modulate = Color.WHITE
			var secs: int = BreedingSystem.get_breeding_remaining_seconds(chamber)
			timer_label.text = _format_countdown(secs)
		"ready":
			_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
			icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
			icon.modulate = Color(0.50, 1.0, 0.55, 1.0)
			timer_label.text = _localized_text("incubator.breeding_ready", "Ready!")
		"failed":
			_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
			icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
			icon.modulate = Color(1.0, 0.45, 0.40, 1.0)
			timer_label.text = _localized_text("incubator.breeding_failed", "Failed")
		_:
			_apply_icon_size(icon, icon_size, icon_ox, icon_oy)
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
		_show_incubation_panel(index)
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
		_add_storage_header(content, "storage.reptiles_header", "Reptiles in Storage")
		for entry in reptiles:
			if typeof(entry) == TYPE_DICTIONARY:
				content.add_child(_make_storage_reptile_row(entry as Dictionary))

	if eggs.size() > 0:
		var available_eggs: Array = []
		for entry in eggs:
			if typeof(entry) == TYPE_DICTIONARY:
				var e: Dictionary = entry as Dictionary
				if not bool(e.get("in_container", false)):
					available_eggs.append(e)
		if available_eggs.size() > 0:
			_add_storage_header(content, "storage.eggs_header", "Eggs in Storage")
			for entry in available_eggs:
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
				display_name = LocalizationSystem.tr_key(str(rd.get("name_key", instance_id)))

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
	var species_name: String = LocalizationSystem.tr_key(str(rd.get("name_key", reptile_id)))
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
	if _incubation_panel != null and _incubation_panel.visible and _incubation_panel_idx >= 0:
		var container: Dictionary = IncubationSystem.get_container(_incubation_panel_idx)
		var state: String = str(container.get("state", "empty"))
		if state == "running" or state == "paused_low_humidity":
			_populate_incubation_panel()


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
			if _storage_overlay != null:
				_populate_storage_overlay()
				_storage_overlay.visible = true
		"shop":
			if _egg_shop_overlay != null:
				_populate_egg_shop()
				_egg_shop_overlay.visible = true
		"upgrades":
			if _upgrades_overlay != null:
				_populate_upgrades_overlay()
				_upgrades_overlay.visible = true
		_:
			_show_toast("incubator.coming_soon", "This feature will be added in a later stage.")


# ─── Incubation panel overlay ──────────────────────────────────────────

func _add_incubation_panel() -> void:
	_incubation_panel = Control.new()
	_incubation_panel.name = "IncubationPanel"
	_incubation_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_incubation_panel.visible = false
	_incubation_panel.z_index = 115
	add_child(_incubation_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.70)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_incubation_panel.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "IPInner"
	panel.anchor_left = 0.03
	panel.anchor_top = 0.08
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.93
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.11, 0.08, 0.05, 0.98)
	ps.border_color = Color(0.65, 0.48, 0.22, 0.95)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(14)
	ps.content_margin_left = 14
	ps.content_margin_right = 14
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	_incubation_panel.add_child(panel)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	_incubation_panel_title = Label.new()
	_incubation_panel_title.name = "IPTitle"
	_incubation_panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_incubation_panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_incubation_panel_title.add_theme_font_size_override("font_size", 20)
	_incubation_panel_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(_incubation_panel_title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "IPScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	_incubation_panel_content = VBoxContainer.new()
	_incubation_panel_content.name = "IPContent"
	_incubation_panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_incubation_panel_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_incubation_panel_content)
	_make_scroll_safe(_incubation_panel_content)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(close_row)

	_incubation_panel_close_btn = Button.new()
	_incubation_panel_close_btn.name = "IPClose"
	_incubation_panel_close_btn.text = _localized_text("incubation.close", "Close")
	_incubation_panel_close_btn.focus_mode = Control.FOCUS_NONE
	_incubation_panel_close_btn.custom_minimum_size = Vector2(130, 42)
	_incubation_panel_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_incubation_panel_close_btn.pressed.connect(func() -> void:
		_incubation_panel.visible = false
		_incubation_panel_idx = -1
	)
	close_row.add_child(_incubation_panel_close_btn)


func _show_incubation_panel(index: int) -> void:
	_incubation_panel_idx = index
	_incubation_panel_step = 0
	_incubation_panel_species = ""
	_incubation_panel_count = 1
	_incubation_panel_available_ids = []
	_populate_incubation_panel()
	if _incubation_panel != null:
		_incubation_panel.visible = true


func _populate_incubation_panel() -> void:
	if _incubation_panel_content == null or _incubation_panel_title == null:
		return
	_clear_vbox(_incubation_panel_content)

	var container: Dictionary = IncubationSystem.get_container(_incubation_panel_idx)
	var state: String = str(container.get("state", "empty"))

	if _incubation_panel_close_btn != null:
		var close_txt: String = _localized_text("incubator.cancel", "Cancel") if state == "empty" else _localized_text("incubation.close", "Close")
		_incubation_panel_close_btn.text = close_txt

	match state:
		"empty":
			_incubation_panel_title.text = _localized_text("incubation.select_species", "Select species")
			if _incubation_panel_step == 0:
				_ip_show_species_select()
			else:
				_ip_show_count_select()
		"loaded":
			_incubation_panel_title.text = _localized_text("incubation.container_title", "Incubation Container")
			_ip_show_loaded(container)
		"running":
			_incubation_panel_title.text = _localized_text("incubation.in_progress", "Incubation in progress")
			_ip_show_running(container)
		"paused_low_humidity":
			_incubation_panel_title.text = _localized_text("incubation.paused", "Incubation paused")
			_ip_show_paused(container)
		"failed_dry":
			_incubation_panel_title.text = _localized_text("incubation.failed_dry_short", "Incubation Failed")
			_ip_show_failed()
		"ready_to_hatch":
			_incubation_panel_title.text = _localized_text("incubation.ready_to_hatch", "Ready to hatch")
			_ip_show_ready(container)


func _ip_show_species_select() -> void:
	var by_species: Dictionary = IncubationSystem.get_eggs_by_species()
	if by_species.is_empty():
		_incubation_panel_content.add_child(_make_ip_info_label(
			_localized_text("incubation.no_eggs_in_storage", "No eggs in storage.")
		))
		return

	var lang: String = GameState.get_language()
	for species_id in by_species.keys():
		var eggs: Array = by_species[species_id] as Array
		var count: int = eggs.size()
		var egg_name: String = IncubationSystem.get_egg_name(species_id, lang)

		var btn := Button.new()
		btn.text = egg_name + "  (" + str(count) + ")"
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 14)
		var sid_capture: String = species_id
		var ids: Array = []
		for ev in eggs:
			if typeof(ev) == TYPE_DICTIONARY:
				ids.append(str((ev as Dictionary).get("egg_id", "")))
		btn.pressed.connect(func() -> void:
			_incubation_panel_species = sid_capture
			_incubation_panel_available_ids = ids
			_incubation_panel_count = 1
			_incubation_panel_step = 1
			_populate_incubation_panel()
		)
		_incubation_panel_content.add_child(btn)


func _ip_show_count_select() -> void:
	var lang: String = GameState.get_language()
	var egg_name: String = IncubationSystem.get_egg_name(_incubation_panel_species, lang)
	var max_count: int = mini(IncubationSystem.get_max_eggs_per_container(), _incubation_panel_available_ids.size())
	_incubation_panel_count = clampi(_incubation_panel_count, 1, max_count)

	_incubation_panel_content.add_child(_make_ip_info_label(egg_name))

	var avail_lbl := _make_ip_info_label(
		_localized_text("incubation.available_count", "Available: {count}").replace("{count}", str(_incubation_panel_available_ids.size()))
	)
	_incubation_panel_content.add_child(avail_lbl)

	var count_row := HBoxContainer.new()
	count_row.alignment = BoxContainer.ALIGNMENT_CENTER
	count_row.add_theme_constant_override("separation", 16)
	_incubation_panel_content.add_child(count_row)

	var minus_btn := Button.new()
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(48, 42)
	minus_btn.focus_mode = Control.FOCUS_NONE
	minus_btn.disabled = _incubation_panel_count <= 1
	minus_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	minus_btn.pressed.connect(func() -> void:
		_incubation_panel_count = maxi(1, _incubation_panel_count - 1)
		_populate_incubation_panel()
	)
	count_row.add_child(minus_btn)

	var count_lbl := Label.new()
	count_lbl.text = str(_incubation_panel_count)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.custom_minimum_size = Vector2(48, 0)
	count_lbl.add_theme_font_size_override("font_size", 22)
	count_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_row.add_child(count_lbl)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(48, 42)
	plus_btn.focus_mode = Control.FOCUS_NONE
	plus_btn.disabled = _incubation_panel_count >= max_count
	plus_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plus_btn.pressed.connect(func() -> void:
		_incubation_panel_count = mini(max_count, _incubation_panel_count + 1)
		_populate_incubation_panel()
	)
	count_row.add_child(plus_btn)

	var time_h: int = IncubationSystem.get_incubation_time_hours(_incubation_panel_species)
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.incubation_time", "Incubation time: {h}h").replace("{h}", str(time_h))
	))

	if _incubation_panel_count >= 8:
		_incubation_panel_content.add_child(_make_ip_info_label(
			_localized_text("incubation.large_batch_warning", "More eggs → faster humidity drop"),
			Color(1.0, 0.80, 0.35, 0.90)
		))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_incubation_panel_content.add_child(sp)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	_incubation_panel_content.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = _localized_text("button.back", "Back")
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.pressed.connect(func() -> void:
		_incubation_panel_step = 0
		_populate_incubation_panel()
	)
	btn_row.add_child(back_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = _localized_text("incubation.start", "Start Incubation")
	confirm_btn.focus_mode = Control.FOCUS_NONE
	confirm_btn.custom_minimum_size = Vector2(160, 40)
	confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ids_slice: Array = _incubation_panel_available_ids.slice(0, _incubation_panel_count)
	var sid: String = _incubation_panel_species
	var cidx: int = _incubation_panel_idx
	confirm_btn.pressed.connect(func() -> void:
		var result: Dictionary = IncubationSystem.load_eggs_into_container(cidx, ids_slice, sid)
		if bool(result.get("success", false)):
			_incubation_panel_step = 0
			_populate_incubation_panel()
			_refresh_all_slots()
		else:
			_show_toast(str(result.get("error_key", "")), "Error.")
	)
	btn_row.add_child(confirm_btn)


func _ip_show_loaded(container: Dictionary) -> void:
	var lang: String = GameState.get_language()
	var species_id: String = str(container.get("species_id", ""))
	var egg_name: String = IncubationSystem.get_egg_name(species_id, lang)
	var count: int = int(container.get("egg_count", 0))
	var time_h: int = int(container.get("incubation_time_hours", 0))

	_incubation_panel_content.add_child(_make_ip_info_label(egg_name, Color(0.95, 0.88, 0.68, 1.0)))
	_incubation_panel_content.add_child(_make_ip_info_label(str(count) + " jaj"))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.incubation_time", "Incubation time: {h}h").replace("{h}", str(time_h))
	))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_incubation_panel_content.add_child(sp)

	var start_btn := _make_ip_action_btn(
		_localized_text("incubation.start", "Start Incubation"),
		func() -> void:
			var result: Dictionary = IncubationSystem.start_incubation(_incubation_panel_idx)
			if bool(result.get("success", false)):
				_populate_incubation_panel()
				_refresh_all_slots()
			else:
				_show_toast(str(result.get("error_key", "")), "Error.")
	)
	_incubation_panel_content.add_child(start_btn)

	var cancel_btn := _make_ip_action_btn(
		_localized_text("incubation.cancel_and_return", "Cancel and return eggs"),
		func() -> void:
			IncubationSystem.cancel_loaded_container(_incubation_panel_idx)
			_incubation_panel.visible = false
			_incubation_panel_idx = -1
			_refresh_all_slots()
	)
	_incubation_panel_content.add_child(cancel_btn)


func _ip_show_running(container: Dictionary) -> void:
	var lang: String = GameState.get_language()
	var species_id: String = str(container.get("species_id", ""))
	var egg_name: String = IncubationSystem.get_egg_name(species_id, lang)
	var remaining: int = IncubationSystem.get_remaining_seconds(container)
	var humidity: int = int(float(container.get("humidity_percent", 100.0)))
	var count: int = int(container.get("egg_count", 0))

	_incubation_panel_content.add_child(_make_ip_info_label(egg_name, Color(0.95, 0.88, 0.68, 1.0)))
	_incubation_panel_content.add_child(_make_ip_info_label(str(count) + " jaj"))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.time_remaining", "Time remaining:") + "  " + _format_countdown(remaining)
	))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.humidity", "Humidity:") + "  " + str(humidity) + "%"
	))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_incubation_panel_content.add_child(sp)

	_incubation_panel_content.add_child(_make_ip_action_btn(
		_localized_text("incubation.water", "Water"),
		func() -> void:
			var result: Dictionary = IncubationSystem.water_container(_incubation_panel_idx)
			if bool(result.get("success", false)):
				_show_toast("incubation.watered", "Container watered!")
			_populate_incubation_panel()
			_refresh_all_slots()
	))


func _ip_show_paused(container: Dictionary) -> void:
	var lang: String = GameState.get_language()
	var species_id: String = str(container.get("species_id", ""))
	var egg_name: String = IncubationSystem.get_egg_name(species_id, lang)
	var humidity: int = int(float(container.get("humidity_percent", 0.0)))
	var remaining: int = IncubationSystem.get_remaining_seconds(container)

	_incubation_panel_content.add_child(_make_ip_info_label(egg_name, Color(0.95, 0.88, 0.68, 1.0)))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.humidity_low_warning", "Humidity too low — incubation paused"),
		Color(1.0, 0.72, 0.20, 1.0)
	))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.humidity", "Humidity:") + "  " + str(humidity) + "%"
	))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.time_remaining", "Time remaining:") + "  " + _format_countdown(remaining)
	))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_incubation_panel_content.add_child(sp)

	_incubation_panel_content.add_child(_make_ip_action_btn(
		_localized_text("incubation.water", "Water"),
		func() -> void:
			var result: Dictionary = IncubationSystem.water_container(_incubation_panel_idx)
			if bool(result.get("success", false)):
				_show_toast("incubation.watered", "Container watered!")
			_populate_incubation_panel()
			_refresh_all_slots()
	))


func _ip_show_failed() -> void:
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.failed_dry_message", "Humidity reached 0%. The eggs were lost."),
		Color(1.0, 0.42, 0.35, 1.0)
	))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_incubation_panel_content.add_child(sp)

	_incubation_panel_content.add_child(_make_ip_action_btn(
		_localized_text("incubation.clear_container", "Clear container"),
		func() -> void:
			IncubationSystem.clear_failed_container(_incubation_panel_idx)
			_incubation_panel.visible = false
			_incubation_panel_idx = -1
			_refresh_all_slots()
	))


func _ip_show_ready(container: Dictionary) -> void:
	var lang: String = GameState.get_language()
	var species_id: String = str(container.get("species_id", ""))
	var egg_name: String = IncubationSystem.get_egg_name(species_id, lang)
	var count: int = int(container.get("egg_count", 0))

	_incubation_panel_content.add_child(_make_ip_info_label(egg_name, Color(0.95, 0.88, 0.68, 1.0)))
	_incubation_panel_content.add_child(_make_ip_info_label(str(count) + " jaj"))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubation.status_ready_to_hatch", "Ready to hatch"),
		Color(0.42, 1.0, 0.52, 1.0)
	))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_incubation_panel_content.add_child(sp)

	var cidx: int = _incubation_panel_idx
	var hatch_btn := Button.new()
	hatch_btn.text = _localized_text("incubation.hatch", "Wykluj")
	hatch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hatch_btn.focus_mode = Control.FOCUS_NONE
	hatch_btn.custom_minimum_size = Vector2(0, 44)
	hatch_btn.add_theme_font_size_override("font_size", 15)
	hatch_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hatch_btn.pressed.connect(func() -> void:
		hatch_btn.disabled = true
		var result: Dictionary = IncubationSystem.hatch_batch(cidx)
		if bool(result.get("success", false)):
			_incubation_panel.visible = false
			_incubation_panel_idx = -1
			_refresh_all_slots()
			var results_arr: Array = result.get("results", []) as Array
			_show_hatch_results(results_arr)
		else:
			hatch_btn.disabled = false
			_show_toast(str(result.get("error_key", "")), "Hatching failed.")
	)
	_incubation_panel_content.add_child(hatch_btn)


func _make_ip_info_label(text: String, color: Color = Color(0.80, 0.75, 0.62, 1.0)) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_ip_action_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 14)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(callback)
	return btn


func _clear_vbox(vbox: VBoxContainer) -> void:
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()


# ─── Egg shop overlay ──────────────────────────────────────────────────

func _add_egg_shop_overlay() -> void:
	_egg_shop_overlay = Control.new()
	_egg_shop_overlay.name = "EggShopOverlay"
	_egg_shop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_egg_shop_overlay.visible = false
	_egg_shop_overlay.z_index = 120
	add_child(_egg_shop_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_egg_shop_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "ESPanel"
	panel.anchor_left = 0.03
	panel.anchor_top = 0.06
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.95
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.07, 0.04, 0.97)
	ps.border_color = Color(0.70, 0.52, 0.25, 0.95)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.content_margin_left = 14
	ps.content_margin_right = 14
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	_egg_shop_overlay.add_child(panel)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.text = _localized_text("egg_shop.title", "Egg Shop")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "ESScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "ESContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_make_scroll_safe(content)
	_egg_shop_content = content

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(close_row)

	var close_btn := Button.new()
	close_btn.text = _localized_text("button.back", "Back")
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(130, 42)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: _egg_shop_overlay.visible = false)
	close_row.add_child(close_btn)


func _populate_egg_shop() -> void:
	if _egg_shop_overlay == null or _egg_shop_content == null:
		return
	var content: VBoxContainer = _egg_shop_content
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	var available: Array = IncubationSystem.get_available_species_for_shop()
	var qualities: Dictionary = IncubationSystem.get_species_shop_qualities()
	var quality_order: Array = IncubationSystem.get_quality_order()

	if available.is_empty() or qualities.is_empty():
		var lbl := Label.new()
		lbl.text = _localized_text("egg_shop.no_species_available", "No species available")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(lbl)
		return

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)

	for species_val in available:
		if typeof(species_val) != TYPE_DICTIONARY:
			continue
		var species: Dictionary = species_val as Dictionary
		for qid in quality_order:
			if not qualities.has(qid):
				continue
			grid.add_child(_make_species_quality_card(species, qid, qualities[qid] as Dictionary))

	_make_scroll_safe(grid)


func _make_species_quality_card(species: Dictionary, quality_id: String, qdef: Dictionary) -> Control:
	var lang: String = LocalizationSystem.get_language()
	var species_id: String = str(species.get("species_id", ""))
	var egg_name: String = str(species.get("egg_name_" + lang, str(species.get("egg_name_en", species_id))))
	var quality_label: String = _localized_text(str(qdef.get("name_suffix_key", "")), quality_id.capitalize())
	var price: int = int(qdef.get("price", 0))
	var inc_hours: int = int(species.get("incubation_time_hours", 24))
	var rates: Dictionary = {}
	var rates_val: Variant = qdef.get("drop_rates", {})
	if typeof(rates_val) == TYPE_DICTIONARY:
		rates = rates_val as Dictionary

	var badge_color: Color
	match quality_id:
		"standard": badge_color = Color(0.45, 0.45, 0.45, 0.95)
		"improved":  badge_color = Color(0.20, 0.42, 0.88, 0.95)
		"rare":      badge_color = Color(0.56, 0.15, 0.85, 0.95)
		"elite":     badge_color = Color(0.85, 0.62, 0.08, 0.95)
		_:           badge_color = Color(0.45, 0.45, 0.45, 0.95)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.09, 0.05, 0.90)
	cs.border_color = badge_color
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(10)
	cs.content_margin_left = 8
	cs.content_margin_right = 8
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var icon_row := HBoxContainer.new()
	icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(icon_row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var asset_path: String = str(qdef.get("asset", ""))
	if not asset_path.is_empty():
		icon.texture = AssetPaths.load_texture(asset_path)
	icon_row.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = egg_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(badge_row)

	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = badge_color
	bs.set_corner_radius_all(6)
	bs.content_margin_left = 6
	bs.content_margin_right = 6
	bs.content_margin_top = 2
	bs.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", bs)
	badge_row.add_child(badge)
	var badge_lbl := Label.new()
	badge_lbl.text = quality_label
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", Color.WHITE)
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_lbl)

	var time_lbl := Label.new()
	time_lbl.text = _localized_text("egg_shop.incubation_time", "Time:") + " " + str(inc_hours) + "h"
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.add_theme_font_size_override("font_size", 10)
	time_lbl.add_theme_color_override("font_color", Color(0.68, 0.63, 0.50, 0.85))
	time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(time_lbl)

	var price_lbl := Label.new()
	price_lbl.text = str(price) + " R$"
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_lbl.add_theme_font_size_override("font_size", 13)
	price_lbl.add_theme_color_override("font_color", Color(0.95, 0.83, 0.38, 1.0))
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(price_lbl)

	var c_pct: String = str(int(round(float(rates.get("common", 0)))))
	var r_pct: String = str(int(round(float(rates.get("rare", 0)))))
	var ur_pct: String = str(int(round(float(rates.get("ultra_rare", 0)))))
	var e_pct: String = str(int(round(float(rates.get("exceptional", 0)))))
	var odds_lbl := Label.new()
	odds_lbl.text = "C:" + c_pct + "% R:" + r_pct + "%\nUR:" + ur_pct + "% E:" + e_pct + "%"
	odds_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	odds_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	odds_lbl.add_theme_font_size_override("font_size", 10)
	odds_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45, 0.85))
	odds_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(odds_lbl)

	var buy_btn := Button.new()
	buy_btn.text = _localized_text("egg_shop.buy", "Buy")
	buy_btn.focus_mode = Control.FOCUS_NONE
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.custom_minimum_size = Vector2(0, 32)
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sid: String = species_id
	var qid: String = quality_id
	buy_btn.pressed.connect(func() -> void:
		buy_btn.disabled = true
		var result: Dictionary = IncubationSystem.buy_species_egg(sid, qid)
		buy_btn.disabled = false
		if bool(result.get("success", false)):
			_show_toast("egg_shop.purchased", "Egg purchased!")
		else:
			_show_toast(str(result.get("error_key", "")), "Error.")
	)
	vbox.add_child(buy_btn)

	return card


# ─── Hatch results overlay ─────────────────────────────────────────────

func _add_hatch_results_overlay() -> void:
	_hatch_results_overlay = Control.new()
	_hatch_results_overlay.name = "HatchResultsOverlay"
	_hatch_results_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hatch_results_overlay.visible = false
	_hatch_results_overlay.z_index = 130
	add_child(_hatch_results_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_hatch_results_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "HRPanel"
	panel.anchor_left = 0.03
	panel.anchor_top = 0.05
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.95
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.07, 0.04, 0.97)
	ps.border_color = Color(0.80, 0.65, 0.20, 0.95)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.content_margin_left = 14
	ps.content_margin_right = 14
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	_hatch_results_overlay.add_child(panel)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	var title := Label.new()
	title.name = "HRTitle"
	title.text = _localized_text("hatch.title", "Hatching Results")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30, 1.0))
	outer.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "HRSubtitle"
	subtitle.text = _localized_text("hatch.subtitle", "New reptiles hatched!")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.80, 0.75, 0.55, 1.0))
	outer.add_child(subtitle)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.70, 0.55, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "HRScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "HRContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	_make_scroll_safe(content)

	var ok_row := HBoxContainer.new()
	ok_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ok_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(ok_row)

	var ok_btn := Button.new()
	ok_btn.name = "HROkBtn"
	ok_btn.text = _localized_text("hatch.ok", "OK")
	ok_btn.focus_mode = Control.FOCUS_NONE
	ok_btn.custom_minimum_size = Vector2(160, 46)
	ok_btn.add_theme_font_size_override("font_size", 16)
	ok_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ok_btn.pressed.connect(func() -> void: _hatch_results_overlay.visible = false)
	ok_row.add_child(ok_btn)


func _show_hatch_results(results: Array) -> void:
	if _hatch_results_overlay == null:
		return
	var content: VBoxContainer = _hatch_results_overlay.get_node_or_null(
		"HRPanel/HRScroll/HRContent") as VBoxContainer
	if content == null:
		return
	_clear_vbox(content)

	var lang: String = GameState.get_language()

	if results.is_empty():
		var lbl := Label.new()
		lbl.text = _localized_text("hatch.no_eggs", "No eggs hatched.")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.70, 0.65, 0.50, 1.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(lbl)
	else:
		for r_val in results:
			if typeof(r_val) == TYPE_DICTIONARY:
				content.add_child(_make_hatch_result_card(r_val as Dictionary, lang))

	var added_lbl := Label.new()
	added_lbl.text = _localized_text("hatch.added_to_storage", "Added to storage")
	added_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	added_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	added_lbl.add_theme_font_size_override("font_size", 13)
	added_lbl.add_theme_color_override("font_color", Color(0.60, 0.82, 0.55, 1.0))
	added_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(added_lbl)

	_hatch_results_overlay.visible = true


func _make_hatch_result_card(r: Dictionary, _lang: String) -> Control:
	var rarity: String = str(r.get("rarity", "common"))
	var is_new: bool = bool(r.get("is_new_discovery", false))

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	var border_col: Color = _rarity_color(rarity)
	cs.bg_color = Color(border_col.r * 0.15, border_col.g * 0.12, border_col.b * 0.08, 0.85)
	cs.border_color = border_col
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(10)
	cs.content_margin_left = 10
	cs.content_margin_right = 10
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(60, 60)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_path: String = str(r.get("portrait_path", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait.texture = AssetPaths.load_texture(portrait_path)
	hbox.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)

	var species_id: String = str(r.get("species_id", ""))
	var variant_id: String = str(r.get("variant_id", ""))
	var species_name: String = species_id
	var reptile_data: Dictionary = ReptileSystem.get_reptile(species_id)
	if not reptile_data.is_empty():
		var name_key: String = str(reptile_data.get("name_key", ""))
		if not name_key.is_empty():
			var localized: String = LocalizationSystem.tr_key(name_key)
			if not localized.is_empty() and localized != name_key:
				species_name = localized
	var variant_name: String = variant_id
	var variant_data: Dictionary = ReptileSystem.get_variant(variant_id)
	if not variant_data.is_empty():
		var vname_key: String = str(variant_data.get("name_key", ""))
		if not vname_key.is_empty():
			var localized: String = LocalizationSystem.tr_key(vname_key)
			if not localized.is_empty() and localized != vname_key:
				variant_name = localized

	var name_lbl := Label.new()
	name_lbl.text = species_name + " — " + variant_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var rarity_lbl := Label.new()
	var sex_key: String = "sex." + str(r.get("sex", "male"))
	var sex_text: String = _localized_text(sex_key, str(r.get("sex", "male")))
	rarity_lbl.text = _localized_rarity(rarity) + "  •  " + sex_text
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	rarity_lbl.add_theme_color_override("font_color", border_col)
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(rarity_lbl)

	if rarity == "exceptional":
		var hl_lbl := Label.new()
		hl_lbl.text = _localized_text("hatch.exceptional", "Exceptional hatch!")
		hl_lbl.add_theme_font_size_override("font_size", 12)
		hl_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.20, 1.0))
		hl_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(hl_lbl)
	elif rarity == "ultra_rare":
		var hl_lbl := Label.new()
		hl_lbl.text = _localized_text("hatch.ultra_rare", "Ultra Rare hatch!")
		hl_lbl.add_theme_font_size_override("font_size", 12)
		hl_lbl.add_theme_color_override("font_color", Color(0.80, 0.40, 1.0, 1.0))
		hl_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(hl_lbl)

	if is_new:
		var disc_lbl := Label.new()
		disc_lbl.text = _localized_text("hatch.new_discovery", "New discovery!")
		disc_lbl.add_theme_font_size_override("font_size", 12)
		disc_lbl.add_theme_color_override("font_color", Color(0.30, 0.95, 0.50, 1.0))
		disc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(disc_lbl)

	return card


# ─── Incubator upgrades overlay ────────────────────────────────────────

func _add_upgrades_overlay() -> void:
	_upgrades_overlay = Control.new()
	_upgrades_overlay.name = "UpgradesOverlay"
	_upgrades_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrades_overlay.visible = false
	_upgrades_overlay.z_index = 125
	add_child(_upgrades_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrades_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "UPPanel"
	panel.anchor_left = 0.03
	panel.anchor_top = 0.06
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.95
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.07, 0.04, 0.97)
	ps.border_color = Color(0.70, 0.52, 0.25, 0.95)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.content_margin_left = 14
	ps.content_margin_right = 14
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	_upgrades_overlay.add_child(panel)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.text = _localized_text("incubator.upgrades_title", "Incubator Upgrades")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "UPScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "UPContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_make_scroll_safe(content)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(close_row)

	var close_btn := Button.new()
	close_btn.text = _localized_text("button.back", "Back")
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(130, 42)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: _upgrades_overlay.visible = false)
	close_row.add_child(close_btn)


func _populate_upgrades_overlay() -> void:
	if _upgrades_overlay == null:
		return
	var content: VBoxContainer = _upgrades_overlay.get_node_or_null(
		"UPPanel/UPScroll/UPContent") as VBoxContainer
	if content == null:
		return
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	if not has_node("/root/IncubatorUpgradeSystem"):
		var lbl := Label.new()
		lbl.text = "IncubatorUpgradeSystem not available."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(lbl)
		return

	var sys: Node = get_node("/root/IncubatorUpgradeSystem")
	if not sys.has_method("get_upgrade_definitions"):
		return
	var defs: Array = sys.call("get_upgrade_definitions") as Array
	for def_val in defs:
		if typeof(def_val) == TYPE_DICTIONARY:
			content.add_child(_make_incubator_upgrade_card(def_val as Dictionary))
	_make_scroll_safe(content)


func _make_incubator_upgrade_card(upgrade: Dictionary) -> Control:
	var upgrade_id: String = str(upgrade.get("id", ""))
	var sys: Node = get_node("/root/IncubatorUpgradeSystem")
	var level: int = int(sys.call("get_level", upgrade_id))
	var max_level: int = int(upgrade.get("max_level", 5))
	var cost: int = int(sys.call("get_cost", upgrade_id))
	var is_maxed: bool = level >= max_level

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.13, 0.09, 0.06, 0.88)
	cs.border_color = Color(0.30, 0.75, 0.35, 0.80) if is_maxed else Color(0.60, 0.45, 0.22, 0.75)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(10)
	cs.content_margin_left = 10
	cs.content_margin_right = 10
	cs.content_margin_top = 10
	cs.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", cs)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 6)
	card.add_child(main_vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	main_vbox.add_child(top_row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path: String = str(upgrade.get("icon_path", ""))
	if not icon_path.is_empty():
		icon.texture = AssetPaths.load_texture(icon_path)
	top_row.add_child(icon)

	var name_desc_vbox := VBoxContainer.new()
	name_desc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_desc_vbox.add_theme_constant_override("separation", 3)
	top_row.add_child(name_desc_vbox)

	var name_lbl := Label.new()
	name_lbl.text = _localized_text(str(upgrade.get("name_key", "")), upgrade_id)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_desc_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = _localized_text(str(upgrade.get("description_key", "")), "")
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.68, 0.62, 0.50, 0.85))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_desc_vbox.add_child(desc_lbl)

	var level_lbl := Label.new()
	level_lbl.text = _localized_text("upgrade.level_label", "Level") + ": " + str(level) + "/" + str(max_level)
	level_lbl.add_theme_font_size_override("font_size", 12)
	level_lbl.add_theme_color_override("font_color", Color(0.80, 0.75, 0.60, 1.0))
	level_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(level_lbl)

	var effect_text: String = _get_incubator_upgrade_effect_text(upgrade_id, level, upgrade)
	if not effect_text.is_empty():
		var effect_lbl := Label.new()
		effect_lbl.text = effect_text
		effect_lbl.add_theme_font_size_override("font_size", 13)
		effect_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 0.55, 1.0))
		effect_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_vbox.add_child(effect_lbl)

	var buy_row := HBoxContainer.new()
	buy_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(buy_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy_row.add_child(spacer)

	if is_maxed:
		var max_lbl := Label.new()
		max_lbl.text = _localized_text("ui.upgrade_max", "MAX")
		max_lbl.add_theme_font_size_override("font_size", 13)
		max_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.40, 1.0))
		max_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buy_row.add_child(max_lbl)
	else:
		var cost_lbl := Label.new()
		cost_lbl.text = str(cost) + " R$"
		cost_lbl.add_theme_font_size_override("font_size", 13)
		cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.83, 0.38, 1.0))
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buy_row.add_child(cost_lbl)

		var can_afford: bool = EconomySystem.can_afford("repticash", cost)
		var buy_btn := Button.new()
		buy_btn.text = _localized_text("button.buy", "Kup")
		buy_btn.focus_mode = Control.FOCUS_NONE
		buy_btn.disabled = not can_afford
		buy_btn.custom_minimum_size = Vector2(70, 32)
		buy_btn.add_theme_font_size_override("font_size", 12)
		buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var uid: String = upgrade_id
		buy_btn.pressed.connect(func() -> void:
			var result: Dictionary = (get_node("/root/IncubatorUpgradeSystem") as Node).call("buy", uid) as Dictionary
			if bool(result.get("success", false)):
				_populate_upgrades_overlay()
			else:
				_show_toast(str(result.get("message_key", "")), "Error.")
		)
		buy_row.add_child(buy_btn)

	return card


func _get_incubator_upgrade_effect_text(upgrade_id: String, level: int, upgrade: Dictionary) -> String:
	if level <= 0:
		return ""
	var effect_per_level: float = float(upgrade.get("effect_per_level", 0.0))
	match upgrade_id:
		"incubator_faster_connection":
			var pct: int = int(round(float(level) * effect_per_level * 100.0))
			return _localized_text("ui.incubator_faster_connection_effect", "Breeding time: -{value}%").replace("{value}", str(pct))
		"incubator_faster_incubation":
			var pct: int = int(round(float(level) * effect_per_level * 100.0))
			return _localized_text("ui.incubator_faster_incubation_effect", "Incubation time: -{value}%").replace("{value}", str(pct))
		"incubator_humidity_longer":
			var pct: int = int(round(float(level) * effect_per_level * 100.0))
			return _localized_text("ui.incubator_humidity_longer_effect", "Humidity decay: -{value}%").replace("{value}", str(pct))
		"incubator_more_eggs":
			var current_max: int = IncubationSystem.get_max_eggs_per_container()
			return _localized_text("ui.incubator_more_eggs_effect", "Max eggs: {value}").replace("{value}", str(current_max))
	return ""


# ─── Language change ────────────────────────────────────────────────────

func _on_language_changed(_language: String) -> void:
	_rebuild_layout()
