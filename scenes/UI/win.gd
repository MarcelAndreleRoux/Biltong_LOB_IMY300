extends CanvasLayer

@onready var buttonselect = $Buttonselect

var exit: bool = false
var reset: bool = false

func _ready():
	AudioController.button_select.connect(_on_select_finished)
	self.hide()

func _on_exit_pressed():
	exit = true
	buttonselect.play()

func _on_select_finished():
	if exit:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
		exit = false
	elif reset:
		get_tree().paused = false
		get_tree().reload_current_scene()
		reset = false

func win():
	get_tree().paused = true
	self.show()
