class_name MainMenu
extends Control

@onready var animation_player = $AnimationPlayer
@onready var options_menu = $Options_Menu as OptionsMenu
@onready var margin_container = $MarginContainer
@onready var lob = $Lob
@onready var shake_camera = $ShakeCamera
@onready var confirm_quit = $MarginContainer/TextureRect2/ConfirmQuit

var exit: bool = false
var options: bool = false
var play: bool = false
var confirm_exit: bool = false

func _ready():
	confirm_quit.visible = false
	animation_player.play("fade_in_white")
	GameMusicController.stop_music()
	MenuAudioController.play_music()
	AudioController.button_select.connect(_on_select_finished)
	options_menu.exit_options_menu.connect(on_exit_options_menu)

func _on_play_pressed():
	LevelManager.current_level = 0
	shake_camera.apply_shake_super_small()
	AudioController.play_sfx("button_select")
	exit = false
	options = false
	play = true
	GlobalValues.playing_game = true

func _on_option_pressed():
	shake_camera.apply_shake_super_small()
	AudioController.play_sfx("button_select")
	exit = false
	options = true
	
func on_exit_options_menu():
	shake_camera.apply_shake_super_small()
	margin_container.visible = true
	lob.visible = true
	options_menu.visible = false

func _on_cancel_pressed():
	AudioController.play_sfx("button_select")
	confirm_quit.visible = false

func _on_confirm_pressed():
	AudioController.play_sfx("button_select")
	confirm_exit = true

func _on_exit_pressed():
	AudioController.play_sfx("button_select")
	shake_camera.apply_shake_super_small()
	exit = true
	options = false

func _on_select_finished():
	if exit:
		confirm_quit.visible = true
		exit = false
	elif options:
		margin_container.visible = false
		lob.visible = false
		options_menu.visible = true
		options = false
	elif play:
		GlobalValues.playing_game = true
		MenuAudioController.stop_music()
		GameMusicController.play_music()
		get_tree().change_scene_to_file("res://scenes/world/levels_production/level_1.tscn")
	elif confirm_exit:
		get_tree().quit()
	else:
		margin_container.visible = true
		lob.visible = true
		options_menu.visible = false

func _on_play_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_levels_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_option_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_exit_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_cancel_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_confirm_mouse_entered():
	AudioController.play_sfx("button_hover")
