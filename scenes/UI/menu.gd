extends Control

var exit: bool = false
var options: bool = false

func _ready():
	AudioController.button_select.connect(_on_select_finished)
	GlobalValues.playing_game = false

func _on_play_pressed():
	LevelManager.current_level = 0
	AudioController.play_sfx("button_select")
	exit = false
	options = false
	GlobalValues.playing_game = true
	
func _on_exit_pressed():
	AudioController.play_sfx("button_select")
	exit = true
	options = false

func _on_option_pressed():
	AudioController.play_sfx("button_select")
	exit = false
	options = true

func _on_select_finished():
	if exit:
		get_tree().quit()
	elif options:
		get_tree().change_scene_to_file("res://scenes/UI/audio_options.tscn")
	else:
		GlobalValues.playing_game = true
		get_tree().change_scene_to_file("res://scenes/world/levels_production/level_1.tscn")
