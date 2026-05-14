extends Control

const AssetPaths := preload("res://scripts/helpers/AssetPaths.gd")

const TOP_BAR_SCENE := preload("res://scenes/ui/TopBar.tscn")
const BOTTOM_NAV_SCENE := preload("res://scenes/ui/BottomNav.tscn")
const HABITAT_SLOT_SCENE := preload("res://scenes/habitat/HabitatSlot.tscn")

const BACKGROUND_PATH := "res://assets/art/biomes/green_meadow_background.png"
const LOGO_PATH := "res://assets/art/ui/logo.png"
const EDIT_ICON_PATH := "res://assets/art/ui/icons/menu/edit_icon.png"
const MALE_ICON_PATH := "res://assets/art/ui/icons/menu/male.png"
const FEMALE_ICON_PATH := "res://assets/art/ui/icons/menu/female.png"
const FREE_ICON_PATH := "res://assets/art/ui/icons/menu/free.png"
const ASSIGNED_ICON_PATH := "res://assets/art/ui/icons/menu/in_habitad.png"
const HAPPY_ICON_PATH := "res://assets/art/ui/icons/menu/happy.png"
const INCOME_ICON_PATH := "res://assets/art/ui/icons/menu/income.png"
const FOOD_ICON_PATH := "res://assets/art/ui/icons/menu/food.png"
const WATER_ICON_PATH := "res://assets/art/ui/icons/menu/water.png"
const CLEAN_ICON_PATH := "res://assets/art/ui/icons/menu/clean.png"
const PLAY_ICON_PATH := "res://assets/art/ui/icons/menu/play.png"
const FOOD_ACTION_ICON_PATH := "res://assets/art/ui/icons/menu/food_add.png"
const WATER_ACTION_ICON_PATH := "res://assets/art/ui/icons/menu/wather_add.png"
const CLEAN_ACTION_ICON_PATH := "res://assets/art/ui/icons/menu/clean_add.png"
const COOLDOWN_ICON_PATH := "res://assets/art/ui/icons/menu/cooldown.png"
const ALERT_ICON_PATH := "res://assets/art/ui/icons/menu/alert.png"
const HABITATS_PATH := "res://data/habitats.json"

const BIOME_ID := "green_meadow"
const STATE_NOT_PURCHASED := "not_purchased"
const STATE_PURCHASED_EMPTY := "purchased_empty"
const STATE_OCCUPIED := "occupied"
const TOP_BAR_HEIGHT := 78
const BOTTOM_NAV_HEIGHT := 176
const POPUP_TEXT_PRIMARY := Color(0.14, 0.10, 0.07, 1.0)
const POPUP_TEXT_SECONDARY := Color(0.28, 0.22, 0.15, 1.0)
const POPUP_TEXT_ACCENT := Color(0.35, 0.24, 0.08, 1.0)
const POPUP_TEXT_SUCCESS := Color(0.10, 0.36, 0.14, 1.0)
const BUTTON_TEXT_COLOR := Color(1.0, 0.98, 0.90, 1.0)
const RARITY_ICON_SIZE := Vector2(32, 32)
const MANAGEMENT_PORTRAIT_SIZE := Vector2(520, 520)
const DISCOVERY_PORTRAIT_SIZE := Vector2(132, 132)
const DISCOVERY_RARITY_ICON_SIZE := Vector2(112, 112)
const LOGO_SIZE := Vector2(150, 112)
const NAME_MAX_LENGTH := 16
const GALLERY_REPTILE_IDS := ["leopard_gecko", "bearded_dragon", "corn_snake", "steppe_tortoise", "small_monitor"]
const GALLERY_RARITIES := ["common", "rare", "exceptional", "ultra_rare"]

var habitat_data: Array = []
var habitat_slots: Dictionary = {}
var action_popup: PopupPanel
var reptile_selection_modal: Control
var management_modal: Control
var habitat_purchase_modal: Control
var variant_discovery_modal: Control
var naming_modal: Control
var shop_view: Control
var animals_view: Control
var pending_name_instance_id: String = ""
var current_management_instance_id: String = ""
var current_management_feedback_key: String = ""
var care_update_timer: Timer


func _ready() -> void:
	ReptileSystem.migrate_save_state()
	ReptileSystem.apply_time_updates(true)
	habitat_data = _load_habitats()
	_build_layout()
	_setup_care_update_timer()
	if EconomySystem.has_signal("income_progress_updated"):
		EconomySystem.income_progress_updated.connect(_on_income_progress_updated)
	if EconomySystem.has_signal("income_tick"):
		EconomySystem.income_tick.connect(_on_income_tick)
	GameState.language_changed.connect(func(_language: String) -> void: _rebuild_layout())
	GameState.state_changed.connect(_refresh_habitat_slots)


func _rebuild_layout() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	habitat_slots.clear()
	action_popup = null
	reptile_selection_modal = null
	management_modal = null
	habitat_purchase_modal = null
	variant_discovery_modal = null
	naming_modal = null
	shop_view = null
	animals_view = null
	pending_name_instance_id = ""
	current_management_instance_id = ""
	current_management_feedback_key = ""
	care_update_timer = null
	_build_layout()
	_setup_care_update_timer()


func _setup_care_update_timer() -> void:
	if care_update_timer != null:
		care_update_timer.queue_free()

	care_update_timer = Timer.new()
	care_update_timer.name = "CareUpdateTimer"
	care_update_timer.wait_time = 1.0
	care_update_timer.autostart = true
	care_update_timer.timeout.connect(_on_care_update_timer_timeout)
	add_child(care_update_timer)


func _on_care_update_timer_timeout() -> void:
	ReptileSystem.apply_time_updates(false)
	_refresh_habitat_slots()
	if management_modal != null and not current_management_instance_id.is_empty():
		_show_management_for_instance_id(current_management_instance_id, false)


func _on_income_progress_updated(_progress: float, _time_left: int) -> void:
	_refresh_habitat_income_progress()


func _on_income_tick(amount: float) -> void:
	if amount <= 0.0:
		return

	_show_income_float(amount)
	_refresh_habitat_income_progress()


func _build_layout() -> void:
	_add_background()
	_add_top_bar()
	_add_map_area()
	_add_top_logo()
	_add_bottom_nav()


func _add_background() -> void:
	var background: TextureRect = TextureRect.new()
	background.name = "GreenMeadowBackground"
	background.texture = AssetPaths.load_texture(BACKGROUND_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	if background.texture != null:
		return

	var fallback := ColorRect.new()
	fallback.name = "BackgroundFallback"
	fallback.color = Color(0.45, 0.75, 0.45, 1.0)
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fallback)
	move_child(fallback, 0)


func _add_top_bar() -> void:
	var top_bar: Control = TOP_BAR_SCENE.instantiate() as Control
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = TOP_BAR_HEIGHT
	add_child(top_bar)


func _add_top_logo() -> void:
	var logo_texture: Texture2D = AssetPaths.load_texture(LOGO_PATH)
	if logo_texture == null:
		push_warning("Top-left logo missing: " + LOGO_PATH)
		return

	var logo: TextureRect = TextureRect.new()
	logo.name = "GameLogo"
	logo.texture = logo_texture
	logo.anchor_left = 0.0
	logo.anchor_top = 0.0
	logo.anchor_right = 0.0
	logo.anchor_bottom = 0.0
	logo.offset_left = 10.0
	logo.offset_top = 0.0
	logo.offset_right = 10.0 + LOGO_SIZE.x
	logo.offset_bottom = LOGO_SIZE.y
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)


func _add_bottom_nav() -> void:
	var bottom_nav: Control = BOTTOM_NAV_SCENE.instantiate() as Control
	bottom_nav.name = "BottomNav"
	bottom_nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_nav.offset_top = -BOTTOM_NAV_HEIGHT
	bottom_nav.offset_bottom = 0
	if bottom_nav.has_signal("nav_pressed"):
		bottom_nav.connect("nav_pressed", Callable(self, "_on_bottom_nav_pressed"))
	add_child(bottom_nav)


func _add_map_area() -> void:
	var play_area := Control.new()
	play_area.name = "PlayArea"
	play_area.anchor_left = 0.0
	play_area.anchor_top = 0.0
	play_area.anchor_right = 1.0
	play_area.anchor_bottom = 1.0
	play_area.offset_top = TOP_BAR_HEIGHT + 16
	play_area.offset_bottom = -(BOTTOM_NAV_HEIGHT + 18)
	add_child(play_area)

	_add_habitat_slots(play_area)


