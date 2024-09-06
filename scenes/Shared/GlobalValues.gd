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
var left_swap: bool = false
var right_swap: bool = false

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
		# Ensure can_throw is preserved across scenes
		can_throw = true
		
		SharedSignals.inventory_changed.emit(GlobalValues.inventory_select)

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
		
		finish_changingscene()
