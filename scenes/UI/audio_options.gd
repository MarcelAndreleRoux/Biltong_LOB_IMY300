extends Control

var back: bool = false

func _ready():
	AudioController.button_select.connect(_on_select_finished)

func _on_back_pressed():
	AudioController.play_sfx("button_select")
	back = true

func _on_back_mouse_entered():
	AudioController.play_sfx("button_hover")
	
func _on_select_finished():
	if back:
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")

func _on_volume_slider_3_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_volume_slider_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_volume_slider_2_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_volume_slider_2_drag_started():
	AudioController.play_sfx("TICKSOUND_MASTER")

func _on_volume_slider_drag_started():
	AudioController.play_sfx("TICKSOUND_MUSIC")

func _on_volume_slider_3_drag_started():
	AudioController.play_sfx("TICKSOUND_SFX")
