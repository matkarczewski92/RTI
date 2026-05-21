extends Control

signal biome_map_requested

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")
const TOP_BAR_SCENE := preload("res://scenes/ui/TopBar.tscn")
const BOTTOM_NAV_SCENE := preload("res://scenes/ui/BottomNav.tscn")
const SETTINGS_MODAL_SCRIPT := preload("res://scripts/ui/SettingsModal.gd")

const BACKGROUND_PATH := "res://assets/art/biomes/incubator_background_long.png"
const TOP_BAR_ART_PATH := "res://assets/art/ui/top_bar_incubation.png"
const BOTTOM_MENU_ART_PATH := "res://assets/art/ui/bottom_menu_incubation.png"
const BIOMES_CONFIG_PATH := "res://data/biomes.json"
const INCUBATOR_CONFIG_PATH := "res://data/incubator.json"
const INCUBATOR_LAYOUT_PATH := "res://data/incubator_layout.json"
const INCUBATOR_BIOME_ID := "incubator"

const PLUS_ICON_PATH := "res://assets/art/incubator/empty_incubation_or_connection.png"
const CONNECTION_IN_PROGRESS_PATH := "res://assets/art/incubator/in_progress_icons/connection_in_progress.png"
const INCUBATION_IN_PROGRESS_PATH := "res://assets/art/incubator/in_progress_icons/incubation_in_progress.png"

const EGG_PATH := "res://assets/art/incubator/eggs/egg.png"
const EGG_SHOP_COMMON_PATH := "res://assets/art/incubator/eggs/shop_egg_common.png"
const EGG_SHOP_RARE_PATH := "res://assets/art/incubator/eggs/shop_egg_rare.png"
const EGG_SHOP_ULTRA_RARE_PATH := "res://assets/art/incubator/eggs/shop_egg_ultra_rare.png"
const EGG_SHOP_EXCEPTIONAL_PATH := "res://assets/art/incubator/eggs/shop_egg_exceptional.png"

const LAYOUT_REF_W := 754.0
const LAYOUT_REF_H := 2084.0
const PLAY_AREA_REF_TOP := 150.722775   # TOP_BAR_HEIGHT in reference pixels
const TOP_BAR_HEIGHT := 150.722775
const TOP_BAR_Y_OFFSET := -10.0
const TOP_BAR_EXTRA_HEIGHT_RATIO := 0.20
const BOTTOM_MENU_HEIGHT := 226.157092875
const SCROLL_DRAG_THRESHOLD := 12.0
const SCROLL_WHEEL_STEP := 90.0

const SLOT_HITBOX_PAD := 40.0   # extra px added to max(icon_size, habitat_size) for the hitbox
const SLOT_ICON_DEFAULT := 80.0
const SLOT_HABITAT_DEFAULT := 80.0

# ─── UI Scale Constants — Full HD portrait 1080×1920 ──────────────────────────
# Tuning: adjust these constants to change layout across all Incubator overlays.
const TITLE_FONT_SIZE      := 45   # overlay / modal titles
const SECTION_FONT_SIZE    := 34   # section / column headers
const ROW_TITLE_FONT_SIZE  := 32   # card / row primary names
const BODY_FONT_SIZE       := 25   # body text, descriptions, progress
const META_FONT_SIZE       := 22   # small metadata: biome, source, time, odds
const BUTTON_FONT_SIZE     := 25   # button labels
const BUTTON_HEIGHT        := 88   # standard action / confirm button height
const BACK_BTN_MIN_W       := 253  # Back / Cancel / Close button min width
const ICON_SIZE_CARD       := 140  # portrait icon in list cards (storage, select)
const ICON_SIZE_QUALITY    := 140  # egg icon in quality 2×2 grid
const ICON_SIZE_UPGRADE    := 113  # upgrade card icon
const EGG_SHOP_SPECIES_PORTRAIT_SIZE := 82.0
const EGG_SHOP_SPECIES_PORTRAIT_SCALE := 2.0
const EGG_SHOP_SPECIES_TEXT_SHIFT_RATIO := 0.20
const EGG_SHOP_SPECIES_SELECT_BUTTON_WIDTH := 100.0
const EGG_SHOP_SPECIES_SELECT_BUTTON_SCALE := 2.0
const EGG_SHOP_QUALITY_ICON_SCALE := 1.35
const EGG_SHOP_QUALITY_BUY_FONT_SCALE := 2.0
const CARD_CONTENT_MARGIN  := 22   # PanelContainer content_margin_* for cards
const LIST_SEPARATION      := 15   # VBoxContainer separation between cards
const CARD_SEPARATION      := 9    # inner card VBoxContainer separation
# ──────────────────────────────────────────────────────────────────────────────

var _config: Dictionary = {}
var _biome_config: Dictionary = {}
var _layout: Dictionary = {}
var _layout_reference_size: Vector2 = Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
var _scroll_content_reference_size: Vector2 = Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
var _scroll_map_layer: Control
var _scroll_offset: float = 0.0
var _scroll_max: float = 0.0
var _scroll_drag_active: bool = false
var _scroll_drag_start: Vector2 = Vector2.ZERO
var _scroll_drag_start_offset: float = 0.0
var _scroll_was_drag: bool = false
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
var _select_species_id: String = ""
var _selected_female_id: String = ""
var _selected_male_id: String = ""
var _select_is_long: bool = false
var _select_start_in_progress: bool = false

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
var _incubation_load_in_progress: bool = false

# Egg shop
var _egg_shop_overlay: Control
var _egg_shop_content: VBoxContainer
var _egg_shop_title_label: Label
var _egg_shop_step: int = 0
var _egg_shop_selected_species: Dictionary = {}
var _hatch_results_overlay: Control
var _quests_overlay: Control

var _settings_modal: Control
var _upgrades_overlay: Control


func _ready() -> void:
	ReptileSystem.sync_discovered_variants_from_owned_reptiles()
	_load_config()
	_load_biome_config()
	_load_incubator_layout()
	_migrate_overflow_slot_state()
	_build_layout()
	_start_tick_timer()
	if ReptileSystem.has_signal("reptile_leveled_up") and not ReptileSystem.reptile_leveled_up.is_connected(_on_reptile_leveled_up):
		ReptileSystem.reptile_leveled_up.connect(_on_reptile_leveled_up)
	if not GameState.language_changed.is_connected(_on_language_changed):
		GameState.language_changed.connect(_on_language_changed)


func _rebuild_layout_preserving_scroll(scroll_offset: float) -> void:
	_rebuild_layout()
	_scroll_to(scroll_offset)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree() and _scroll_map_layer != null:
		call_deferred("_rebuild_layout_preserving_scroll", _scroll_offset)


func _input(event: InputEvent) -> void:
	if _scroll_map_layer == null or _is_any_overlay_open():
		_scroll_drag_active = false
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _is_scroll_input_position(mb.position):
				_scroll_drag_start = mb.position
				_scroll_drag_start_offset = _scroll_offset
				_scroll_drag_active = true
				_scroll_was_drag = false
			elif not mb.pressed:
				_scroll_drag_active = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed and _is_scroll_input_position(mb.position):
			_scroll_to(_scroll_offset - SCROLL_WHEEL_STEP)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed and _is_scroll_input_position(mb.position):
			_scroll_to(_scroll_offset + SCROLL_WHEEL_STEP)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _scroll_drag_active:
		var delta_y := (event as InputEventMouseMotion).position.y - _scroll_drag_start.y
		if not _scroll_was_drag and absf(delta_y) > SCROLL_DRAG_THRESHOLD:
			_scroll_was_drag = true
		if _scroll_was_drag:
			_scroll_to(_scroll_drag_start_offset - delta_y)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _is_scroll_input_position(touch.position):
			_scroll_drag_start = touch.position
			_scroll_drag_start_offset = _scroll_offset
			_scroll_drag_active = true
			_scroll_was_drag = false
		elif not touch.pressed:
			_scroll_drag_active = false
	elif event is InputEventScreenDrag and _scroll_drag_active:
		var drag := event as InputEventScreenDrag
		var delta_y := drag.position.y - _scroll_drag_start.y
		if not _scroll_was_drag and absf(delta_y) > SCROLL_DRAG_THRESHOLD:
			_scroll_was_drag = true
		if _scroll_was_drag:
			_scroll_to(_scroll_drag_start_offset - delta_y)
			get_viewport().set_input_as_handled()


func _is_scroll_input_position(position: Vector2) -> bool:
	var viewport_height: float = get_viewport_rect().size.y
	return position.y >= _get_top_bar_bottom_y() and position.y <= viewport_height - BOTTOM_MENU_HEIGHT


func _is_any_overlay_open() -> bool:
	return (
		(_storage_overlay != null and _storage_overlay.visible)
		or (_select_overlay != null and _select_overlay.visible)
		or (_incubation_panel != null and _incubation_panel.visible)
		or (_egg_shop_overlay != null and _egg_shop_overlay.visible)
		or (_hatch_results_overlay != null and _hatch_results_overlay.visible)
		or (_quests_overlay != null and _quests_overlay.visible)
		or (_upgrades_overlay != null and _upgrades_overlay.visible)
		or (_settings_modal != null and is_instance_valid(_settings_modal))
	)


func _load_config() -> void:
	_config = {"breeding_chambers": 4, "incubation_containers": 6}
	var file := FileAccess.open(INCUBATOR_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) == TYPE_DICTIONARY:
		_config = data as Dictionary


func _load_biome_config() -> void:
	_biome_config = {}
	var file := FileAccess.open(BIOMES_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return

	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_ARRAY:
		return

	var biomes: Array = data as Array
	for entry in biomes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var biome: Dictionary = entry as Dictionary
		if str(biome.get("id", "")) == INCUBATOR_BIOME_ID:
			_biome_config = biome
			return


func _load_incubator_layout() -> void:
	_layout = {}
	_layout_reference_size = Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
	_scroll_content_reference_size = Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
	var file := FileAccess.open(INCUBATOR_LAYOUT_PATH, FileAccess.READ)
	if file == null:
		push_warning("IncubatorView: incubator_layout.json not found, using fallback.")
		_layout = _get_fallback_layout()
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) == TYPE_DICTIONARY:
		var root: Dictionary = data as Dictionary
		var ref_value: Variant = root.get("reference_resolution", {})
		if typeof(ref_value) == TYPE_DICTIONARY:
			var ref_dict: Dictionary = ref_value as Dictionary
			_layout_reference_size = Vector2(
				float(ref_dict.get("width", LAYOUT_REF_W)),
				float(ref_dict.get("height", LAYOUT_REF_H))
			)

		var section: Variant = root.get("incubator", null)
		if typeof(section) == TYPE_DICTIONARY:
			_layout = (section as Dictionary).duplicate(true)
			var content_value: Variant = _layout.get("scroll_content_size", {})
			if typeof(content_value) == TYPE_DICTIONARY:
				var content_dict: Dictionary = content_value as Dictionary
				_scroll_content_reference_size = Vector2(
					float(content_dict.get("width", _layout_reference_size.x)),
					float(content_dict.get("height", _layout_reference_size.y))
				)
			else:
				_scroll_content_reference_size = _layout_reference_size
			return
	push_warning("IncubatorView: incubator_layout.json malformed, using fallback.")
	_layout = _get_fallback_layout()


