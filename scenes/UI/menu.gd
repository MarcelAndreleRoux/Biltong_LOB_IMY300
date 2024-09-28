extends Control

@onready var click = $Node/click

var exit: bool = false
var options: bool = false

func _ready():
	MenuAudioController.play_main_music()

func _on_play_pressed():
	LevelManager.current_level = 0
	click.play()
	exit = false
	options = false
	
func _on_exit_pressed():
	click.play()
	exit = true
	options = false

func _on_option_pressed():
	click.play()
	exit = false
	options = true

func _on_click_finished():
	if exit:
		get_tree().quit()
	elif options:
		get_tree().change_scene_to_file("res://scenes/UI/audio_options.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/world/levels_production/level_1.tscn")
