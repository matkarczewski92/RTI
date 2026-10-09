extends Control
## The frame is the terrarium: its full window shows the interior and its resident.
signal profile_requested(instance_id: String)
signal assign_requested(habitat_id: String)
signal care_requested(instance_id: String, action_id: String)

const T := preload("res://scripts/modern/SanctuaryTheme.gd")
const ART := "res://assets/prototype/art/"
const INTERIOR_CROP := Rect2(0.12, 0.14, 0.76, 0.72)
const FRAME_RATIO := 1602.0 / 981.0
const MAX_ART_WIDTH := 420.0
static var _animal_texture_cache: Dictionary = {}
static var _last_model_tick: int = -1
var habitat: Dictionary = {}
var animal: Dictionary = {}
var welfare: TextureProgressBar
var welfare_label: Label
var actions: HBoxContainer
var _environment: TextureRect
var _sprite: TextureRect
var _shadow: Control
var _name_label: Label
var _level_label: Label
var _status: Panel
var _status_label: Label
var _hit: Button
var _signature := ""
var _illustration_signature := ""
var _feedback := ""
var _feedback_until := 0
var _art_rect := Rect2()

class ActionSkin extends Control:
	var texture: Texture2D
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if texture == null or size.y <= 0: return
		# Scale the painted corners uniformly; only the central spans may stretch.
		var skin := StyleBoxTexture.new()
		skin.texture = texture
		for side in [SIDE_LEFT, SIDE_RIGHT]: skin.set_texture_margin(side, texture.get_width() * 0.17)
		for side in [SIDE_TOP, SIDE_BOTTOM]: skin.set_texture_margin(side, texture.get_height() * 0.22)
		var factor := size.y / texture.get_height()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * factor)
		draw_style_box(skin, Rect2(Vector2.ZERO, size / factor))

class GroundShadow extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x <= 0: return
		draw_set_transform(size * 0.5, 0, Vector2(1, size.y / size.x))
		draw_circle(Vector2.ZERO, size.x * 0.5, Color(0.035, 0.022, 0.005, 0.30))

func setup(h: Dictionary, a: Dictionary) -> void:
	habitat = h.duplicate(true)
	animal = a.duplicate(true)
	if is_node_ready(): refresh()

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = 365
	resized.connect(_fit_layout)
	_environment = TextureRect.new()
	_environment.name = "TerrariumInterior"
	_environment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_environment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_environment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_environment, Rect2(0.076, 0.06, 0.85, 0.606))
	add_child(_environment)
	_shadow = GroundShadow.new()
	_place(_shadow, Rect2(0.24, 0.604, 0.55, 0.042))
	add_child(_shadow)
	_sprite = TextureRect.new()
	_sprite.name = "Resident"
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
	var frame := T.texture(ART + "ui/center/center_card_skin_v2.png", Vector2.ZERO)
	frame.name = "TerrariumFrame"
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place(frame, Rect2(0, 0, 1, 1))
	add_child(frame)
	_name_label = T.label("", 24)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_place(_name_label, Rect2(0.17, 0.055, 0.56, 0.087))
	add_child(_name_label)
	_level_label = T.label("", 30, T.GOLD)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# A one-digit badge must never retain the minimum height of a wrapped label
	# measured while the grid still had zero width.
	_level_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place(_level_label, Rect2(0.75, 0.147, 0.14, 0.11))
	add_child(_level_label)
	_hit = Button.new()
	_blank(_hit)
	_place(_hit, Rect2(0.08, 0.06, 0.85, 0.59))
	_hit.pressed.connect(_open_resident)
	add_child(_hit)
	_status = Panel.new()
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.clip_contents = true
	_status.add_theme_stylebox_override("panel", T.style(Color("142215e0"), 10, T.GOLD, 5))
	_place(_status, Rect2(0.12, 0.285, 0.76, 0.18))
	_status_label = T.label("", 23)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_label.offset_left = 4
	_status_label.offset_right = -4
	_status.add_child(_status_label)
	add_child(_status)
	welfare = TextureProgressBar.new()
	welfare.texture_under = load(ART + "ui/center/center_welfare_under_v2.png")
	welfare.texture_progress = load(ART + "ui/center/center_welfare_fill_v2.png")
	welfare.nine_patch_stretch = true
	welfare.stretch_margin_left = 14
	welfare.stretch_margin_right = 14
	welfare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(welfare, Rect2(0.265, 0.686, 0.607, 0.056))
	add_child(welfare)
	var happy := T.texture(ART + "icons/welfare.png", Vector2.ZERO)
	_place(happy, Rect2(0.125, 0.678, 0.10, 0.064))
	add_child(happy)
	welfare_label = T.label("", 23)
	welfare_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(welfare_label, Rect2(0.29, 0.684, 0.56, 0.06))
	add_child(welfare_label)
	actions = T.row(4)
	_place(actions, Rect2(0.047, 0.760, 0.908, 0.218))
	add_child(actions)
	var clock := Timer.new()
	clock.wait_time = 1.0
	clock.autostart = true
	clock.timeout.connect(_tick)
	add_child(clock)
	refresh()
	_fit_layout()

