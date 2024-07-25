extends Control

@onready var click = $Node/click

var exit: bool = false

func _on_start_pressed():
	click.play()
	exit = false
	
func _on_exit_pressed():
	click.play()
	exit = true

func _on_click_finished():
	if exit:
		get_tree().quit()
	else:
		get_tree().change_scene_to_file("res://scenes/world/world.tscn")
