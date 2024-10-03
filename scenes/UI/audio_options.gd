extends Control

var back: bool = false
@onready var button_select = $ButtonSelect

func _on_back_pressed():
	back = true
	button_select.play()

func _on_button_select_finished():
	if back:
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
