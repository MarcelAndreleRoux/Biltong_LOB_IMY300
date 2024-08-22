extends Node

var current_scene = "World"
var transition_scene = false
var can_throw: bool = false

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

func change_scene():
	if transition_scene:
		match current_scene:
			"World":
				get_tree().change_scene_to_file("res://scenes/world/level_2.tscn")
			"level2":
				get_tree().change_scene_to_file("res://scenes/world/level_3.tscn")
		
		finish_changingscene()