func _get_fallback_layout() -> Dictionary:
	_layout_reference_size = Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
	_scroll_content_reference_size = Vector2(LAYOUT_REF_W, LAYOUT_REF_H)
	return {
		"background_path": BACKGROUND_PATH,
		"scroll_content_size": {"width": LAYOUT_REF_W, "height": LAYOUT_REF_H},
		"slot_defaults": {
			"plus_size": 74,
			"overlay_padding": 0,
			"overlay_scale": 1.0,
			"overlay_fit": "scale"
		},
		"connection_slots": [
			{"id": "connection_1", "x": 89, "y": 314, "w": 280, "h": 308, "plus_size": 37},
			{"id": "connection_2", "x": 386, "y": 314, "w": 280, "h": 308, "plus_size": 37},
			{"id": "connection_3", "x": 89, "y": 638, "w": 280, "h": 308, "plus_size": 37},
			{"id": "connection_4", "x": 386, "y": 638, "w": 280, "h": 308, "plus_size": 37}
		],
		"incubation_slots": [
			{"id": "incubation_1", "x": 77, "y": 1190, "w": 232, "h": 212, "plus_size": 26},
			{"id": "incubation_2", "x": 445, "y": 1190, "w": 232, "h": 212, "plus_size": 26},
			{"id": "incubation_3", "x": 77, "y": 1402, "w": 232, "h": 212, "plus_size": 26},
			{"id": "incubation_4", "x": 445, "y": 1402, "w": 232, "h": 212, "plus_size": 26},
			{"id": "incubation_5", "x": 77, "y": 1614, "w": 232, "h": 212, "plus_size": 26},
			{"id": "incubation_6", "x": 445, "y": 1614, "w": 232, "h": 212, "plus_size": 26}
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
	_add_scrollable_map()
	_add_top_bar()
	_add_bottom_nav()
	_add_storage_overlay()
	_add_select_overlay()
	_add_incubation_panel()
	_add_egg_shop_overlay()
	_add_hatch_results_overlay()
	_add_upgrades_overlay()
	_add_quests_overlay()
	_add_toast()


func _rebuild_layout() -> void:
	_load_incubator_layout()
	_migrate_overflow_slot_state()
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
	_select_species_id = ""
	_selected_female_id = ""
	_selected_male_id = ""
	_select_is_long = false
	_select_start_in_progress = false
	_scroll_map_layer = null
	_scroll_drag_active = false
	_scroll_was_drag = false
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
	_incubation_load_in_progress = false
	_egg_shop_overlay = null
	_egg_shop_content = null
	_egg_shop_title_label = null
	_egg_shop_step = 0
	_egg_shop_selected_species = {}
	_hatch_results_overlay = null
	_quests_overlay = null
	_upgrades_overlay = null
	_build_layout()


# ─── Background ────────────────────────────────────────────────────────

func _add_background() -> void:
	_add_scrollable_map()


func _get_map_fit_scale() -> float:
	var viewport_width: float = get_viewport_rect().size.x
	if viewport_width <= 0.0 or _scroll_content_reference_size.x <= 0.0:
		return 1.0
	return viewport_width / _scroll_content_reference_size.x


func _get_top_bar_bottom_y() -> float:
	return TOP_BAR_Y_OFFSET + TOP_BAR_HEIGHT * (1.0 + TOP_BAR_EXTRA_HEIGHT_RATIO)


func _add_scrollable_map() -> void:
	_scroll_map_layer = Control.new()
	_scroll_map_layer.name = "IncubatorScrollMapLayer"
	_scroll_map_layer.anchor_left = 0.0
	_scroll_map_layer.anchor_top = 0.0
	_scroll_map_layer.anchor_right = 0.0
	_scroll_map_layer.anchor_bottom = 0.0
	_scroll_map_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_scroll_map_layer)

	_add_scrollable_background()
	_add_play_area()
	_compute_scroll_max()
	_scroll_to(_scroll_offset)


func _add_scrollable_background() -> void:
	if _scroll_map_layer == null:
		return

	var bg_path: String = str(_layout.get("background_path", _biome_config.get("background_path", BACKGROUND_PATH)))
	var texture: Texture2D = AssetPaths.load_texture(bg_path)
	var scale: float = _get_map_fit_scale()
	var bg_size: Vector2 = _scroll_content_reference_size * scale

	_scroll_map_layer.offset_left = 0.0
	_scroll_map_layer.offset_top = 0.0
	_scroll_map_layer.offset_right = bg_size.x
	_scroll_map_layer.offset_bottom = bg_size.y
	_scroll_map_layer.custom_minimum_size = bg_size

	var bg := TextureRect.new()
	bg.name = "IncubatorBackground"
	bg.texture = texture
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 0.0
	bg.anchor_bottom = 0.0
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = bg_size.x
	bg.offset_bottom = bg_size.y
	_scroll_map_layer.add_child(bg)

	if texture == null:
		var fallback := ColorRect.new()
		fallback.name = "IncubatorBackgroundFallback"
		fallback.color = Color(0.15, 0.10, 0.07, 1.0)
		fallback.anchor_left = 0.0
		fallback.anchor_top = 0.0
		fallback.anchor_right = 0.0
		fallback.anchor_bottom = 0.0
		fallback.offset_right = bg_size.x
		fallback.offset_bottom = bg_size.y
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scroll_map_layer.add_child(fallback)
		_scroll_map_layer.move_child(fallback, 0)


func _compute_scroll_max() -> void:
	if _scroll_map_layer == null:
		_scroll_max = 0.0
		return
	var viewport_height: float = get_viewport_rect().size.y
	var fixed_bottom_height: float = BOTTOM_MENU_HEIGHT
	_scroll_max = max(0.0, _scroll_map_layer.custom_minimum_size.y - max(1.0, viewport_height - fixed_bottom_height))
	_scroll_to(_scroll_offset)


func _scroll_to(offset: float) -> void:
	_scroll_offset = clamp(offset, 0.0, _scroll_max)
	if _scroll_map_layer == null:
		return
	var map_height: float = _scroll_map_layer.custom_minimum_size.y
	_scroll_map_layer.offset_top = -_scroll_offset
	_scroll_map_layer.offset_bottom = map_height - _scroll_offset


func _add_top_bar() -> void:
	var top_bar: Control = TOP_BAR_SCENE.instantiate() as Control
	top_bar.name = "TopBar"
	if "art_path" in top_bar:
		top_bar.art_path = str(_biome_config.get("top_bar_path", TOP_BAR_ART_PATH))
	if "biome_id" in top_bar:
		top_bar.biome_id = INCUBATOR_BIOME_ID
	if "top_bar_ui_positions" in top_bar:
		var top_bar_positions: Variant = _biome_config.get("top_bar_ui_positions", {})
		if typeof(top_bar_positions) == TYPE_DICTIONARY:
			top_bar.top_bar_ui_positions = top_bar_positions as Dictionary
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = TOP_BAR_Y_OFFSET
	top_bar.offset_bottom = _get_top_bar_bottom_y()
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
	if _scroll_map_layer == null:
		return

	var breeding_defs: Array = _get_connection_slot_defs()
	var incubation_defs: Array = _get_incubation_slot_defs()

	# Breeding chamber slots
	for i in range(breeding_defs.size()):
		var def: Variant = breeding_defs[i]
		if typeof(def) == TYPE_DICTIONARY:
			var node := _add_slot(_scroll_map_layer, def as Dictionary, i, "breeding")
			_breeding_slot_nodes[i] = node

	# Incubation container slots
	for i in range(incubation_defs.size()):
		var def: Variant = incubation_defs[i]
		if typeof(def) == TYPE_DICTIONARY:
			var node := _add_slot(_scroll_map_layer, def as Dictionary, i, "incubation")
			_incubation_slot_nodes[i] = node


func _get_connection_slot_defs() -> Array:
	var defs: Variant = _layout.get("connection_slots", _layout.get("breeding_chambers", []))
	if typeof(defs) == TYPE_ARRAY:
		return defs as Array
	return []


func _get_incubation_slot_defs() -> Array:
	var defs: Variant = _layout.get("incubation_slots", _layout.get("incubation_containers", []))
	if typeof(defs) == TYPE_ARRAY:
		return defs as Array
	return []


func _migrate_overflow_slot_state() -> void:
	_migrate_overflow_dictionary_slots("breeding_chambers", _get_connection_slot_defs().size(), "breeding")
	_migrate_overflow_dictionary_slots("incubation_containers", _get_incubation_slot_defs().size(), "incubation")


func _migrate_overflow_dictionary_slots(state_key: String, visible_count: int, slot_type: String) -> void:
	if visible_count <= 0:
		return
	var value: Variant = GameState.get_value(state_key, {})
	if typeof(value) != TYPE_DICTIONARY:
		return

	var slots: Dictionary = (value as Dictionary).duplicate(true)
	var changed: bool = false
	for raw_key in slots.keys():
		var slot_index: int = int(str(raw_key))
		if slot_index < visible_count:
			continue
		var slot_value: Variant = slots.get(raw_key)
		if _is_saved_slot_empty(slot_value):
			continue

		var target_index: int = _find_empty_visible_slot(slots, visible_count)
		if target_index >= 0:
			slots[str(target_index)] = slot_value
			slots.erase(raw_key)
			changed = true
			push_warning("IncubatorView: migrated hidden " + slot_type + " slot " + str(raw_key) + " to visible slot " + str(target_index) + ".")
		else:
			push_warning("IncubatorView: saved " + slot_type + " slot " + str(raw_key) + " is outside the visible layout and was preserved hidden.")

	if changed:
		GameState.set_value(state_key, slots)
		SaveSystem.save_game()


func _find_empty_visible_slot(slots: Dictionary, visible_count: int) -> int:
	for i in range(visible_count):
		if not slots.has(str(i)) or _is_saved_slot_empty(slots.get(str(i))):
			return i
	return -1


func _is_saved_slot_empty(slot_value: Variant) -> bool:
	if typeof(slot_value) != TYPE_DICTIONARY:
		return true
	var slot: Dictionary = slot_value as Dictionary
	return str(slot.get("state", "empty")) == "empty"


func _add_section_label(parent: Control, key: String, fallback: String,
		x_ref: float, y_ref: float, play_ref_h: float) -> void:
	var ax := x_ref / LAYOUT_REF_W
	var ay := clampf((y_ref - PLAY_AREA_REF_TOP) / play_ref_h, 0.0, 1.0)

	var label := Label.new()
	label.text = _localized_text(key, fallback)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
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


func _add_slot(parent: Control, slot_def: Dictionary, index: int, slot_type: String) -> Control:
	var scale: float = _get_map_fit_scale()
	var defaults: Dictionary = _get_slot_defaults()
	var rect: Rect2 = _get_slot_rect(slot_def)
	var slot_size: Vector2 = rect.size * scale
	var plus_size: float = float(slot_def.get("plus_size", defaults.get("plus_size", SLOT_ICON_DEFAULT))) * scale
	var overlay_padding: float = float(slot_def.get("overlay_padding", defaults.get("overlay_padding", 0.0))) * scale
	var overlay_scale: float = float(slot_def.get("overlay_scale", defaults.get("overlay_scale", 1.0)))
	var overlay_fit: String = str(slot_def.get("overlay_fit", defaults.get("overlay_fit", "scale")))
	var plus_offset := Vector2(
		float(slot_def.get("plus_offset_x", defaults.get("plus_offset_x", 0.0))) * scale,
		float(slot_def.get("plus_offset_y", defaults.get("plus_offset_y", 0.0))) * scale
	)

	var container := Control.new()
	container.name = slot_type + "_slot_" + str(index)
	container.anchor_left = 0.0
	container.anchor_top = 0.0
	container.anchor_right = 0.0
	container.anchor_bottom = 0.0
	container.offset_left = rect.position.x * scale
	container.offset_top = rect.position.y * scale
	container.offset_right = container.offset_left + slot_size.x
	container.offset_bottom = container.offset_top + slot_size.y
	container.custom_minimum_size = slot_size
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.set_meta("slot_size", slot_size)
	container.set_meta("plus_size", plus_size)
	container.set_meta("plus_offset", plus_offset)
	container.set_meta("overlay_padding", overlay_padding)
	container.set_meta("overlay_scale", overlay_scale)
	container.set_meta("overlay_fit", overlay_fit)
	parent.add_child(container)

	var icon := TextureRect.new()
	icon.name = "SlotIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	var timer_label := Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", max(14, int(round(17.0 * scale))))
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

func _get_slot_defaults() -> Dictionary:
	var defaults_value: Variant = _layout.get("slot_defaults", {})
	if typeof(defaults_value) == TYPE_DICTIONARY:
		return defaults_value as Dictionary
	return {}