func _add_habitat_slots(parent: Control) -> void:
	var default_size := Vector2(260, 220)
	var empty_size := Vector2(130, 130)
	var purchased_size := Vector2(273, 273)
	# Manual Green Meadow tuning: final position = base_position + offset_percent / 100.
	# Empty buy placeholders and purchased habitat visuals then receive separate
	# state offsets, also expressed as percentages of this biome map container.
	var slot_configs := [
		{
			"name": "slot_1_left_top",
			"base_position": Vector2(0.225, 0.145),
			"offset_percent": Vector2(10, 4),
			"empty_state_offset_percent": Vector2.ZERO,
			"purchased_state_offset_percent": Vector2.ZERO,
			"size": default_size,
			"empty_offset": Vector2(0, 2),
			"purchased_offset": Vector2(-10, -20)
		},
		{
			"name": "slot_2_left_middle",
			"base_position": Vector2(0.325, 0.365),
			"offset_percent": Vector2(-2, 7.5),
			"empty_state_offset_percent": Vector2(0, -3),
			"purchased_state_offset_percent": Vector2.ZERO,
			"size": default_size,
			"empty_offset": Vector2(-2, 2),
			"purchased_offset": Vector2(-6, -12)
		},
		{
			"name": "slot_3_left_bottom",
			"base_position": Vector2(0.220, 0.660),
			"offset_percent": Vector2(8, 5),
			"empty_state_offset_percent": Vector2(0, -3),
			"purchased_state_offset_percent": Vector2.ZERO,
			"size": default_size,
			"empty_offset": Vector2(-2, 2),
			"purchased_offset": Vector2(-8, -12)
		},
		{
			"name": "slot_4_right_top",
			"base_position": Vector2(0.605, 0.170),
			"offset_percent": Vector2(9, 14),
			"empty_state_offset_percent": Vector2.ZERO,
			"purchased_state_offset_percent": Vector2.ZERO,
			"size": default_size,
			"empty_offset": Vector2(2, 0),
			"purchased_offset": Vector2(0, -16)
		},
		{
			"name": "slot_5_right_middle",
			"base_position": Vector2(0.725, 0.430),
			"offset_percent": Vector2(-4, 18),
			"empty_state_offset_percent": Vector2(0, -3),
			"purchased_state_offset_percent": Vector2(0, -1),
			"size": default_size,
			"empty_offset": Vector2(4, 0),
			"purchased_offset": Vector2(8, -14)
		},
		{
			"name": "slot_6_right_bottom",
			"base_position": Vector2(0.575, 0.755),
			"offset_percent": Vector2(12, 8),
			"empty_state_offset_percent": Vector2(0, -3),
			"purchased_state_offset_percent": Vector2.ZERO,
			"size": default_size,
			"empty_offset": Vector2(0, 2),
			"purchased_offset": Vector2(0, -12)
		}
	]

	var count: int = int(min(habitat_data.size(), slot_configs.size()))
	for index in count:
		var habitat: Dictionary = habitat_data[index] as Dictionary
		var slot_config: Dictionary = slot_configs[index] as Dictionary
		var base_position: Vector2 = slot_config.get("base_position", Vector2.ZERO) as Vector2
		var offset_percent: Vector2 = slot_config.get("offset_percent", Vector2.ZERO) as Vector2
		var slot_position: Vector2 = base_position + (offset_percent / 100.0)
		var slot_size: Vector2 = slot_config.get("size", default_size) as Vector2
		var empty_offset: Vector2 = slot_config.get("empty_offset", Vector2.ZERO) as Vector2
		var purchased_offset: Vector2 = slot_config.get("purchased_offset", Vector2(0, -14)) as Vector2
		var empty_state_offset_percent: Vector2 = slot_config.get("empty_state_offset_percent", Vector2.ZERO) as Vector2
		var purchased_state_offset_percent: Vector2 = slot_config.get("purchased_state_offset_percent", Vector2.ZERO) as Vector2
		var empty_state_offset: Vector2 = Vector2(
			parent.size.x * empty_state_offset_percent.x / 100.0,
			parent.size.y * empty_state_offset_percent.y / 100.0
		)
		var purchased_state_offset: Vector2 = Vector2(
			parent.size.x * purchased_state_offset_percent.x / 100.0,
			parent.size.y * purchased_state_offset_percent.y / 100.0
		)
		var slot: Control = HABITAT_SLOT_SCENE.instantiate() as Control
		var habitat_id: String = str(habitat.get("id", ""))
		var slot_index: int = int(habitat.get("slot_index", index + 1))
		var state: String = _get_habitat_state(habitat_id)

		slot.name = "HabitatSlot" + str(slot_index)
		slot.anchor_left = slot_position.x
		slot.anchor_top = slot_position.y
		slot.anchor_right = slot_position.x
		slot.anchor_bottom = slot_position.y
		slot.offset_left = -slot_size.x * 0.5
		slot.offset_top = -slot_size.y * 0.5
		slot.offset_right = slot_size.x * 0.5
		slot.offset_bottom = slot_size.y * 0.5
		slot.call(
			"set_visual_tuning",
			empty_size,
			purchased_size,
			empty_offset + empty_state_offset,
			purchased_offset + purchased_state_offset
		)
		slot.call("setup", habitat_id, slot_index, state)
		slot.call("set_occupied_icon", _get_habitat_reptile_icon_path(habitat_id) if state == STATE_OCCUPIED else "")
		slot.connect("habitat_pressed", Callable(self, "_on_habitat_pressed"))
		parent.add_child(slot)
		habitat_slots[habitat_id] = slot


func _on_habitat_pressed(habitat_id: String) -> void:
	var habitat: Dictionary = _get_habitat_data(habitat_id)
	if habitat.is_empty():
		return

	var state: String = _get_habitat_state(habitat_id)
	if state == STATE_NOT_PURCHASED:
		_show_purchase_popup(habitat)
	elif state == STATE_PURCHASED_EMPTY:
		_show_reptile_assignment_popup(habitat_id)
	else:
		_show_management_popup(habitat_id)


func _show_purchase_popup(habitat: Dictionary) -> void:
	_close_habitat_purchase_modal()

	var habitat_id: String = str(habitat.get("id", ""))
	var slot_index: int = int(habitat.get("slot_index", 0))
	var purchase_cost: int = EconomySystem.get_next_habitat_price(BIOME_ID, habitat_data.size())

	habitat_purchase_modal = Control.new()
	habitat_purchase_modal.name = "HabitatPurchaseModal"
	habitat_purchase_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(habitat_purchase_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	habitat_purchase_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	habitat_purchase_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 260)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.habitat"), 22)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	if purchase_cost < 0:
		var sold_out_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.all_habitats_purchased"), 15)
		_apply_label_color(sold_out_label, POPUP_TEXT_SECONDARY)
		column.add_child(sold_out_label)
	else:
		var price_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.price") + ": " + LocalizationSystem.tr_key("currency.repticash") + " " + str(purchase_cost), 16)
		_apply_label_color(price_label, POPUP_TEXT_SECONDARY)
		column.add_child(price_label)

	var buy_button: Button = _make_popup_button("ui.buy_habitat", func() -> void:
		_try_purchase_habitat(habitat_id, slot_index)
	)
	buy_button.disabled = purchase_cost < 0
	buy_button.custom_minimum_size = Vector2(0, 48)
	buy_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	buy_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	buy_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	buy_button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	_apply_button_text_color(buy_button, BUTTON_TEXT_COLOR)
	column.add_child(buy_button)
	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_habitat_purchase_modal()
	))


func _show_placeholder_popup(title_key: String, body_key: String) -> void:
	var popup: PopupPanel = _create_action_popup()
	var column: VBoxContainer = _add_popup_column(popup)

	column.add_child(_make_popup_label(LocalizationSystem.tr_key(title_key), 20))
	column.add_child(_make_popup_label(LocalizationSystem.tr_key(body_key), 14))
	column.add_child(_make_popup_button("ui.open_management" if title_key == "ui.reptile_management" else "ui.add_reptile", func() -> void:
		popup.hide()
	))
	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		popup.hide()
	))

	popup.popup_centered(Vector2(360, 230))


func _show_reptile_assignment_popup(habitat_id: String) -> void:
	_close_reptile_selection_modal()

	reptile_selection_modal = Control.new()
	reptile_selection_modal.name = "ReptileAssignmentModal"
	reptile_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(reptile_selection_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reptile_selection_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 20
	center.offset_right = -20
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	reptile_selection_modal.add_child(center)

	var viewport_size: Vector2 = get_viewport_rect().size
	var modal_width: float = min(max(viewport_size.x * 0.9, 560.0), viewport_size.x - 40.0)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(modal_width, 610)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.choose_reptile"), 21)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(88, 42)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	close_button.pressed.connect(_close_reptile_selection_modal)
	header.add_child(close_button)

	var subtitle: Label = _make_popup_label(LocalizationSystem.tr_key("ui.available_reptiles"), 13)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_color(subtitle, POPUP_TEXT_SECONDARY)
	column.add_child(subtitle)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 450)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	var instances: Array = ReptileSystem.get_owned_unassigned_reptiles()
	if instances.is_empty():
		_close_reptile_selection_modal()
		_show_no_available_reptiles_popup()
		return

	for instance_value in instances:
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		var instance: Dictionary = instance_value as Dictionary
		list.add_child(_make_assignable_reptile_card(instance, habitat_id))

	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_reptile_selection_modal()
	))


