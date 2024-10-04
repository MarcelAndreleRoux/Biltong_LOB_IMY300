extends CanvasLayer

var exit: bool = false
var reset: bool = false
var resume: bool = false
var options: bool = false

@onready var button_select = $ButtonSelect

func _ready():
	self.hide()

func _on_restart_pressed():
	print("reset clicked in pause menu")
	reset = true
	button_select.play()

func _on_resume_pressed():
	print("resume clicked in pause menu")
	resume = true
	button_select.play()

func _on_options_pressed():
	print("options clicked in pause menu")
	options = true
	button_select.play()

func _on_exit_pressed():
	print("exit clicked in pause menu")
	exit = true
	button_select.play()
	
func game_exit():
	print("exit game")
	get_tree().paused = true
	self.show()
	button_select.play()

func _on_button_select_finished():
	if exit:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
		exit = false
	elif reset:
		get_tree().paused = false
		get_tree().reload_current_scene()
		reset = false
	elif options:
		get_tree().paused = true
		self.hide()
		var audio_paused_menu = get_parent().get_node("AudioPausedMenu")
		audio_paused_menu.audio_options_selected()
	elif resume:
		# Hide both the pause menu and the audio options menu to resume the game
		self.hide()
		var audio_paused_menu = get_parent().get_node("AudioPausedMenu")
		if audio_paused_menu.is_visible():
			audio_paused_menu.hide()  # Ensure the audio options menu is hidden
		get_tree().paused = false
		resume = false
