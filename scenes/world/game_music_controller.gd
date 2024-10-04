extends Node

@onready var random_audio_player = $RandomAudioPlayer

var playing: bool = false

func play_music():
	random_audio_player.play()

func stop_music():
	random_audio_player.stop()