func _get_slot_rect(slot_def: Dictionary) -> Rect2:
	if slot_def.has("w") and slot_def.has("h"):
		return Rect2(
			Vector2(float(slot_def.get("x", 0.0)), float(slot_def.get("y", 0.0))),
			Vector2(float(slot_def.get("w", SLOT_ICON_DEFAULT)), float(slot_def.get("h", SLOT_ICON_DEFAULT)))
		)

	var raw_x: float = float(slot_def.get("x", _layout_reference_size.x * 0.5))
	var raw_y: float = float(slot_def.get("y", _layout_reference_size.y * 0.5))
	var icon_size: float = float(slot_def.get("icon_size", SLOT_ICON_DEFAULT))
	var habitat_size: float = float(slot_def.get("habitat_size", SLOT_HABITAT_DEFAULT))
	var size: float = max(icon_size + SLOT_HITBOX_PAD, habitat_size)
	return Rect2(Vector2(raw_x - size * 0.5, raw_y - size * 0.5), Vector2(size, size))


func _get_vector2_meta(container: Control, key: String, fallback: Vector2) -> Vector2:
	var value: Variant = container.get_meta(key, fallback)
	if typeof(value) == TYPE_VECTOR2:
		return value as Vector2
	return fallback


func _apply_plus_visual(icon: TextureRect, container: Control, modulate: Color) -> void:
	var slot_size: Vector2 = _get_vector2_meta(container, "slot_size", container.size)
	var plus_size: float = float(container.get_meta("plus_size", SLOT_ICON_DEFAULT))
	var plus_offset: Vector2 = _get_vector2_meta(container, "plus_offset", Vector2.ZERO)
	var half: float = plus_size * 0.5
	var center: Vector2 = slot_size * 0.5 + plus_offset
	icon.anchor_left = 0.0
	icon.anchor_top = 0.0
	icon.anchor_right = 0.0
	icon.anchor_bottom = 0.0
	icon.offset_left = center.x - half
	icon.offset_top = center.y - half
	icon.offset_right = center.x + half
	icon.offset_bottom = center.y + half
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
	icon.modulate = modulate


func _apply_overlay_visual(icon: TextureRect, container: Control, texture_path: String, modulate: Color) -> void:
	var slot_size: Vector2 = _get_vector2_meta(container, "slot_size", container.size)
	var padding: float = float(container.get_meta("overlay_padding", 0.0))
	var overlay_scale: float = float(container.get_meta("overlay_scale", 1.0))
	var overlay_size: Vector2 = Vector2(
		max(1.0, slot_size.x - padding * 2.0),
		max(1.0, slot_size.y - padding * 2.0)
	) * overlay_scale
	var center: Vector2 = slot_size * 0.5
	icon.anchor_left = 0.0
	icon.anchor_top = 0.0
	icon.anchor_right = 0.0
	icon.anchor_bottom = 0.0
	icon.offset_left = center.x - overlay_size.x * 0.5
	icon.offset_top = center.y - overlay_size.y * 0.5
	icon.offset_right = center.x + overlay_size.x * 0.5
	icon.offset_bottom = center.y + overlay_size.y * 0.5
	icon.stretch_mode = _slot_stretch_mode(str(container.get_meta("overlay_fit", "scale")))
	icon.texture = AssetPaths.load_texture(texture_path)
	if icon.texture == null:
		icon.texture = AssetPaths.load_texture(PLUS_ICON_PATH)
	icon.modulate = modulate


func _slot_stretch_mode(mode: String):
	match mode:
		"keep_aspect":
			return TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		"cover":
			return TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_:
			return TextureRect.STRETCH_SCALE


func _refresh_slot(container: Control, index: int, slot_type: String) -> void:
	var icon: TextureRect = container.get_node_or_null("SlotIcon") as TextureRect
	var timer_label: Label = container.get_node_or_null("TimerLabel") as Label
	if icon == null or timer_label == null:
		return

	if slot_type == "incubation":
		var containers: Dictionary = IncubationSystem.get_containers()
		var cv: Variant = containers.get(str(index), null)
		if cv == null or typeof(cv) != TYPE_DICTIONARY:
			_apply_plus_visual(icon, container, Color.WHITE)
			timer_label.text = ""
			return
		var ic: Dictionary = cv as Dictionary
		var ic_state: String = str(ic.get("state", "empty"))
		match ic_state:
			"loaded":
				_apply_overlay_visual(icon, container, INCUBATION_IN_PROGRESS_PATH, Color(0.82, 0.94, 1.0, 1.0))
				timer_label.text = str(int(ic.get("egg_count", 0))) + " jaj"
			"running":
				_apply_overlay_visual(icon, container, INCUBATION_IN_PROGRESS_PATH, Color.WHITE)
				var rem: int = IncubationSystem.get_remaining_seconds(ic)
				timer_label.text = _format_countdown(rem)
			"paused_low_humidity":
				_apply_overlay_visual(icon, container, INCUBATION_IN_PROGRESS_PATH, Color(1.0, 0.72, 0.20, 1.0))
				var hum: int = int(float(ic.get("humidity_percent", 0.0)))
				timer_label.text = str(hum) + "%"
			"failed_dry":
				_apply_overlay_visual(icon, container, INCUBATION_IN_PROGRESS_PATH, Color(1.0, 0.38, 0.32, 1.0))
				timer_label.text = _localized_text("incubation.failed_short", "Failed")
			"ready_to_hatch":
				_apply_overlay_visual(icon, container, INCUBATION_IN_PROGRESS_PATH, Color(0.50, 1.0, 0.58, 1.0))
				timer_label.text = _localized_text("incubation.ready_short", "Ready!")
			_:
				_apply_plus_visual(icon, container, Color.WHITE)
				timer_label.text = ""
		return

	# Breeding chamber
	var chambers: Dictionary = BreedingSystem.get_chambers()
	var val: Variant = chambers.get(str(index), null)
	if val == null or typeof(val) != TYPE_DICTIONARY:
		_apply_plus_visual(icon, container, Color.WHITE)
		timer_label.text = ""
		return

	var chamber: Dictionary = val as Dictionary
	var state: String = str(chamber.get("state", "empty"))
	match state:
		"breeding":
			_apply_overlay_visual(icon, container, CONNECTION_IN_PROGRESS_PATH, Color.WHITE)
			var secs: int = BreedingSystem.get_breeding_remaining_seconds(chamber)
			timer_label.text = _format_countdown(secs)
		"ready":
			_apply_overlay_visual(icon, container, CONNECTION_IN_PROGRESS_PATH, Color(0.55, 1.0, 0.60, 1.0))
			timer_label.text = _localized_text("incubator.breeding_ready", "Ready!")
		"failed":
			_apply_overlay_visual(icon, container, CONNECTION_IN_PROGRESS_PATH, Color(1.0, 0.45, 0.40, 1.0))
			timer_label.text = _localized_text("incubator.breeding_failed", "Failed")
		_:
			_apply_plus_visual(icon, container, Color.WHITE)
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


func _on_reptile_leveled_up(instance_id: String, reptile_id: String, new_level: int) -> void:
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	var instance: Dictionary = {}
	if typeof(instance_value) == TYPE_DICTIONARY:
		instance = instance_value as Dictionary
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var species_name: String = _get_reptile_card_name(instance) if not instance.is_empty() else _localized_text(str(reptile.get("name_key", "")), reptile_id)
	var text: String = _localized_text("reptile_level_up_toast", "{species_name} reached level {level}!")
	text = text.replace("{species_name}", species_name).replace("{level}", str(new_level))
	_show_toast_raw(text)


# ─── Slot press handler ────────────────────────────────────────────────

func _on_slot_pressed(index: int, slot_type: String) -> void:
	if _scroll_was_drag:
		return

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
	title.text = _localized_text("incubator_storage_title", "Storage")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
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
	_configure_scroll_container(scroll)
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
	close_btn.text = _localized_text("incubator_egg_back", "Back")
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(BACK_BTN_MIN_W, BUTTON_HEIGHT)
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
	_clear_vbox(content)

	var storage: Dictionary = BreedingSystem.get_storage()
	var reptiles: Array = storage.get("reptiles", []) as Array
	var hatchlings: Array = storage.get("hatchlings", []) as Array
	for hatchling_value in hatchlings:
		if typeof(hatchling_value) == TYPE_DICTIONARY:
			reptiles.append(hatchling_value)
	var eggs: Array = IncubationSystem.get_available_storage_eggs()

	if reptiles.size() == 0 and eggs.size() == 0:
		content.add_child(_make_storage_empty_label(_localized_text("incubator_storage_empty", "Storage is empty.")))
		return

	_add_storage_header(content, "incubator_storage_eggs", "Eggs in Storage")
	var egg_groups: Array = _get_egg_group_summaries(eggs)
	if egg_groups.is_empty():
		content.add_child(_make_storage_empty_label(_localized_text("incubator_storage_no_eggs", "No eggs in storage.")))
	else:
		for group_value in egg_groups:
			if typeof(group_value) == TYPE_DICTIONARY:
				content.add_child(_make_storage_egg_group_card(group_value as Dictionary))

	_add_storage_header(content, "incubator_storage_reptiles", "Reptiles in Storage")
	if reptiles.is_empty():
		content.add_child(_make_storage_empty_label(_localized_text("incubator_storage_no_reptiles", "No reptiles in storage.")))
	else:
		for entry in reptiles:
			if typeof(entry) == TYPE_DICTIONARY:
				content.add_child(_make_storage_reptile_card(entry as Dictionary))
	_make_scroll_safe(content)


func _add_storage_header(parent: VBoxContainer, key: String, fallback: String) -> void:
	var lbl := Label.new()
	lbl.text = _localized_text(key, fallback)
	lbl.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.83, 0.38, 1.0))
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

func _make_storage_reptile_card(entry: Dictionary) -> Control:
	var instance_id: String = str(entry.get("instance_id", ""))
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, null)
	if typeof(instance_value) != TYPE_DICTIONARY:
		return _make_storage_empty_label(instance_id)

	var inst: Dictionary = (instance_value as Dictionary).duplicate(true)
	var rarity: String = str(inst.get("rarity", "common"))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_breeding_card_style(false, false))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(_make_breeding_portrait(_get_instance_portrait_path(inst), Vector2(ICON_SIZE_CARD, ICON_SIZE_CARD)))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = _localized_species_name(str(inst.get("reptile_id", ""))) + " - " + _get_variant_display_name(inst)
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var meta_lbl := Label.new()
	var sex_text: String = _localized_text("sex." + str(inst.get("sex", "male")), str(inst.get("sex", "male")))
	meta_lbl.text = _localized_rarity(rarity) + " | " + sex_text + " | " + _localized_storage_source(str(entry.get("source", inst.get("source", ""))))
	meta_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	meta_lbl.add_theme_color_override("font_color", _rarity_color(rarity))
	meta_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(meta_lbl)

	var cooldown: int = BreedingSystem.get_cooldown_remaining_seconds(inst)
	if cooldown > 0:
		var cooldown_lbl := Label.new()
		cooldown_lbl.text = _localized_text("incubator.cooldown_label", "Cooldown") + ": " + _format_countdown(cooldown)
		cooldown_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
		cooldown_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.35, 0.95))
		cooldown_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(cooldown_lbl)

	var btn := Button.new()
	btn.text = _localized_text("incubator_storage_return_to_pool", "Return to Pool")
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(150, BUTTON_HEIGHT)
	btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void:
		BreedingSystem.return_reptile_from_storage(instance_id)
		_populate_storage_overlay()
	)
	row.add_child(btn)
	return card


