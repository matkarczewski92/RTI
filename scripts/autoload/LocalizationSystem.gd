extends Node

const TRANSLATIONS_PATH := "res://data/translations.json"
const DEFAULT_LANGUAGE := "pl"
const FALLBACK_LANGUAGE := "en"

var translations: Dictionary = {}
var missing_key_warnings: Dictionary = {}


func _ready() -> void:
	load_translations()


func load_translations() -> bool:
	var file: FileAccess = FileAccess.open(TRANSLATIONS_PATH, FileAccess.READ)
	if file == null:
		translations = {}
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		translations = {}
		return false

	translations = parsed as Dictionary
	return true


func tr_key(key: String, language: String = "") -> String:
	var selected_language := language
	if selected_language.is_empty():
		selected_language = GameState.get_language()

	var entry: Variant = translations.get(key)
	if typeof(entry) == TYPE_DICTIONARY:
		var entry_dict: Dictionary = entry as Dictionary
		if entry_dict.has(selected_language):
			return str(entry_dict.get(selected_language))
		if entry_dict.has(FALLBACK_LANGUAGE):
			_warn_missing_once(key + ":" + selected_language, "Missing translation for '%s' in '%s'. Using '%s' fallback." % [key, selected_language, FALLBACK_LANGUAGE])
			return str(entry_dict.get(FALLBACK_LANGUAGE))
		if entry_dict.has(DEFAULT_LANGUAGE):
			_warn_missing_once(key + ":" + selected_language, "Missing translation for '%s' in '%s'. Using '%s' fallback." % [key, selected_language, DEFAULT_LANGUAGE])
			return str(entry_dict.get(DEFAULT_LANGUAGE))

	_warn_missing_once(key, "Missing translation key: " + key)
	return key


func get_text(key: String, language: String = "") -> String:
	return tr_key(key, language)


func get_language() -> String:
	return GameState.get_language()


func set_language(language: String) -> void:
	var previous_language := GameState.get_language()
	GameState.set_language(language)
	if GameState.get_language() == previous_language:
		return
	if has_node("/root/SaveSystem") and SaveSystem.has_method("save_game"):
		SaveSystem.save_game()


func refresh_localized_ui() -> void:
	GameState.language_changed.emit(GameState.get_language())


func _warn_missing_once(warning_id: String, message: String) -> void:
	if missing_key_warnings.has(warning_id):
		return
	missing_key_warnings[warning_id] = true
	push_warning(message)