func _show_no_available_reptiles_popup() -> void:
	_close_reptile_selection_modal()

	reptile_selection_modal = Control.new()
	reptile_selection_modal.name = "NoAvailableReptilesModal"
	reptile_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(reptile_selection_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reptile_selection_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	reptile_selection_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 260)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.no_available_reptiles"), 20)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var message: Label = _make_popup_label(LocalizationSystem.tr_key("ui.no_available_reptiles_message"), 14)
	_apply_label_color(message, POPUP_TEXT_SECONDARY)
	column.add_child(message)

	var open_shop: Button = _make_popup_button("ui.open_shop", func() -> void:
		_close_reptile_selection_modal()
		_show_shop_view()
	)
	open_shop.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	open_shop.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	open_shop.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(open_shop, BUTTON_TEXT_COLOR)
	column.add_child(open_shop)

	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_reptile_selection_modal()
	))


func _make_assignable_reptile_card(instance: Dictionary, habitat_id: String) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 140)
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var reptile_id: String = str(instance.get("reptile_id", ""))
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var variant: Dictionary = ReptileSystem.get_owned_animal_variant(instance)

	var icon: TextureRect = _make_fixed_texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2(88, 88))
	row.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = _get_reptile_display_name(instance, reptile)
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 15)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var species_label: Label = Label.new()
	species_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	species_label.clip_text = true
	species_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(species_label, POPUP_TEXT_SECONDARY)
	info.add_child(species_label)

	var variant_label: Label = Label.new()
	variant_label.text = LocalizationSystem.tr_key("ui.variant") + ": " + LocalizationSystem.tr_key(str(variant.get("name_key", "ui.variant")))
	variant_label.clip_text = true
	variant_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(variant_label, POPUP_TEXT_SECONDARY)
	info.add_child(variant_label)

	var rarity_row: HBoxContainer = HBoxContainer.new()
	rarity_row.add_theme_constant_override("separation", 6)
	info.add_child(rarity_row)
	rarity_row.add_child(_make_rarity_icon(str(variant.get("rarity_icon_path", "")), RARITY_ICON_SIZE))

	var rarity: Label = Label.new()
	rarity.text = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common"))))
	rarity.clip_text = true
	rarity.add_theme_font_size_override("font_size", 12)
	_apply_label_color(rarity, POPUP_TEXT_ACCENT)
	rarity_row.add_child(rarity)

	var sex_label: Label = Label.new()
	sex_label.text = LocalizationSystem.tr_key("ui.sex") + ": " + _get_localized_sex(str(instance.get("sex", "male")))
	sex_label.clip_text = true
	sex_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(sex_label, POPUP_TEXT_SECONDARY)
	info.add_child(sex_label)

	var action_area: CenterContainer = CenterContainer.new()
	action_area.custom_minimum_size = Vector2(104, 0)
	row.add_child(action_area)

	var button: Button = Button.new()
	button.text = LocalizationSystem.tr_key("ui.place_reptile")
	button.custom_minimum_size = Vector2(96, 48)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)
	button.pressed.connect(func() -> void:
		_place_owned_reptile(str(instance.get("instance_id", "")), habitat_id)
	)
	action_area.add_child(button)

	return card


func _make_shop_reptile_card(reptile: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 174)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var reptile_id: String = str(reptile.get("id", ""))
	var variant: Dictionary = ReptileSystem.get_variant_for_reptile(reptile_id, str(reptile.get("default_variant_id", "")))

	var icon: TextureRect = _make_fixed_texture(_get_variant_image_path(reptile, variant, true), Vector2(92, 92))
	row.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 15)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var rarity_row: HBoxContainer = HBoxContainer.new()
	rarity_row.add_theme_constant_override("separation", 6)
	info.add_child(rarity_row)

	rarity_row.add_child(_make_rarity_icon(str(variant.get("rarity_icon_path", "")), RARITY_ICON_SIZE))

	var rarity: Label = Label.new()
	rarity.text = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common"))))
	rarity.clip_text = true
	rarity.add_theme_font_size_override("font_size", 12)
	_apply_label_color(rarity, POPUP_TEXT_ACCENT)
	rarity_row.add_child(rarity)

	var income: Label = Label.new()
	income.text = LocalizationSystem.tr_key("ui.base_income") + ": " + LocalizationSystem.tr_key("currency.repticash") + " " + str(int(reptile.get("base_income_per_minute", 0))) + " " + LocalizationSystem.tr_key("ui.per_minute")
	income.clip_text = true
	income.add_theme_font_size_override("font_size", 12)
	_apply_label_color(income, POPUP_TEXT_SECONDARY)
	info.add_child(income)

	var sex_row: HBoxContainer = HBoxContainer.new()
	sex_row.add_theme_constant_override("separation", 6)
	info.add_child(sex_row)

	var sex_label: Label = Label.new()
	sex_label.text = LocalizationSystem.tr_key("ui.sex") + ":"
	sex_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(sex_label, POPUP_TEXT_SECONDARY)
	sex_row.add_child(sex_label)

	var sex_selector: OptionButton = OptionButton.new()
	sex_selector.custom_minimum_size = Vector2(122, 34)
	sex_selector.add_item(LocalizationSystem.tr_key("ui.male"), 0)
	sex_selector.add_item(LocalizationSystem.tr_key("ui.female"), 1)
	sex_row.add_child(sex_selector)

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = Vector2(154, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", 8)
	row.add_child(action_area)

	action_area.add_child(_make_shop_variant_button(reptile_id, "common", sex_selector))
	action_area.add_child(_make_shop_variant_button(reptile_id, "rare", sex_selector))

	return card


func _make_shop_variant_button(reptile_id: String, rarity: String, sex_selector: OptionButton) -> Button:
	var variant: Dictionary = ReptileSystem.get_shop_variant_for_rarity(reptile_id, rarity)
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(146, 56)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.45, 0.45, 0.42, 0.75)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)

	var rarity_label: String = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(rarity))

	if variant.is_empty():
		button.text = rarity_label + "\n" + LocalizationSystem.tr_key("shop.unavailable")
		button.disabled = true
		return button

	var price: int = ReptileSystem.get_shop_purchase_price(reptile_id, rarity)
	var price_text: String = LocalizationSystem.tr_key("ui.free") if price == 0 else LocalizationSystem.tr_key("currency.repticash") + " " + str(price)
	button.text = LocalizationSystem.tr_key("ui.buy") + " " + rarity_label + "\n" + price_text
	button.disabled = price > 0 and not EconomySystem.can_afford("repticash", price)
	button.pressed.connect(func() -> void:
		_try_shop_buy_reptile(reptile_id, rarity, _get_selected_sex(sex_selector))
	)
	return button


func _place_owned_reptile(instance_id: String, habitat_id: String) -> void:
	var result: Dictionary = ReptileSystem.assign_reptile_to_habitat(instance_id, habitat_id, BIOME_ID)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.not_enough_currency")))
		return

	_refresh_habitat_slots()
	_close_reptile_selection_modal()
	if action_popup != null:
		action_popup.hide()


func _show_management_popup(habitat_id: String) -> void:
	current_management_feedback_key = ""
	var instance: Dictionary = ReptileSystem.get_reptile_for_habitat(habitat_id)
	_show_management_for_instance(instance)


func _show_management_for_instance_id(instance_id: String, clear_feedback: bool = true) -> void:
	if clear_feedback:
		current_management_feedback_key = ""

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	if typeof(instance_value) != TYPE_DICTIONARY:
		_show_message_popup("ui.reptile_unavailable")
		return

	_show_management_for_instance(instance_value as Dictionary)


