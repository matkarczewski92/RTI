extends RefCounted

static var _resolved_cache: Dictionary = {}
static var _warning_cache: Dictionary = {}

static func find_texture_path(expected_path: String) -> String:
	if _resolved_cache.has(expected_path):
		return _resolved_cache[expected_path]
	if _warning_cache.has(expected_path):
		return ""

	var search_path: String = expected_path
	if search_path.get_extension() == "":
		search_path += ".png"

	if ResourceLoader.exists(search_path):
		_resolved_cache[expected_path] = search_path
		return search_path

	var directory_path: String = search_path.get_base_dir()
	var expected_file: String = search_path.get_file()
	var expected_stem: String = expected_file.get_basename()
	if expected_stem.ends_with(".png"):
		expected_stem = expected_stem.get_basename()

	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		if not _warning_cache.has(expected_path):
			push_warning("Missing asset directory: " + directory_path)
			_warning_cache[expected_path] = true
		return ""

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	var fallback_path: String = ""
	while not file_name.is_empty():
		if not directory.current_is_dir():
			var lower_name: String = file_name.to_lower()
			var target_stem: String = expected_stem.to_lower()
			if lower_name == target_stem + ".png" or lower_name == target_stem + ".png.png":
				fallback_path = directory_path.path_join(file_name)
				break
			elif lower_name.ends_with(".png") and lower_name.begins_with(target_stem):
				fallback_path = directory_path.path_join(file_name)
		file_name = directory.get_next()

	directory.list_dir_end()

	if not fallback_path.is_empty():
		if not _warning_cache.has(expected_path):
			push_warning("Asset not found at " + expected_path + ". Using fallback: " + fallback_path)
			_warning_cache[expected_path] = true
		_resolved_cache[expected_path] = fallback_path
		return fallback_path

	if not _warning_cache.has(expected_path):
		push_warning("Missing asset: " + expected_path + ". Keeping placeholder UI.")
		_warning_cache[expected_path] = true
	return ""


static func load_texture(expected_path: String) -> Texture2D:
	if expected_path.is_empty():
		return null

	var resolved_path: String = find_texture_path(expected_path)
	if resolved_path.is_empty():
		return null

	return ResourceLoader.load(resolved_path) as Texture2D
