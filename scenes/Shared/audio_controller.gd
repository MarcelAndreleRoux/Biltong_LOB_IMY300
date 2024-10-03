extends Node2D

signal button_select

func play_sfx(song_name: String):
	var audio_player = get_node(song_name)
	if audio_player and audio_player is AudioStreamPlayer2D:
		audio_player.play()
	else:
		print("Audio node not found or incorrect type:", song_name)

func _on_button_select_finished():
	button_select.emit()
