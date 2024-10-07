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

var wire_on: bool = false
var vinesSize: String

var turtle_original_pos: Vector2
var player_position: Vector2

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
	"res://scenes/world/levels_production/level_1.tscn",
	"res://scenes/world/levels_production/level_2.tscn",
	"res://scenes/world/levels_production/level_3.tscn",
	"res://scenes/world/levels_production/level_4.tscn",
	"res://scenes/world/levels_production/level_5.tscn",
	"res://scenes/world/levels_production/level_6.tscn",
	"res://scenes/world/levels_production/level_7.tscn",
	"res://scenes/world/levels_production/level_8.tscn",
	"res://scenes/world/levels_production/level_9.tscn",
	"res://scenes/world/levels_production/level_10.tscn"
]

func change_scene_to_next_level():
	if LevelManager.current_level == 9:  # If we are at the last level (level 10)
		game_done.emit()
	else:
		LevelManager.current_level += 1  # Increment the level counter

		if LevelManager.current_level < LEVEL_PATHS.size():
			var next_level = LEVEL_PATHS[LevelManager.current_level]
			get_tree().change_scene_to_file(next_level)
		else:
			print("You've completed all levels!")
