extends Control
## Two quiet, independent heart motions indicate an occupied breeding room.
const ART := preload("res://assets/prototype/art/icons/actions/care.png")
var _hearts: Array[TextureRect] = []
var _elapsed := 0.0

func _ready() -> void:
	name = "BreedingHearts"
	custom_minimum_size = Vector2(86, 104)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(2):
		var heart := TextureRect.new()
		heart.name = "Heart" + str(index + 1)
		heart.texture = ART
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size = Vector2(46, 46)
		heart.pivot_offset = heart.size * 0.5
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(heart)
		_hearts.append(heart)
	_process(0.0)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	for index in range(_hearts.size()):
		var phase := _elapsed * 2.3 + index * 1.8
		_hearts[index].position = Vector2(3 + index * 34, size.y * 0.5 - 28 + index * 15 + sin(phase) * 5)
		_hearts[index].scale = Vector2.ONE * (1.0 + sin(phase) * 0.07)
