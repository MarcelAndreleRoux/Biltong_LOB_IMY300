extends Control

var back: bool = false
@onready var audio_controler = $AudioControler

func _on_back_pressed():
	back = true
	audio_controler.click.play()

func _on_click_finished():
	if back:
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
