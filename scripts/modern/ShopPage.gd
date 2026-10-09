extends VBoxContainer
## Prototype shop cards over the existing ReptiCash and optional rewarded-ad APIs.

signal details_requested(instance_id: String)
signal toast_requested(message: String)
signal refresh_requested
signal nursery_requested

const T = preload("res://scripts/modern/SanctuaryTheme.gd")
const P = preload("res://scripts/modern/PrototypeUiKit.gd")
const BLACK_KEY = preload("res://assets/prototype/shaders/black_key.gdshader")
const ART := "res://assets/prototype/art/ui/shop/"
const SHOP_RARITIES: Array[String] = ["common", "rare"]
const SHOP_SEXES: Array[String] = ["female", "male"]
var tab := "animals"
var biome_id := "green_meadow"
var selected_rarity := "all"
var selected_sex := "all"
var query := ""
var _content: VBoxContainer
var _grid: GridContainer
var _summary: Label
var _biomes: Array = []
var _refresh_queued := false
var _signature_value := ""
var _language := ""
var _busy := false
var _ad_busy := false


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var definitions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/biomes.json"))
	if definitions is Array:
		_biomes = definitions
	if biome_id not in ["green_meadow", "dry_prairie"]:
		biome_id = "green_meadow"
	_content = T.column(10)
	add_child(_content)
	_rebuild()


func refresh() -> void:
	if _refresh_queued or not is_instance_valid(_content):
		return
	_refresh_queued = true
	call_deferred("_refresh_now")


func _refresh_now() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	if _language != GameState.get_language():
		_rebuild()
	elif _signature() != _signature_value:
		_render_cards()


func _signature() -> String:
	return str([tab, biome_id, selected_rarity, selected_sex, int(EconomySystem.get_currency()), GameState.get_value("level", 1), GameState.get_value("starter_reptile_claimed", false), GameState.get_value("biome_resources", {}), ResourceAdService.get_used_count()])


func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _button(copy: String, callback: Callable, selected: bool = false, font_size: int = 26) -> Button:
	var button: Button = T.button(copy, callback, "secondary")
	button.custom_minimum_size.y = 56
	P.apply_button(button, "green" if selected else "wood", font_size)
	return button


func _rebuild() -> void:
	_clear(_content)
	_language = GameState.get_language()
	var title := PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/prototype/art/ui/world/world_title_plaque_clean.png")
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		style.set_content_margin(side, 16)
	title.add_theme_stylebox_override("panel", style)
	var heading: Label = T.label(T.text("SANCTUARY SHOP", "SKLEP HODOWLI"), 36, P.CREAM)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_child(heading)
	_content.add_child(title)
	var tabs: HBoxContainer = T.row(8)
	_content.add_child(tabs)
	tabs.add_child(_button(T.text("REPTILES", "GADY"), _select_tab.bind("animals"), tab == "animals"))
	tabs.add_child(_button(T.text("SUPPLIES", "ZAPASY"), _select_tab.bind("resources"), tab == "resources"))
	var region := OptionButton.new()
	region.name = "ShopBiome"
	region.custom_minimum_size.y = 54
	region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region.add_theme_font_size_override("font_size", 25)
	var biome_values: Array[String] = ["green_meadow", "dry_prairie"]
	for id in biome_values:
		var copy: String = T.localized("biome." + id + ".name")
		if not _is_unlocked(id):
			copy += " · " + T.text("Level ", "Poziom ") + str(_unlock_level(id))
		region.add_item(copy)
	region.select(maxi(0, biome_values.find(biome_id)))
	region.item_selected.connect(func(index: int) -> void: biome_id = biome_values[index]; _rebuild())
	_content.add_child(region)
	if tab == "animals":
		var choices: HBoxContainer = T.row(8)
		_content.add_child(choices)
		var rarity := OptionButton.new()
		rarity.name = "ShopRarity"
		rarity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rarity.custom_minimum_size.y = 54
		rarity.add_theme_font_size_override("font_size", 24)
		var rarity_values: Array[String] = ["all", "common", "rare"]
		rarity.add_item(T.text("All rarities", "Wszystkie rzadkości"))
		for value: String in SHOP_RARITIES:
			rarity.add_item(T.rarity_name(value))
		rarity.select(maxi(0, rarity_values.find(selected_rarity)))
		rarity.item_selected.connect(func(index: int) -> void: selected_rarity = rarity_values[index]; _render_cards())
		choices.add_child(rarity)
		var sex := OptionButton.new()
		sex.name = "ShopSex"
		sex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sex.custom_minimum_size.y = 54
		sex.add_theme_font_size_override("font_size", 24)
		var sex_values: Array[String] = ["all", "female", "male"]
		sex.add_item(T.text("All sexes", "Wszystkie płcie"))
		sex.add_item(T.text("Female", "Samica"))
		sex.add_item(T.text("Male", "Samiec"))
		sex.select(maxi(0, sex_values.find(selected_sex)))
		sex.item_selected.connect(func(index: int) -> void: selected_sex = sex_values[index]; _render_cards())
		choices.add_child(sex)
		var search := LineEdit.new()
		search.name = "ShopSearch"
		search.placeholder_text = T.text("Search species…", "Szukaj gatunku…")
		search.text = query
		search.custom_minimum_size.y = 54
		search.add_theme_font_size_override("font_size", 24)
		search.text_changed.connect(func(value: String) -> void: query = value; _render_cards())
		_content.add_child(search)
	_summary = T.label("", 22, P.CREAM)
	_content.add_child(_summary)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 10)
	_content.add_child(_grid)
	_render_cards()


