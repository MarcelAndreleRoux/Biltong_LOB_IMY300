extends CanvasLayer

@onready var confetti = $Confetti
@onready var shake_camera = $ShakeCamera

var exit: bool = false
var reset: bool = false

func _ready():
	AudioController.button_select.connect(_on_select_finished)
	self.hide()

func _on_restart_pressed():
	shake_camera.apply_shake_smaller()
	AudioController.play_sfx("button_select")
	reset = true
	_on_select_finished()

func _on_exit_pressed():
	shake_camera.apply_shake_smaller()
	AudioController.play_sfx("button_select")
	exit = true
	_on_select_finished()

func _on_select_finished():
	if exit:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
		exit = false
	elif reset:
		get_tree().paused = false
		get_tree().reload_current_scene()
		reset = false

func death_lose():
	get_tree().paused = true
	self.show()
