extends Control
## Portrait-first presentation over the existing, migrated game systems.

const T := preload("res://scripts/modern/SanctuaryTheme.gd")
const Nursery := preload("res://scripts/modern/IncubatorPage.gd")
const TerrariumCard := preload("res://scripts/modern/PrototypeTerrariumCard.gd")
var page := "home"
var biome := "green_meadow"
var collection_tab := "owned"
var store_tab := "animals"
var safe: MarginContainer
var content: VBoxContainer
var scroll: ScrollContainer
var body: VBoxContainer
var cash_label: Label
var status_label: Label
var modal: Control
var toast_panel: PanelContainer
var toast_label: Label
var toast_serial := 0
var nav: Control
var top_bar: Control
var expedition_page: Node
var nursery_page: Node
var collection_page: Node
var shop_page: Node
var _tick := 0.0
var _rebuilding := false
var _refresh_pending := false
var _onboarding_signature := ""
var _timer_signature := ""
var biome_definitions: Array = []
var habitat_definitions: Array = []
var reward_badge: TextureRect
var reward_badge_tween: Tween

func _ready() -> void:
	theme = T.make_theme()
	biome_definitions = _json("res://data/biomes.json")
	habitat_definitions = _json("res://data/habitats.json")
	OnboardingSystem.set_embedded_mode(true)
	OnboardingSystem.onboarding_progress_changed.connect(_on_progress)
	GameState.language_changed.connect(func(_language: String): _build_shell())
	EconomySystem.currency_changed.connect(func(_id: String, _value: Variant): _update_header())
	get_viewport().size_changed.connect(_apply_safe_area)
	_build_shell()
	call_deferred("_welcome_back")
	if not _is_unlocked(biome): biome = "green_meadow"
	get_tree().auto_accept_quit = false

func _json(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if AppUpdateService.dismiss_overlay(): return
		if LevelUpOverlay.visible:
			LevelUpOverlay._on_continue()
			return
		var ad_confirmation := find_child("SpeedUpConfirmModal", true, false)
		if is_instance_valid(ad_confirmation):
			ad_confirmation.queue_free()
			return
		if is_instance_valid(collection_page) and collection_page.dismiss_overlay(): return
		if is_instance_valid(expedition_page) and expedition_page.dismiss_overlay(): return
		if is_instance_valid(nursery_page) and nursery_page.dismiss_overlay(): return
		if is_instance_valid(modal): _close_modal()
		elif page != "home": _navigate("home")
		else: _confirm(T.text("Leave your sanctuary?", "Opuścić hodowlę?"), T.text("Your progress is saved. Your eggs keep incubating.", "Postęp jest zapisany. Twoje jaja nadal się inkubują."), func(): SaveSystem.save_game(); get_tree().quit())
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveSystem.save_game()
		get_tree().quit()

func _build_shell() -> void:
	_close_modal()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := ColorRect.new()
	background.color = T.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var backdrop := T.texture("res://assets/art/modern/sanctuary_background.png", Vector2.ZERO)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.01, 0.27)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	safe = MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	content = T.column(0)
	safe.add_child(content)
	top_bar = preload("res://scripts/modern/PrototypeTopBar.gd").new()
	content.add_child(top_bar)
	top_bar.shop_requested.connect(func(resource: String):
		store_tab = "resources" if resource in ["food", "water", "repticash"] else "animals"
		_navigate("shop"))
	top_bar.context_back_requested.connect(func(): _navigate("home"))
	scroll = preload("res://scripts/modern/TouchScrollContainer.gd").new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var padding := MarginContainer.new()
	padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right"]: padding.add_theme_constant_override("margin_" + edge, 24)
	padding.add_theme_constant_override("margin_bottom", 32)
	scroll.add_child(padding)
	body = T.column(12)
	padding.add_child(body)
	# The navigation's illustrated frame extends 26% above its layout box.
	# Reserve that space outside the clipped scroll viewport, at every scroll offset.
	var nav_clearance := Control.new()
	nav_clearance.name = "NavigationClearance"
	nav_clearance.custom_minimum_size.y = 38
	nav_clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(nav_clearance)
	nav = preload("res://scripts/modern/PrototypeBottomNav.gd").new()
	content.add_child(nav)
	nav.tab_selected.connect(_navigate)
	_build_nav()
	_apply_safe_area()
	_update_header()
	_render()

func _apply_safe_area() -> void:
	if not is_instance_valid(safe): return
	var top := 0
	var bottom := 0
	var left := 0
	var right := 0
	if OS.has_feature("android") or OS.has_feature("ios"):
		var area := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var view := get_viewport_rect().size
		if screen.x > 0 and screen.y > 0 and area.size.x > 0:
			var sx := view.x / float(screen.x)
			var sy := view.y / float(screen.y)
			left = int(area.position.x * sx)
			right = int((screen.x - area.end.x) * sx)
			top = int(area.position.y * sy)
			bottom = int((screen.y - area.end.y) * sy)
	safe.add_theme_constant_override("margin_top", maxi(top, 8))
	safe.add_theme_constant_override("margin_bottom", maxi(bottom, 10))
	safe.add_theme_constant_override("margin_left", maxi(left, 0))
	safe.add_theme_constant_override("margin_right", maxi(right, 0))

func _build_nav() -> void:
	if is_instance_valid(nav): nav.set_selected(page)

func _navigate(next: String) -> void:
	_close_modal()
	page = next
	scroll.scroll_vertical = 0
	_build_nav()
	_render()
	FirebaseAnalyticsService.log_event("game_screen_view", {"screen": page})
	var screen_id: String = {"home": "biome", "tasks": "quests", "team": "workers", "collection": "animals"}.get(page, page)
	QuestSystem.notify_event("screen_opened", {"screen": screen_id})
	if page == "nursery" and _is_unlocked("incubator"): QuestSystem.notify_event("incubator_entered", {})

