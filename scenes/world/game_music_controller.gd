extends Node

@onready var random_audio_player = $RandomAudioPlayer

var playing: bool = false

func _ready():
	print("GlobalValues.playing_game: ", GlobalValues.playing_game)
	if GlobalValues.playing_game:
		print("Stopping menu music and starting game music")
		MenuAudioController.stop_music()
		playing = true
		random_audio_player.play()
	else:
		print("Not in game, stopping game music")
		if playing:
			random_audio_player.stop()
		else:
			playing = false