func _show_management_for_instance(instance: Dictionary) -> void:
	var preserved_feedback_key: String = current_management_feedback_key
	_close_management_modal()
	current_management_feedback_key = preserved_feedback_key
	if instance.is_empty():
		_show_message_popup("ui.reptile_unavailable")
		return
	current_management_instance_id = str(instance.get("instance_id", ""))

	var reptile: Dictionary = ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))
	var variant: Dictionary = ReptileSystem.get_owned_animal_variant(instance)
	var is_assigned: bool = _is_reptile_instance_assigned(instance)

	management_modal = Control.new()
	management_modal.name = "ReptileManagementModal"
	management_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(management_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	management_modal.add_child(overlay)

	var sheet_height: float = get_viewport_rect().size.y * 0.65

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ManagementSheet"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = -sheet_height
	panel.offset_bottom = 0
	panel.add_theme_stylebox_override("panel", _make_bottom_sheet_style())
	management_modal.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.reptile_management"), 21)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var header_close: Button = Button.new()
	header_close.text = LocalizationSystem.tr_key("ui.close")
	header_close.custom_minimum_size = Vector2(88, 42)
	_apply_button_text_color(header_close, POPUP_TEXT_PRIMARY)
	header_close.pressed.connect(_close_management_modal)
	header.add_child(header_close)

	var body: Control = Control.new()
	body.custom_minimum_size = Vector2(0, 470)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	var portrait: TextureRect = TextureRect.new()
	portrait.name = "DecorativePortrait"
	portrait.texture = AssetPaths.load_texture(ReptileSystem.get_owned_animal_image_path(instance))
	portrait.anchor_left = 1.0
	portrait.anchor_top = 1.0
	portrait.anchor_right = 1.0
	portrait.anchor_bottom = 1.0
	var portrait_overflow: float = MANAGEMENT_PORTRAIT_SIZE.x * 0.15 + 24.0
	portrait.offset_left = -MANAGEMENT_PORTRAIT_SIZE.x + portrait_overflow
	portrait.offset_top = -MANAGEMENT_PORTRAIT_SIZE.y + 20.0
	portrait.offset_right = portrait_overflow
	portrait.offset_bottom = 20.0
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(portrait)

	var details: VBoxContainer = VBoxContainer.new()
	details.anchor_left = 0.0
	details.anchor_top = 0.0
	details.anchor_right = 0.62
	details.anchor_bottom = 1.0
	details.offset_left = 0.0
	details.offset_top = 10.0
	details.offset_right = -10.0
	details.offset_bottom = -10.0
	details.custom_minimum_size = Vector2(300, 220)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	details.add_theme_constant_override("separation", 9)
	body.add_child(details)

	var name_row: HBoxContainer = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(name_row)

	var name_label: Label = _make_popup_label(_get_reptile_display_name(instance, reptile), 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	name_row.add_child(name_label)

	var edit_button: Button = _make_edit_icon_button(str(instance.get("instance_id", "")))
	name_row.add_child(edit_button)

	details.add_child(_make_management_text_row("ui.species", LocalizationSystem.tr_key(str(reptile.get("name_key", "ui.reptile_management_placeholder")))))
	details.add_child(_make_management_text_row("ui.variant", LocalizationSystem.tr_key(str(variant.get("name_key", "ui.variant")))))
	details.add_child(_make_management_icon_row("ui.rarity", str(variant.get("rarity_icon_path", "")), LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common"))))))

	var sex_icon_path: String = FEMALE_ICON_PATH if str(instance.get("sex", "male")) == "female" else MALE_ICON_PATH
	details.add_child(_make_management_icon_row("ui.sex", sex_icon_path, _get_localized_sex(str(instance.get("sex", "male")))))

	var status_icon_path: String = ASSIGNED_ICON_PATH if is_assigned else FREE_ICON_PATH
	var status_key: String = "animals.status.assigned" if is_assigned else "animals.status.free"
	details.add_child(_make_management_icon_row("ui.status", status_icon_path, LocalizationSystem.tr_key(status_key)))

	if is_assigned:
		details.add_child(_make_management_text_row("ui.habitat", _get_habitat_display_name(str(instance.get("habitat_id", "")))))

	var happiness: int = _get_percent_state(instance, "happiness", 100)
	details.add_child(_make_need_bar_row("ui.happiness", HAPPY_ICON_PATH, happiness))
	var satiety: int = _get_percent_state(instance, "hunger", 100)
	details.add_child(_make_need_bar_row("ui.satiety", FOOD_ICON_PATH, satiety))
	var hydration: int = _get_percent_state(instance, "hydration", 100)
	details.add_child(_make_need_bar_row("ui.hydration", WATER_ICON_PATH, hydration))
	var cleanliness: int = _get_percent_state(instance, "cleanliness", 100)
	details.add_child(_make_need_bar_row("ui.cleanliness", CLEAN_ICON_PATH, cleanliness))

	var base_income: float = ReptileSystem.get_base_reptile_income(str(instance.get("reptile_id", "")))
	var happiness_multiplier: float = ReptileSystem.get_happiness_multiplier(instance.get("happiness", 100))
	var variant_multiplier: float = ReptileSystem.get_variant_income_multiplier(variant)
	var effective_income: float = ReptileSystem.get_effective_animal_income_per_min(instance)
	details.add_child(_make_management_icon_row("ui.base_income", INCOME_ICON_PATH, _format_repticash_per_min(base_income)))
	details.add_child(_make_management_text_row("ui.happiness_multiplier", _format_multiplier(happiness_multiplier)))
	details.add_child(_make_management_text_row("ui.variant_multiplier", _format_multiplier(variant_multiplier)))
	details.add_child(_make_management_icon_row("ui.effective_income", INCOME_ICON_PATH, _format_repticash_per_min(effective_income)))

	var care_hint_key: String = current_management_feedback_key
	if care_hint_key.is_empty() and not is_assigned:
		care_hint_key = "ui.place_reptile_to_care"
	var care_hint_text: String = LocalizationSystem.tr_key(care_hint_key) if care_hint_key.begins_with("ui.") else care_hint_key
	var placeholder_label: Label = _make_popup_label(care_hint_text, 12)
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	placeholder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(placeholder_label, POPUP_TEXT_SECONDARY)
	placeholder_label.visible = not care_hint_key.is_empty()
	details.add_child(placeholder_label)

	var care_grid: GridContainer = GridContainer.new()
	care_grid.columns = 2
	care_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	care_grid.add_theme_constant_override("h_separation", 8)
	care_grid.add_theme_constant_override("v_separation", 8)
	details.add_child(care_grid)

	care_grid.add_child(_make_care_action_button("feed", "ui.feed", FOOD_ACTION_ICON_PATH, instance, is_assigned))
	care_grid.add_child(_make_care_action_button("water", "ui.water", WATER_ACTION_ICON_PATH, instance, is_assigned))
	care_grid.add_child(_make_care_action_button("clean", "ui.clean", CLEAN_ACTION_ICON_PATH, instance, is_assigned))
	care_grid.add_child(_make_care_action_button("play", "ui.play", PLAY_ICON_PATH, instance, is_assigned))

	var footer_close: Button = _make_popup_button("ui.close", _close_management_modal)
	column.add_child(footer_close)


func _on_bottom_nav_pressed(item_id: String) -> void:
	if item_id == "biome":
		_close_animals_view()
		_close_shop_view()
		_close_management_modal()
		_close_reptile_selection_modal()
		_close_habitat_purchase_modal()
		return

	if item_id == "animals":
		_show_animals_view("owned")
		return

	if item_id == "shop":
		_show_shop_view()
		return

	_show_nav_placeholder("nav." + item_id)


func _show_nav_placeholder(title_key: String) -> void:
	_close_animals_view()
	_close_shop_view()
	_show_message_popup(title_key)


func _show_shop_view() -> void:
	_close_animals_view()
	_close_shop_view()
	_close_management_modal()
	_close_reptile_selection_modal()
	_close_habitat_purchase_modal()

	shop_view = Control.new()
	shop_view.name = "ShopView"
	shop_view.anchor_left = 0.0
	shop_view.anchor_top = 0.0
	shop_view.anchor_right = 1.0
	shop_view.anchor_bottom = 1.0
	shop_view.offset_top = TOP_BAR_HEIGHT + 10
	shop_view.offset_bottom = -(BOTTOM_NAV_HEIGHT + 8)
	add_child(shop_view)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	shop_view.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("nav.shop"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(96, 42)
	close_button.pressed.connect(_close_shop_view)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	header.add_child(close_button)

	var section: Label = _make_popup_label(LocalizationSystem.tr_key("shop.reptiles"), 17)
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_color(section, POPUP_TEXT_ACCENT)
	column.add_child(section)

	if ReptileSystem.is_first_reptile_free():
		var free_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.first_reptile_free"), 13)
		free_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_label_color(free_label, POPUP_TEXT_SUCCESS)
		column.add_child(free_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var reptiles: Array = ReptileSystem.get_available_reptiles(BIOME_ID)
	for reptile_value in reptiles:
		if typeof(reptile_value) != TYPE_DICTIONARY:
			continue

		list.add_child(_make_shop_reptile_card(reptile_value as Dictionary))


func _show_animals_view(tab_id: String = "owned") -> void:
	_close_animals_view()
	_close_shop_view()
	_close_management_modal()
	_close_reptile_selection_modal()
	_close_habitat_purchase_modal()

	animals_view = Control.new()
	animals_view.name = "AnimalsView"
	animals_view.anchor_left = 0.0
	animals_view.anchor_top = 0.0
	animals_view.anchor_right = 1.0
	animals_view.anchor_bottom = 1.0
	animals_view.offset_top = TOP_BAR_HEIGHT + 10
	animals_view.offset_bottom = -(BOTTOM_NAV_HEIGHT + 8)
	add_child(animals_view)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	animals_view.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("animals.title"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	header.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = LocalizationSystem.tr_key("ui.close")
	close_button.custom_minimum_size = Vector2(96, 42)
	close_button.pressed.connect(_close_animals_view)
	_apply_button_text_color(close_button, POPUP_TEXT_PRIMARY)
	header.add_child(close_button)

	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)

	tabs.add_child(_make_animals_tab_button("animals.tab.owned", "owned", tab_id))
	tabs.add_child(_make_animals_tab_button("animals.tab.gallery", "gallery", tab_id))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	if tab_id == "gallery":
		_populate_animals_gallery(content)
	else:
		_populate_owned_animals(content)


func _make_animals_tab_button(label_key: String, tab_id: String, active_tab_id: String) -> Button:
	var button: Button = Button.new()
	button.text = LocalizationSystem.tr_key(label_key)
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var active: bool = tab_id == active_tab_id
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.86, 0.66, 0.25, 0.95) if active else Color(0.78, 0.70, 0.55, 0.45)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.90, 0.70, 0.30, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.72, 0.54, 0.20, 0.95)))
	_apply_button_text_color(button, POPUP_TEXT_PRIMARY)
	button.pressed.connect(func() -> void:
		_show_animals_view(tab_id)
	)
	return button


func _populate_owned_animals(parent: VBoxContainer) -> void:
	var instances: Array = _get_sorted_owned_instances()
	if instances.is_empty():
		parent.add_child(_make_owned_empty_state())
		return

	for instance_value in instances:
		if typeof(instance_value) != TYPE_DICTIONARY:
			continue

		parent.add_child(_make_owned_reptile_card(instance_value as Dictionary))


func _make_owned_empty_state() -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("animals.empty_title"), 18)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var subtitle: Label = _make_popup_label(LocalizationSystem.tr_key("animals.empty_subtitle"), 14)
	_apply_label_color(subtitle, POPUP_TEXT_SECONDARY)
	column.add_child(subtitle)

	var open_shop: Button = _make_popup_button("animals.open_shop", func() -> void:
		_show_shop_view()
	)
	open_shop.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	open_shop.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	open_shop.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(open_shop, BUTTON_TEXT_COLOR)
	column.add_child(open_shop)

	return card


func _make_owned_reptile_card(instance: Dictionary) -> Control:
	var reptile_id: String = str(instance.get("reptile_id", ""))
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var variant: Dictionary = ReptileSystem.get_owned_animal_variant(instance)
	var is_assigned: bool = _is_reptile_instance_assigned(instance)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 166)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	row.add_child(_make_fixed_texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2(92, 92)))

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = _get_reptile_display_name(instance, reptile)
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 16)
	_apply_label_color(name_label, POPUP_TEXT_PRIMARY)
	info.add_child(name_label)

	var species_label: Label = Label.new()
	species_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	species_label.clip_text = true
	species_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(species_label, POPUP_TEXT_SECONDARY)
	info.add_child(species_label)

	var variant_label: Label = Label.new()
	variant_label.text = LocalizationSystem.tr_key("ui.variant") + ": " + LocalizationSystem.tr_key(str(variant.get("name_key", "ui.variant")))
	variant_label.clip_text = true
	variant_label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(variant_label, POPUP_TEXT_SECONDARY)
	info.add_child(variant_label)

	var rarity_row: HBoxContainer = _make_icon_text_row(str(variant.get("rarity_icon_path", "")), LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common")))), 28)
	info.add_child(rarity_row)

	var sex_icon_path: String = FEMALE_ICON_PATH if str(instance.get("sex", "male")) == "female" else MALE_ICON_PATH
	info.add_child(_make_icon_text_row(sex_icon_path, _get_localized_sex(str(instance.get("sex", "male"))), 28))

	var status_icon_path: String = ASSIGNED_ICON_PATH if is_assigned else FREE_ICON_PATH
	var status_key: String = "animals.status.assigned" if is_assigned else "animals.status.free"
	info.add_child(_make_icon_text_row(status_icon_path, LocalizationSystem.tr_key(status_key), 28))

	var action_area: VBoxContainer = VBoxContainer.new()
	action_area.custom_minimum_size = Vector2(112, 0)
	action_area.alignment = BoxContainer.ALIGNMENT_CENTER
	action_area.add_theme_constant_override("separation", 8)
	row.add_child(action_area)

	var manage_button: Button = _make_owned_card_action_button("animals.manage")
	manage_button.pressed.connect(func() -> void:
		_close_animals_view()
		_show_management_for_instance_id(str(instance.get("instance_id", "")))
	)
	action_area.add_child(manage_button)

	if not is_assigned:
		var assign_button: Button = _make_owned_card_action_button("animals.assign")
		assign_button.pressed.connect(func() -> void:
			_show_assign_instance_to_habitat_popup(str(instance.get("instance_id", "")))
		)
		action_area.add_child(assign_button)

	return card


func _populate_animals_gallery(parent: VBoxContainer) -> void:
	var discovered_count: int = _get_expected_gallery_discovered_count()
	var total_count: int = GALLERY_REPTILE_IDS.size() * GALLERY_RARITIES.size()
	var completion: int = int(round(float(discovered_count) / max(1.0, float(total_count)) * 100.0))

	var progress: Label = _make_popup_label(
		LocalizationSystem.tr_key("animals.gallery_progress") + "\n"
		+ LocalizationSystem.tr_key("animals.discovered") + ": " + str(discovered_count) + " / " + str(total_count) + "\n"
		+ LocalizationSystem.tr_key("animals.completion") + ": " + str(completion) + "%",
		14
	)
	_apply_label_color(progress, POPUP_TEXT_ACCENT)
	parent.add_child(progress)

	for reptile_id_value in GALLERY_REPTILE_IDS:
		parent.add_child(_make_gallery_species_section(str(reptile_id_value)))


func _make_gallery_species_section(reptile_id: String) -> Control:
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var section: PanelContainer = PanelContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_stylebox_override("panel", _make_card_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var species_label: Label = Label.new()
	species_label.text = LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))
	species_label.clip_text = true
	species_label.add_theme_font_size_override("font_size", 16)
	_apply_label_color(species_label, POPUP_TEXT_PRIMARY)
	column.add_child(species_label)

	var slot_row: HBoxContainer = HBoxContainer.new()
	slot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_row.add_theme_constant_override("separation", 8)
	column.add_child(slot_row)

	for rarity_value in GALLERY_RARITIES:
		slot_row.add_child(_make_gallery_rarity_slot(reptile_id, str(rarity_value)))

	return section