func _make_storage_egg_group_card(group: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_breeding_card_style(false, false))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(_make_breeding_portrait(str(group.get("visual_asset", EGG_PATH)), Vector2(ICON_SIZE_CARD, ICON_SIZE_CARD)))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = str(group.get("egg_name", ""))
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var lines: Array[String] = [
		_localized_text("incubator_egg_count_value", "Eggs: {count}").replace("{count}", str(int(group.get("count", 0)))) if bool(group.get("loaded", false)) else _localized_text("incubator_egg_available", "Available: {count}").replace("{count}", str(int(group.get("count", 0)))),
		_localized_text("incubator_egg_incubation_time", "Incubation time: {time}").replace("{time}", _format_hours(int(group.get("incubation_time_hours", 0))))
	]
	var rarity_summary: String = _format_egg_rarity_summary(group.get("rarity_counts", {}))
	if not rarity_summary.is_empty():
		lines.insert(1, rarity_summary)
	var quality_summary: String = _format_egg_quality_summary(group.get("quality_counts", {}))
	if not quality_summary.is_empty():
		lines.insert(1, quality_summary)
	var source_counts_value: Variant = group.get("source_counts", {})
	var has_source_counts: bool = typeof(source_counts_value) == TYPE_DICTIONARY and not (source_counts_value as Dictionary).is_empty()
	if not bool(group.get("loaded", false)) or has_source_counts:
		lines.append(_format_source_summary(group.get("source_counts", {})))
	for line in lines:
		var lbl := Label.new()
		lbl.text = str(line)
		lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		lbl.add_theme_color_override("font_color", Color(0.78, 0.71, 0.58, 0.95))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(lbl)

	var details_btn := Button.new()
	details_btn.text = _localized_text("incubator_storage_details", "Details")
	details_btn.focus_mode = Control.FOCUS_NONE
	details_btn.custom_minimum_size = Vector2(130, BUTTON_HEIGHT)
	details_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	details_btn.pressed.connect(func() -> void:
		var details: Array[String] = [str(group.get("egg_name", ""))]
		var details_rarity: String = _format_egg_rarity_summary(group.get("rarity_counts", {}))
		var details_quality: String = _format_egg_quality_summary(group.get("quality_counts", {}))
		if not details_quality.is_empty():
			details.append(details_quality)
		if not details_rarity.is_empty():
			details.append(details_rarity)
		details.append(_format_source_summary(group.get("source_counts", {})))
		_show_toast_raw(_join_plain_text(details, " | "))
	)
	row.add_child(details_btn)
	return card


func _make_egg_select_group_card(group: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_breeding_card_style(false, false))

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 7)
	card.add_child(body)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 9)
	body.add_child(top_row)
	var sp_id: String = str(group.get("species_id", ""))
	var sp_portrait: String = _get_species_portrait_path(sp_id)
	if sp_portrait == PLUS_ICON_PATH:
		sp_portrait = str(group.get("visual_asset", EGG_PATH))
	top_row.add_child(_make_breeding_portrait(sp_portrait, Vector2(82, 82)))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	top_row.add_child(info)

	var species_name_lbl := Label.new()
	species_name_lbl.text = _localized_species_name(sp_id)
	species_name_lbl.clip_text = true
	species_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	species_name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	species_name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 1.0))
	species_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(species_name_lbl)

	var egg_name_lbl := Label.new()
	egg_name_lbl.text = str(group.get("egg_name", ""))
	egg_name_lbl.clip_text = true
	egg_name_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	egg_name_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.54, 0.90))
	egg_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(egg_name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = _localized_text("incubator_egg_available", "Available: {count}").replace("{count}", str(int(group.get("count", 0))))
	count_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	count_lbl.add_theme_color_override("font_color", Color(0.82, 0.77, 0.62, 1.0))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(count_lbl)

	for summary in [
		_format_egg_quality_summary(group.get("quality_counts", {})),
		_format_egg_rarity_summary(group.get("rarity_counts", {}))
	]:
		if str(summary).is_empty():
			continue
		var summary_lbl := Label.new()
		summary_lbl.text = str(summary)
		summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
		summary_lbl.add_theme_color_override("font_color", Color(0.82, 0.77, 0.62, 1.0))
		summary_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(summary_lbl)

	var time_lbl := Label.new()
	time_lbl.text = _localized_text("incubator_egg_incubation_time", "Incubation time: {time}").replace("{time}", _format_hours(int(group.get("incubation_time_hours", 0))))
	time_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	time_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.54, 1.0))
	time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(time_lbl)

	var source_lbl := Label.new()
	source_lbl.text = _format_source_summary(group.get("source_counts", {}))
	source_lbl.clip_text = true
	source_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	source_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.54, 0.95))
	source_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(source_lbl)

	var select_btn := Button.new()
	select_btn.text = _localized_text("incubator_egg_select", "Select")
	select_btn.focus_mode = Control.FOCUS_NONE
	select_btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	select_btn.pressed.connect(func() -> void:
		_incubation_panel_species = str(group.get("species_id", ""))
		_incubation_panel_available_ids = group.get("egg_ids", []) as Array
		_incubation_panel_count = 1
		_incubation_panel_step = 1
		_populate_incubation_panel()
	)
	body.add_child(select_btn)
	return card


func _make_selected_egg_header(group: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_breeding_card_style(true, false))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	row.add_child(_make_breeding_portrait(str(group.get("visual_asset", EGG_PATH)), Vector2(96, 96)))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = str(group.get("egg_name", ""))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var lines: Array[String] = [
		_localized_text("incubator_egg_count_value", "Eggs: {count}").replace("{count}", str(int(group.get("count", 0)))) if bool(group.get("loaded", false)) else _localized_text("incubator_egg_available", "Available: {count}").replace("{count}", str(int(group.get("count", 0)))),
		_localized_text("incubator_egg_incubation_time", "Incubation time: {time}").replace("{time}", _format_hours(int(group.get("incubation_time_hours", 0))))
	]
	var rarity_summary: String = _format_egg_rarity_summary(group.get("rarity_counts", {}))
	if not rarity_summary.is_empty():
		lines.insert(1, rarity_summary)
	var quality_summary: String = _format_egg_quality_summary(group.get("quality_counts", {}))
	if not quality_summary.is_empty():
		lines.insert(1, quality_summary)
	var source_counts_value: Variant = group.get("source_counts", {})
	var has_source_counts: bool = typeof(source_counts_value) == TYPE_DICTIONARY and not (source_counts_value as Dictionary).is_empty()
	if not bool(group.get("loaded", false)) or has_source_counts:
		lines.append(_format_source_summary(group.get("source_counts", {})))
	for line in lines:
		var lbl := Label.new()
		lbl.text = str(line)
		lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		lbl.add_theme_color_override("font_color", Color(0.82, 0.77, 0.62, 1.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(lbl)

	return card


func _make_storage_empty_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


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
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "SelectScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_configure_scroll_container(scroll)
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "SelectList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	_make_scroll_safe(list)

	var cancel_row := HBoxContainer.new()
	cancel_row.name = "SelectCancelRow"
	cancel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cancel_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(cancel_row)

	var cancel_btn := Button.new()
	cancel_btn.name = "SelectCancel"
	cancel_btn.text = _localized_text("incubator.cancel", "Cancel")
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.custom_minimum_size = Vector2(BACK_BTN_MIN_W, BUTTON_HEIGHT)
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
	_select_species_id = ""
	_selected_female_id = ""
	_selected_male_id = ""
	_select_is_long = false
	_select_start_in_progress = false
	_set_select_cancel_visible(true)
	_populate_species_select_step()
	_select_overlay.visible = true


func _get_select_list() -> VBoxContainer:
	if _select_overlay == null:
		return null
	return _select_overlay.get_node_or_null("SelectPanel/SelectOuter/SelectScroll/SelectList") as VBoxContainer


func _get_select_title() -> Label:
	if _select_overlay == null:
		return null
	return _select_overlay.get_node_or_null("SelectPanel/SelectOuter/SelectTitle") as Label


func _get_select_cancel_button() -> Button:
	if _select_overlay == null:
		return null
	return _select_overlay.get_node_or_null("SelectPanel/SelectOuter/SelectCancelRow/SelectCancel") as Button


func _set_select_cancel_visible(visible: bool) -> void:
	var cancel_button := _get_select_cancel_button()
	if cancel_button != null:
		cancel_button.visible = visible


func _populate_species_select_step() -> void:
	_select_step = 1
	_set_select_cancel_visible(true)
	var title := _get_select_title()
	if title != null:
		title.text = _localized_text("incubator_breeding_select_species", "Select Species")
	var list := _get_select_list()
	if list == null:
		return
	_clear_select_list(list)

	var groups: Array = _get_species_breeding_groups()
	if groups.is_empty():
		_add_list_empty(list, "incubator_breeding_no_pairs", "No available pairs for breeding.")
		return

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	list.add_child(grid)

	for group_value in groups:
		if typeof(group_value) == TYPE_DICTIONARY:
			grid.add_child(_make_species_group_card(group_value as Dictionary))
	_make_scroll_safe(grid)


func _show_pair_selection(species_id: String) -> void:
	_select_species_id = species_id
	_selected_female_id = ""
	_selected_male_id = ""
	_selected_instance_a = ""
	_selected_instance_b = ""
	_select_is_long = false
	_select_start_in_progress = false
	_select_step = 2
	_populate_pair_selection_step()


func _populate_pair_selection_step() -> void:
	_set_select_cancel_visible(false)
	var title := _get_select_title()
	if title != null:
		title.text = _localized_text("incubator_breeding_select_pair", "Select Pair")
	var list := _get_select_list()
	if list == null:
		return
	_clear_select_list(list)

	var females: Array = _get_available_instances_for_species_and_sex(_select_species_id, "female")
	var males: Array = _get_available_instances_for_species_and_sex(_select_species_id, "male")
	if females.is_empty() or males.is_empty():
		_add_list_empty(list, "incubator_breeding_no_pairs", "No available pairs for breeding.")
		list.add_child(_make_pair_action_row(false))
		return

	list.add_child(_make_pair_species_header(_select_species_id))
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	list.add_child(columns)
	columns.add_child(_make_parent_column("incubator_breeding_females", "Females", females, "female"))
	columns.add_child(_make_parent_column("incubator_breeding_males", "Males", males, "male"))
	list.add_child(_make_prediction_panel())
	list.add_child(_make_duration_selector())
	list.add_child(_make_pair_action_row(_has_selected_valid_pair()))
	_make_scroll_safe(list)


func _clear_select_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()


func _make_species_group_card(group: Dictionary) -> Control:
	var species_id: String = str(group.get("species_id", ""))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 200)   # CARD_MIN_HEIGHT — species group card
	card.add_theme_stylebox_override("panel", _make_breeding_card_style(false, false))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(_make_breeding_portrait(str(group.get("portrait_path", "")), Vector2(96, 96)))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = _localized_species_name(species_id)
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	for line in [
		_localized_text("incubator_breeding_available_females", "Females: {count}").replace("{count}", str(int(group.get("female_count", 0)))),
		_localized_text("incubator_breeding_available_males", "Males: {count}").replace("{count}", str(int(group.get("male_count", 0)))),
		_localized_text("incubator_breeding_available_pairs", "Pairs: {count}").replace("{count}", str(int(group.get("pair_count", 0))))
	]:
		var lbl := Label.new()
		lbl.text = str(line)
		lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		lbl.add_theme_color_override("font_color", Color(0.78, 0.71, 0.58, 0.95))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(lbl)

	var btn := Button.new()
	btn.text = _localized_text("incubator_breeding_select", "Select")
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void: _show_pair_selection(species_id))
	info.add_child(btn)
	return card


func _make_pair_species_header(species_id: String) -> Control:
	var header := PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _make_breeding_card_style(false, false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	header.add_child(row)
	row.add_child(_make_breeding_portrait(_get_species_portrait_path(species_id, _get_available_instances()), Vector2(ICON_SIZE_CARD, ICON_SIZE_CARD)))

	var label := Label.new()
	label.text = _localized_species_name(species_id)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return header


func _make_parent_column(title_key: String, fallback: String, instances: Array, sex: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_breeding_card_style(false, false))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)

	var title := Label.new()
	title.text = _localized_text(title_key, fallback)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.83, 0.38, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 350)   # PARENT_COL_SCROLL_H — min height of female/male scroll list
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_configure_scroll_container(scroll)
	column.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for inst_value in instances:
		if typeof(inst_value) == TYPE_DICTIONARY:
			list.add_child(_make_parent_card(inst_value as Dictionary, sex))
	_make_scroll_safe(list)
	return panel


