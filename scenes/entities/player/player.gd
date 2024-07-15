extends CharacterBody2D

@export var SPEED = 300.0
@export var ACCEL = 2.0

var input: Vector2

func get_input():
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	return input.normalized();

func _process(delta):
	var player_input = get_input()
	
	position += player_input * SPEED * delta
	
	move_and_slide()
