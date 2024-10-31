class_name MainMenu
extends Control

@onready var animation_player = $AnimationPlayer
@onready var options_menu = $Options_Menu as OptionsMenu
@onready var margin_container = $MarginContainer
@onready var lob = $Lob
@onready var shake_camera = $ShakeCamera
@onready var confirm_quit = $MarginContainer/ConfirmQuit
@onready var new_game = $MarginContainer/VBoxContainer/NewGame
@onready var load_saves = $MarginContainer/VBoxContainer/LoadSaves
@onready var continue_button = $MarginContainer/VBoxContainer/Continue
@onready var play_button = $MarginContainer/VBoxContainer/Play
@onready var new_game_confirm = $MarginContainer/ConfirmNewGame/TextureRect2/HBoxContainer/NewGameConfirm
@onready var new_game_cancel = $MarginContainer/ConfirmNewGame/TextureRect2/HBoxContainer/NewGameCancel
@onready var confirm_new_game = $MarginContainer/ConfirmNewGame

var exit: bool = false
var options: bool = false
var play: bool = false
var confirm_exit: bool = false
var load_save_pressed: bool = false
var new_game_pressed: bool = false
var continue_pressed:bool = false

func _ready():
	get_tree().paused = false
	confirm_quit.visible = false
	confirm_new_game.visible = false
	animation_player.play("fade_in_white")
	GameMusicController.stop_music()
	MenuAudioController.play_music()
	AudioController.button_select.connect(_on_select_finished)
	options_menu.exit_options_menu.connect(on_exit_options_menu)
	
	update_button_visibility()

func update_button_visibility():
	var has_saves = SaveManager.has_any_saves()
	
	play_button.visible = not has_saves
	new_game.visible = has_saves
	load_saves.visible = has_saves
	continue_button.visible = has_saves

func _on_play_pressed():
	# Reset game state
	_reset_game_state()
	
	# Initialize new save
	var save_slot = SaveManager.initialize_new_save()
	if save_slot != -1:
		GlobalValues.playing_game = true
		MenuAudioController.stop_music()
		GameMusicController.play_music()
		get_tree().change_scene_to_file("res://scenes/world/levels_new/level_0.tscn")

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
	# Stop any running animations
	animation_player.stop()
	# Optional: Play a fade out animation before quitting
	if animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		# Wait for animation to finish before quitting
		await animation_player.animation_finished
	# Cleanup before quitting
	MenuAudioController.stop_music()
	get_tree().quit()

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
		get_tree().change_scene_to_file("res://scenes/world/levels_new/level_0.tscn")
	elif load_save_pressed:
		get_tree().change_scene_to_file("res://scenes/UI/loadsave/load_save.tscn")
		load_save_pressed = false
	elif continue_pressed:
		var most_recent_slot = SaveManager.get_most_recent_save()
		if most_recent_slot != -1:
			var save_data = SaveManager.load_game(most_recent_slot)
			
			# Find oldest slot to override
			var new_slot = SaveManager.get_oldest_save_slot()
			SaveManager.current_active_save_slot = new_slot
			
			# Apply save data and create new save
			_apply_save_data(save_data)
			SaveManager.save_game(new_slot)
			
			# Start the game
			GlobalValues.playing_game = true
			MenuAudioController.stop_music()
			GameMusicController.play_music()
			var level_path = GlobalValues.LEVEL_PATHS[LevelManager.current_level]
			get_tree().change_scene_to_file(level_path)
		
		continue_pressed = false
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

# Saved buttons pressed

func _on_continue_pressed():
	var target_slot = SaveManager.continue_game()
	if target_slot != -1:
		var save_data = SaveManager.load_game(target_slot)
		
		# Apply save data
		_apply_save_data(save_data)
		
		# Start the game
		GlobalValues.playing_game = true
		MenuAudioController.stop_music()
		GameMusicController.play_music()
		var level_path = GlobalValues.LEVEL_PATHS[LevelManager.current_level]
		get_tree().change_scene_to_file(level_path)

func _apply_save_data(save_data: Dictionary):
	LevelManager.current_level = save_data.level
	GlobalValues.can_throw = save_data.can_throw
	GlobalValues.can_swap_food = save_data.can_swap_food
	GlobalValues.can_swap_fire = save_data.can_swap_fire
	GlobalValues.can_swap_water = save_data.can_swap_water
	GlobalValues.has_pickeup_box_once = save_data.has_pickeup_box_once
	GlobalValues.has_pickeup_c_box_once = save_data.has_pickeup_c_box_once
	GlobalValues.has_pickeup_fire_once = save_data.has_pickeup_fire_once
	GlobalValues.has_pickeup_food_once = save_data.has_pickeup_food_once
	GlobalValues.has_pickup_water_once = save_data.has_pickup_water_once
	GlobalValues.box_pickup_once = save_data.box_pickup_once
	GlobalValues.food_already_picked = save_data.food_already_picked
	GlobalValues.hazmat_picked_up = save_data.hazmat_picked_up

# In menu.gd, update the new game handling:

func _on_new_game_pressed():
	# Show confirmation popup
	confirm_new_game.visible = true

func _reset_game_state():
	LevelManager.current_level = 0
	GlobalValues.can_throw = false
	GlobalValues.can_swap_food = false
	GlobalValues.can_swap_fire = false
	GlobalValues.can_swap_water = false
	GlobalValues.has_pickeup_box_once = false
	GlobalValues.has_pickeup_c_box_once = false
	GlobalValues.has_pickeup_fire_once = false
	GlobalValues.has_pickeup_food_once = false
	GlobalValues.has_pickup_water_once = false
	GlobalValues.box_pickup_once = false
	GlobalValues.food_already_picked = false
	GlobalValues.hazmat_picked_up = false
	GlobalValues.player_position = Vector2.ZERO

func _on_load_saves_pressed():
	load_save_pressed = true
	AudioController.play_sfx("button_select")

func _on_continue_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_new_game_mouse_entered():
	AudioController.play_sfx("button_hover")

func _on_new_game_confirm_pressed():
	# Delete all saves
	SaveManager.delete_all_saves()
	
	confirm_new_game.visible = false
	
	# Reset game state
	_reset_game_state()
	
	# Initialize new save
	var save_slot = SaveManager.initialize_new_save()
	if save_slot != -1:
		GlobalValues.playing_game = true
		MenuAudioController.stop_music()
		GameMusicController.play_music()
		get_tree().change_scene_to_file("res://scenes/world/levels_new/level_0.tscn")

func _on_new_game_cancel_pressed():
	confirm_new_game.visible = false
