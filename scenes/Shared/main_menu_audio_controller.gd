extends Node

@onready var random_music_player: AudioStreamPlayer = $RandomMusicPlayer

func play_music():
	fade_in_music()

func fade_in_music(duration: float = 2.0):
	if random_music_player.stream == null:
		return
	random_music_player.volume_db = -20
	random_music_player.play()
	var tween = create_tween()
	tween.tween_property(random_music_player, "volume_db", 0, duration)

func stop_music():
	fade_out_music()

func fade_out_music(duration: float = 2.0):
	var tween = create_tween()
	tween.tween_property(random_music_player, "volume_db", -20, duration)
	tween.tween_callback(Callable(self, "_on_fade_out_finished"))

func _on_fade_out_finished():
	random_music_player.stop()
