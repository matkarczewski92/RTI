extends Node

const TRANSLATIONS_PATH := "res://data/translations.json"

var translations: Dictionary = {}


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
		return str(entry.get(selected_language, entry.get("en", key)))

	return key


func set_language(language: String) -> void:
	GameState.set_language(language)