func _render() -> void:
	if _rebuilding or not is_instance_valid(body): return
	_rebuilding = true
	nursery_page = null
	expedition_page = null
	collection_page = null
	shop_page = null
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	_brand_header()
	match page:
		"home": _home()
		"collection":
			collection_page = preload("res://scripts/modern/CollectionPage.gd").new()
			collection_page.tab = collection_tab
			body.add_child(collection_page)
			collection_page.toast_requested.connect(_toast)
			collection_page.refresh_requested.connect(_schedule_refresh)
			collection_page.details_requested.connect(_animal_detail)
			collection_page.nursery_requested.connect(func(): _navigate("nursery"))
			collection_page.shop_requested.connect(func(): store_tab = "animals"; _navigate("shop"))
		"world":
			expedition_page = preload("res://scripts/modern/ExpeditionsPage.gd").new()
			body.add_child(expedition_page)
			expedition_page.toast_requested.connect(_toast)
			expedition_page.refresh_requested.connect(_schedule_refresh)
			expedition_page.details_requested.connect(_animal_detail)
		"shop":
			shop_page = preload("res://scripts/modern/ShopPage.gd").new()
			shop_page.tab = store_tab
			shop_page.biome_id = biome
			body.add_child(shop_page)
			shop_page.toast_requested.connect(_toast)
			shop_page.refresh_requested.connect(_schedule_refresh)
			shop_page.details_requested.connect(_animal_detail)
			shop_page.nursery_requested.connect(func(): _navigate("nursery"))
		"tasks": _tasks()
		"team": _team()
		"upgrades": _upgrades()
		"nursery":
			if _is_unlocked("incubator"):
				nursery_page = Nursery.new()
				body.add_child(nursery_page)
				nursery_page.toast_requested.connect(_toast)
				if nursery_page.has_signal("details_requested"): nursery_page.details_requested.connect(_animal_detail)
				if nursery_page.has_signal("refresh_requested"): nursery_page.refresh_requested.connect(_schedule_refresh)
			else:
				_hero(T.text("A little wonder is waiting.", "Czeka tu mały cud."), T.text("Your nursery opens at level %d.", "Inkubator otwiera się na poziomie %d.") % _unlock_level("incubator"))
				_onboarding_card()
				body.add_child(T.button(T.text("Continue your first steps", "Kontynuuj pierwsze kroki"), func(): _navigate("home")))
	_rebuilding = false
	_update_header()

func _schedule_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	call_deferred("_deferred_refresh")

func _deferred_refresh() -> void:
	_refresh_pending = false
	if page == "collection" and is_instance_valid(collection_page):
		collection_page.refresh()
		_update_header()
		return
	if page == "shop" and is_instance_valid(shop_page):
		shop_page.refresh()
		_update_header()
		return
	if page == "world" and is_instance_valid(expedition_page):
		expedition_page.refresh()
		_update_header()
		return
	if page == "nursery" and is_instance_valid(nursery_page):
		nursery_page.refresh()
		_update_header()
		return
	var offset := scroll.scroll_vertical
	_render()
	scroll.set_deferred("scroll_vertical", offset)

func _on_progress() -> void:
	var state: Dictionary = OnboardingSystem.get_current_task_state()
	var signature := str(state)
	if signature != _onboarding_signature:
		_onboarding_signature = signature
		if page == "home": _schedule_refresh()

func _process(delta: float) -> void:
	_tick += delta
	if _tick < 1.0: return
	_tick = 0.0
	ReptileSystem.apply_time_updates(false)
	_update_header()
	if page == "home" and not is_instance_valid(modal):
		var sig := ""
		for h in _owned_habitats(): sig += str(h.get("is_building", false)) + str(h.get("is_upgrading", false))
		if sig != _timer_signature:
			_timer_signature = sig
			_schedule_refresh()

func _update_header() -> void:
	_update_reward_attention()
	if is_instance_valid(top_bar):
		top_bar.set_biome(biome)
		top_bar.refresh()

func _hero(title: String, subtitle: String) -> void:
	var hero := PanelContainer.new()
	hero.custom_minimum_size.y = 350
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", T.style(T.SURFACE, 26, Color.TRANSPARENT, 0))
	body.add_child(hero)
	var image := T.texture("res://assets/art/modern/sanctuary_hero.png", Vector2.ZERO)
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.add_child(image)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 235)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	hero.add_child(margin)
	var words := T.column(15)
	margin.add_child(words)
	words.add_child(T.label(T.text("GROW SOMETHING EXTRAORDINARY", "WYHODUJ COŚ WYJĄTKOWEGO"), 17, T.ACCENT))
	words.add_child(T.label(title, 40))
	words.add_child(T.label(subtitle, 22, Color("d4dfca")))

func _home() -> void:
	var habitats := _owned_habitats()
	if _is_unlocked("dry_prairie"):
		var selector := T.row(8)
		body.add_child(selector)
		for region in ["green_meadow", "dry_prairie"]:
			var pick := T.button(_biome_name(region), func(): biome = region; _schedule_refresh(), "primary" if region == biome else "secondary")
			pick.custom_minimum_size.y = 52
			pick.add_theme_font_size_override("font_size", 23)
			selector.add_child(pick)
	if habitats.is_empty():
		_first_terrarium()
	else:
		var grid := GridContainer.new()
		grid.columns = clampi(habitats.size(), 2, 3)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 10)
		body.add_child(grid)
		for habitat in habitats: _habitat_card(grid, habitat)
		if habitats.size() == 1:
			var next_slot := Control.new()
			next_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(next_slot)
	if not bool(GameState.get_value("starter_reptile_claimed", false)):
		body.add_child(T.button(T.text("Adopt your first gecko · FREE", "Odbierz pierwszego gekona · GRATIS"), _adopt_starter))
	elif ReptileSystem.get_owned_unassigned_reptiles(biome).size() > 0 and _has_ready_empty_terrarium(habitats):
		body.add_child(T.button(T.text("Place a reptile in a terrarium", "Umieść gada w terrarium"), func():
			_assign(str(ReptileSystem.get_owned_unassigned_reptiles(biome)[0].get("instance_id", "")))))
	var summaries := T.row(8)
	body.add_child(summaries)
	_summary_widget(summaries, T.text("SANCTUARY INCOME", "DOCHÓD HODOWLI"), "%.1f / min" % ReptileSystem.get_total_assigned_income_per_min(), T.text("%d terrariums", "%d terrariów") % habitats.size(), "center_summary_wood_v2.png", func(): _navigate("upgrades"))
	var task_state: Dictionary = OnboardingSystem.get_current_task_state()
	_summary_widget(summaries, T.text("KEEPER'S TASKS", "ZADANIA OPIEKUNA"), T.text("Your next discovery", "Kolejne odkrycie"), str(task_state.get("title", T.text("Goals & rewards", "Cele i nagrody"))), "center_summary_tasks_v2.png", func(): _navigate("tasks"))
	_onboarding_card()
	if not habitats.is_empty() and _can_build_terrarium(): _build_banner()
	if EconomySystem.has_pending_offline_income():
		body.add_child(T.button(T.text("Collect offline income · %s R$", "Odbierz dochód offline · %s R$") % T.amount(EconomySystem.get_pending_offline_income()), func():
			_toast("+" + T.amount(EconomySystem.claim_offline_income()) + " R$")
			_schedule_refresh()))
	var management := T.row(10)
	body.add_child(management)
	management.add_child(T.button(T.text("KEEPERS", "OPIEKUNOWIE"), func(): _navigate("team"), "secondary"))
	management.add_child(T.button(T.text("UPGRADES", "ULEPSZENIA"), func(): _navigate("upgrades"), "secondary"))

