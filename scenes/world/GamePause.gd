extends CanvasLayer

@onready var select = $select

var exit: bool = false
var reset: bool = false
var resume: bool = false

func _ready():
	self.hide()

func _on_restart_pressed():
	reset = true
	select.play()

func _on_resume_pressed():
	select.play()
	resume = true

func game_exit():
	get_tree().paused = true
	self.show()

func game_over():
	get_tree().paused = true
	self.show()

func _on_exit_pressed():
	exit = true
	select.play()

func _on_select_finished():
	if exit:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
		exit = false
	elif reset:
		get_tree().paused = false
		get_tree().reload_current_scene()
		reset = false
	elif resume:
		self.hide()
		get_tree().paused = false
		resume = false
