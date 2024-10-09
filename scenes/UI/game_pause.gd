class_name GamePause
extends CanvasLayer

var exit: bool = false
var reset: bool = false
var resume: bool = false
var options: bool = false

@onready var confirm_quit = $Control/ConfirmQuit
@onready var shake_camera = $ShakeCamera
@onready var options_menu = $Options_Menu
@onready var button_select = $ButtonSelect
@onready var control = $Control

var can_exit: bool = false

func _ready():
	self.hide()
	confirm_quit.visible = false
	options_menu.visible = false
	control.visible = true

func _change_exit_again():
	can_exit = true

func _on_restart_pressed():
	shake_camera.apply_shake_smaller()
	button_select.play()
	print("reset clicked in pause menu")
	reset = true

func _on_resume_pressed():
	shake_camera.apply_shake_smaller()
	button_select.play()
	resume = true

func _on_options_pressed():
	shake_camera.apply_shake_smaller()
	button_select.play()
	options = true

func _on_exit_pressed():
	shake_camera.apply_shake_smaller()
	button_select.play()
	exit = true
	
func game_pause():
	print("exit game")
	button_select.play()
	self.show()
	control.visible = true

func _on_cancel_pressed():
	confirm_quit.visible = false

func _on_confirm_pressed():
	confirm_quit.visible = false
	options_menu.visible = false
	control.visible = false
	get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")

func _on_resume_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_restart_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_options_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_exit_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_confirm_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_cancel_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_button_select_finished ():
	if exit:
		confirm_quit.visible = true
		options_menu.visible = false
		exit = false
	elif reset:
		control.visible = false
		options_menu.visible = false
		confirm_quit.visible = false
		get_tree().reload_current_scene()
		reset = false
	elif options:
		control.visible = false
		confirm_quit.visible = false
		options_menu.visible = true
		options_menu.exit_options_menu.connect(_exit_options)
		options = false
	elif resume:
		control.visible = false
		options_menu.visible = false
		confirm_quit.visible = false
		self.hide()
		resume = false

func _exit_options():
	control.visible = true
	options_menu.visible = false
