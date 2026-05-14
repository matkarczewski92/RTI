extends RefCounted


static func find_texture_path(expected_path: String) -> String:
	if ResourceLoader.exists(expected_path):
		return expected_path

	var directory_path: String = expected_path.get_base_dir()
	var expected_file: String = expected_path.get_file()
	var expected_stem: String = expected_file.get_basename()
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_warning("Missing asset directory: " + directory_path)
		return ""

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir():
			var lower_name: String = file_name.to_lower()
			if lower_name.ends_with(".png") and lower_name.begins_with(expected_stem.to_lower()):
				var resolved_path: String = directory_path.path_join(file_name)
				push_warning("Asset not found at " + expected_path + ". Using closest match: " + resolved_path)
				directory.list_dir_end()
				return resolved_path
		file_name = directory.get_next()

	directory.list_dir_end()
	push_warning("Missing asset: " + expected_path + ". Keeping placeholder UI.")
	return ""


static func load_texture(expected_path: String) -> Texture2D:
	var resolved_path: String = find_texture_path(expected_path)
	if resolved_path.is_empty():
		return null

	return ResourceLoader.load(resolved_path) as Texture2D