func _make_parent_card(inst: Dictionary, sex: String) -> Control:
	var instance_id: String = str(inst.get("instance_id", ""))
	var selected: bool = instance_id == (_selected_female_id if sex == "female" else _selected_male_id)
	var rarity: String = str(inst.get("rarity", "common"))
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 130)   # PARENT_CARD_HEIGHT — reptile card in selection column
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", _make_breeding_card_style(selected, false))
	btn.add_theme_stylebox_override("hover", _make_breeding_card_style(selected, true))
	btn.add_theme_stylebox_override("pressed", _make_breeding_card_style(true, true))
	btn.pressed.connect(func() -> void:
		if sex == "female":
			_selected_female_id = instance_id
		else:
			_selected_male_id = instance_id
		_update_selected_pair_ids()
		_populate_pair_selection_step()
	)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_top = 8
	row.offset_right = -8
	row.offset_bottom = -8
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	row.add_child(_make_breeding_portrait(_get_instance_portrait_path(inst), Vector2(70, 70)))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = _get_reptile_card_name(inst)
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var rarity_lbl := Label.new()
	rarity_lbl.text = _get_variant_display_name(inst) + " - " + _localized_rarity(rarity)
	rarity_lbl.clip_text = true
	rarity_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	rarity_lbl.add_theme_color_override("font_color", _rarity_color(rarity))
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(rarity_lbl)

	var sex_lbl := Label.new()
	sex_lbl.text = _localized_text("sex." + sex, sex)
	sex_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	sex_lbl.add_theme_color_override("font_color", Color(0.76, 0.70, 0.58, 0.95))
	sex_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(sex_lbl)
	return btn


func _make_prediction_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_breeding_card_style(false, false))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)

	var title := Label.new()
	title.text = _localized_text("incubator_breeding_predicted_results", "Predicted Results")
	title.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)

	if not _has_selected_valid_pair():
		var hint := Label.new()
		hint.text = _localized_text("incubator_breeding_select_female_and_male", "Select one female and one male.")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		hint.add_theme_color_override("font_color", Color(0.74, 0.68, 0.56, 0.95))
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(hint)
		return panel

	var prediction: Dictionary = BreedingSystem.get_predicted_breeding_odds(
		_get_instance_by_id(_selected_female_id),
		_get_instance_by_id(_selected_male_id),
		_select_is_long
	)
	var rates: Dictionary = prediction.get("rates", {}) as Dictionary
	var odds := Label.new()
	odds.text = _localized_text("incubator_breeding_odds", "Odds") + ": " + _format_rates(rates)
	odds.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	odds.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62, 1.0))
	odds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(odds)

	var success := Label.new()
	success.text = _localized_text("incubator_breeding_success_chance", "Success chance") + ": " + _format_breeding_percent(float(prediction.get("success_chance", 0.0))) + "%  |  " + _localized_text("incubator_breeding_failure_risk", "Failure risk") + ": " + _format_breeding_percent(float(prediction.get("failure_risk", 0.0))) + "%"
	success.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	success.add_theme_color_override("font_color", Color(0.66, 0.90, 0.58, 1.0))
	success.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(success)

	var level_bonus := Label.new()
	level_bonus.text = LocalizationSystem.tr_key("reptile_breeding_bonus").replace("{points}", _format_breeding_percent(float(prediction.get("level_failure_reduction", 0.0))))
	level_bonus.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	level_bonus.add_theme_color_override("font_color", Color(0.72, 0.84, 0.62, 1.0))
	level_bonus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(level_bonus)

	var eggs := Label.new()
	eggs.text = _localized_text("incubator_breeding_egg_count_range", "Egg count: 1-5")
	eggs.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	eggs.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62, 1.0))
	eggs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(eggs)
	return panel


func _make_duration_selector() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_duration_toggle(false))
	row.add_child(_make_duration_toggle(true))
	box.add_child(row)
	var note := Label.new()
	note.text = _localized_text("incubator_breeding_long_bonus", "Long Breeding increases the chance for Ultra Rare and Exceptional.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", META_FONT_SIZE)
	note.add_theme_color_override("font_color", Color(0.74, 0.68, 0.56, 0.95))
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(note)
	return box


func _make_duration_toggle(is_long: bool) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 60)   # DURATION_TOGGLE_H
	btn.focus_mode = Control.FOCUS_NONE
	btn.toggle_mode = true
	btn.button_pressed = _select_is_long == is_long
	btn.text = _localized_text("incubator_breeding_long_48h" if is_long else "incubator_breeding_fast_24h", "Long Breeding - 48h" if is_long else "Fast Breeding - 24h")
	btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void:
		_select_is_long = is_long
		_populate_pair_selection_step()
	)
	return btn


func _make_pair_action_row(can_start: bool) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var back := Button.new()
	back.text = _localized_text("incubator_breeding_back", "Back")
	back.custom_minimum_size = Vector2(130, BUTTON_HEIGHT)
	back.focus_mode = Control.FOCUS_NONE
	back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back.pressed.connect(func() -> void: _populate_species_select_step())
	row.add_child(back)

	var cancel := Button.new()
	cancel.text = _localized_text("incubator_breeding_cancel", "Cancel")
	cancel.custom_minimum_size = Vector2(130, BUTTON_HEIGHT)
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.pressed.connect(_cancel_select_overlay)
	row.add_child(cancel)

	var start := Button.new()
	start.text = _localized_text("incubator_breeding_start", "Start Breeding")
	start.custom_minimum_size = Vector2(180, BUTTON_HEIGHT)
	start.focus_mode = Control.FOCUS_NONE
	start.disabled = not can_start or _select_start_in_progress
	start.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start.pressed.connect(_confirm_selected_pair)
	row.add_child(start)
	return row


func _confirm_selected_pair() -> void:
	if _select_start_in_progress:
		return
	if not _has_selected_valid_pair():
		_show_toast("incubator_breeding_select_female_and_male", "Select one female and one male.")
		return
	_select_start_in_progress = true
	_update_selected_pair_ids()
	var result: Dictionary = BreedingSystem.start_breeding(
		_select_chamber_index, _selected_female_id, _selected_male_id, _select_is_long)
	if bool(result.get("success", false)):
		_cancel_select_overlay()
		_refresh_all_slots()
	else:
		_select_start_in_progress = false
		_show_toast(str(result.get("error_key", "")), "Error starting breeding.")
		_populate_pair_selection_step()


func _cancel_select_overlay() -> void:
	_select_step = 0
	_select_start_in_progress = false
	if _select_overlay != null:
		_select_overlay.visible = false


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
		_make_scroll_safe(list)
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
	_make_scroll_safe(list)


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
		_make_scroll_safe(list)
		return
	for inst in candidates:
		list.add_child(_make_reptile_row(inst, func(iid: String) -> void:
			_selected_instance_b = iid
			_select_step = 3
			_populate_duration_step()
		))
	_make_scroll_safe(list)


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
	_make_scroll_safe(list)


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
	t.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	t.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(t)

	var info := Label.new()
	info.text = info_text
	info.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
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
	rl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	rl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45, 0.85))
	rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rl)

	var btn := Button.new()
	btn.text = _localized_text("incubator.start_breeding", "Start Breeding")
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
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
	lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(lbl)


func _make_reptile_row(inst: Dictionary, on_press: Callable) -> Control:
	var instance_id: String = str(inst.get("instance_id", ""))
	var rarity: String = str(inst.get("rarity", "common"))
	var sex: String = str(inst.get("sex", "male"))
	var custom_name: String = str(inst.get("custom_name", ""))
	var reptile_id: String = str(inst.get("reptile_id", ""))
	var species: String = _localized_species_name(reptile_id)
	var display: String = custom_name if not custom_name.is_empty() else species
	var sex_lbl: String = _localized_text("incubator.sex_male", "M") if sex == "male" else _localized_text("incubator.sex_female", "F")

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
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
	return BreedingSystem.get_available_breeding_reptiles()


func _get_compatible_instances(exclude_id: String, reptile_id_filter: String, sex_filter: String) -> Array:
	var result: Array = []
	for inst_value in _get_available_instances():
		if typeof(inst_value) != TYPE_DICTIONARY:
			continue
		var inst: Dictionary = inst_value as Dictionary
		if str(inst.get("instance_id", "")) == exclude_id:
			continue
		if str(inst.get("reptile_id", "")) != reptile_id_filter:
			continue
		if str(inst.get("sex", "")) != sex_filter:
			continue
		result.append(inst)
	return result


func _get_species_breeding_groups() -> Array:
	var grouped: Dictionary = {}
	for inst_value in _get_available_instances():
		if typeof(inst_value) != TYPE_DICTIONARY:
			continue
		var inst: Dictionary = inst_value as Dictionary
		var species_id: String = str(inst.get("reptile_id", ""))
		if species_id.is_empty():
			continue
		if not grouped.has(species_id):
			grouped[species_id] = {"species_id": species_id, "females": [], "males": []}
		var species_group: Dictionary = grouped[species_id] as Dictionary
		match str(inst.get("sex", "")):
			"female":
				(species_group.get("females", []) as Array).append(inst)
			"male":
				(species_group.get("males", []) as Array).append(inst)

	var result: Array = []
	for species_id in grouped.keys():
		var group: Dictionary = grouped[species_id] as Dictionary
		var females: Array = group.get("females", []) as Array
		var males: Array = group.get("males", []) as Array
		if females.is_empty() or males.is_empty():
			continue
		result.append({
			"species_id": str(species_id),
			"female_count": females.size(),
			"male_count": males.size(),
			"pair_count": min(females.size(), males.size()),
			"portrait_path": _get_species_portrait_path(str(species_id), females + males)
		})

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _localized_species_name(str(a.get("species_id", ""))) < _localized_species_name(str(b.get("species_id", "")))
	)
	return result


func _get_available_instances_for_species_and_sex(species_id: String, sex: String) -> Array:
	var result: Array = []
	for inst_value in _get_available_instances():
		if typeof(inst_value) != TYPE_DICTIONARY:
			continue
		var inst: Dictionary = inst_value as Dictionary
		if str(inst.get("reptile_id", "")) == species_id and str(inst.get("sex", "")) == sex:
			result.append(inst)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _get_reptile_card_name(a) < _get_reptile_card_name(b)
	)
	return result


func _get_instance_by_id(instance_id: String) -> Dictionary:
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var value: Variant = instances.get(instance_id, null)
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var instance: Dictionary = (value as Dictionary).duplicate(true)
	if str(instance.get("instance_id", "")).is_empty():
		instance["instance_id"] = instance_id
	return instance


func _has_selected_valid_pair() -> bool:
	if _selected_female_id.is_empty() or _selected_male_id.is_empty():
		return false
	var female: Dictionary = _get_instance_by_id(_selected_female_id)
	var male: Dictionary = _get_instance_by_id(_selected_male_id)
	if female.is_empty() or male.is_empty():
		return false
	var pair_check: Dictionary = BreedingSystem.can_pair(female, male)
	return bool(pair_check.get("ok", false))


func _update_selected_pair_ids() -> void:
	_selected_instance_a = _selected_female_id
	_selected_instance_b = _selected_male_id


# ─── Tick ──────────────────────────────────────────────────────────────

