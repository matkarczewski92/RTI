extends Node

signal save_loaded
signal save_saved
signal save_failed(reason: String)
signal save_corrupted(backup_path: String)
signal save_migrated(from_version: int, to_version: int)

const SAVE_PATH := "user://save_game.json"
const SAVE_BACKUP_PATH := "user://save_game_backup.json"
const SAVE_TEMP_PATH := "user://save_game.tmp"
const CURRENT_SAVE_VERSION := GameState.CURRENT_SAVE_VERSION
const ERROR_THROTTLE_SECONDS := 5.0

var last_save_error_message := ""
var last_save_error_time := -9999.0


func _ready() -> void:
	load_game()


func save_game() -> bool:
	GameState.state = GameState.normalize_save_data(GameState.state)
	GameState.state["save_version"] = CURRENT_SAVE_VERSION
	GameState.state["last_saved_at"] = Time.get_unix_time_from_system()
	GameState.state["owned_animals"] = GameState.state.get("owned_reptile_instances", {})

	var json_text: String = JSON.stringify(GameState.state, "\t")
	if json_text.is_empty():
		save_failed.emit("Could not serialize save data.")
		_push_save_error("SaveSystem: Could not serialize save data.")
		return false

	var temp_file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if temp_file == null:
		var open_error: Error = FileAccess.get_open_error()
		save_failed.emit("Could not open temporary save file for writing.")
		_push_save_error("SaveSystem: Failed to open temp save file: %s error=%s" % [SAVE_TEMP_PATH, open_error])
		return false

	temp_file.store_string(json_text)
	temp_file.flush()
	temp_file.close()

	if FileAccess.file_exists(SAVE_PATH):
		var backup_error: Error = DirAccess.copy_absolute(SAVE_PATH, SAVE_BACKUP_PATH)
		if backup_error != OK:
			_push_save_warning("SaveSystem: Could not update save backup: %s" % backup_error)

	var save_error: Error = DirAccess.copy_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	if save_error != OK:
		save_failed.emit("Could not write save file.")
		_push_save_error("SaveSystem: Failed to write save file: %s error=%s" % [SAVE_PATH, save_error])
		return false

	save_saved.emit()
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.reset_to_default()
		save_game()
		save_loaded.emit()
		return true

	var loaded: Dictionary = _load_save_dictionary(SAVE_PATH)
	if loaded.is_empty():
		loaded = _load_save_dictionary(SAVE_BACKUP_PATH)
		if loaded.is_empty():
			GameState.reset_to_default()
			save_game()
			save_loaded.emit()
			return true

	var old_version: int = int(loaded.get("save_version", 0))
	GameState.apply_loaded_state(loaded)
	var new_version: int = int(GameState.state.get("save_version", CURRENT_SAVE_VERSION))
	if old_version < new_version:
		save_migrated.emit(old_version, new_version)
		_push_save_warning("SaveSystem: Save migrated from version %s to %s." % [old_version, new_version])
		save_game()

	save_loaded.emit()
	return true


func _load_save_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		save_failed.emit("Could not open save file for reading.")
		_push_save_error("SaveSystem: Failed to open save file: %s error=%s" % [path, FileAccess.get_open_error()])
		return {}

	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		var corrupted_backup_path: String = _backup_corrupted_save(raw_text)
		save_corrupted.emit(corrupted_backup_path)
		save_failed.emit("Save file was corrupted.")
		_push_save_warning("SaveSystem: Save file was corrupted: %s backup=%s" % [path, corrupted_backup_path])
		return {}

	return parsed as Dictionary


func reset_game() -> bool:
	GameState.reset_to_default()
	return save_game()


func _backup_corrupted_save(raw_text: String) -> String:
	var timestamp: int = int(Time.get_unix_time_from_system())
	var backup_path: String = "user://save_corrupted_backup_" + str(timestamp) + ".json"
	var backup_file: FileAccess = FileAccess.open(backup_path, FileAccess.WRITE)
	if backup_file == null:
		push_warning("Could not create corrupted save backup.")
		return ""
	backup_file.store_string(raw_text)
	backup_file.flush()
	backup_file.close()
	return backup_path


func _push_save_error(message: String) -> void:
	if _should_print_save_message(message):
		push_error(message)


func _push_save_warning(message: String) -> void:
	if _should_print_save_message(message):
		push_warning(message)


func _should_print_save_message(message: String) -> bool:
	var now: float = Time.get_ticks_msec() / 1000.0
	if message == last_save_error_message and now - last_save_error_time < ERROR_THROTTLE_SECONDS:
		return false
	last_save_error_message = message
	last_save_error_time = now
	return true