func _make_gallery_rarity_slot(reptile_id: String, rarity: String) -> Control:
	var reptile: Dictionary = ReptileSystem.get_reptile(reptile_id)
	var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(reptile_id, rarity)
	var has_variant_data: bool = not variant.is_empty()
	var variant_id: String = str(variant.get("id", ""))
	var discovered: bool = has_variant_data and ReptileSystem.is_variant_discovered(variant_id)

	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = Vector2(0, 168)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", _make_gallery_slot_style(discovered))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	slot.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var image_path: String = _get_variant_image_path(reptile, variant, false) if discovered else _get_gallery_shadow_path(reptile_id, variant)
	var image: TextureRect = _make_fixed_texture(image_path, Vector2(72, 72))
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(image)

	var rarity_icon_path: String = str(variant.get("rarity_icon_path", ReptileSystem.get_rarity_icon_path(rarity))) if has_variant_data else ReptileSystem.get_rarity_icon_path(rarity)
	var rarity_row: HBoxContainer = HBoxContainer.new()
	rarity_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rarity_row.add_theme_constant_override("separation", 4)
	column.add_child(rarity_row)

	var rarity_icon: TextureRect = _make_fixed_texture(rarity_icon_path, Vector2(22, 22))
	rarity_row.add_child(rarity_icon)

	var rarity_label: Label = Label.new()
	rarity_label.text = LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(rarity))
	rarity_label.clip_text = true
	rarity_label.add_theme_font_size_override("font_size", 11)
	_apply_label_color(rarity_label, POPUP_TEXT_ACCENT)
	rarity_row.add_child(rarity_label)

	var variant_name: String = LocalizationSystem.tr_key(str(variant.get("name_key", "ui.variant"))) if discovered else "???"
	var variant_label: Label = Label.new()
	variant_label.text = variant_name
	variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	variant_label.clip_text = true
	variant_label.add_theme_font_size_override("font_size", 11)
	_apply_label_color(variant_label, POPUP_TEXT_SECONDARY)
	column.add_child(variant_label)

	var state_key: String = "animals.discovered_state" if discovered else "animals.undiscovered_state"
	var state_label: Label = Label.new()
	state_label.text = LocalizationSystem.tr_key(state_key)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.clip_text = true
	state_label.add_theme_font_size_override("font_size", 10)
	_apply_label_color(state_label, POPUP_TEXT_SUCCESS if discovered else POPUP_TEXT_SECONDARY)
	column.add_child(state_label)

	return slot


func _try_shop_buy_reptile(reptile_id: String, rarity: String, sex: String) -> void:
	var result: Dictionary = ReptileSystem.purchase_reptile_from_shop(reptile_id, rarity, sex)
	if not bool(result.get("success", false)):
		_show_message_popup(str(result.get("message_key", "ui.not_enough_currency")))
		return

	_show_shop_view()
	if bool(result.get("new_variant_discovered", false)):
		pending_name_instance_id = str(result.get("instance_id", ""))
		_show_variant_discovery_popup(str(result.get("variant_id", "")), str(result.get("instance_id", "")))
	else:
		_show_reptile_name_popup(str(result.get("instance_id", "")), false)


func _close_shop_view() -> void:
	if shop_view == null:
		return

	shop_view.queue_free()
	shop_view = null


func _close_animals_view() -> void:
	if animals_view == null:
		return

	animals_view.queue_free()
	animals_view = null