func _get_egg_group_summaries(eggs: Array) -> Array:
	var grouped: Dictionary = {}
	for egg_value in eggs:
		if typeof(egg_value) != TYPE_DICTIONARY:
			continue
		var egg: Dictionary = egg_value as Dictionary
		var species_id: String = _get_egg_species_id(egg)
		if species_id.is_empty():
			continue
		if not grouped.has(species_id):
			grouped[species_id] = []
		(grouped[species_id] as Array).append(egg)

	var result: Array = []
	for species_id in grouped.keys():
		var group_eggs: Array = grouped[species_id] as Array
		if group_eggs.is_empty():
			continue
		var first_egg: Dictionary = group_eggs[0] as Dictionary
		var ids: Array = []
		var source_counts: Dictionary = {}
		var rarity_counts: Dictionary = {}
		var quality_counts: Dictionary = {}
		for egg_value in group_eggs:
			if typeof(egg_value) != TYPE_DICTIONARY:
				continue
			var egg: Dictionary = egg_value as Dictionary
			var egg_id: String = str(egg.get("egg_id", egg.get("egg_instance_id", "")))
			if not egg_id.is_empty():
				ids.append(egg_id)
			var source: String = str(egg.get("source", "unknown"))
			source_counts[source] = int(source_counts.get(source, 0)) + 1
			var rarity_raw: String = str(egg.get("rarity", "")).strip_edges()
			if not rarity_raw.is_empty():
				var rarity: String = ReptileSystem.normalize_rarity(rarity_raw)
				rarity_counts[rarity] = int(rarity_counts.get(rarity, 0)) + 1
			else:
				var quality_id: String = str(egg.get("offer_quality", "")).strip_edges()
				if not quality_id.is_empty():
					quality_counts[quality_id] = int(quality_counts.get(quality_id, 0)) + 1
		result.append({
			"species_id": str(species_id),
			"egg_name": _get_egg_display_name(str(species_id), first_egg),
			"count": group_eggs.size(),
			"egg_ids": ids,
			"incubation_time_hours": int(first_egg.get("incubation_time_hours", IncubationSystem.get_incubation_time_hours(str(species_id)))),
			"visual_asset": _get_egg_visual_asset(first_egg),
			"source_counts": source_counts,
			"rarity_counts": rarity_counts,
			"quality_counts": quality_counts
		})

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("egg_name", "")) < str(b.get("egg_name", ""))
	)
	return result


func _get_current_egg_group_summary() -> Dictionary:
	if _incubation_panel_species.is_empty():
		return {}
	var groups: Array = _get_egg_group_summaries(IncubationSystem.get_available_storage_eggs())
	for group_value in groups:
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_value as Dictionary
		if str(group.get("species_id", "")) == _incubation_panel_species:
			return group
	return {}


func _get_egg_species_id(egg: Dictionary) -> String:
	return str(egg.get("reptile_id", egg.get("species_id", ""))).strip_edges()


func _get_egg_display_name(species_id: String, egg: Dictionary = {}) -> String:
	var language: String = GameState.get_language()
	var egg_name: String = IncubationSystem.get_egg_name(species_id, language)
	if not egg_name.is_empty() and egg_name != species_id:
		return egg_name
	egg_name = str(egg.get("egg_name_" + language, ""))
	if not egg_name.is_empty():
		return egg_name
	return _localized_species_name(species_id)


func _get_egg_visual_asset(egg: Dictionary) -> String:
	for key in ["visual_asset", "visual_asset_variant", "asset"]:
		var path: String = str(egg.get(key, ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	return EGG_PATH


func _format_source_summary(source_counts_value: Variant) -> String:
	var source_counts: Dictionary = source_counts_value as Dictionary if typeof(source_counts_value) == TYPE_DICTIONARY else {}
	if source_counts.is_empty():
		return _localized_text("incubator_storage_source_unknown", "Source: Unknown")
	var pieces: Array[String] = []
	for source in source_counts.keys():
		pieces.append(_localized_storage_source(str(source)) + ": " + str(int(source_counts.get(source, 0))))
	if pieces.size() == 1:
		return pieces[0]
	return _localized_text("incubator_storage_source_mixed", "Mixed") + " | " + _join_plain_text(pieces, " | ")


func _format_egg_rarity_summary(rarity_counts_value: Variant) -> String:
	var rarity_counts: Dictionary = rarity_counts_value as Dictionary if typeof(rarity_counts_value) == TYPE_DICTIONARY else {}
	if rarity_counts.is_empty():
		return ""
	var pieces: Array[String] = []
	for rarity in ["common", "rare", "ultra_rare", "exceptional"]:
		var count: int = int(rarity_counts.get(rarity, 0))
		if count > 0:
			pieces.append(_localized_rarity(rarity) + ": " + str(count))
	if pieces.is_empty():
		return ""
	return _localized_text("incubator_egg_rarity_summary", "Rarities: {summary}").replace("{summary}", _join_plain_text(pieces, " | "))


func _format_egg_quality_summary(quality_counts_value: Variant) -> String:
	var quality_counts: Dictionary = quality_counts_value as Dictionary if typeof(quality_counts_value) == TYPE_DICTIONARY else {}
	if quality_counts.is_empty():
		return ""
	var pieces: Array[String] = []
	var ordered_quality_ids: Array = IncubationSystem.get_quality_order()
	for quality_id_value in ordered_quality_ids:
		var quality_id: String = str(quality_id_value)
		var count: int = int(quality_counts.get(quality_id, 0))
		if count > 0:
			pieces.append(_localized_egg_quality(quality_id) + ": " + str(count))
	for quality_id_value in quality_counts.keys():
		var quality_id: String = str(quality_id_value)
		if ordered_quality_ids.has(quality_id):
			continue
		var count: int = int(quality_counts.get(quality_id, 0))
		if count > 0:
			pieces.append(_localized_egg_quality(quality_id) + ": " + str(count))
	if pieces.is_empty():
		return ""
	return _localized_text("incubator_egg_quality_summary", "Egg types: {summary}").replace("{summary}", _join_plain_text(pieces, " | "))


func _localized_egg_quality(quality_id: String) -> String:
	var qualities: Dictionary = IncubationSystem.get_species_shop_qualities()
	var quality_value: Variant = qualities.get(quality_id, null)
	if typeof(quality_value) == TYPE_DICTIONARY:
		var quality: Dictionary = quality_value as Dictionary
		return _localized_text(str(quality.get("name_suffix_key", "")), quality_id.capitalize())
	return quality_id.capitalize()


func _localized_storage_source(source: String) -> String:
	match source:
		"shop":
			return _localized_text("incubator_storage_source_shop", "Shop")
		"breeding":
			return _localized_text("incubator_storage_source_breeding", "Breeding")
		"incubation":
			return _localized_text("incubator_storage_source_incubation", "Incubation")
		_:
			return _localized_text("incubator_storage_source_unknown", "Unknown")


func _format_hours(hours: int) -> String:
	return str(max(0, hours)) + "h"


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


func _configure_scroll_container(scroll: ScrollContainer) -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS


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


func _make_breeding_card_style(selected: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(0.24, 0.18, 0.08, 0.96)
		style.border_color = Color(0.95, 0.74, 0.24, 1.0)
	elif hover:
		style.bg_color = Color(0.18, 0.12, 0.07, 0.92)
		style.border_color = Color(0.72, 0.52, 0.24, 0.95)
	else:
		style.bg_color = Color(0.13, 0.09, 0.06, 0.88)
		style.border_color = Color(0.55, 0.40, 0.20, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_breeding_portrait(path: String, size: Vector2) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var resolved_path: String = path
	if resolved_path.is_empty() or not ResourceLoader.exists(resolved_path):
		resolved_path = PLUS_ICON_PATH
	portrait.texture = AssetPaths.load_texture(resolved_path)
	return portrait


func _get_species_portrait_path(species_id: String, instances: Array = []) -> String:
	var reptile: Dictionary = ReptileSystem.get_reptile(species_id)
	for key in ["portrait_path", "icon_path"]:
		var path: String = str(reptile.get(key, ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	for inst_value in instances:
		if typeof(inst_value) != TYPE_DICTIONARY:
			continue
		var inst: Dictionary = inst_value as Dictionary
		if str(inst.get("reptile_id", "")) != species_id:
			continue
		var path: String = _get_instance_portrait_path(inst)
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	return PLUS_ICON_PATH


func _get_instance_portrait_path(inst: Dictionary) -> String:
	var variant_id: String = str(inst.get("variant_id", ""))
	var variant: Dictionary = ReptileSystem.get_variant(variant_id)
	for key in ["portrait_path", "icon_path"]:
		var path: String = str(variant.get(key, ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	var species_id: String = str(inst.get("reptile_id", ""))
	return _get_species_portrait_path(species_id)


func _localized_species_name(species_id: String) -> String:
	var reptile: Dictionary = ReptileSystem.get_reptile(species_id)
	var name_key: String = str(reptile.get("name_key", ""))
	var fallback: String = _humanize_id(species_id)
	var localized: String = _localized_text(name_key, fallback)
	if localized == fallback and not name_key.is_empty():
		push_warning("Missing species localization: " + name_key)
	return localized


func _get_reptile_card_name(inst: Dictionary) -> String:
	var custom_name: String = str(inst.get("custom_name", ""))
	if not custom_name.is_empty():
		return custom_name
	return _localized_species_name(str(inst.get("reptile_id", "")))


func _get_variant_display_name(inst: Dictionary) -> String:
	var variant: Dictionary = ReptileSystem.get_variant(str(inst.get("variant_id", "")))
	var name_key: String = str(variant.get("name_key", ""))
	var fallback: String = _localized_rarity(str(inst.get("rarity", variant.get("rarity", "common"))))
	var localized: String = _localized_text(name_key, fallback)
	if localized == fallback and not name_key.is_empty():
		push_warning("Missing variant localization: " + name_key)
	return localized


func _format_rates(rates: Dictionary) -> String:
	var pieces: Array[String] = []
	for rarity in ["common", "rare", "ultra_rare", "exceptional"]:
		pieces.append(_localized_rarity(rarity) + " " + str(int(round(float(rates.get(rarity, 0.0))))) + "%")
	return _join_plain_text(pieces, " | ")


func _format_breeding_percent(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.1f" % value


func _join_plain_text(pieces: Array[String], separator: String) -> String:
	var text: String = ""
	for piece in pieces:
		if text.is_empty():
			text = piece
		else:
			text += separator + piece
	return text


func _humanize_id(value: String) -> String:
	return value.replace("_", " ").capitalize()


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
		"quests":
			if _quests_overlay != null:
				_populate_quests_overlay()
				_quests_overlay.visible = true
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
	_incubation_panel_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_incubation_panel_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(_incubation_panel_title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "IPScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_configure_scroll_container(scroll)
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
	_incubation_panel_close_btn.custom_minimum_size = Vector2(BACK_BTN_MIN_W, BUTTON_HEIGHT)
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
	_incubation_load_in_progress = false
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
			_incubation_panel_title.text = _localized_text("incubator_egg_select_species", "Select Egg Species") if _incubation_panel_step == 0 else _localized_text("incubator_egg_select_count", "Select Egg Count")
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
	_make_scroll_safe(_incubation_panel_content)


func _ip_show_species_select() -> void:
	var groups: Array = _get_egg_group_summaries(IncubationSystem.get_available_storage_eggs())
	if groups.is_empty():
		_incubation_panel_content.add_child(_make_ip_info_label(
			_localized_text("incubator_storage_no_eggs", "No eggs in storage.")
		))
		return

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_incubation_panel_content.add_child(grid)

	for group_value in groups:
		if typeof(group_value) == TYPE_DICTIONARY:
			grid.add_child(_make_egg_select_group_card(group_value as Dictionary))
	_make_scroll_safe(grid)


func _ip_show_count_select() -> void:
	var group: Dictionary = _get_current_egg_group_summary()
	if group.is_empty():
		_incubation_panel_step = 0
		_ip_show_species_select()
		return

	_incubation_panel_available_ids = group.get("egg_ids", []) as Array
	var egg_name: String = str(group.get("egg_name", _get_egg_display_name(_incubation_panel_species)))
	var max_count: int = mini(IncubationSystem.get_max_eggs_per_container(), _incubation_panel_available_ids.size())
	if max_count < 1:
		_incubation_panel_step = 0
		_ip_show_species_select()
		return
	_incubation_panel_count = clampi(_incubation_panel_count, 1, max_count)

	_incubation_panel_content.add_child(_make_selected_egg_header(group))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubator_egg_available", "Available: {count}").replace("{count}", str(_incubation_panel_available_ids.size()))
	))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubator_egg_max", "Max: {count}").replace("{count}", str(IncubationSystem.get_max_eggs_per_container()))
	))

	var count_row := HBoxContainer.new()
	count_row.alignment = BoxContainer.ALIGNMENT_CENTER
	count_row.add_theme_constant_override("separation", 16)
	_incubation_panel_content.add_child(count_row)

	var minus_btn := Button.new()
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(64, BUTTON_HEIGHT)   # COUNT_STEPPER_SIZE
	minus_btn.focus_mode = Control.FOCUS_NONE
	minus_btn.disabled = _incubation_panel_count <= 1
	minus_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	minus_btn.pressed.connect(func() -> void:
		_incubation_panel_count = maxi(1, _incubation_panel_count - 1)
		_populate_incubation_panel()
	)
	count_row.add_child(minus_btn)

	var count_lbl := Label.new()
	count_lbl.text = _localized_text("incubator_egg_count", "Egg Count") + "\n" + str(_incubation_panel_count)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.custom_minimum_size = Vector2(140, 0)
	count_lbl.add_theme_font_size_override("font_size", 22)   # COUNT_LABEL_FONT_SIZE
	count_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_row.add_child(count_lbl)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(64, BUTTON_HEIGHT)   # COUNT_STEPPER_SIZE
	plus_btn.focus_mode = Control.FOCUS_NONE
	plus_btn.disabled = _incubation_panel_count >= max_count
	plus_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plus_btn.pressed.connect(func() -> void:
		_incubation_panel_count = mini(max_count, _incubation_panel_count + 1)
		_populate_incubation_panel()
	)
	count_row.add_child(plus_btn)

	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubator_egg_incubation_time", "Incubation time: {time}").replace("{time}", _format_hours(int(group.get("incubation_time_hours", 0))))
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
	back_btn.text = _localized_text("incubator_egg_back", "Back")
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.custom_minimum_size = Vector2(120, BUTTON_HEIGHT)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.pressed.connect(func() -> void:
		_incubation_panel_step = 0
		_populate_incubation_panel()
	)
	btn_row.add_child(back_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = _localized_text("incubator_egg_cancel", "Cancel")
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.custom_minimum_size = Vector2(120, BUTTON_HEIGHT)
	cancel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel_btn.pressed.connect(func() -> void:
		_incubation_load_in_progress = false
		_incubation_panel.visible = false
		_incubation_panel_idx = -1
	)
	btn_row.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = _localized_text("incubator_egg_place_in_container", "Place in Container")
	confirm_btn.focus_mode = Control.FOCUS_NONE
	confirm_btn.custom_minimum_size = Vector2(190, BUTTON_HEIGHT)
	confirm_btn.disabled = _incubation_load_in_progress
	confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ids_slice: Array = _incubation_panel_available_ids.slice(0, _incubation_panel_count)
	var sid: String = _incubation_panel_species
	var cidx: int = _incubation_panel_idx
	confirm_btn.pressed.connect(func() -> void:
		if _incubation_load_in_progress:
			return
		_incubation_load_in_progress = true
		var result: Dictionary = IncubationSystem.load_eggs_into_container(cidx, ids_slice, sid)
		if bool(result.get("success", false)):
			_incubation_load_in_progress = false
			_incubation_panel_step = 0
			_populate_incubation_panel()
			_refresh_all_slots()
		else:
			_incubation_load_in_progress = false
			_show_toast(str(result.get("error_key", "")), "Error.")
			_populate_incubation_panel()
	)
	btn_row.add_child(confirm_btn)


func _ip_show_loaded(container: Dictionary) -> void:
	var species_id: String = str(container.get("species_id", ""))
	var egg_name: String = _get_egg_display_name(species_id)
	var count: int = int(container.get("egg_count", 0))
	var time_h: int = int(container.get("incubation_time_hours", 0))

	_incubation_panel_content.add_child(_make_selected_egg_header({
		"egg_name": egg_name,
		"count": count,
		"incubation_time_hours": time_h,
		"visual_asset": EGG_PATH,
		"source_counts": {},
		"loaded": true
	}))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubator_egg_species", "Species: {name}").replace("{name}", egg_name)
	))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubator_egg_count_value", "Eggs: {count}").replace("{count}", str(count))
	))
	_incubation_panel_content.add_child(_make_ip_info_label(
		_localized_text("incubator_egg_incubation_time", "Incubation time: {time}").replace("{time}", _format_hours(time_h))
	))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_incubation_panel_content.add_child(sp)

	var start_btn := _make_ip_action_btn(
		_localized_text("incubator_egg_start_incubation", "Start Incubation"),
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
		_localized_text("incubator_egg_cancel_and_return", "Cancel and return eggs"),
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
	hatch_btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	hatch_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
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
	lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_ip_action_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
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
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)
	_egg_shop_title_label = title

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "ESScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_configure_scroll_container(scroll)
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
	close_btn.custom_minimum_size = Vector2(BACK_BTN_MIN_W, BUTTON_HEIGHT)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void:
		_egg_shop_step = 0
		_egg_shop_selected_species = {}
		_egg_shop_overlay.visible = false
	)
	close_row.add_child(close_btn)


func _populate_egg_shop() -> void:
	if _egg_shop_overlay == null or _egg_shop_content == null:
		return
	_clear_vbox(_egg_shop_content)

	if _egg_shop_step == 0:
		if _egg_shop_title_label != null:
			_egg_shop_title_label.text = _localized_text("egg_shop.title", "Egg Shop")
		_populate_egg_shop_species()
	else:
		if _egg_shop_title_label != null:
			var sp_id: String = str(_egg_shop_selected_species.get("species_id", ""))
			_egg_shop_title_label.text = _localized_species_name(sp_id)
		_populate_egg_shop_qualities()
	_make_scroll_safe(_egg_shop_content)


func _populate_egg_shop_species() -> void:
	var content: VBoxContainer = _egg_shop_content
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

	var sorted_species: Array = available.duplicate()
	sorted_species.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ba: int = _egg_shop_biome_order(str(a.get("biome_id", "")))
		var bb: int = _egg_shop_biome_order(str(b.get("biome_id", "")))
		if ba != bb:
			return ba < bb
		return str(a.get("species_id", "")) < str(b.get("species_id", ""))
	)

	for species_val in sorted_species:
		if typeof(species_val) != TYPE_DICTIONARY:
			continue
		var species: Dictionary = species_val as Dictionary
		var min_price: int = 999999
		for qid in quality_order:
			if qualities.has(qid):
				var p: int = int((qualities[qid] as Dictionary).get("price", 0))
				if p < min_price:
					min_price = p
		content.add_child(_make_egg_shop_species_card(species, qualities, quality_order, min_price))


func _make_egg_shop_species_card(species: Dictionary, _qualities: Dictionary, _quality_order: Array, min_price: int) -> Control:
	var lang: String = LocalizationSystem.get_language()
	var sp_id: String = str(species.get("species_id", ""))
	var egg_name: String = str(species.get("egg_name_" + lang, str(species.get("egg_name_en", sp_id))))
	var biome_id: String = str(species.get("biome_id", ""))
	var inc_hours: int = int(species.get("incubation_time_hours", 24))

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.09, 0.05, 0.90)
	cs.border_color = Color(0.55, 0.40, 0.20, 0.80)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(10)
	cs.content_margin_left = 10
	cs.content_margin_right = 10
	cs.content_margin_top = 10
	cs.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", cs)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var portrait_path: String = _get_species_portrait_path(sp_id)
	if portrait_path == PLUS_ICON_PATH:
		portrait_path = str(species.get("visual_asset", EGG_PATH))
	var portrait_size: float = EGG_SHOP_SPECIES_PORTRAIT_SIZE * EGG_SHOP_SPECIES_PORTRAIT_SCALE
	hbox.add_child(_make_breeding_portrait(portrait_path, Vector2(portrait_size, portrait_size)))

	var info_margin := MarginContainer.new()
	info_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_margin.add_theme_constant_override("margin_left", int(round(portrait_size * EGG_SHOP_SPECIES_TEXT_SHIFT_RATIO)))
	hbox.add_child(info_margin)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	info_margin.add_child(info)

	var sp_name_lbl := Label.new()
	sp_name_lbl.text = _localized_species_name(sp_id)
	sp_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp_name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	sp_name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 1.0))
	sp_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(sp_name_lbl)

	var egg_name_lbl := Label.new()
	egg_name_lbl.text = egg_name
	egg_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	egg_name_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	egg_name_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.54, 0.85))
	egg_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(egg_name_lbl)

	if not biome_id.is_empty():
		var biome_lbl := Label.new()
		biome_lbl.text = _localized_text("biome." + biome_id, biome_id.capitalize())
		biome_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		biome_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
		biome_lbl.add_theme_color_override("font_color", Color(0.55, 0.72, 0.45, 0.85))
		biome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(biome_lbl)

	var time_lbl := Label.new()
	var time_text: String = _localized_text("incubator_egg_incubation_time", "Incubation time: {time}")
	time_lbl.text = time_text.replace("{time}", str(inc_hours) + "h")
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	time_lbl.add_theme_color_override("font_color", Color(0.68, 0.63, 0.50, 0.85))
	time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(time_lbl)

	var price_lbl := Label.new()
	var from_text: String = _localized_text("egg_shop.from_price", "From: {price} R$")
	price_lbl.text = from_text.replace("{price}", str(min_price))
	price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	price_lbl.add_theme_color_override("font_color", Color(0.95, 0.83, 0.38, 1.0))
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(price_lbl)

	var select_btn := Button.new()
	select_btn.text = _localized_text("incubator_egg_select", "Select")
	select_btn.focus_mode = Control.FOCUS_NONE
	select_btn.custom_minimum_size = Vector2(
		EGG_SHOP_SPECIES_SELECT_BUTTON_WIDTH * EGG_SHOP_SPECIES_SELECT_BUTTON_SCALE,
		BUTTON_HEIGHT * EGG_SHOP_SPECIES_SELECT_BUTTON_SCALE
	)
	select_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	select_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	select_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sp_copy: Dictionary = species.duplicate()
	select_btn.pressed.connect(func() -> void:
		_egg_shop_selected_species = sp_copy
		_egg_shop_step = 1
		_populate_egg_shop()
	)
	hbox.add_child(select_btn)

	return card


