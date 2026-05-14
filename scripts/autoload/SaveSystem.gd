extends Node

signal save_loaded
signal save_saved
signal save_failed(reason: String)

const SAVE_PATH := "user://save_game.json"


func _ready() -> void:
	load_game()


func save_game() -> bool:
	GameState.state["save_version"] = GameState.SAVE_VERSION
	GameState.state["last_saved_at"] = Time.get_unix_time_from_system()

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_failed.emit("Could not open save file for writing.")
		return false

	file.store_string(JSON.stringify(GameState.state, "\t"))
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
		save_failed.emit("Could not open save file for reading.")
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		GameState.reset_to_default()
		save_failed.emit("Save file was invalid. Started a new game state.")
		return false

	GameState.apply_loaded_state(parsed as Dictionary)
	save_loaded.emit()
	return true


func reset_game() -> void:
	GameState.reset_to_default()
	save_game()