func _show_assign_instance_to_habitat_popup(instance_id: String) -> void:
	_close_reptile_selection_modal()

	reptile_selection_modal = Control.new()
	reptile_selection_modal.name = "AssignToHabitatModal"
	reptile_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(reptile_selection_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.04, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reptile_selection_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	reptile_selection_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 420)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("animals.assign"), 20)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var found_habitat: bool = false
	for habitat_value in habitat_data:
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = habitat_value as Dictionary
		var habitat_id: String = str(habitat.get("id", ""))
		if _get_habitat_state(habitat_id) != STATE_PURCHASED_EMPTY:
			continue

		found_habitat = true
		column.add_child(_make_assign_habitat_button(instance_id, habitat_id, int(habitat.get("slot_index", 0))))

	if not found_habitat:
		var empty_label: Label = _make_popup_label(LocalizationSystem.tr_key("animals.no_empty_habitats"), 14)
		_apply_label_color(empty_label, POPUP_TEXT_SECONDARY)
		column.add_child(empty_label)

	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		_close_reptile_selection_modal()
	))


func _make_assign_habitat_button(instance_id: String, habitat_id: String, slot_index: int) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 46)
	button.text = LocalizationSystem.tr_key("ui.habitat") + " " + str(slot_index + 1)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)
	button.pressed.connect(func() -> void:
		var result: Dictionary = ReptileSystem.assign_reptile_to_habitat(instance_id, habitat_id, BIOME_ID)
		if not bool(result.get("success", false)):
			_show_message_popup(str(result.get("message_key", "ui.habitat_unavailable")))
			return

		_refresh_habitat_slots()
		_close_reptile_selection_modal()
		_show_animals_view("owned")
	)
	return button


func _try_purchase_habitat(habitat_id: String, slot_index: int) -> void:
	var purchase_cost: int = EconomySystem.get_next_habitat_price(BIOME_ID, habitat_data.size())
	if purchase_cost < 0:
		return

	if not EconomySystem.can_afford("repticash", purchase_cost):
		_show_message_popup("ui.not_enough_currency")
		return

	if not EconomySystem.spend_currency("repticash", purchase_cost):
		_show_message_popup("ui.not_enough_currency")
		return

	var habitats: Dictionary = _get_habitats_state()
	habitats[habitat_id] = {
		"habitat_id": habitat_id,
		"biome_id": BIOME_ID,
		"slot_index": slot_index,
		"purchased": true,
		"habitat_variant_id": "default",
		"habitat_skin_id": "default",
		"reptile_id": "",
		"reptile_instance_id": "",
		"animal_instance_id": ""
	}
	GameState.set_value("habitats", habitats)
	SaveSystem.save_game()
	_refresh_habitat_slots()
	_close_habitat_purchase_modal()

	if action_popup != null:
		action_popup.hide()


func _show_message_popup(message_key: String) -> void:
	var popup: PopupPanel = _create_action_popup()
	var column: VBoxContainer = _add_popup_column(popup)
	column.add_child(_make_popup_label(LocalizationSystem.tr_key(message_key), 18))
	column.add_child(_make_popup_button("ui.cancel", func() -> void:
		popup.hide()
	))
	popup.popup_centered(Vector2(330, 170))


func _show_variant_discovery_popup(variant_id: String, instance_id: String = "") -> void:
	_close_variant_discovery_modal()

	var variant: Dictionary = ReptileSystem.get_variant(variant_id)
	var reptile: Dictionary = ReptileSystem.get_reptile(str(variant.get("reptile_id", "")))
	var discovered_sex: String = _get_discovered_instance_sex(instance_id)

	variant_discovery_modal = Control.new()
	variant_discovery_modal.name = "VariantDiscoveryModal"
	variant_discovery_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(variant_discovery_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.66)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	variant_discovery_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	variant_discovery_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 580)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title: Label = _make_popup_label(LocalizationSystem.tr_key("ui.new_variant_discovered"), 21)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var portrait_frame: PanelContainer = PanelContainer.new()
	portrait_frame.custom_minimum_size = DISCOVERY_PORTRAIT_SIZE
	portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_frame.clip_contents = true
	portrait_frame.add_theme_stylebox_override("panel", _make_portrait_frame_style())
	column.add_child(portrait_frame)

	var portrait: TextureRect = TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 8
	portrait.offset_top = 8
	portrait.offset_right = -8
	portrait.offset_bottom = -8
	portrait.texture = AssetPaths.load_texture(_get_variant_image_path(reptile, variant, false))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait)

	var reptile_label: Label = _make_popup_label(LocalizationSystem.tr_key(str(reptile.get("name_key", ""))), 15)
	_apply_label_color(reptile_label, POPUP_TEXT_SECONDARY)
	column.add_child(reptile_label)

	var variant_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.variant") + ": " + LocalizationSystem.tr_key(str(variant.get("name_key", "ui.variant"))), 15)
	_apply_label_color(variant_label, POPUP_TEXT_SECONDARY)
	column.add_child(variant_label)

	var sex_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.sex") + ": " + _get_localized_sex(discovered_sex), 15)
	_apply_label_color(sex_label, POPUP_TEXT_SECONDARY)
	column.add_child(sex_label)

	var rarity_block: VBoxContainer = VBoxContainer.new()
	rarity_block.alignment = BoxContainer.ALIGNMENT_CENTER
	rarity_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_block.add_theme_constant_override("separation", 4)
	column.add_child(rarity_block)

	var rarity_icon: TextureRect = _make_rarity_icon(str(variant.get("rarity_icon_path", "")), DISCOVERY_RARITY_ICON_SIZE)
	rarity_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rarity_block.add_child(rarity_icon)

	var rarity_label: Label = _make_popup_label(LocalizationSystem.tr_key(ReptileSystem.get_rarity_label_key(str(variant.get("rarity", "common")))), 14)
	rarity_label.custom_minimum_size = Vector2(180, 0)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rarity_label.clip_text = false
	_apply_label_color(rarity_label, POPUP_TEXT_ACCENT)
	rarity_block.add_child(rarity_label)

	var ok_button: Button = _make_popup_button("ui.ok", _close_variant_discovery_modal)
	ok_button.custom_minimum_size = Vector2(0, 48)
	ok_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	ok_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	ok_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(ok_button, BUTTON_TEXT_COLOR)
	column.add_child(ok_button)


func _show_reptile_name_popup(instance_id: String, edit_mode: bool) -> void:
	_close_naming_modal()
	if instance_id.is_empty():
		return

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	if typeof(instance_value) != TYPE_DICTIONARY:
		return

	var instance: Dictionary = instance_value as Dictionary
	var reptile: Dictionary = ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))
	var variant: Dictionary = ReptileSystem.get_owned_animal_variant(instance)

	naming_modal = Control.new()
	naming_modal.name = "ReptileNamingModal"
	naming_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(naming_modal)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0.04, 0.05, 0.04, 0.66)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	naming_modal.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = TOP_BAR_HEIGHT * 0.5
	center.offset_bottom = -(BOTTOM_NAV_HEIGHT * 0.5)
	naming_modal.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 390)
	panel.add_theme_stylebox_override("panel", _make_modal_panel_style())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title_key: String = "ui.rename_reptile" if edit_mode else "ui.name_reptile"
	var title: Label = _make_popup_label(LocalizationSystem.tr_key(title_key), 21)
	_apply_label_color(title, POPUP_TEXT_PRIMARY)
	column.add_child(title)

	var context_row: HBoxContainer = HBoxContainer.new()
	context_row.add_theme_constant_override("separation", 12)
	column.add_child(context_row)

	var icon: TextureRect = _make_fixed_texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2(76, 76))
	context_row.add_child(icon)

	var context_info: VBoxContainer = VBoxContainer.new()
	context_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_info.add_theme_constant_override("separation", 4)
	context_row.add_child(context_info)

	var species_label: Label = _make_popup_label(LocalizationSystem.tr_key(str(reptile.get("name_key", "ui.reptile_management_placeholder"))), 15)
	species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	species_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	species_label.clip_text = true
	_apply_label_color(species_label, POPUP_TEXT_PRIMARY)
	context_info.add_child(species_label)

	var variant_label: Label = _make_popup_label(LocalizationSystem.tr_key("ui.variant") + ": " + LocalizationSystem.tr_key(str(variant.get("name_key", "ui.variant"))), 13)
	variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	variant_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	variant_label.clip_text = true
	_apply_label_color(variant_label, POPUP_TEXT_SECONDARY)
	context_info.add_child(variant_label)

	var prompt_key: String = "ui.reptile_name_prompt"
	var prompt: Label = _make_popup_label(LocalizationSystem.tr_key(prompt_key), 14)
	_apply_label_color(prompt, POPUP_TEXT_SECONDARY)
	column.add_child(prompt)

	var input: LineEdit = LineEdit.new()
	input.name = "NameInput"
	input.custom_minimum_size = Vector2(0, 44)
	input.placeholder_text = LocalizationSystem.tr_key("ui.reptile_name_placeholder")
	input.max_length = NAME_MAX_LENGTH
	input.text = str(instance.get("custom_name", "")) if edit_mode else ""
	column.add_child(input)

	var validation_label: Label = _make_popup_label("", 12)
	validation_label.name = "ValidationLabel"
	validation_label.visible = false
	_apply_label_color(validation_label, Color(0.62, 0.12, 0.08, 1.0))
	column.add_child(validation_label)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)

	var cancel_key: String = "ui.cancel" if edit_mode else "ui.skip"
	var cancel_button: Button = _make_popup_button(cancel_key, func() -> void:
		if not edit_mode:
			SaveSystem.save_game()
		_close_naming_modal()
	)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(cancel_button)

	var save_button: Button = _make_popup_button("ui.save", func() -> void:
		var normalized_name: String = _sanitize_reptile_name(input.text)
		if not edit_mode and normalized_name.is_empty():
			_show_name_validation(validation_label, "ui.name_required_or_skip")
			return
		if normalized_name.length() > NAME_MAX_LENGTH:
			_show_name_validation(validation_label, "ui.name_too_long")
			return

		if ReptileSystem.set_reptile_custom_name(instance_id, normalized_name):
			_refresh_habitat_slots()
			_close_naming_modal()
			if edit_mode:
				var habitat_id: String = str(instance.get("habitat_id", ""))
				if not habitat_id.is_empty():
					_show_management_popup(habitat_id)
	)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	save_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	save_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(save_button, BUTTON_TEXT_COLOR)
	buttons.add_child(save_button)

	input.grab_focus()