func _populate_egg_shop_qualities() -> void:
	var content: VBoxContainer = _egg_shop_content
	var qualities: Dictionary = IncubationSystem.get_species_shop_qualities()
	var quality_order: Array = IncubationSystem.get_quality_order()
	var species: Dictionary = _egg_shop_selected_species

	var back_btn := Button.new()
	back_btn.text = "← " + _localized_text("incubator_egg_back", "Back")
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.custom_minimum_size = Vector2(BACK_BTN_MIN_W, BUTTON_HEIGHT)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.pressed.connect(func() -> void:
		_egg_shop_step = 0
		_egg_shop_selected_species = {}
		_populate_egg_shop()
	)
	content.add_child(back_btn)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)

	for qid in quality_order:
		if not qualities.has(qid):
			continue
		grid.add_child(_make_species_quality_card(species, qid, qualities[qid] as Dictionary))

	_make_scroll_safe(grid)


func _egg_shop_biome_order(biome_id: String) -> int:
	match biome_id:
		"green_meadow": return 0
		"dry_prairie":  return 1
		_:              return 99


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
	cs.content_margin_left = 12
	cs.content_margin_right = 12
	cs.content_margin_top = 12
	cs.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", cs)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", CARD_SEPARATION)
	card.add_child(vbox)

	var icon_row := HBoxContainer.new()
	icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(icon_row)

	var icon := TextureRect.new()
	var quality_icon_size: float = ICON_SIZE_QUALITY * EGG_SHOP_QUALITY_ICON_SCALE
	icon.custom_minimum_size = Vector2(quality_icon_size, quality_icon_size)
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
	name_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
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
	bs.content_margin_left = 8
	bs.content_margin_right = 8
	bs.content_margin_top = 4
	bs.content_margin_bottom = 4
	badge.add_theme_stylebox_override("panel", bs)
	badge_row.add_child(badge)
	var badge_lbl := Label.new()
	badge_lbl.text = quality_label
	badge_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	badge_lbl.add_theme_color_override("font_color", Color.WHITE)
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_lbl)

	var time_lbl := Label.new()
	time_lbl.text = _localized_text("egg_shop.incubation_time", "Time:") + " " + str(inc_hours) + "h"
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	time_lbl.add_theme_color_override("font_color", Color(0.68, 0.63, 0.50, 0.85))
	time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(time_lbl)

	var price_lbl := Label.new()
	price_lbl.text = str(price) + " R$"
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_lbl.add_theme_font_size_override("font_size", 18)   # QUALITY_PRICE_FONT_SIZE
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
	odds_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	odds_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45, 0.85))
	odds_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(odds_lbl)

	var buy_btn := Button.new()
	buy_btn.text = _localized_text("egg_shop.buy", "Buy")
	buy_btn.focus_mode = Control.FOCUS_NONE
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	buy_btn.add_theme_font_size_override("font_size", int(round(BUTTON_FONT_SIZE * EGG_SHOP_QUALITY_BUY_FONT_SCALE)))
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
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30, 1.0))
	outer.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "HRSubtitle"
	subtitle.text = _localized_text("hatch.subtitle", "New reptiles hatched!")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	subtitle.add_theme_color_override("font_color", Color(0.80, 0.75, 0.55, 1.0))
	outer.add_child(subtitle)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.70, 0.55, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "HRScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_configure_scroll_container(scroll)
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
	ok_btn.custom_minimum_size = Vector2(180, BUTTON_HEIGHT)
	ok_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
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
	added_lbl.text = _localized_text("hatch.added_to_pool", "Added to reptile pool")
	added_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	added_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	added_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	added_lbl.add_theme_color_override("font_color", Color(0.60, 0.82, 0.55, 1.0))
	added_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(added_lbl)

	_make_scroll_safe(content)
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
	portrait.custom_minimum_size = Vector2(80, 80)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_path: String = str(r.get("portrait_path", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait.texture = AssetPaths.load_texture(portrait_path)
	hbox.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", CARD_SEPARATION)
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
	name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var rarity_lbl := Label.new()
	var sex_key: String = "sex." + str(r.get("sex", "male"))
	var sex_text: String = _localized_text(sex_key, str(r.get("sex", "male")))
	rarity_lbl.text = _localized_rarity(rarity) + "  •  " + sex_text
	rarity_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	rarity_lbl.add_theme_color_override("font_color", border_col)
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(rarity_lbl)

	if rarity == "exceptional":
		var hl_lbl := Label.new()
		hl_lbl.text = _localized_text("hatch.exceptional", "Exceptional hatch!")
		hl_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		hl_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.20, 1.0))
		hl_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(hl_lbl)
	elif rarity == "ultra_rare":
		var hl_lbl := Label.new()
		hl_lbl.text = _localized_text("hatch.ultra_rare", "Ultra Rare hatch!")
		hl_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		hl_lbl.add_theme_color_override("font_color", Color(0.80, 0.40, 1.0, 1.0))
		hl_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(hl_lbl)

	if is_new:
		var disc_lbl := Label.new()
		disc_lbl.text = _localized_text("hatch.new_discovery", "New discovery!")
		disc_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
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
	outer.name = "UPOuter"
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.text = _localized_text("incubator.upgrades_title", "Incubator Upgrades")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "UPScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_configure_scroll_container(scroll)
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
	close_btn.custom_minimum_size = Vector2(BACK_BTN_MIN_W, BUTTON_HEIGHT)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: _upgrades_overlay.visible = false)
	close_row.add_child(close_btn)


