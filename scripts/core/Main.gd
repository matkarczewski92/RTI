extends Control

const MAIN_MENU_SCENE := preload("res://scenes/menu/MainMenu.tscn")
const BIOME_MAP_SCENE := preload("res://scenes/map/BiomeMap.tscn")
const BIOME_VIEW_SCENE := preload("res://scenes/biome/BiomeView.tscn")

var content_root: Control


func _ready() -> void:
	_build_layout()
	_show_main_menu()


func _build_layout() -> void:
	content_root = Control.new()
	content_root.name = "Content"
	content_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(content_root)


func _set_screen(scene: PackedScene) -> Node:
	for child in content_root.get_children():
		child.queue_free()

	var screen: Node = scene.instantiate()
	content_root.add_child(screen)
	if screen is Control:
		screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	return screen


func _show_main_menu() -> void:
	var menu: Node = _set_screen(MAIN_MENU_SCENE)
	if menu.has_signal("play_pressed"):
		menu.connect("play_pressed", Callable(self, "_show_biome_map"))


func _show_biome_map() -> void:
	var map: Node = _set_screen(BIOME_MAP_SCENE)
	if map.has_signal("back_pressed"):
		map.connect("back_pressed", Callable(self, "_show_main_menu"))
	if map.has_signal("biome_selected"):
		map.connect("biome_selected", Callable(self, "_show_biome_view"))


func _show_biome_view(selected_biome_id: String) -> void:
	for child in content_root.get_children():
		child.queue_free()
	var biome_view: Node = BIOME_VIEW_SCENE.instantiate()
	if "biome_id" in biome_view:
		biome_view.biome_id = selected_biome_id
	content_root.add_child(biome_view)
	if biome_view is Control:
		(biome_view as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	if biome_view.has_signal("biome_map_requested"):
		biome_view.connect("biome_map_requested", Callable(self, "_show_biome_map"))
