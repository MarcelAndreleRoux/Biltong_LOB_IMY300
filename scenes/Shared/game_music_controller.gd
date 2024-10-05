extends Node

@onready var random_audio_player_game = $RandomAudioPlayerGame

func play_music():
	random_audio_player_game.play()

func stop_music():
	random_audio_player_game.stop()
