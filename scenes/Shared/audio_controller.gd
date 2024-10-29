extends Node2D

signal button_select

var fade_speed = 0.1
var min_db = -80  # Minimum volume in decibels (silence)
var max_db = 0    # Maximum volume in decibels (full volume)

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

# Add getter/setter functions for volumes
func get_master_volume() -> float:
	return master_volume

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	_update_all_volumes()

func get_music_volume() -> float:
	return music_volume

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_update_music_volumes()

func get_sfx_volume() -> float:
	return sfx_volume

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_update_sfx_volumes()

# Add helper functions to update volumes
func _update_all_volumes() -> void:
	for child in get_children():
		if child is AudioStreamPlayer2D:
			var base_volume = music_volume if _is_music_player(child) else sfx_volume
			child.volume_db = linear_to_db(base_volume * master_volume)

func _update_music_volumes() -> void:
	for child in get_children():
		if child is AudioStreamPlayer2D and _is_music_player(child):
			child.volume_db = linear_to_db(music_volume * master_volume)

func _update_sfx_volumes() -> void:
	for child in get_children():
		if child is AudioStreamPlayer2D and not _is_music_player(child):
			child.volume_db = linear_to_db(sfx_volume * master_volume)

# Helper to identify music players
func _is_music_player(audio_player: Node) -> bool:
	# You can customize this based on your naming convention
	return audio_player.name.to_lower().contains("music")

func play_sfx(song_name: String):
	var audio_player = get_node(song_name)
	if audio_player and audio_player is AudioStreamPlayer2D:
		# Apply volume settings when playing
		var base_volume = music_volume if _is_music_player(audio_player) else sfx_volume
		audio_player.volume_db = linear_to_db(base_volume * master_volume)
		audio_player.play()
	else:
		print("Audio node not found or incorrect type:", song_name)

func fade_in_audio(audio_player: AudioStreamPlayer2D, target_volume: float = 1.0):
	if not audio_player.playing:
		audio_player.play()
	var base_volume = music_volume if _is_music_player(audio_player) else sfx_volume
	var final_volume = base_volume * master_volume * target_volume
	audio_player.volume_db = lerp(audio_player.volume_db, linear_to_db(final_volume), fade_speed)

func fade_out_audio(audio_player: AudioStreamPlayer2D):
	if audio_player.playing:
		audio_player.volume_db = lerp(audio_player.volume_db, float(min_db), fade_speed)
		if audio_player.volume_db <= float(min_db) + 0.01:
			audio_player.stop()

func _on_button_select_finished():
	button_select.emit()