func _has_ready_empty_terrarium(habitats: Array) -> bool:
	for habitat: Dictionary in habitats:
		if bool(habitat.get("is_building", false)) or bool(habitat.get("is_upgrading", false)): continue
		if ReptileSystem.get_reptile_for_habitat(str(habitat.get("habitat_id", ""))).is_empty(): return true
	return false

func _adopt_starter() -> void:
	var result := ReptileSystem.purchase_reptile_from_shop("leopard_gecko", "common", "female")
	if result.get("success", false): QuestSystem.notify_event("reptile_purchased", {"reptile_id": "leopard_gecko", "rarity": "common", "price": 0})
	_result(result)
	_schedule_refresh()

func _first_terrarium() -> void:
	var title := T.label(T.text("YOUR FIRST TERRARIUM", "TWOJE PIERWSZE TERRARIUM"), 34, T.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	# This is an empty enclosure preview. A reptile only appears after assignment.
	var enclosure := T.texture(_terrarium_path("grass", 1), Vector2(0, 450))
	body.add_child(enclosure)
	_build_banner()

func _build_banner() -> void:
	var banner := Button.new()
	_empty_button(banner)
	banner.custom_minimum_size.y = 164
	banner.resized.connect(func(): banner.custom_minimum_size.y = banner.size.x * 528.0 / 2172.0)
	banner.pressed.connect(_choose_habitat)
	body.add_child(banner)
	var art := T.texture("res://assets/prototype/art/ui/center/center_build_banner_source_v2.png", Vector2.ZERO)
	var crop := AtlasTexture.new()
	crop.atlas = art.texture
	crop.region = Rect2(0, 74, art.texture.get_width(), 528)
	art.texture = crop
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.add_child(art)
	var plus := T.label("+", 66, T.GOLD)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(plus, Rect2(0.064, 0.15, 0.16, 0.70))
	banner.add_child(plus)
	var words := T.column(0)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(words, Rect2(0.27, 0.12, 0.67, 0.76))
	banner.add_child(words)
	var heading := T.label(T.text("BUILD A TERRARIUM · %s R$", "ZBUDUJ TERRARIUM · %s R$") % T.amount(EconomySystem.get_next_habitat_price(biome)), 30, Color("35240f"))
	heading.add_theme_constant_override("outline_size", 0)
	heading.add_theme_constant_override("shadow_offset_y", 0)
	words.add_child(heading)
	var detail := T.label(T.text("Choose a biome. Make room for a new discovery.", "Wybierz biom. Stwórz dom dla kolejnego odkrycia."), 24)
	words.add_child(detail)

func _brand_header() -> void:
	var stage := Control.new()
	stage.custom_minimum_size.y = 150
	body.add_child(stage)
	var logo := T.texture("res://assets/prototype/art/ui/prototype/logo_reptile_tycoon_cutout_v2.png", Vector2.ZERO)
	var atlas := AtlasTexture.new()
	atlas.atlas = logo.texture
	atlas.region = Rect2(136, 42, 1673, 663)
	logo.texture = atlas
	_place_control(logo, Rect2(0.25, 0.02, 0.5, 0.90))
	stage.add_child(logo)
	var utilities := T.texture("res://assets/prototype/art/ui/prototype/center_utilities.png", Vector2.ZERO)
	_place_control(utilities, Rect2(0, 0.16, 0.25, 0.70))
	_black_key(utilities)
	stage.add_child(utilities)
	for index in range(2):
		var utility := Button.new()
		_empty_button(utility)
		_place_control(utility, Rect2(index * 0.125, 0.17, 0.12, 0.66))
		utility.tooltip_text = T.text("Settings", "Ustawienia") if index == 0 else T.text("Keeper tasks", "Zadania opiekuna")
		utility.pressed.connect(_settings if index == 0 else func(): _navigate("tasks"))
		stage.add_child(utility)
	var reward := T.texture("res://assets/prototype/art/ui/prototype/daily_bonus.png", Vector2.ZERO)
	var crop := AtlasTexture.new()
	crop.atlas = reward.texture
	crop.region = Rect2(0, 140, reward.texture.get_width(), reward.texture.get_height() - 280)
	reward.texture = crop
	_place_control(reward, Rect2(0.75, 0.19, 0.25, 0.64))
	_black_key(reward)
	stage.add_child(reward)
	var goals := T.label(T.text("GOALS\n& REWARDS", "CELE\nI NAGRODY"), 21, T.TEXT)
	goals.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place_control(goals, Rect2(0.83, 0.30, 0.155, 0.46))
	stage.add_child(goals)
	var hit := Button.new()
	_empty_button(hit)
	_place_control(hit, Rect2(0.75, 0.19, 0.25, 0.64))
	hit.pressed.connect(func(): _navigate("tasks"))
	stage.add_child(hit)
	reward_badge = T.texture("res://assets/prototype/art/icons/alert.png", Vector2.ZERO)
	reward_badge.name = "ClaimableRewardBadge"
	reward_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_badge.anchor_left = 1.0
	reward_badge.anchor_right = 1.0
	reward_badge.offset_left = -49
	reward_badge.offset_right = -3
	reward_badge.offset_top = 3
	reward_badge.offset_bottom = 49
	reward_badge.tooltip_text = T.text("A reward is ready to collect!", "Nagroda czeka na odbiór!")
	stage.add_child(reward_badge)
	_update_reward_attention()

func _has_claimable_rewards() -> bool:
	if bool(OnboardingSystem.get_current_task_state().get("claimable", false)):
		return true
	if not QuestSystem.get_completed_unclaimed_quests().is_empty():
		return true
	for achievement: Dictionary in AchievementSystem.get_achievement_states():
		if bool(achievement.get("claimable", false)):
			return true
	return false

func _update_reward_attention() -> void:
	if not is_instance_valid(reward_badge): return
	var show_badge := _has_claimable_rewards()
	reward_badge.visible = show_badge
	if not show_badge:
		if reward_badge_tween and reward_badge_tween.is_valid(): reward_badge_tween.kill()
		reward_badge.modulate.a = 1.0
	elif not reward_badge_tween or not reward_badge_tween.is_valid():
		reward_badge_tween = reward_badge.create_tween().set_loops()
		reward_badge_tween.tween_property(reward_badge, "modulate:a", 0.35, 0.45)
		reward_badge_tween.tween_property(reward_badge, "modulate:a", 1.0, 0.45)

func _feature_card(parent: Node, title: String, art: String, description: String, action: String, callback: Callable) -> void:
	var card := Control.new()
	card.custom_minimum_size.y = 365
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var background := T.texture("res://assets/prototype/art/ui/center/center_empty_slot_v2.png", Vector2.ZERO)
	var aspect: float = float(background.texture.get_height()) / float(background.texture.get_width())
	card.resized.connect(func(): card.custom_minimum_size.y = ceilf(card.size.x * aspect))
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(background)
	var heading := T.label(title, 22)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.max_lines_visible = 2
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.tooltip_text = title
	_place_control(heading, Rect2(0.12, 0.05, 0.76, 0.13))
	card.add_child(heading)
	var picture := T.texture(art, Vector2.ZERO)
	_place_control(picture, Rect2(0.12, 0.18, 0.76, 0.43))
	card.add_child(picture)
	var text := T.label(description, 23, Color("422509"))
	text.add_theme_constant_override("outline_size", 0)
	text.add_theme_constant_override("shadow_offset_y", 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.max_lines_visible = 3
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.tooltip_text = description
	_place_control(text, Rect2(0.12, 0.63, 0.76, 0.17))
	card.add_child(text)
	var button := Button.new()
	_empty_button(button)
	button.text = action
	button.add_theme_font_size_override("font_size", 24)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text = action
	_place_control(button, Rect2(0.08, 0.83, 0.84, 0.125))
	button.pressed.connect(callback)
	card.add_child(button)

func _summary_widget(parent: Node, title: String, value: String, subtitle: String, skin: String, callback: Callable) -> void:
	var paper: bool = "tasks" in skin or "parchment" in skin
	var panel := PanelContainer.new()
	panel.name = "SummaryTasks" if paper else "SummaryIncome"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", T.Controls.parchment() if paper else T.Controls.wood_panel())
	parent.add_child(panel)
	var box := T.column(3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(box)
	box.add_child(T.label(title, 21, T.GOLD))
	box.add_child(T.label(value, 27, T.TEXT))
	box.add_child(T.label(subtitle, 20, T.TEXT))
	for index in range(box.get_child_count()):
		var label: Label = box.get_child(index)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.max_lines_visible = 2
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.tooltip_text = label.text
		if paper:
			label.add_theme_color_override("font_color", Color("493014"))
			label.add_theme_constant_override("outline_size", 0)
			label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	var button := Button.new()
	_empty_button(button)
	button.tooltip_text = title + " ? " + subtitle
	button.pressed.connect(callback)
	panel.add_child(button)

func _place_control(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.end.x
	control.anchor_bottom = rect.end.y

func _black_key(control: CanvasItem) -> void:
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/prototype/shaders/black_key.gdshader")
	control.material = material

func _empty_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _onboarding_card() -> void:
	var state: Dictionary = OnboardingSystem.get_current_task_state()
	if state.is_empty(): return
	var box := _box(body)
	box.add_child(T.label(T.text("YOUR NEXT DISCOVERY · %d/%d", "KOLEJNE ODKRYCIE · %d/%d") % [state.get("step", 1), state.get("total_steps", 6)], 18, T.ACCENT))
	box.add_child(T.label(str(state.get("title", "")), 28))
	box.add_child(T.label(str(state.get("body", "")), 23, T.MUTED))
	if state.get("claimable", false):
		box.add_child(T.button(T.text("Collect & continue", "Odbierz i kontynuuj"), func(): OnboardingSystem.claim_current_task(); _schedule_refresh()))
	else:
		box.add_child(T.button(str(state.get("action", T.text("Let's go", "Zaczynajmy"))), func(): _onboarding_action(str(state.get("target_ui_key", "")))))

func _onboarding_action(target: String) -> void:
	match target:
		"collection": _navigate("shop")
		"habitat":
			_navigate("home")
			if _owned_habitats().is_empty(): _choose_habitat()
			else:
				for instance in ReptileSystem.get_owned_unassigned_reptiles():
					_assign(str(instance.get("instance_id", "")))
					break
		"care":
			for instance in ReptileSystem.get_owned_reptile_instances().values():
				if instance.get("habitat_id") != null and not str(instance.get("habitat_id", "")).is_empty():
					_animal_detail(str(instance.get("instance_id", "")))
					break
		"incubator", "breeding": _navigate("nursery")
		_: _navigate("home")

func _box(parent: Node) -> VBoxContainer:
	var panel := T.card()
	parent.add_child(panel)
	var box := T.column(12)
	panel.add_child(box)
	return box

func _habitat_card(parent: Node, habitat: Dictionary) -> void:
	var card := TerrariumCard.new()
	card.setup(habitat, ReptileSystem.get_reptile_for_habitat(str(habitat.get("habitat_id", ""))))
	card.profile_requested.connect(_animal_detail)
	card.assign_requested.connect(_choose_animal)
	card.care_requested.connect(func(id: String, action: String):
		var result := ReptileSystem.perform_care_action(id, action)
		if result.get("success", false): QuestSystem.notify_event("care_action_success", {"action": action, "instance_id": id})
		_result(result)
		card.refresh()
		SaveSystem.save_game())
	parent.add_child(card)

func _legacy_habitat_card(parent: Node, habitat: Dictionary) -> void:
	var box := _box(parent)
	var id: String = habitat.get("habitat_id", "")
	var animal: Dictionary = ReptileSystem.get_reptile_for_habitat(id)
	box.add_child(T.label(T.text("LEVEL %d · %s", "POZIOM %d · %s") % [habitat.get("habitat_level", 1), _habitat_name(str(habitat.get("habitat_type", "grass")))], 20, T.GOLD))
	box.add_child(_terrarium_view(habitat, animal, 300))
	if animal.is_empty():
		var working := bool(habitat.get("is_building", false))
		box.add_child(T.label(_habitat_name(habitat.get("habitat_type", "grass")), 26))
		if working:
			box.add_child(T.label(T.text("Preparing your habitat…", "Przygotowanie siedliska…"), 22, T.GOLD))
		else:
			box.add_child(T.button(T.text("Choose a reptile", "Wybierz gada"), func(): _choose_animal(id), "secondary"))
	else:
		box.add_child(T.label(_animal_name(animal), 27))
		box.add_child(T.label(T.rarity_name(str(animal.get("rarity", "common"))), 20, T.rarity_color(str(animal.get("rarity", "common")))))
		box.add_child(T.progress(_condition(animal)))
		box.add_child(T.button(T.text("Care", "Opieka"), func(): _animal_detail(str(animal.get("instance_id", ""))), "primary"))

func _can_build_terrarium() -> bool:
	var owned: Dictionary = GameState.get_value("habitats", {})
	for definition in habitat_definitions:
		if definition.get("biome_id") == biome and not owned.get(definition["id"], {}).get("purchased", false):
			return true
	return false

func _terrarium_path(type: String, level: int) -> String:
	var path := "res://assets/art/modern/terrarium_%s_%d.png" % [type, clampi(level, 1, 3)]
	return path if ResourceLoader.exists(path) else ReptileSystem.get_habitat_texture_path(type, level)

func _terrarium_view(habitat: Dictionary, animal: Dictionary, height: int) -> Control:
	var view := Control.new()
	view.custom_minimum_size.y = height
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var enclosure := T.texture(_terrarium_path(str(habitat.get("habitat_type", "grass")), int(habitat.get("habitat_level", 1))), Vector2.ZERO)
	enclosure.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.add_child(enclosure)
	if not animal.is_empty():
		var resident := T.texture(ReptileSystem.get_owned_animal_image_path(animal), Vector2.ZERO)
		resident.anchor_left = 0.15
		resident.anchor_right = 0.85
		resident.anchor_top = 0.31
		resident.anchor_bottom = 0.86
		view.add_child(resident)
	return view

func _choose_habitat() -> void:
	_close_modal()
	var picker := preload("res://scripts/modern/BuildTerrariumView.gd").new()
	picker.biome_id = biome
	picker.region_name = _biome_name(biome)
	picker.terrarium_path = _terrarium_path
	picker.habitat_name = _habitat_name
	picker.black_key = _black_key
	picker.safe_insets = Vector4(safe.get_theme_constant("margin_left"), safe.get_theme_constant("margin_top"), safe.get_theme_constant("margin_right"), safe.get_theme_constant("margin_bottom"))
	picker.has_build_slot = false
	var habitats: Dictionary = GameState.get_value("habitats", {})
	for definition in habitat_definitions:
		if definition.get("biome_id") == biome and not bool(habitats.get(definition["id"], {}).get("purchased", false)):
			picker.has_build_slot = true
			break
	picker.z_index = 50
	modal = picker
	picker.closed.connect(_close_modal)
	picker.build_requested.connect(_build_habitat)
	picker.route_requested.connect(_navigate)
	picker.shop_requested.connect(func(_resource: String): store_tab = "resources"; _navigate("shop"))
	add_child(picker)

func _build_habitat(type: String) -> void:
	var habitats: Dictionary = GameState.get_value("habitats", {})
	var chosen: Dictionary = {}
	for definition in habitat_definitions:
		if definition.get("biome_id") == biome and not bool(habitats.get(definition["id"], {}).get("purchased", false)):
			chosen = definition
			break
	if chosen.is_empty(): return
	var result: Dictionary = ReptileSystem.start_habitat_build(str(chosen["id"]), type)
	if not bool(result.get("success", false)):
		_result(result)
		return
	_close_modal()
	_schedule_refresh()
	_toast(T.text("A new home is on its way.", "Nowy dom już powstaje.") + ("  +%d XP" % int(result.get("xp_reward", 0)) if int(result.get("xp_reward", 0)) > 0 else ""))

func _choose_animal(habitat_id: String) -> void:
	_close_modal()
	var target: Dictionary = ReptileSystem.get_habitat_state(habitat_id)
	var picker := preload("res://scripts/modern/ResidentPickerView.gd").new()
	picker.target_habitat_id = habitat_id
	picker.biome_id = str(target.get("biome_id", biome))
	picker.safe_insets = Vector4(safe.get_theme_constant("margin_left"), safe.get_theme_constant("margin_top"), safe.get_theme_constant("margin_right"), safe.get_theme_constant("margin_bottom"))
	picker.z_index = 50
	modal = picker
	picker.closed.connect(_close_modal)
	picker.toast_requested.connect(_toast)
	picker.shop_requested.connect(func() -> void: store_tab = "animals"; _navigate("shop"))
	picker.assignment_completed.connect(func(id: String, region: String, result: Dictionary) -> void:
		_result(result)
		if str(result.get("previous_habitat_id", "")).is_empty():
			QuestSystem.notify_event("reptile_assigned", {"instance_id": id, "biome_id": region})
		_close_modal()
		_schedule_refresh())
	add_child(picker)

func _assign(instance_id: String) -> void:
	var instance: Dictionary = ReptileSystem.get_owned_reptile_instances().get(instance_id, {})
	if instance.is_empty(): return
	var species := ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))
	var destination: String = species.get("biome_id", "green_meadow")
	_close_modal()
	var picker := preload("res://scripts/modern/ResidentPickerView.gd").new()
	picker.instance_id = instance_id
	picker.biome_id = destination
	picker.safe_insets = Vector4(safe.get_theme_constant("margin_left"), safe.get_theme_constant("margin_top"), safe.get_theme_constant("margin_right"), safe.get_theme_constant("margin_bottom"))
	picker.z_index = 50
	modal = picker
	picker.closed.connect(_close_modal)
	picker.toast_requested.connect(_toast)
	picker.home_requested.connect(func(region: String) -> void: biome = region; _navigate("home"); _choose_habitat())
	picker.assignment_completed.connect(func(id: String, region: String, result: Dictionary) -> void:
		_result(result)
		if str(result.get("previous_habitat_id", "")).is_empty():
			QuestSystem.notify_event("reptile_assigned", {"instance_id": id, "biome_id": region})
		_close_modal()
		_schedule_refresh())
	add_child(picker)

func _animal_detail(instance_id: String) -> void:
	var instance: Dictionary = ReptileSystem.get_owned_reptile_instances().get(instance_id, {})
	if instance.is_empty(): return
	_close_modal()
	var profile := preload("res://scripts/modern/AnimalProfileView.gd").new()
	profile.instance_id = instance_id
	profile.terrarium_path = _terrarium_path
	profile.black_key = _black_key
	var species: Dictionary = ReptileSystem.get_reptile(str(instance.get("reptile_id", "")))
	profile.biome_id = str(species.get("biome_id", biome))
	profile.selected_route = page
	profile.safe_insets = Vector4(safe.get_theme_constant("margin_left"), safe.get_theme_constant("margin_top"), safe.get_theme_constant("margin_right"), safe.get_theme_constant("margin_bottom"))
	profile.z_index = 50
	modal = profile
	profile.closed.connect(_close_modal)
	profile.route_requested.connect(_navigate)
	profile.shop_requested.connect(func(_resource: String): store_tab = "resources"; _navigate("shop"))
	profile.rename_requested.connect(func(value: String):
		if ReptileSystem.set_reptile_custom_name(instance_id, value):
			QuestSystem.notify_event("reptile_named", {"instance_id": instance_id})
			_toast(T.text("Name saved", "Imię zapisane"))
			profile.refresh()
			_schedule_refresh())
	profile.care_requested.connect(func(action: String):
		var result := ReptileSystem.perform_care_action(instance_id, action)
		_result(result)
		if result.get("success", false):
			QuestSystem.notify_event("care_action_success", {"action": action, "instance_id": instance_id})
		profile.refresh()
		_schedule_refresh())
	profile.assign_requested.connect(func(): _assign(instance_id))
	profile.move_requested.connect(func():
		var current: Dictionary = ReptileSystem.get_owned_reptile_instances().get(instance_id, {})
		_result(ReptileSystem.remove_reptile_from_habitat(str(current.get("habitat_id", ""))))
		profile.refresh()
		_schedule_refresh())
	profile.sell_requested.connect(func():
		_confirm(T.text("Sell this reptile?", "Sprzedać tego gada?"), T.text("It leaves your breeding collection. Discovered variants remain in your journal.", "Opuści Twoją hodowlę. Odkryta odmiana pozostanie w atlasie."), func(): _result(ReptileSystem.sell_reptile_instance(instance_id)); _schedule_refresh()))
	profile.upgrade_requested.connect(func():
		var current: Dictionary = ReptileSystem.get_owned_reptile_instances().get(instance_id, {})
		_result(ReptileSystem.start_habitat_upgrade(str(current.get("habitat_id", ""))))
		profile.refresh()
		_schedule_refresh())
	add_child(profile)

func _collection() -> void:
	body.add_child(T.title(T.text("Your living collection", "Twoja żywa kolekcja"), T.text("Every discovery begins a new possibility.", "Każde odkrycie otwiera nowe możliwości.")))
	var tabs := T.row()
	body.add_child(tabs)
	tabs.add_child(T.button(T.text("My reptiles", "Moje gady"), func(): collection_tab = "owned"; _render(), "primary" if collection_tab == "owned" else "secondary"))
	tabs.add_child(T.button(T.text("Field journal", "Atlas odmian"), func(): collection_tab = "journal"; _render(), "primary" if collection_tab == "journal" else "secondary"))
	if collection_tab == "owned":
		var animals := ReptileSystem.get_owned_reptile_instances()
		if animals.is_empty():
			body.add_child(T.texture("res://assets/art/modern/nursery_egg.png", Vector2(0, 260)))
			body.add_child(T.label(T.text("Your first companion is waiting.", "Twój pierwszy podopieczny już czeka."), 30))
			body.add_child(T.button(T.text("Meet your first reptile", "Poznaj pierwszego gada"), func(): _navigate("shop")))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		body.add_child(grid)
		for instance in animals.values():
			var box := _box(grid)
			box.add_child(T.texture(ReptileSystem.get_owned_animal_image_path(instance), Vector2(0, 210)))
			box.add_child(T.label(_animal_name(instance), 26))
			box.add_child(T.label(T.rarity_name(str(instance.get("rarity", "common"))), 21, T.rarity_color(str(instance.get("rarity", "common")))))
			box.add_child(T.label(T.text("Female", "Samica") if instance.get("sex") == "female" else T.text("Male", "Samiec"), 20, T.MUTED))
			box.add_child(T.button(T.text("Meet & care", "Poznaj i zadbaj"), func(): _animal_detail(str(instance["instance_id"])), "secondary"))
	else:
		for species in ReptileSystem.reptiles:
			var sid: String = species.get("id", "")
			var box := _box(body)
			box.add_child(T.label(T.localized(species.get("name_key", "")), 29))
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 14)
			grid.add_theme_constant_override("v_separation", 14)
			box.add_child(grid)
			var count := 0
			for rarity in ["common", "rare", "ultra_rare", "exceptional"]:
				var variant: Dictionary = ReptileSystem.get_variant_for_reptile_rarity(sid, rarity)
				var found := ReptileSystem.is_variant_discovered(str(variant.get("id", "")))
				if found: count += 1
				var cell := T.column(4)
				grid.add_child(cell)
				var portrait := T.texture(str(variant.get("portrait_path", species.get("portrait_path", ""))), Vector2(0, 138))
				if not found: portrait.modulate = Color(0.08, 0.15, 0.12, 0.65)
				cell.add_child(portrait)
				cell.add_child(T.label(T.rarity_name(rarity), 22, T.rarity_color(rarity)))
				cell.add_child(T.label(T.text("Discovered", "Odkryto") if found else "?", 19, T.MUTED))
			box.add_child(T.progress(count * 25.0, T.GOLD))
			box.add_child(T.button(T.text("Breed for your next discovery · %d/4", "Wyhoduj kolejną odmianę · %d/4") % count, func(): _navigate("nursery"), "secondary"))

func _world() -> void:
	body.add_child(T.title(T.text("A world to grow into", "Świat pełen możliwości"), T.text("More habitats. More remarkable reptiles.", "Nowe siedliska. Nowe niezwykłe gady.")))
	for definition in biome_definitions:
		var id: String = definition.get("id", "")
		if id == "incubator": continue
		var box := _box(body)
		var art := T.texture(str(definition.get("background_path", "")), Vector2(0, 225))
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.clip_contents = true
		box.add_child(art)
		box.add_child(T.label(_biome_name(id), 32))
		var accessible := _is_unlocked(id)
		box.add_child(T.label(T.text("%d habitats · %d species", "%d siedlisk · %d gatunków") % [definition.get("habitat_slots", 0), ReptileSystem.get_available_reptiles(id).size()], 22, T.MUTED))
		var button := T.button(T.text("Visit sanctuary", "Odwiedź hodowlę") if accessible else T.text("Opens at level %d", "Dostępne od poziomu %d") % _unlock_level(id), func(): biome = id; _navigate("home"), "primary" if accessible else "secondary")
		button.disabled = not accessible
		box.add_child(button)

func _shop() -> void:
	body.add_child(T.title(T.text("Welcome someone new", "Poznaj kogoś nowego"), T.text("Find the parents of your next discovery.", "Znajdź rodziców kolejnego odkrycia.")))
	var tabs := T.row()
	body.add_child(tabs)
	tabs.add_child(T.button(T.text("Reptiles", "Gady"), func(): store_tab = "animals"; _render(), "primary" if store_tab == "animals" else "secondary"))
	tabs.add_child(T.button(T.text("Supplies", "Zapasy"), func(): store_tab = "resources"; _render(), "primary" if store_tab == "resources" else "secondary"))
	if store_tab == "resources":
		for resource in ["food", "water"]:
			var box := _box(body)
			var config := ReptileSystem.get_shop_config(resource)
			box.add_child(T.label(T.text("Food", "Pokarm") if resource == "food" else T.text("Water", "Woda"), 30))
			box.add_child(T.button(T.text("Buy %d · %s R$", "Kup %d · %s R$") % [config.get("amount", 20), T.amount(config.get("price", 500))], func(): _result(ReptileSystem.buy_resource(biome, resource)); _schedule_refresh()))
			box.add_child(T.button(T.text("Watch an ad · refill", "Obejrzyj reklamę · uzupełnij"), func(): _resource_ad(resource), "secondary"))
		var box := _box(body)
		box.add_child(T.label(T.text("An optional little boost", "Dodatkowe wsparcie"), 29))
		box.add_child(T.label(T.text("Ads are always your choice. Your reptiles can grow without them.", "Reklamy są dobrowolne. Twoja hodowla może rozwijać się bez nich."), 23, T.MUTED))
		box.add_child(T.button(T.text("Watch an ad · %s R$", "Obejrzyj reklamę · %s R$") % T.amount(ResourceAdService.get_money_reward_amount()), func(): _resource_ad("money"), "secondary"))
		return
	body.add_child(T.label(_biome_name(biome), 25, T.ACCENT))
	for species in ReptileSystem.get_available_reptiles(biome):
		var sid: String = species.get("id", "")
		var box := _box(body)
		var row := T.row(20)
		box.add_child(row)
		row.add_child(T.texture(str(species.get("portrait_path", "")), Vector2(180, 200)))
		var info := T.column(8)
		row.add_child(info)
		info.add_child(T.label(T.localized(str(species.get("name_key", ""))), 30))
		info.add_child(T.label(_habitat_name(str(species.get("preferred_habitat_type", "grass"))), 22, T.MUTED))
		info.add_child(T.label(T.text("Base income · %.1f R$/min", "Dochód bazowy · %.1f R$/min") % ReptileSystem.get_base_reptile_income(sid), 21, T.GOLD))
		var picks := T.row()
		box.add_child(picks)
		var sex := OptionButton.new()
		sex.add_item(T.text("Female", "Samica"))
		sex.add_item(T.text("Male", "Samiec"))
		sex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sex.custom_minimum_size.y = 76
		picks.add_child(sex)
		var price := ReptileSystem.get_shop_purchase_price(sid, "common")
		var buy := T.button(T.text("Adopt · %s R$", "Przygarnij · %s R$") % T.amount(price), func():
			var result := ReptileSystem.purchase_reptile_from_shop(sid, "common", "female" if sex.selected == 0 else "male")
			_result(result)
			if result.get("success", false): QuestSystem.notify_event("reptile_purchased", {"reptile_id": sid, "rarity": "common", "price": price})
			_schedule_refresh()
			if result.get("success", false): _navigate("collection"))
		buy.disabled = price < 0 or not EconomySystem.can_afford("repticash", price)
		picks.add_child(buy)
		var rare_price := ReptileSystem.get_shop_purchase_price(sid, "rare")
		var rare := T.button(T.text("Rare parent · %s R$", "Rzadki rodzic · %s R$") % T.amount(rare_price), func():
			var result := ReptileSystem.purchase_reptile_from_shop(sid, "rare", "female" if sex.selected == 0 else "male")
			_result(result)
			if result.get("success", false): QuestSystem.notify_event("reptile_purchased", {"reptile_id": sid, "rarity": "rare", "price": rare_price})
			_schedule_refresh(), "secondary")
		rare.disabled = rare_price < 0 or not EconomySystem.can_afford("repticash", rare_price)
		box.add_child(rare)

func _resource_ad(resource: String) -> void:
	_toast(T.text("Preparing your optional ad…", "Przygotowanie dobrowolnej reklamy…"))
	ResourceAdService.request_resource_reward(resource, biome, func(_result_value: Dictionary): _toast(T.text("Reward received", "Nagroda odebrana")); _schedule_refresh(), func(key: String): _toast(T.localized(key)))

func _tasks() -> void:
	body.add_child(T.title(T.text("Little goals, real progress", "Małe cele, prawdziwy postęp")))
	_onboarding_card()
	for quest in QuestSystem.get_active_quests(8): _goal_card(quest, false)
	body.add_child(T.title(T.text("Collection milestones", "Osiągnięcia kolekcji")))
	for achievement in AchievementSystem.get_achievement_states():
		if not achievement.get("claimed", false): _goal_card(achievement, true)

func _goal_card(goal: Dictionary, achievement: bool) -> void:
	var box := _box(body)
	box.add_child(T.label(T.localized(str(goal.get("title_key", goal.get("name_key", "")))), 27))
	box.add_child(T.label(T.localized(str(goal.get("description_key", ""))), 22, T.MUTED))
	var current: float = goal.get("current", 0)
	var target: float = maxf(1, float(goal.get("target", 1)))
	box.add_child(T.progress(current / target * 100))
	box.add_child(T.label("%d / %d" % [mini(int(current), int(target)), int(target)], 20, T.MUTED))
	if goal.get("claimable", false):
		box.add_child(T.button(T.text("Collect reward", "Odbierz nagrodę"), func():
			var result: Dictionary
			if achievement: result = AchievementSystem.claim_achievement(str(goal["id"]))
			else: result = QuestSystem.claim_quest_reward(str(goal["id"]))
			_result(result)
			_schedule_refresh()))

func _team() -> void:
	body.add_child(T.title(T.text("Your keepers", "Twoi opiekunowie"), _biome_name(biome)))
	body.add_child(T.label(T.text("Let your team handle routine care while you plan the next pairing.", "Niech zespół zajmie się codzienną opieką, gdy Ty planujesz kolejną parę."), 24, T.MUTED))
	for worker in WorkerSystem.get_worker_definitions():
		var id: String = worker.get("id", "")
		var box := _box(body)
		box.add_child(T.label(T.localized(worker.get("name_key", "")), 28))
		box.add_child(T.label(T.localized(worker.get("description_key", "")), 23, T.MUTED))
		var cost := WorkerSystem.get_next_cost(id, biome)
		box.add_child(T.label(T.text("Level %d", "Poziom %d") % WorkerSystem.get_worker_level(id, biome), 22, T.ACCENT))
		var buy := T.button(T.text("Improve · %s R$", "Rozwiń · %s R$") % T.amount(cost) if cost >= 0 else T.text("Fully trained", "Pełne wyszkolenie"), func(): _result(WorkerSystem.buy_or_upgrade_worker(id, biome)); _schedule_refresh())
		buy.disabled = cost < 0 or not EconomySystem.can_afford("repticash", cost)
		box.add_child(buy)

func _upgrades() -> void:
	body.add_child(T.title(T.text("Room to flourish", "Miejsce na rozwój"), _biome_name(biome)))
	for upgrade in UpgradeSystem.get_upgrade_definitions():
		var id: String = upgrade.get("id", "")
		var box := _box(body)
		box.add_child(T.label(T.localized(upgrade.get("name_key", "")), 28))
		box.add_child(T.label(T.localized(upgrade.get("description_key", "")), 23, T.MUTED))
		var cost := UpgradeSystem.get_upgrade_cost(id, biome)
		box.add_child(T.label(T.text("Level %d", "Poziom %d") % UpgradeSystem.get_upgrade_level(id, biome), 22, T.ACCENT))
		var button := T.button(T.text("Upgrade · %s R$", "Ulepsz · %s R$") % T.amount(cost) if cost >= 0 else T.text("Complete", "Ukończone"), func(): _result(UpgradeSystem.buy_upgrade(id, biome)); _schedule_refresh())
		button.disabled = cost < 0 or not EconomySystem.can_afford("repticash", cost)
		box.add_child(button)

func _settings() -> void:
	var box := _open_modal(T.text("Make yourself at home", "Rozgość się"))
	var languages := T.row()
	box.add_child(languages)
	languages.add_child(T.button("English", func(): GameState.set_language("en"); SaveSystem.save_game(), "secondary"))
	languages.add_child(T.button("Polski", func(): GameState.set_language("pl"); SaveSystem.save_game(), "secondary"))
	for setting in [["music_enabled", T.text("Music", "Muzyka")], ["sfx_enabled", T.text("Sounds", "Dźwięki")], ["vibration_enabled", T.text("Vibration", "Wibracje")]]:
		var toggle := CheckButton.new()
		T.Controls.apply(toggle, "wood")
		toggle.text = setting[1]
		toggle.name = str(setting[0])
		toggle.custom_minimum_size.y = 80
		toggle.button_pressed = GameState.get_setting(setting[0], true)
		toggle.toggled.connect(func(value: bool): GameState.set_setting(setting[0], value); SaveSystem.save_game())
		box.add_child(toggle)
	box.add_child(_paper_label(T.text("Your progress is saved on this device. Uninstalling or clearing app data removes it.", "Postęp jest zapisywany na tym urządzeniu. Odinstalowanie lub wyczyszczenie danych aplikacji usuwa go."), 22))
	box.add_child(T.button(T.text("Save now", "Zapisz teraz"), func(): _toast(T.text("Progress saved", "Postęp zapisany") if SaveSystem.save_game() else T.text("Could not save progress", "Nie udało się zapisać postępu")), "secondary"))

func _open_modal(title: String) -> VBoxContainer:
	_close_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.z_index = 50
	add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.05, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 26)
	margin.add_theme_constant_override("margin_top", 42 + safe.get_theme_constant("margin_top"))
	margin.add_theme_constant_override("margin_bottom", 32 + safe.get_theme_constant("margin_bottom"))
	modal.add_child(margin)
	var panel := PanelContainer.new()
	panel.name = "CommonModalPanel"
	panel.add_theme_stylebox_override("panel", T.Controls.parchment())
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(panel)
	var layout := T.column(16)
	panel.add_child(layout)
	var heading := T.row()
	layout.add_child(heading)
	heading.add_child(_paper_label(title, 31))
	var close := T.button("×", _close_modal, "secondary")
	close.custom_minimum_size.x = 76
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.tooltip_text = T.text("Close", "Zamknij")
	heading.add_child(close)
	var scroller := preload("res://scripts/modern/TouchScrollContainer.gd").new()
	scroller.size_flags_vertical = Control.SIZE_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroller)
	var box := T.column(16)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(box)
	var fit: Callable = func() -> void:
		if not is_instance_valid(box) or not is_instance_valid(panel): return
		var available: float = get_viewport_rect().size.y - 74 - safe.get_theme_constant("margin_top") - safe.get_theme_constant("margin_bottom") - heading.get_combined_minimum_size().y - 104
		scroller.custom_minimum_size.y = minf(maxf(120, box.get_combined_minimum_size().y), maxf(120, available))
	box.minimum_size_changed.connect(func() -> void: fit.call_deferred())
	modal.resized.connect(func() -> void: fit.call_deferred())
	fit.call_deferred()
	return box

