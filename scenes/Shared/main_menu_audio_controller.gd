# MenuAudioController.gd
extends Node

@onready var random_music_player = $RandomMusicPlayer

var playing: bool = false

func _ready():
	if not GlobalValues.playing_game:
		playing = true
		random_music_player.play()
	else:
		if playing:
			random_music_player.stop()
		else:
			playing = false

func stop_music():
	if playing:
		print("Stopping menu music")
		random_music_player.stop()