func _select_tab(value: String) -> void:
	tab = value
	_rebuild()


func _unlock_level(id: String) -> int:
	for value: Variant in _biomes:
		if str(value.get("id", "")) == id:
			return int(value.get("unlock_requirements", {}).get("level", 1))
	return 999


func _is_unlocked(id: String) -> bool:
	return int(GameState.get_value("level", 1)) >= _unlock_level(id) or id in GameState.get_value("unlocked_biomes", [])


func _render_cards() -> void:
	if not is_instance_valid(_grid):
		return
	_clear(_grid)
	var unlocked: bool = _is_unlocked(biome_id)
	if tab == "resources":
		for resource in ["food", "water"]:
			_grid.add_child(_resource_card(resource))
		_grid.add_child(_ad_card())
		_summary.text = T.text("Supplies for ", "Zapasy dla: ") + T.localized("biome." + biome_id + ".name")
	else:
		var offer_count := 0
		var species_count := 0
		for value: Variant in ReptileSystem.get_available_reptiles(biome_id):
			var species: Dictionary = value
			if not query.strip_edges().is_empty() and query.to_lower() not in T.localized(str(species.get("name_key", ""))).to_lower():
				continue
			var id: String = str(species.get("id", ""))
			var has_offer := false
			for rarity: String in SHOP_RARITIES:
				if selected_rarity != "all" and selected_rarity != rarity:
					continue
				if ReptileSystem.get_shop_variant_for_rarity(id, rarity).is_empty() or ReptileSystem.get_shop_purchase_price(id, rarity) < 0:
					continue
				for sex: String in SHOP_SEXES:
					if selected_sex != "all" and selected_sex != sex:
						continue
					_grid.add_child(_animal_card(species, rarity, sex))
					offer_count += 1
					has_offer = true
			if has_offer:
				species_count += 1
		_summary.text = T.text("Offers: %d · Species: %d", "Oferty: %d · Gatunki: %d") % [offer_count, species_count]
	if not unlocked:
		_summary.text = T.text("This region unlocks at level ", "Ten region odblokujesz na poziomie ") + str(_unlock_level(biome_id))
	if _grid.get_child_count() == 1:
		var empty := Control.new()
		empty.name = "EmptyShopSlot"
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grid.add_child(empty)
	_signature_value = _signature()


func _card(id: String) -> Control:
	var card := Control.new()
	card.name = "Offer_" + id
	card.custom_minimum_size.y = 420
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	var frame: TextureRect = T.texture(ART + "product_card.png", Vector2.ZERO)
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
	card.resized.connect(func() -> void: card.custom_minimum_size.y = ceilf(card.size.x * aspect))
	return card


func _place(parent: Control, child: Control, bounds: Rect2) -> void:
	parent.add_child(child)
	child.anchor_left = bounds.position.x
	child.anchor_top = bounds.position.y
	child.anchor_right = bounds.end.x
	child.anchor_bottom = bounds.end.y
	child.offset_left = 0
	child.offset_right = 0
	child.offset_top = 0
	child.offset_bottom = 0


