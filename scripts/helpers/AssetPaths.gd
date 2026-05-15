extends RefCounted

static var _resolved_cache: Dictionary = {}
static var _warning_cache: Dictionary = {}


static func normalize_texture_path(path: String) -> String:
	var normalized: String = path.strip_edges()
	if normalized.is_empty():
		return ""

	if normalized.begins_with("res://") or normalized.begins_with("user://"):
		normalized = normalized
	else:
		normalized = "res://" + normalized.trim_prefix("/")

	if normalized.ends_with(".png.png"):
		push_warning("Invalid texture path uses duplicated extension (.png.png): " + normalized)
		normalized = normalized.substr(0, normalized.length() - 4)

	return normalized


static func _path_has_source_file(resource_path: String) -> bool:
	if resource_path.is_empty():
		return false
	return FileAccess.file_exists(ProjectSettings.globalize_path(resource_path))


static func _can_load_texture(resource_path: String) -> bool:
	if resource_path.is_empty():
		return false
	if ResourceLoader.exists(resource_path):
		return true
	if not _path_has_source_file(resource_path):
		return false
	var resource: Resource = ResourceLoader.load(resource_path)
	return resource is Texture2D


static func find_texture_path(expected_path: String) -> String:
	var normalized_path: String = normalize_texture_path(expected_path)
	if normalized_path.is_empty():
		return ""

	if _resolved_cache.has(normalized_path):
		return _resolved_cache[normalized_path]
	if _warning_cache.has(normalized_path):
		return ""

	var candidate_paths: Array[String] = [normalized_path]
	if normalized_path.get_extension().is_empty():
		candidate_paths.append(normalized_path + ".png")

	for candidate_path in candidate_paths:
		if _can_load_texture(candidate_path):
			_resolved_cache[normalized_path] = candidate_path
			return candidate_path

	if not _warning_cache.has(normalized_path):
		push_warning("Missing texture asset at exact path: " + normalized_path)
		_warning_cache[normalized_path] = true
	return ""


static func load_texture(expected_path: String) -> Texture2D:
	if expected_path.is_empty():
		return null

	var resolved_path: String = find_texture_path(expected_path)
	if resolved_path.is_empty():
		return null

	var resource: Resource = ResourceLoader.load(resolved_path)
	if resource is Texture2D:
		return resource as Texture2D

	if not _warning_cache.has(expected_path):
		push_warning("Resource is not a Texture2D: " + resolved_path)
		_warning_cache[expected_path] = true
	return null
