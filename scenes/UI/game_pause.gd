class_name GamePause
extends CanvasLayer

var exit: bool = false
var reset: bool = false
var resume: bool = false
var options: bool = false

@onready var shake_camera = $ShakeCamera
@onready var button_select = $ButtonSelect
@onready var game_music_player = GameMusicController

func _ready():
	self.hide()
	
	# Manually control the music here if needed, but we won't pause the music

func _on_restart_pressed():
	shake_camera.apply_shake_smaller()
	print("reset clicked in pause menu")
	reset = true
	button_select.play()

func _on_resume_pressed():
	shake_camera.apply_shake_smaller()
	print("resume clicked in pause menu")
	resume = true
	button_select.play()

func _on_options_pressed():
	shake_camera.apply_shake_smaller()
	print("options clicked in pause menu")
	options = true
	button_select.play()

func _on_exit_pressed():
	shake_camera.apply_shake_smaller()
	print("exit clicked in pause menu")
	exit = true
	button_select.play()
	
func game_exit():
	print("exit game")
	# Pause the game but keep music playing
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
		self.hide()
		var audio_paused_menu = get_parent().get_node("AudioPausedMenu")
		audio_paused_menu.audio_options_selected()
		options = false
	elif resume:
		self.hide()
		get_tree().paused = false
		resume = false
