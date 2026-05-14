extends Label

var speed: float = 50.0
var life: float = 2.0

func setup(text_val: String) -> void:
	text = text_val

func _process(delta: float) -> void:
	position.y -= speed * delta
	life -= delta
	modulate.a = clamp(life / 2.0, 0.0, 1.0)
	if life <= 0:
		queue_free()