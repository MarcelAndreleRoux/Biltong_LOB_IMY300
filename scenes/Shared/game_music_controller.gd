extends Node

@onready var random_audio_player_game = $RandomAudioPlayerGame

func play_music():
	fade_in_music()

func stop_music():
	fade_out_music()

func fade_in_music(duration = 2.0):
	random_audio_player_game.volume_db = -30
	random_audio_player_game.play()
	var tween = create_tween()
	tween.tween_property(random_audio_player_game, "volume_db", -10, duration)

func fade_out_music(duration = 2.0):
	var tween = create_tween()
	tween.tween_property(random_audio_player_game, "volume_db", -30, duration)
	tween.tween_callback(self._on_fade_out_finished)

func _on_fade_out_finished():
	random_audio_player_game.stop()
