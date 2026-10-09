extends CanvasLayer
## A single, asynchronous Play update check per launch. Flexible downloads never
## interrupt gameplay; installation always requires consent and a successful save.

const T := preload("res://scripts/modern/SanctuaryTheme.gd")
var state := "unavailable"
var available_version := 0
var _bridge: Object
var _startup_checked := false
var _update_requested := false
var _download_prompt_shown := false
var _error_kind := ""
var _dialog: Control
var _title: Label
var _description: Label
var _error: Label
var _restart: Button
var _later: Button

func _ready() -> void:
	layer = 150
	visible = false
	_build_dialog()
	GameState.language_changed.connect(func(_language: String): _localize())
	call_deferred("check_at_startup")

func _find_bridge() -> Object:
	if OS.has_feature("android") and Engine.has_singleton("PlayUpdate"):
		return Engine.get_singleton("PlayUpdate")
	return null

func _has_bridge_method(method: String) -> bool:
	if not is_instance_valid(_bridge): return false
	return _bridge.has_method(method) or (
		_bridge.has_method("has_java_method")
		and bool(_bridge.call("has_java_method", StringName(method))))

func check_at_startup() -> void:
	if _startup_checked: return
	_startup_checked = true
	_bridge = _find_bridge()
	if not _has_bridge_method("check_for_update") or not _has_bridge_method("start_update") or not _has_bridge_method("complete_update"):
		state = "unavailable"
		return
	var callbacks := {
		"update_available": _on_update_available,
		"update_not_available": _on_update_not_available,
		"update_downloaded": _on_update_downloaded,
		"update_started": _on_update_started,
		"update_cancelled": _on_update_cancelled,
		"update_error": _on_update_error,
	}
	for signal_name: String in callbacks:
		if not _bridge.has_signal(signal_name):
			state = "unavailable"
			return
	for signal_name: String in callbacks:
		_bridge.connect(signal_name, callbacks[signal_name], CONNECT_DEFERRED)
	state = "checking"
	_bridge.call("check_for_update")

func _on_update_available(version_code: int) -> void:
	if _update_requested or state in ["downloaded", "installing"]: return
	available_version = version_code
	state = "available"
	start_update()

func start_update() -> bool:
	if _update_requested or state != "available" or not _has_bridge_method("start_update"):
		return false
	_update_requested = true
	state = "downloading"
	_bridge.call("start_update")
	return true

func _on_update_not_available() -> void:
	if state in ["checking", "available", "downloading"]:
		state = "unavailable"

func _on_update_started() -> void:
	if state not in ["downloaded", "installing"]: state = "downloading"

func _on_update_cancelled() -> void:
	if state == "installing":
		_on_update_error(-1)
	elif state != "downloaded":
		state = "unavailable"

func _on_update_downloaded() -> void:
	if state == "installing": return
	state = "downloaded"
	if _download_prompt_shown: return
	_download_prompt_shown = true
	_error_kind = ""
	_localize()
	visible = true
	_restart.grab_focus()

func _save_progress() -> bool:
	return SaveSystem.save_game()

func finish_update() -> bool:
	if state != "downloaded" or not _has_bridge_method("complete_update"):
		return false
	if not _save_progress():
		_error_kind = "save"
		_localize()
		return false
	state = "installing"
	_restart.disabled = true
	_later.disabled = true
	_error_kind = ""
	_localize()
	_bridge.call("complete_update")
	return true

func _on_update_error(_code: int) -> void:
	if state == "installing":
		state = "downloaded"
		_restart.disabled = false
		_later.disabled = false
		_error_kind = "install"
		_localize()
	else:
		# No network, no Play ownership or an unavailable store must not block play.
		if state != "downloaded": state = "error"

func dismiss_prompt() -> void:
	if state != "installing": visible = false

func dismiss_overlay() -> bool:
	if not visible: return false
	dismiss_prompt()
	return true

func is_prompt_visible() -> bool:
	return visible

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		dismiss_prompt()
		get_viewport().set_input_as_handled()

func _build_dialog() -> void:
	_dialog = Control.new()
	_dialog.name = "AppUpdateDialog"
	_dialog.theme = T.make_theme()
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dialog)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.01, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.add_child(dim)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 48)
	_dialog.add_child(margins)
	var panel := T.card()
	panel.name = "UpdatePanel"
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margins.add_child(panel)
	var column := T.column(20)
	panel.add_child(column)
	column.add_child(T.texture("res://assets/prototype/art/ui/prototype/logo_reptile_tycoon_cutout_v2.png", Vector2(0, 160)))
	_title = T.label("", 38, T.GOLD)
	_title.name = "UpdateTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_description = T.label("", 28)
	_description.name = "UpdateDescription"
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_description)
	_error = T.label("", 25, T.DANGER)
	_error.name = "UpdateError"
	_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_error)
	_restart = T.button("", finish_update)
	_restart.name = "RestartUpdateButton"
	column.add_child(_restart)
	_later = T.button("", dismiss_prompt, "secondary")
	_later.name = "LaterUpdateButton"
	column.add_child(_later)
	_localize()

func _localize() -> void:
	_title.text = T.text("Update ready", "Aktualizacja gotowa")
	_description.text = T.text("The new version has been downloaded. Restart to install it; your progress will be saved first.", "Nowa wersja jest pobrana. Uruchom grę ponownie, aby ją zainstalować. Najpierw zapiszemy Twój postęp.")
	_restart.text = T.text("Installing…", "Instalowanie…") if state == "installing" else T.text("Save & restart", "Zapisz i uruchom ponownie")
	_later.text = T.text("Later", "Później")
	match _error_kind:
		"save": _error.text = T.text("Your progress could not be saved. Please try again.", "Nie udało się zapisać postępu. Spróbuj ponownie.")
		"install": _error.text = T.text("The update could not be installed. Try again or continue playing.", "Nie udało się zainstalować aktualizacji. Spróbuj ponownie lub graj dalej.")
		_: _error.text = ""