func _populate_upgrades_overlay() -> void:
	if _upgrades_overlay == null:
		return
	var content: VBoxContainer = _upgrades_overlay.get_node_or_null(
		"UPPanel/UPOuter/UPScroll/UPContent") as VBoxContainer
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
	icon.custom_minimum_size = Vector2(ICON_SIZE_UPGRADE, ICON_SIZE_UPGRADE)
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
	name_lbl.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_desc_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = _localized_text(str(upgrade.get("description_key", "")), "")
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", META_FONT_SIZE)
	desc_lbl.add_theme_color_override("font_color", Color(0.68, 0.62, 0.50, 0.85))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_desc_vbox.add_child(desc_lbl)

	var level_lbl := Label.new()
	level_lbl.text = _localized_text("upgrade.level_label", "Level") + ": " + str(level) + "/" + str(max_level)
	level_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	level_lbl.add_theme_color_override("font_color", Color(0.80, 0.75, 0.60, 1.0))
	level_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(level_lbl)

	var effect_text: String = _get_incubator_upgrade_effect_text(upgrade_id, level, upgrade)
	if not effect_text.is_empty():
		var effect_lbl := Label.new()
		effect_lbl.text = effect_text
		effect_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
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
		max_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		max_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.40, 1.0))
		max_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buy_row.add_child(max_lbl)
	else:
		var cost_lbl := Label.new()
		cost_lbl.text = str(cost) + " R$"
		cost_lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.83, 0.38, 1.0))
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buy_row.add_child(cost_lbl)

		var can_afford: bool = EconomySystem.can_afford("repticash", cost)
		var buy_btn := Button.new()
		buy_btn.text = _localized_text("button.buy", "Kup")
		buy_btn.focus_mode = Control.FOCUS_NONE
		buy_btn.disabled = not can_afford
		buy_btn.custom_minimum_size = Vector2(90, BUTTON_HEIGHT)
		buy_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
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

func _add_quests_overlay() -> void:
	_quests_overlay = Control.new()
	_quests_overlay.name = "QuestsOverlay"
	_quests_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quests_overlay.visible = false
	_quests_overlay.z_index = 126
	add_child(_quests_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_quests_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "QPanel"
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
	_quests_overlay.add_child(panel)

	var outer := VBoxContainer.new()
	outer.name = "QOuter"
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.text = _localized_text("task_category_incubator_name", "Incubator") + " - " + _localized_text("quests.title", "Quests")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	outer.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.40, 0.20, 0.70))
	outer.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.name = "QScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_configure_scroll_container(scroll)
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "QContent"
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
	close_btn.custom_minimum_size = Vector2(BACK_BTN_MIN_W, BUTTON_HEIGHT)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: _quests_overlay.visible = false)
	close_row.add_child(close_btn)


func _populate_quests_overlay() -> void:
	if _quests_overlay == null:
		return
	var content: VBoxContainer = _quests_overlay.get_node_or_null(
		"QPanel/QOuter/QScroll/QContent") as VBoxContainer
	if content == null:
		return
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	if not has_node("/root/QuestSystem"):
		content.add_child(_make_quest_empty_label(_localized_text("quests.no_quests", "No active quests")))
		return

	var states: Array = QuestSystem.get_all_quests(false)
	var added := false
	for state_value in states:
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = state_value as Dictionary
		if str(state.get("category", "")) != "incubator_tasks":
			continue
		if not bool(state.get("is_active", true)) and not bool(state.get("claimed", false)):
			continue
		content.add_child(_make_incubator_quest_card(state))
		added = true

	if not added:
		content.add_child(_make_quest_empty_label(_localized_text("quests.no_quests", "No active quests")))
	_make_scroll_safe(content)


func _make_quest_empty_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.76, 0.70, 0.58, 0.95))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_incubator_quest_card(state: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	var completed: bool = bool(state.get("completed", false))
	var claimed: bool = bool(state.get("claimed", false))
	var claimable: bool = bool(state.get("claimable", false))
	cs.bg_color = Color(0.13, 0.09, 0.06, 0.90)
	cs.border_color = Color(0.30, 0.75, 0.35, 0.85) if completed else Color(0.60, 0.45, 0.22, 0.75)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(10)
	cs.content_margin_left = CARD_CONTENT_MARGIN
	cs.content_margin_right = CARD_CONTENT_MARGIN
	cs.content_margin_top = CARD_CONTENT_MARGIN
	cs.content_margin_bottom = CARD_CONTENT_MARGIN
	card.add_theme_stylebox_override("panel", cs)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", CARD_SEPARATION)
	row.add_child(info)

	var title := Label.new()
	title.text = _localized_text(str(state.get("title_key", "")), str(state.get("id", "")))
	title.clip_text = true
	title.add_theme_font_size_override("font_size", ROW_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(title)

	var desc := Label.new()
	desc.text = _localized_text(str(state.get("description_key", "")), "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", META_FONT_SIZE)
	desc.add_theme_color_override("font_color", Color(0.68, 0.62, 0.50, 0.88))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(desc)

	var current: int = int(state.get("current", 0))
	var target: int = max(1, int(state.get("target", 1)))
	var displayed_current: int = target if completed else current
	var progress := Label.new()
	progress.text = _localized_text("quests.progress", "Progress") + ": " + str(displayed_current) + "/" + str(target)
	progress.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	progress.add_theme_color_override("font_color", Color(0.95, 0.83, 0.38, 1.0))
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(progress)

	var reward := Label.new()
	reward.text = _format_quest_reward_text(state)
	reward.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	reward.add_theme_color_override("font_color", Color(0.55, 0.88, 0.55, 1.0))
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(reward)

	var action_col := VBoxContainer.new()
	action_col.custom_minimum_size = Vector2(130, 0)   # QUEST_ACTION_COL_W
	action_col.alignment = BoxContainer.ALIGNMENT_CENTER
	action_col.add_theme_constant_override("separation", 6)
	row.add_child(action_col)

	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	status.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60, 1.0))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_col.add_child(status)

	if claimed:
		status.text = _localized_text("quests.claimed", "Claimed")
	elif claimable:
		status.text = _localized_text("quests.completed", "Completed")
		var claim_btn := Button.new()
		claim_btn.text = _localized_text("quests.claim", "Claim")
		claim_btn.focus_mode = Control.FOCUS_NONE
		claim_btn.custom_minimum_size = Vector2(120, BUTTON_HEIGHT)
		claim_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var quest_id: String = str(state.get("id", ""))
		claim_btn.pressed.connect(func() -> void:
			_claim_incubator_quest(quest_id)
		)
		action_col.add_child(claim_btn)
	else:
		status.text = _localized_text("quests.in_progress", "In progress")

	return card


func _claim_incubator_quest(quest_id: String) -> void:
	var result: Dictionary = QuestSystem.claim_quest_reward(quest_id)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message_key", "quests.in_progress")), "In progress")
		return
	_populate_quests_overlay()
	_show_toast_raw(_format_quest_claim_text(result))


func _format_quest_reward_text(state: Dictionary) -> String:
	var pieces: Array[String] = []
	var reward_amount: float = float(state.get("reward_amount", 0.0))
	if reward_amount > 0.0:
		pieces.append(_localized_text("currency.repticash", "R$") + " " + _format_reward_amount(reward_amount))
	var reward_xp: float = float(state.get("reward_xp", 0.0))
	if reward_xp > 0.0:
		pieces.append(_format_reward_amount(reward_xp) + " XP")
	_append_quest_capacity_reward_pieces(pieces, state)
	return _localized_text("quests.reward", "Reward") + ": " + _join_reward_pieces(pieces, " + ")


func _format_quest_claim_text(result: Dictionary) -> String:
	var pieces: Array[String] = []
	var reward_amount: float = float(result.get("reward_amount", 0.0))
	if reward_amount > 0.0:
		pieces.append("+" + _localized_text("currency.repticash", "R$") + " " + _format_reward_amount(reward_amount))
	var reward_xp: float = float(result.get("reward_xp", 0.0))
	if reward_xp > 0.0:
		pieces.append("+" + _format_reward_amount(reward_xp) + " XP")
	_append_quest_capacity_reward_pieces(pieces, result)
	return _join_reward_pieces(pieces, "  ")


func _append_quest_capacity_reward_pieces(pieces: Array[String], source: Dictionary) -> void:
	var reward_food_max: int = max(0, int(source.get("reward_food_max", 0)))
	if reward_food_max > 0:
		pieces.append(_localized_text("quests.reward_food_max", "Food cap +{amount}").replace("{amount}", str(reward_food_max)))
	var reward_water_max: int = max(0, int(source.get("reward_water_max", 0)))
	if reward_water_max > 0:
		pieces.append(_localized_text("quests.reward_water_max", "Water cap +{amount}").replace("{amount}", str(reward_water_max)))


func _format_reward_amount(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return str(snappedf(value, 0.01))


func _join_reward_pieces(pieces: Array[String], separator: String) -> String:
	var text := ""
	for piece in pieces:
		if text.is_empty():
			text = piece
		else:
			text += separator + piece
	return text


func _on_language_changed(_language: String) -> void:
	_rebuild_layout_preserving_scroll(_scroll_offset)