func _tick() -> void:
	# A grid may have many cards, but the shared model only needs one update per second.
	var now := int(Time.get_unix_time_from_system())
	if _last_model_tick != now:
		_last_model_tick = now
		ReptileSystem.apply_time_updates(false)
	refresh()

func refresh() -> void:
	if not is_instance_valid(welfare): return
	var habitat_id := str(habitat.get("habitat_id", ""))
	var was_working := bool(habitat.get("is_building", false)) or bool(habitat.get("is_upgrading", false))
	var live: Dictionary = ReptileSystem.get_habitat_state(habitat_id)
	if not live.is_empty():
		habitat = live.duplicate(true)
		animal = ReptileSystem.get_reptile_for_habitat(habitat_id).duplicate(true)
	var building := bool(habitat.get("is_building", false))
	var upgrading := bool(habitat.get("is_upgrading", false))
	var working := building or upgrading
	if was_working and not working: SaveSystem.save_game()
	var remaining := ReptileSystem.get_habitat_build_remaining_seconds(habitat_id) if building else ReptileSystem.get_habitat_upgrade_remaining_seconds(habitat_id)
	var target_type := "habitat_build" if building else "habitat_upgrade"
	_refresh_illustration()
	var name_text := T.text("EMPTY TERRARIUM", "PUSTE TERRARIUM")
	if building:
		name_text = T.text("BUILDING", "BUDOWA")
	elif not animal.is_empty():
		name_text = str(animal.get("custom_name", ""))
		if name_text.is_empty(): name_text = T.localized(str(ReptileSystem.get_reptile(str(animal.get("reptile_id", ""))).get("name_key", "")))
	_name_label.text = name_text
	_name_label.tooltip_text = name_text
	_hit.tooltip_text = name_text
	_hit.disabled = animal.is_empty() and working
	_level_label.text = str(habitat.get("habitat_level", 1))
	var condition := 0.0
	for stat in ["hunger", "hydration", "cleanliness", "happiness"]: condition += float(animal.get(stat, 100)) / 4.0
	welfare.value = condition
	welfare_label.text = "%d%%" % int(condition) if not animal.is_empty() else (T.text("WORKING", "W TOKU") if working else T.text("READY", "GOTOWE"))
	var showing_feedback := int(Time.get_unix_time_from_system()) < _feedback_until
	_status.visible = working or showing_feedback
	_status_label.text = _feedback if showing_feedback else (T.text("BUILDING", "BUDOWA") if building else T.text("UPGRADING", "ULEPSZANIE")) + "\n" + T.time(remaining)
	var options := [{"id": "feed", "stat": "hunger", "color": "red", "icon": "feed", "name": T.text("FEED", "KARM")}, {"id": "water", "stat": "hydration", "color": "green", "icon": "water", "name": T.text("WATER", "WODA")}, {"id": "clean", "stat": "cleanliness", "color": "green", "icon": "clean", "name": T.text("CLEAN", "CZYŚĆ")}, {"id": "play", "stat": "happiness", "color": "gold", "icon": "care", "name": T.text("CARE", "OPIEKA")}]
	options.sort_custom(func(a: Dictionary, b: Dictionary): return float(animal.get(a.stat, 100)) < float(animal.get(b.stat, 100)))
	var available: Array = []
	if not animal.is_empty():
		for option: Dictionary in options:
			if ReptileSystem.get_care_action_availability(animal, option.id).get("available", false):
				available.append(option)
				if available.size() == 2: break
	var speedup := working and SpeedUpService.should_show_button(remaining)
	var speedup_disabled := SpeedUpService.is_on_cooldown(target_type, habitat_id) or RewardedAdService.is_ad_loading_or_showing()
	var signature := str([available, str(animal.get("instance_id", "")), building, upgrading, speedup, speedup_disabled, GameState.get_language()])
	if signature == _signature: return
	_signature = signature
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	if animal.is_empty():
		if working:
			if speedup:
				var button := _action(T.text("SPEED UP · AD", "PRZYSPIESZ · AD"), "gold", "clock", _request_speedup, false)
				button.disabled = speedup_disabled
			else:
				var button := _action(T.text("IN PROGRESS", "W TOKU"), "gold", "clock", Callable(), false)
				button.disabled = true
		else:
			_action(T.text("CHOOSE REPTILE", "WYBIERZ GADA"), "green", "collection", _open_resident, false)
		return
	for option: Dictionary in available:
		_action(option.name, option.color, option.icon, _request_care.bind(str(option.id)), true)
	if available.size() < 2:
		_action(T.text("DETAILS", "SZCZEGÓŁY"), "green", "collection", _open_resident, false)

