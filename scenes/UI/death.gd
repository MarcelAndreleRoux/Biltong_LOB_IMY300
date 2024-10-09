extends CanvasLayer

@onready var confetti = $Confetti
@onready var shake_camera = $ShakeCamera
@onready var button_select = $ButtonSelect

var exit: bool = false
var reset: bool = false

func _ready():
	self.hide()

func _on_restart_pressed():
	shake_camera.apply_shake_smaller()
	button_select.play()
	reset = true

func _on_exit_pressed():
	shake_camera.apply_shake_smaller()
	button_select.play()
	exit = true

func death_lose():
	get_tree().paused = true
	self.show()

func _on_restart_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_exit_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_button_select_finished():
	if exit:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
		exit = false
	elif reset:
		get_tree().paused = false
		get_tree().reload_current_scene()
		reset = false