func _show_name_validation(label: Label, message_key: String) -> void:
	label.text = LocalizationSystem.tr_key(message_key)
	label.visible = true


func _sanitize_reptile_name(raw_name: String) -> String:
	var sanitized: String = raw_name.replace("\r", " ").replace("\n", " ").strip_edges()
	while sanitized.find("  ") != -1:
		sanitized = sanitized.replace("  ", " ")
	return sanitized


func _create_action_popup() -> PopupPanel:
	if action_popup != null:
		action_popup.queue_free()

	action_popup = PopupPanel.new()
	action_popup.name = "HabitatActionPopup"
	add_child(action_popup)
	return action_popup


func _add_popup_column(popup: PopupPanel) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	popup.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	return column


func _make_popup_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_apply_label_color(label, POPUP_TEXT_PRIMARY)
	return label


func _make_popup_button(key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = LocalizationSystem.tr_key(key)
	button.custom_minimum_size = Vector2(0, 44)
	_apply_button_text_color(button, POPUP_TEXT_PRIMARY)
	button.pressed.connect(callback)
	return button


func _close_reptile_selection_modal() -> void:
	if reptile_selection_modal == null:
		return

	reptile_selection_modal.queue_free()
	reptile_selection_modal = null


func _close_management_modal() -> void:
	if management_modal == null:
		return

	management_modal.queue_free()
	management_modal = null
	current_management_instance_id = ""
	current_management_feedback_key = ""


func _close_habitat_purchase_modal() -> void:
	if habitat_purchase_modal == null:
		return

	habitat_purchase_modal.queue_free()
	habitat_purchase_modal = null


func _close_variant_discovery_modal() -> void:
	if variant_discovery_modal == null:
		return

	variant_discovery_modal.queue_free()
	variant_discovery_modal = null
	var name_instance_id: String = pending_name_instance_id
	pending_name_instance_id = ""
	if not name_instance_id.is_empty():
		_show_reptile_name_popup(name_instance_id, false)


func _close_naming_modal() -> void:
	if naming_modal == null:
		return

	naming_modal.queue_free()
	naming_modal = null


func _make_modal_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.94, 0.88, 0.98)
	style.border_color = Color(0.32, 0.24, 0.16, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 12
	return style


func _make_bottom_sheet_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _make_modal_panel_style()
	style.set_corner_radius(CORNER_BOTTOM_LEFT, 0)
	style.set_corner_radius(CORNER_BOTTOM_RIGHT, 0)
	style.shadow_size = 18
	return style


func _make_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.93, 1.0)
	style.border_color = Color(0.36, 0.29, 0.18, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style


func _make_owned_card_action_button(label_key: String) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(104, 44)
	button.text = LocalizationSystem.tr_key(label_key)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.58, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.30, 0.66, 0.29, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.20, 0.48, 0.19, 1.0)))
	_apply_button_text_color(button, BUTTON_TEXT_COLOR)
	return button


func _make_gallery_slot_style(discovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.86, 1.0) if discovered else Color(0.86, 0.82, 0.72, 0.92)
	style.border_color = Color(0.36, 0.29, 0.18, 0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _make_portrait_frame_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.86, 0.76, 1.0)
	style.border_color = Color(0.36, 0.29, 0.18, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style


func _make_fixed_texture(path: String, texture_size: Vector2) -> TextureRect:
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.custom_minimum_size = texture_size
	texture_rect.texture = AssetPaths.load_texture(path)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _make_icon_text_row(icon_path: String, text: String, icon_size: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	row.add_child(_make_fixed_texture(icon_path, Vector2(icon_size, icon_size)))

	var label: Label = Label.new()
	label.text = text
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	_apply_label_color(label, POPUP_TEXT_SECONDARY)
	row.add_child(label)

	return row


func _make_management_text_row(label_key: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = LocalizationSystem.tr_key(label_key) + ":"
	label.custom_minimum_size = Vector2(92, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(label, POPUP_TEXT_ACCENT)
	row.add_child(label)

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.clip_text = true
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(value_label, POPUP_TEXT_SECONDARY)
	row.add_child(value_label)

	return row


func _make_management_icon_row(label_key: String, icon_path: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = LocalizationSystem.tr_key(label_key) + ":"
	label.custom_minimum_size = Vector2(92, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(label, POPUP_TEXT_ACCENT)
	row.add_child(label)

	row.add_child(_make_fixed_texture(icon_path, Vector2(26, 26)))

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.clip_text = true
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(value_label, POPUP_TEXT_SECONDARY)
	row.add_child(value_label)

	return row


func _get_percent_state(instance: Dictionary, key: String, fallback: int) -> int:
	return int(clamp(int(instance.get(key, fallback)), 0, 100))


func _format_repticash_per_min(value: float) -> String:
	return LocalizationSystem.tr_key("currency.repticash") + " " + _format_decimal(value) + " " + LocalizationSystem.tr_key("ui.per_minute")


func _format_multiplier(value: float) -> String:
	return "x%.2f" % value


func _format_decimal(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))

	return "%.1f" % value


func _make_need_bar_row(label_key: String, icon_path: String, value: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = LocalizationSystem.tr_key(label_key) + ":"
	label.custom_minimum_size = Vector2(92, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(label, POPUP_TEXT_ACCENT)
	row.add_child(label)

	row.add_child(_make_fixed_texture(icon_path, Vector2(24, 24)))

	var progress: ProgressBar = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = value
	progress.custom_minimum_size = Vector2(92, 18)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.show_percentage = false
	row.add_child(progress)

	var value_label: Label = Label.new()
	value_label.text = str(value) + "%"
	value_label.custom_minimum_size = Vector2(42, 0)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 13)
	_apply_label_color(value_label, POPUP_TEXT_SECONDARY)
	row.add_child(value_label)

	return row


func _make_care_action_button(action_id: String, label_key: String, icon_path: String, instance: Dictionary, is_assigned: bool) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	var remaining: int = ReptileSystem.get_care_cooldown_remaining(instance, action_id)
	button.disabled = not is_assigned or remaining > 0
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
	var normal_color: Color = Color(0.32, 0.58, 0.22, 0.96)
	var disabled_color: Color = Color(0.72, 0.64, 0.48, 0.42)
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color))
	button.add_theme_stylebox_override("hover", _make_button_style(normal_color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _make_button_style(normal_color.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", _make_button_style(disabled_color))
	if not button.disabled:
		button.pressed.connect(func() -> void: _on_care_action_pressed(action_id))

	var content: VBoxContainer = VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 2)
	button.add_child(content)

	var display_icon_path: String = COOLDOWN_ICON_PATH if remaining > 0 else icon_path
	var icon: TextureRect = _make_fixed_texture(display_icon_path, Vector2(34, 34))
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)

	var label: Label = Label.new()
	label.text = _format_cooldown(remaining) if remaining > 0 else LocalizationSystem.tr_key(label_key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 10)
	_apply_label_color(label, POPUP_TEXT_SECONDARY if button.disabled else BUTTON_TEXT_COLOR)
	content.add_child(label)

	return button


func _on_care_action_pressed(action_id: String) -> void:
	if current_management_instance_id.is_empty():
		return

	var result: Dictionary = ReptileSystem.perform_care_action(current_management_instance_id, action_id)
	current_management_feedback_key = str(result.get("message_key", "ui.feature_later"))
	if bool(result.get("success", false)):
		current_management_feedback_key = _format_care_success_feedback(result)
	_refresh_habitat_slots()
	_show_management_for_instance_id(current_management_instance_id, false)


func _format_care_success_feedback(result: Dictionary) -> String:
	var text: String = LocalizationSystem.tr_key(str(result.get("message_key", "")))
	text = text.replace("{xp}", _format_decimal(float(result.get("xp", 0.0))))
	text = text.replace("{money}", _format_decimal(float(result.get("money", 0.0))))
	return text


func _show_income_float(amount: float) -> void:
	var float_label: Label = Label.new()
	float_label.text = LocalizationSystem.tr_key("income.plus").replace("{amount}", _format_decimal(amount))
	float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_label.add_theme_color_override("font_color", Color(0.12, 0.55, 0.14, 1.0))
	float_label.add_theme_font_size_override("font_size", 22)
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(float_label)

	float_label.position = Vector2(22, TOP_BAR_HEIGHT + 8)
	var tween: Tween = create_tween()
	tween.tween_property(float_label, "position:y", float_label.position.y - 42.0, 1.4)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.4)
	tween.tween_callback(float_label.queue_free)


func _format_cooldown(seconds: int) -> String:
	var safe_seconds: int = max(0, seconds)
	if safe_seconds >= 60:
		return str(int(ceil(float(safe_seconds) / 60.0))) + "m"

	return str(safe_seconds) + "s"


func _make_rarity_icon(path: String, icon_size: Vector2) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = icon_size
	icon.texture = AssetPaths.load_texture(path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = icon.texture != null
	return icon


func _make_edit_icon_button(instance_id: String) -> Button:
	var button: Button = Button.new()
	button.name = "EditNameButton"
	button.tooltip_text = LocalizationSystem.tr_key("ui.edit_name")
	button.custom_minimum_size = Vector2(42, 42)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void:
		_show_reptile_name_popup(instance_id, true)
	)

	var icon: TextureRect = TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 5
	icon.offset_top = 5
	icon.offset_right = -5
	icon.offset_bottom = -5
	icon.texture = AssetPaths.load_texture(EDIT_ICON_PATH)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	if icon.texture == null:
		push_warning("Edit name icon missing: " + EDIT_ICON_PATH)
		button.text = "..."

	return button


func _get_reptile_display_name(instance: Dictionary, reptile: Dictionary) -> String:
	var custom_name: String = str(instance.get("custom_name", "")).strip_edges()
	if not custom_name.is_empty():
		return custom_name

	var reptile_id: String = str(instance.get("reptile_id", ""))
	return LocalizationSystem.tr_key(str(reptile.get("name_key", reptile_id)))


func _get_sorted_owned_instances() -> Array:
	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var result: Array = []
	for instance_id in instances.keys():
		var instance_value: Variant = instances.get(instance_id)
		if typeof(instance_value) == TYPE_DICTIONARY:
			result.append(instance_value as Dictionary)

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_assigned: bool = _is_reptile_instance_assigned(a)
		var b_assigned: bool = _is_reptile_instance_assigned(b)
		if a_assigned != b_assigned:
			return not a_assigned

		return int(a.get("created_at", 0)) < int(b.get("created_at", 0))
	)
	return result


func _is_reptile_instance_assigned(instance: Dictionary) -> bool:
	var habitat_value: Variant = instance.get("habitat_id", null)
	return habitat_value != null and not str(habitat_value).is_empty()


func _get_discovered_variant_count(variants: Array) -> int:
	var count: int = 0
	for variant_value in variants:
		if typeof(variant_value) != TYPE_DICTIONARY:
			continue

		var variant: Dictionary = variant_value as Dictionary
		if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))):
			count += 1

	return count