func _refresh_illustration() -> void:
	var type := str(habitat.get("habitat_type", "grass"))
	var level := clampi(int(habitat.get("habitat_level", 1)), 1, 3)
	var path := "res://assets/art/modern/terrarium_%s_%d.png" % [type, level]
	if not ResourceLoader.exists(path): path = "res://assets/art/modern/terrarium_%s_1.png" % type
	if not ResourceLoader.exists(path): path = "res://assets/art/modern/terrarium_grass_1.png"
	var animal_path := T.animal_path(animal) if not animal.is_empty() else ""
	var signature := path + "|" + animal_path
	if signature == _illustration_signature: return
	_illustration_signature = signature
	var source: Texture2D = T.AssetPaths.load_texture(path)
	if source != null:
		var interior := AtlasTexture.new()
		interior.atlas = source
		interior.region = Rect2(INTERIOR_CROP.position * source.get_size(), INTERIOR_CROP.size * source.get_size())
		_environment.texture = interior
	_sprite.texture = _grounded_texture(animal_path)
	_sprite.visible = _sprite.texture != null and not animal.is_empty()
	_shadow.visible = _sprite.visible
	_fit_animal()

func _grounded_texture(path: String) -> Texture2D:
	if path.is_empty(): return null
	if _animal_texture_cache.has(path): return _animal_texture_cache[path]
	var texture: Texture2D = T.AssetPaths.load_texture(path)
	if texture == null: return null
	var source := texture.get_image()
	if source != null:
		if source.is_compressed(): source.decompress()
		# Ignore faint export speckles when finding the silhouette; the source art stays intact.
		var mask := BitMap.new()
		mask.create_from_image_alpha(source, 0.12)
		var bounds := Rect2()
		for polygon: PackedVector2Array in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, source.get_size()), 2.0):
			if polygon.is_empty(): continue
			var piece := Rect2(polygon[0], Vector2.ZERO)
			for point in polygon: piece = piece.expand(point)
			if piece.get_area() < float(source.get_width() * source.get_height()) * 0.003: continue
			bounds = piece if not bounds.has_area() else bounds.merge(piece)
		if bounds.has_area():
			var cropped := AtlasTexture.new()
			cropped.atlas = texture
			cropped.region = bounds.grow(2).intersection(Rect2(Vector2.ZERO, texture.get_size()))
			texture = cropped
	_animal_texture_cache[path] = texture
	return texture

