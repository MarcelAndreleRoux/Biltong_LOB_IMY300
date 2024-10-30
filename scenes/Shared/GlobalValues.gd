extends Node

signal game_done

var current_scene = "World"
var transition_scene = false
var can_throw: bool = false
var inventory_update = false

enum INVENTORY_SELECT { NONE, FOOD, FIRE, WATER }
var inventory_select = INVENTORY_SELECT.NONE

var can_swap_food: bool = false
var can_swap_fire: bool = false
var can_swap_water: bool = false
var spotted_food: bool = false
var food_visible: bool = false
var playing_game: bool = false

# Pickups (e.g. box, firebush, waterbush)
var has_pickeup_box_once: bool = false
var has_pickeup_c_box_once: bool = false
var has_pickeup_fire_once: bool = false
var has_pickeup_food_once: bool = false
var has_pickup_water_once: bool = false
var box_pickup_once: bool = false
var food_already_picked: bool = false

var wire_on: bool = false
var vinesSize: String

var turtle_original_pos: Vector2
var player_position: Vector2

var hazmat_picked_up: bool = false

# Censorship
signal censorship_changed
var censorship_enabled: bool = true

func _ready():
	# If this is the first time running (no settings file exists)
	if not FileAccess.file_exists("user://settings.save"):
		# Set default censorship to true and save settings
		censorship_enabled = true
		SaveManager.save_settings()

func get_censorship_enabled() -> bool:
	return censorship_enabled

func set_censorship_enabled(enabled: bool):
	censorship_enabled = enabled
	censorship_changed.emit()

# Player
func update_player_position(new_position: Vector2):
	player_position = new_position

func finish_changingscene():
	if transition_scene:
		transition_scene = false
		match current_scene:
			"World":
				current_scene = "level2"
			"level2":
				current_scene = "level3"
			"level3":
				current_scene = "level4"
		
		can_throw = true
		
		# Emit the inventory_changed signal to update the inventory UI after scene transitions
		SharedSignals.inventory_changed.emit(inventory_select)

func set_inventory_select(value: int):
	if inventory_select != value:
		inventory_select = value
		SharedSignals.inventory_changed.emit(value)

const LEVEL_PATHS = [
	"res://scenes/world/levels_new/level_0.tscn",
	"res://scenes/world/levels_new/level_1.tscn",
	"res://scenes/world/levels_new/level_2.tscn",
	"res://scenes/world/levels_new/level_3.tscn",
	"res://scenes/world/levels_new/level_4.tscn",
	"res://scenes/world/levels_new/level_5.tscn",
	"res://scenes/world/levels_new/level_6.tscn",
	"res://scenes/world/levels_new/level_7.tscn",
	"res://scenes/world/levels_new/level_8.tscn",
	"res://scenes/world/levels_new/level_9.tscn",
	"res://scenes/world/levels_new/level_10.tscn",
	"res://scenes/world/levels_new/level_11.tscn",
	"res://scenes/world/levels_new/level_12.tscn",
]

func change_scene_to_next_level():
	if LevelManager.current_level == LEVEL_PATHS.size() - 1:  # If we are at the last level (level 10)
		game_done.emit()
	else:
		LevelManager.current_level += 1  # Increment the level counter

		if LevelManager.current_level < LEVEL_PATHS.size():
			var next_level = LEVEL_PATHS[LevelManager.current_level]
			get_tree().change_scene_to_file(next_level)
		else:
			print("You've completed all levels!")