func _paper_label(copy: String, font_size: int = 24) -> Label:
	var label := T.label(copy, font_size, Color("382006"))
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	return label

func _close_modal() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null

func _confirm(title: String, message: String, confirmed: Callable) -> void:
	var box := _open_modal(title)
	box.add_child(_paper_label(message, 26))
	box.add_child(T.button(T.text("Confirm", "Potwierdź"), func(): _close_modal(); confirmed.call()))
	box.add_child(T.button(T.text("Keep playing", "Wróć do gry"), _close_modal, "secondary"))

func _toast(message: String) -> void:
	if message.is_empty(): return
	if is_instance_valid(toast_panel): toast_panel.queue_free()
	toast_panel = T.card()
	toast_panel.z_index = 100
	toast_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast_panel.offset_left = 32
	toast_panel.offset_right = -32
	toast_panel.offset_top = -240
	toast_panel.offset_bottom = -140
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label = T.label(message, 24)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)
	add_child(toast_panel)
	toast_serial += 1
	var serial := toast_serial
	get_tree().create_timer(3.2).timeout.connect(func():
		if serial == toast_serial and is_instance_valid(toast_panel): toast_panel.queue_free())

func _result(result: Dictionary) -> void:
	var ok: bool = result.get("success", false)
	var key: String = result.get("message_key", "")
	var message := T.localized(key) if not key.is_empty() else (T.text("Done. Your progress is saved.", "Gotowe. Postęp zapisany.") if ok else T.text("This action isn't available yet.", "Ta akcja nie jest jeszcze dostępna."))
	for token in ["xp", "money", "amount", "price", "level", "seconds"]:
		message = message.replace("{" + token + "}", str(result.get(token, result.get("xp_reward", 0) if token == "xp" else 0)))
	_toast(message)
	_update_header()

