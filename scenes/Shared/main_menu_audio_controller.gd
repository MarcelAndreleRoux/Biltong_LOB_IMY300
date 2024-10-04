# MenuAudioController.gd
extends Node

@onready var random_music_player = $RandomMusicPlayer

func play_music():
	random_music_player.play()

func stop_music():
	random_music_player.stop()
