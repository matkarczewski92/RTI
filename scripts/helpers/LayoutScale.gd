extends RefCounted

const REFERENCE_SIZE := Vector2(1080.0, 1920.0)


static func fit_scale(viewport_size: Vector2, reference_size: Vector2 = REFERENCE_SIZE) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return min(viewport_size.x / reference_size.x, viewport_size.y / reference_size.y)


static func fit_origin(viewport_size: Vector2, scale: float, reference_size: Vector2 = REFERENCE_SIZE) -> Vector2:
	return (viewport_size - reference_size * scale) * 0.5


static func viewport_scale(viewport_size: Vector2, reference_size: Vector2 = REFERENCE_SIZE) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return min(viewport_size.x / reference_size.x, viewport_size.y / reference_size.y)


static func cover_scale(viewport_size: Vector2, reference_size: Vector2 = REFERENCE_SIZE) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return max(viewport_size.x / reference_size.x, viewport_size.y / reference_size.y)


static func cover_origin(viewport_size: Vector2, scale: float, reference_size: Vector2 = REFERENCE_SIZE) -> Vector2:
	return (viewport_size - reference_size * scale) * 0.5