func _welcome_back() -> void:
	if EconomySystem.has_pending_offline_income() and page == "home": _schedule_refresh()

func _owned_habitats() -> Array:
	var result: Array = []
	for h in GameState.get_value("habitats", {}).values():
		if h.get("biome_id") == biome and h.get("purchased", false): result.append(h)
	result.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("slot_index", 0)) < int(b.get("slot_index", 0)))
	return result

func _biome_config(id: String) -> Dictionary:
	for b in biome_definitions:
		if b.get("id") == id: return b
	return {}

func _unlock_level(id: String) -> int:
	return int(_biome_config(id).get("unlock_requirements", {}).get("level", 1))

func _is_unlocked(id: String) -> bool:
	return int(GameState.get_value("player_level", 1)) >= _unlock_level(id) or id in GameState.get_value("unlocked_biomes", [])

func _biome_name(id: String) -> String:
	return T.localized(str(_biome_config(id).get("name_key", "biome." + id + ".name")))

func _habitat_name(id: String) -> String:
	return T.localized(ReptileSystem.get_habitat_type_label_key(id))

func _animal_name(instance: Dictionary) -> String:
	var custom: String = instance.get("custom_name", "")
	if not custom.is_empty(): return custom
	return T.localized(str(ReptileSystem.get_reptile(str(instance.get("reptile_id", ""))).get("name_key", "")))

func _condition(instance: Dictionary) -> float:
	return (float(instance.get("hunger", 100)) + float(instance.get("hydration", 100)) + float(instance.get("happiness", 100)) + float(instance.get("cleanliness", 100))) / 4.0
