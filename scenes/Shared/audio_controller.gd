extends Node2D

signal button_select

var fade_speed = 0.1
var min_db = -80  # Minimum volume in decibels (silence)
var max_db = 0    # Maximum volume in decibels (full volume)

func play_sfx(song_name: String):
	var audio_player = get_node(song_name)
	if audio_player and audio_player is AudioStreamPlayer2D:
		audio_player.play()
	else:
		print("Audio node not found or incorrect type:", song_name)

func fade_in_audio(audio_player: AudioStreamPlayer2D, target_volume: float = 1.0):
	if not audio_player.playing:
		audio_player.play()  # Start the audio if it's not playing
	audio_player.volume_db = lerp(audio_player.volume_db, float(max_db) * target_volume, fade_speed)

# Function to fade out the audio
func fade_out_audio(audio_player: AudioStreamPlayer2D):
	if audio_player.playing:
		audio_player.volume_db = lerp(audio_player.volume_db, float(min_db), fade_speed)
		if audio_player.volume_db <= float(min_db) + 0.01:
			audio_player.stop()

func _on_button_select_finished():
	button_select.emit()
