extends Node

signal currency_changed(currency_id: String, amount: Variant)

const ECONOMY_PATH := "res://data/economy.json"

var economy_data: Dictionary = {}


func _ready() -> void:
	load_economy_data()


func load_economy_data() -> bool:
	var file: FileAccess = FileAccess.open(ECONOMY_PATH, FileAccess.READ)
	if file == null:
		economy_data = {}
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		economy_data = {}
		return false

	economy_data = parsed as Dictionary
	return true


func get_currency(currency_id: String = "repticash") -> Variant:
	return GameState.get_value(currency_id, 0)


func add_currency(currency_id: String, amount: float) -> void:
	if amount <= 0:
		return

	var new_amount: Variant = float(get_currency(currency_id)) + amount if currency_id == "xp" else int(get_currency(currency_id)) + int(amount)
	GameState.set_value(currency_id, new_amount)
	currency_changed.emit(currency_id, new_amount)


func can_afford(currency_id: String, amount: int) -> bool:
	return float(get_currency(currency_id)) >= float(amount)


func spend_currency(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true

	if not can_afford(currency_id, amount):
		return false

	var new_amount: Variant = int(get_currency(currency_id)) - amount
	GameState.set_value(currency_id, new_amount)
	currency_changed.emit(currency_id, new_amount)
	return true


func get_purchased_habitat_count(biome_id: String) -> int:
	var habitats_value: Variant = GameState.get_value("habitats", {})
	if typeof(habitats_value) != TYPE_DICTIONARY:
		return 0

	var habitats: Dictionary = habitats_value as Dictionary
	var count: int = 0
	for habitat_key in habitats.keys():
		var habitat_value: Variant = habitats.get(habitat_key)
		if typeof(habitat_value) != TYPE_DICTIONARY:
			continue

		var habitat: Dictionary = habitat_value as Dictionary
		if str(habitat.get("biome_id", "")) == biome_id and bool(habitat.get("purchased", false)):
			count += 1

	return count


func get_next_habitat_price(biome_id: String, total_habitat_count: int = -1) -> int:
	var purchased_count: int = get_purchased_habitat_count(biome_id)
	if total_habitat_count > -1 and purchased_count >= total_habitat_count:
		return -1

	var price_sequence: Array = _get_habitat_price_sequence(biome_id)
	if price_sequence.is_empty():
		return _get_fallback_habitat_price(purchased_count)

	var price_index: int = int(min(purchased_count, price_sequence.size() - 1))
	return int(price_sequence[price_index])


func _get_habitat_price_sequence(biome_id: String) -> Array:
	var sequences_value: Variant = economy_data.get("habitat_purchase_prices", {})
	if typeof(sequences_value) != TYPE_DICTIONARY:
		return []

	var sequences: Dictionary = sequences_value as Dictionary
	var sequence_value: Variant = sequences.get(biome_id, [])
	if typeof(sequence_value) != TYPE_ARRAY:
		return []

	return sequence_value as Array


func _get_fallback_habitat_price(purchased_count: int) -> int:
	return 100 + (int(max(purchased_count, 0)) * 50)
