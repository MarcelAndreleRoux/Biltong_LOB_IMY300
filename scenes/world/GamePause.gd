extends CanvasLayer

func _ready():
	self.hide()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_resume_pressed():
	self.hide()
	get_tree().paused = false

func game_over():
	get_tree().paused = true
	self.show()

func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
