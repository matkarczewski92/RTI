extends Node

const MUSIC_PATH := "res://assets/audio/music/music.mp3"

@export_range(-80.0, 6.0, 0.1) var music_volume_db := -12.0:
	set(value):
		music_volume_db = value
		_apply_music_volume()

@export var autoplay_music := true

var _music_player: AudioStreamPlayer
var _music_enabled := true


func _ready() -> void:
	_ensure_music_player()
	_music_enabled = _get_music_enabled_from_state()
	_apply_music_volume()
	_apply_music_enabled(_music_enabled)

	if has_node("/root/GameState"):
		if not GameState.state_changed.is_connected(_on_game_state_changed):
			GameState.state_changed.connect(_on_game_state_changed)
		if not GameState.save_loaded.is_connected(_on_game_state_changed):
			GameState.save_loaded.connect(_on_game_state_changed)

	if autoplay_music:
		play_music()


func play_music() -> void:
	_ensure_music_player()
	if _music_player.stream == null:
		push_warning("AudioSystem: background music missing: " + MUSIC_PATH)
		return

	_apply_music_enabled(_get_music_enabled_from_state())
	if not _music_enabled:
		return
	if not _music_player.playing:
		_music_player.play()


func set_music_enabled(enabled: bool) -> void:
	if has_node("/root/GameState") and bool(GameState.get_setting("music_enabled", true)) != enabled:
		GameState.set_setting("music_enabled", enabled)
	_apply_music_enabled(enabled)


func set_sfx_enabled(_enabled: bool) -> void:
	# Reserved for future UI/gameplay sound effects.
	pass


func set_music_volume_db(value: float) -> void:
	music_volume_db = value


func _ensure_music_player() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		return

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "BackgroundMusicPlayer"
	_music_player.bus = "Master"
	_music_player.volume_db = music_volume_db
	_music_player.stream = load(MUSIC_PATH)
	if _music_player.stream is AudioStreamMP3:
		var mp3_stream := _music_player.stream as AudioStreamMP3
		mp3_stream.loop = true
		mp3_stream.loop_offset = 0.0
	if not _music_player.finished.is_connected(_on_music_finished):
		_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)


func _apply_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	_ensure_music_player()
	_music_player.stream_paused = not _music_enabled
	if _music_enabled and autoplay_music and not _music_player.playing:
		_music_player.play()


func _apply_music_volume() -> void:
	if _music_player == null or not is_instance_valid(_music_player):
		return
	_music_player.volume_db = music_volume_db


func _get_music_enabled_from_state() -> bool:
	if not has_node("/root/GameState"):
		return true
	return bool(GameState.get_setting("music_enabled", true))


func _on_game_state_changed() -> void:
	_apply_music_enabled(_get_music_enabled_from_state())


func _on_music_finished() -> void:
	if _music_enabled and autoplay_music:
		_music_player.play()