func _fit_layout() -> void:
	var art_width := minf(size.x, MAX_ART_WIDTH)
	var art_size := Vector2(art_width, art_width * FRAME_RATIO)
	custom_minimum_size.y = maxf(365.0, art_size.y)
	_art_rect = Rect2(Vector2((size.x - art_width) * 0.5, 0), art_size)
	var font_size := clampi(int(art_width / 11.0), 23, 32)
	if is_instance_valid(_name_label): _name_label.add_theme_font_size_override("font_size", font_size)
	if is_instance_valid(_level_label): _level_label.add_theme_font_size_override("font_size", mini(font_size, 30))
	# Keep nodes directly accessible to callers while laying them out within the
	# same proportional drawing rectangle, even if a parent gives us a wide cell.
	for child: Node in get_children():
		if child is Control and child.has_meta("card_bounds"):
			var bounds: Rect2 = child.get_meta("card_bounds")
			child.set_anchors_preset(Control.PRESET_TOP_LEFT)
			child.position = _art_rect.position + bounds.position * art_size
			child.size = bounds.size * art_size
	if is_instance_valid(actions):
		for caption: Label in actions.find_children("ActionCaption", "Label", true, false):
			caption.add_theme_font_size_override("font_size", font_size)
	_fit_animal()

func _fit_animal() -> void:
	if not is_instance_valid(_sprite) or _sprite.texture == null: return
	var natural := _sprite.texture.get_size()
	if natural.x <= 0 or natural.y <= 0: return
	var factor := minf(_art_rect.size.x * 0.77 / natural.x, _art_rect.size.y * 0.35 / natural.y)
	var drawn := natural * factor
	_sprite.size = drawn
	_sprite.position = _art_rect.position + Vector2((_art_rect.size.x - drawn.x) * 0.5, _art_rect.size.y * 0.635 - drawn.y)

func _open_resident() -> void:
	if not animal.is_empty():
		profile_requested.emit(str(animal.get("instance_id", "")))
	elif not bool(habitat.get("is_building", false)) and not bool(habitat.get("is_upgrading", false)):
		assign_requested.emit(str(habitat.get("habitat_id", "")))

func _request_care(action_id: String) -> void:
	care_requested.emit(str(animal.get("instance_id", "")), action_id)
	refresh.call_deferred()

func _request_speedup() -> void:
	var target_type := "habitat_build" if bool(habitat.get("is_building", false)) else "habitat_upgrade"
	SpeedUpService.request_speedup(target_type, str(habitat.get("habitat_id", "")), self,
		func(): refresh(),
		func(key: String):
			_feedback = T.localized(key)
			_feedback_until = int(Time.get_unix_time_from_system()) + 4
			refresh())

func _action(label_text: String, color: String, icon_name: String, callback: Callable, care: bool) -> Button:
	var button := Button.new()
	_blank(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 72
	button.tooltip_text = label_text
	if callback.is_valid(): button.pressed.connect(callback)
	actions.add_child(button)
	var skin_path := ART + "ui/center/center_action_" + color + "_v2.png"
	if not ResourceLoader.exists(skin_path): skin_path = ART + "ui/center/center_action_green_v2.png"
	var skin := ActionSkin.new()
	skin.name = "ActionSkin"
	skin.texture = T.AssetPaths.load_texture(skin_path)
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(skin)
	var icon_path := ART + "icons/" + ("actions/" if care else "") + icon_name + ".png"
	if icon_name == "clock": icon_path = "res://assets/art/ui/icons/speed_up_ico.png"
	var icon := T.texture(icon_path, Vector2.ZERO)
	icon.name = "ActionIcon"
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var single := not care and actions.get_child_count() == 1
	_place(icon, Rect2(0.04, 0.10, 0.25, 0.80) if single else Rect2(0.18, 0.03, 0.64, 0.59))
	button.add_child(icon)
	var caption := T.label(label_text, clampi(int(_art_rect.size.x / 11.0), 23, 32))
	caption.name = "ActionCaption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if single else TextServer.AUTOWRAP_OFF
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_place(caption, Rect2(0.30, 0.10, 0.66, 0.80) if single else Rect2(0.03, 0.60, 0.94, 0.30))
	button.add_child(caption)
	return button

func _place(control: Control, rect: Rect2) -> void:
	control.set_meta("card_bounds", rect)
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.end.x
	control.anchor_bottom = rect.end.y

func _blank(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
