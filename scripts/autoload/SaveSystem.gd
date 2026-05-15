extends Node

signal save_loaded
signal save_saved
signal save_failed(reason: String)
signal save_corrupted(backup_path: String)
signal save_migrated(from_version: int, to_version: int)

const SAVE_PATH := "user://save_game.json"
const TEMP_SAVE_PATH := "user://save_game.json.tmp"
const BACKUP_SAVE_PATH := "user://save_backup.json"
const CURRENT_SAVE_VERSION := GameState.CURRENT_SAVE_VERSION


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
		push_warning("Could not serialize save data.")
		return false

	var file: FileAccess = FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_failed.emit("Could not open temporary save file for writing.")
		push_warning("Could not open temporary save file for writing.")
		return false

	file.store_string(json_text)
	file.flush()
	file.close()

	var user_dir: DirAccess = DirAccess.open("user://")
	if user_dir == null:
		save_failed.emit("Could not open user save directory.")
		push_warning("Could not open user save directory.")
		return false

	if FileAccess.file_exists(SAVE_PATH):
		var backup_error := user_dir.copy("save_game.json", "save_backup.json")
		if backup_error != OK:
			push_warning("Could not update save backup: " + str(backup_error))

	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := user_dir.remove("save_game.json")
		if remove_error != OK:
			save_failed.emit("Could not replace old save file.")
			push_warning("Could not replace old save file: " + str(remove_error))
			return false

	var rename_error := user_dir.rename("save_game.json.tmp", "save_game.json")
	if rename_error != OK:
		save_failed.emit("Could not move temporary save into place.")
		push_warning("Could not move temporary save into place: " + str(rename_error))
		return false

	save_saved.emit()
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.reset_to_default()
		save_game()
		save_loaded.emit()
		return true

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		GameState.reset_to_default()
		save_game()
		save_failed.emit("Could not open save file for reading.")
		push_warning("Could not open save file for reading. Started a new game state.")
		save_loaded.emit()
		return false

	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		var backup_path: String = _backup_corrupted_save(raw_text)
		GameState.reset_to_default()
		save_game()
		save_corrupted.emit(backup_path)
		save_failed.emit("Save file was corrupted. Started a new game state.")
		push_warning("Save file was corrupted. Backup: " + backup_path)
		save_loaded.emit()
		return false

	var loaded: Dictionary = parsed as Dictionary
	var old_version: int = int(loaded.get("save_version", 0))
	GameState.apply_loaded_state(loaded)
	var new_version: int = int(GameState.state.get("save_version", CURRENT_SAVE_VERSION))
	if old_version < new_version:
		save_migrated.emit(old_version, new_version)
		push_warning("Save migrated from version " + str(old_version) + " to " + str(new_version) + ".")
		save_game()

	save_loaded.emit()
	return true


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