func _copy(card: Control, copy: String, bounds: Rect2, font_size: int = 23, color: Color = P.CREAM) -> Label:
	var label: Label = T.label(copy, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.max_lines_visible = 1
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = copy
	if color == P.INK:
		label.add_theme_constant_override("outline_size", 0)
		label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_place(card, label, bounds)
	return label


func _card_button(card: Control, copy: String, callback: Callable, enabled: bool) -> Button:
	var button := Button.new()
	button.name = "Buy"
	button.text = copy
	button.add_theme_font_override("font", P.bold_font())
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", P.CREAM)
	button.add_theme_color_override("font_disabled_color", Color("9d946d"))
	button.add_theme_constant_override("outline_size", 2)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed", "focus"]:
		var style: StyleBoxFlat = T.style(Color(1, 0.90, 0.55, 0.12), 7, P.GOLD, 0)
		button.add_theme_stylebox_override(state, style)
	button.disabled = not enabled
	button.pressed.connect(callback)
	_place(card, button, Rect2(0.13, 0.837, 0.74, 0.122))
	return button


func _animal_card(species: Dictionary, rarity: String, sex: String) -> Control:
	var id: String = str(species.get("id", ""))
	var card: Control = _card(id + "_" + rarity + "_" + sex)
	card.set_meta("reptile_id", id)
	card.set_meta("rarity", rarity)
	card.set_meta("sex", sex)
	var title: Label = _copy(card, T.localized(str(species.get("name_key", ""))), Rect2(0.10, 0.05, 0.80, 0.125), 26)
	title.name = "CardName"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	var variant: Dictionary = ReptileSystem.get_shop_variant_for_rarity(id, rarity)
	var portrait: TextureRect = T.texture(ReptileSystem.get_owned_animal_image_path({"reptile_id": id, "rarity": rarity, "variant_id": variant.get("id", "")}), Vector2.ZERO)
	portrait.name = "Portrait"
	_place(card, portrait, Rect2(0.075, 0.175, 0.85, 0.29))
	_copy(card, T.rarity_name(rarity), Rect2(0.11, 0.4725, 0.78, 0.0625), 23, P.CREAM).name = "Rarity"
	var badge: Control = T.sex_badge(sex, true)
	badge.name = "SexBadge"
	_place(card, badge, Rect2(0.14, 0.55, 0.72, 0.1125))
	_copy(card, T.text("Base %.1f R$/min", "Bazowo %.1f R$/min") % ReptileSystem.get_base_reptile_income(id), Rect2(0.11, 0.676, 0.78, 0.055), 21, P.INK).name = "BaseIncome"
	var price: int = ReptileSystem.get_shop_purchase_price(id, rarity)
	card.set_meta("price", price)
	_copy(card, T.text("FREE", "ZA DARMO") if price == 0 else T.amount(maxi(0, price)) + " R$", Rect2(0.15, 0.738, 0.70, 0.08), 27, P.GOLD).name = "Price"
	var unlocked: bool = _is_unlocked(biome_id)
	var enabled: bool = unlocked and not variant.is_empty() and price >= 0 and EconomySystem.can_afford("repticash", price) and not _busy
	_card_button(card, T.text("ADOPT", "PRZYGARNIJ") if unlocked else T.text("LEVEL ", "POZIOM ") + str(_unlock_level(biome_id)), _purchase.bind(id, rarity, sex), enabled)
	return card


func _product_texture(resource: String) -> Texture2D:
	var source: Texture2D = load(ART + "product_atlas.png")
	var cell_size := Vector2(source.get_width() / 4.0, source.get_height() / 2.0)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	var index: int = 0 if resource == "food" else 1
	atlas.region = Rect2(Vector2(index * cell_size.x + 5, cell_size.y * 0.12), Vector2(cell_size.x - 10, cell_size.y * 0.78))
	return atlas


func _resource_card(resource: String) -> Control:
	var card: Control = _card(resource)
	var food: bool = resource == "food"
	_copy(card, T.text("Food crate", "Skrzynia pokarmu") if food else T.text("Water reserve", "Zapas wody"), Rect2(0.10, 0.05, 0.80, 0.115), 25)
	var portrait := TextureRect.new()
	portrait.texture = _product_texture(resource)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(card, portrait, Rect2(0.10, 0.18, 0.80, 0.35))
	var config: Dictionary = ReptileSystem.get_shop_config(resource)
	var amount: int = int(config.get("amount", 50))
	var price: int = int(config.get("price", 100))
	var current: int = ReptileSystem.get_biome_resource_current(biome_id, resource)
	var maximum: int = ReptileSystem.get_biome_resource_max(biome_id, resource)
	_copy(card, "+%d " % amount + (T.text("food", "pokarmu") if food else T.text("water", "wody")), Rect2(0.11, 0.55, 0.78, 0.07), 26, P.INK)
	_copy(card, "%d / %d" % [current, maximum], Rect2(0.11, 0.63, 0.78, 0.07), 24, P.INK)
	_copy(card, str(price) + " R$", Rect2(0.15, 0.738, 0.70, 0.08), 28, P.GOLD)
	_card_button(card, T.text("FULL", "PEŁNE") if current >= maximum else T.text("BUY", "KUP"), _buy_resource.bind(resource), _is_unlocked(biome_id) and current < maximum and EconomySystem.can_afford("repticash", price) and not _busy)
	return card


func _ad_card() -> Control:
	var card: Control = _card("optional_ad")
	_copy(card, T.text("Optional ad", "Nagroda z reklamy"), Rect2(0.10, 0.05, 0.80, 0.14), 22)
	var portrait: TextureRect = T.texture("res://assets/prototype/art/ui/world/reward_coins_clean.png", Vector2.ZERO)
	_place(card, portrait, Rect2(0.10, 0.205, 0.80, 0.325))
	_copy(card, T.text("Refill supplies or earn R$", "Uzupełnij zapasy lub zdobądź R$"), Rect2(0.11, 0.55, 0.78, 0.13), 22, P.INK)
	_copy(card, T.text("OPTIONAL AD", "REKLAMA"), Rect2(0.15, 0.738, 0.70, 0.08), 23, P.GOLD)
	_card_button(card, T.text("OPTIONS", "WYBIERZ"), _show_ad_options, _is_unlocked(biome_id) and not _ad_busy and not ResourceAdService.is_limit_reached())
	return card


func _purchase(id: String, rarity: String, sex: String) -> void:
	if _busy:
		return
	if rarity not in SHOP_RARITIES or sex not in SHOP_SEXES:
		toast_requested.emit(T.localized("shop.unavailable"))
		return
	if not _is_unlocked(biome_id) or not ReptileSystem.is_reptile_available_in_biome(id, biome_id):
		toast_requested.emit(T.text("This species belongs to a locked or different region.", "Ten gatunek należy do zamkniętego lub innego regionu."))
		return
	_busy = true
	var result: Dictionary = ReptileSystem.purchase_reptile_from_shop(id, rarity, sex)
	if bool(result.get("success", false)):
		QuestSystem.notify_event("reptile_purchased", {"reptile_id": id, "rarity": rarity, "price": int(result.get("price", 0))})
		toast_requested.emit(T.localized(str(result.get("message_key", "ui.reptile_added"))))
		refresh_requested.emit()
		_refresh_queued = true
		call_deferred("_finish_purchase")
		details_requested.emit(str(result.get("instance_id", "")))
	else:
		toast_requested.emit(T.localized(str(result.get("message_key", "shop.unavailable"))))
		call_deferred("_finish_purchase")


func _buy_resource(resource: String) -> void:
	if _busy or not _is_unlocked(biome_id):
		return
	_busy = true
	var before: int = ReptileSystem.get_biome_resource_current(biome_id, resource)
	var result: Dictionary = ReptileSystem.buy_resource(biome_id, resource)
	if bool(result.get("success", false)):
		var received: int = ReptileSystem.get_biome_resource_current(biome_id, resource) - before
		toast_requested.emit(T.text("Supplies added: ", "Dodano zapasy: ") + str(received))
		refresh_requested.emit()
	else:
		toast_requested.emit(T.localized(str(result.get("message_key", "shop.unavailable"))))
	call_deferred("_finish_purchase")


func _finish_purchase() -> void:
	_busy = false
	_refresh_queued = false
	if is_inside_tree():
		_render_cards()


func _show_ad_options() -> void:
	var existing: Node = _content.get_node_or_null("AdOptions")
	if existing != null:
		_content.remove_child(existing)
		existing.queue_free()
		return
	var options: VBoxContainer = T.column(8)
	options.name = "AdOptions"
	_content.add_child(options)
	options.add_child(T.label(T.text("Watch an optional ad for one reward", "Obejrzyj dobrowolną reklamę za jedną nagrodę"), 25, P.CREAM))
	for resource in ["food", "water", "money"]:
		var copy: String = T.text("Refill food", "Uzupełnij pokarm") if resource == "food" else T.text("Refill water", "Uzupełnij wodę")
		if resource == "money":
			copy = T.amount(ResourceAdService.get_money_reward_amount()) + " R$"
		options.add_child(_button(copy, _resource_ad.bind(resource), true, 25))


func _resource_ad(resource: String) -> void:
	if _ad_busy or not _is_unlocked(biome_id):
		return
	_ad_busy = true
	toast_requested.emit(T.text("Preparing your optional ad…", "Przygotowanie dobrowolnej reklamy…"))
	ResourceAdService.request_resource_reward(resource, biome_id,
		func(_result: Dictionary) -> void:
			_ad_busy = false
			toast_requested.emit(T.text("Reward received", "Nagroda odebrana"))
			refresh_requested.emit()
			refresh(),
		func(key: String) -> void:
			_ad_busy = false
			toast_requested.emit(T.localized(key))
			refresh())
