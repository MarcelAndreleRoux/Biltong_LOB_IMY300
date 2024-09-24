extends Node

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

func change_scene():
	if transition_scene:
		match current_scene:
			"World":
				get_tree().change_scene_to_file("res://scenes/world/level_2.tscn")
			"level2":
				get_tree().change_scene_to_file("res://scenes/world/level_3.tscn")
			"level3":
				get_tree().change_scene_to_file("res://scenes/world/level_4.tscn")
		
		finish_changingscene()