func _get_expected_gallery_discovered_count() -> int:
	var count: int = 0
	for reptile_id_value in GALLERY_REPTILE_IDS:
		var reptile_id: String = str(reptile_id_value)
		for rarity_value in GALLERY_RARITIES:
			var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(reptile_id, str(rarity_value))
			if variant.is_empty():
				continue
			if ReptileSystem.is_variant_discovered(str(variant.get("id", ""))):
				count += 1

	return count


func _get_gallery_shadow_path(reptile_id: String, variant: Dictionary) -> String:
	var configured_path: String = str(variant.get("gallery_shadow_path", ""))
	if not configured_path.is_empty():
		return configured_path

	return "res://assets/art/reptiles/gallery/" + reptile_id + "_shadow.png"


func _get_habitat_display_name(habitat_id: String) -> String:
	for habitat_value in habitat_data:
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = habitat_value as Dictionary
		if str(habitat.get("id", "")) == habitat_id:
			return LocalizationSystem.tr_key("ui.habitat") + " " + str(int(habitat.get("slot_index", 0)) + 1)

	return habitat_id


func _get_variant_image_path(reptile: Dictionary, variant: Dictionary, prefer_icon: bool) -> String:
	var icon_path: String = str(variant.get("icon_path", ""))
	var portrait_path: String = str(variant.get("portrait_path", ""))
	if prefer_icon and not icon_path.is_empty():
		return icon_path
	if not portrait_path.is_empty():
		return portrait_path
	if not icon_path.is_empty():
		return icon_path

	return str(reptile.get("icon_path", reptile.get("portrait_path", "")))


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _apply_label_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)


func _apply_button_text_color(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_disabled_color", Color(color.r, color.g, color.b, 0.65))


func _get_discovered_instance_sex(instance_id: String) -> String:
	if instance_id.is_empty():
		return "male"

	var instances: Dictionary = ReptileSystem.get_owned_reptile_instances()
	var instance_value: Variant = instances.get(instance_id, {})
	if typeof(instance_value) != TYPE_DICTIONARY:
		return "male"

	var instance: Dictionary = instance_value as Dictionary
	return str(instance.get("sex", "male"))


func _get_selected_sex(selector: OptionButton) -> String:
	if selector.get_selected_id() == 1:
		return "female"

	return "male"


func _get_localized_sex(sex: String) -> String:
	if sex == "female":
		return LocalizationSystem.tr_key("sex.female")

	return LocalizationSystem.tr_key("sex.male")


func _refresh_habitat_slots() -> void:
	for habitat in habitat_data:
		var habitat_dict: Dictionary = habitat as Dictionary
		var habitat_id: String = str(habitat_dict.get("id", ""))
		if habitat_slots.has(habitat_id):
			var slot: Node = habitat_slots[habitat_id] as Node
			var state: String = _get_habitat_state(habitat_id)
			slot.call("set_state", state)
			slot.call("set_occupied_icon", _get_habitat_reptile_icon_path(habitat_id) if state == STATE_OCCUPIED else "")
			if slot.has_method("set_needs_attention"):
				slot.call("set_needs_attention", _habitat_needs_attention(habitat_id) if state == STATE_OCCUPIED else false)
			if slot.has_method("set_income_progress"):
				slot.call("set_income_progress", EconomySystem.get_income_progress() if state == STATE_OCCUPIED else 0.0)


func _refresh_habitat_income_progress() -> void:
	for habitat_id in habitat_slots.keys():
		var slot: Node = habitat_slots[habitat_id] as Node
		if not slot.has_method("set_income_progress"):
			continue

		var state: String = _get_habitat_state(str(habitat_id))
		slot.call("set_income_progress", EconomySystem.get_income_progress() if state == STATE_OCCUPIED else 0.0)


func _get_habitat_state(habitat_id: String) -> String:
	var habitats: Dictionary = _get_habitats_state()
	if not habitats.has(habitat_id):
		return STATE_NOT_PURCHASED

	var saved_value: Variant = habitats.get(habitat_id, {})
	if typeof(saved_value) != TYPE_DICTIONARY:
		return STATE_NOT_PURCHASED

	var saved: Dictionary = saved_value as Dictionary
	if not bool(saved.get("purchased", false)):
		return STATE_NOT_PURCHASED

	if (
		not str(saved.get("reptile_id", "")).is_empty()
		or not str(saved.get("reptile_instance_id", "")).is_empty()
		or not str(saved.get("animal_instance_id", "")).is_empty()
	):
		return STATE_OCCUPIED

	return STATE_PURCHASED_EMPTY


func _get_habitats_state() -> Dictionary:
	var value: Variant = GameState.get_value("habitats", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value as Dictionary


func _get_habitat_data(habitat_id: String) -> Dictionary:
	for habitat in habitat_data:
		var habitat_dict: Dictionary = habitat as Dictionary
		if str(habitat_dict.get("id", "")) == habitat_id:
			return habitat_dict
	return {}


func _get_habitat_reptile_icon_path(habitat_id: String) -> String:
	var instance: Dictionary = ReptileSystem.get_reptile_for_habitat(habitat_id)
	if instance.is_empty():
		return ""

	return ReptileSystem.get_owned_animal_image_path(instance)


func _habitat_needs_attention(habitat_id: String) -> bool:
	var instance: Dictionary = ReptileSystem.get_reptile_for_habitat(habitat_id)
	if instance.is_empty():
		return false

	return ReptileSystem.reptile_needs_attention(instance)


func _load_habitats() -> Array:
	var file: FileAccess = FileAccess.open(HABITATS_PATH, FileAccess.READ)
	if file == null:
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []

	var result: Array = []
	var parsed_array: Array = parsed as Array
	for item in parsed_array:
		if typeof(item) == TYPE_DICTIONARY:
			var item_dict: Dictionary = item as Dictionary
			if str(item_dict.get("biome_id", "")) == BIOME_ID:
				result.append(item_dict)

	result.sort_custom(_sort_habitats_by_slot)
	return result


func _sort_habitats_by_slot(a: Variant, b: Variant) -> bool:
	var habitat_a: Dictionary = a as Dictionary
	var habitat_b: Dictionary = b as Dictionary
	return int(habitat_a.get("slot_index", 0)) < int(habitat_b.get("slot_index", 0))
