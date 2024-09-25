extends CharacterBody2D

@export var group_name: String
@export var speed: float = 50.0  # Define the speed of the enemy
@export var turn_speed: float = 5.0  # Speed of turning toward target

@onready var animation_tree = $AnimationTree
@onready var wander = $LizardWander

var play_moving: bool = true
var direction: Vector2 = Vector2.ZERO

var is_on: bool = true
var is_idle: bool = true

func _ready():
	print("Lizard ready")
	SharedSignals.lizard_marker_reached.connect(_on_marker_reached)
	SharedSignals.lizard_can_move_again.connect(_make_move_again)
	wander.start_wandering()

func _physics_process(delta):
	if play_moving:
		wander.update_direction()
		direction = wander.get_velocity()

		velocity = direction * speed
		
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	
	_update_animation_parameters()

func _make_move_again():
	play_moving = true
	is_idle = false

func _on_marker_reached():
	print("Lizard reached a marker, stopping to wait.")
	play_moving = false
	is_idle = true
	
	wander.start_stop_timer()

func _update_animation_parameters():
	if is_on:
		if play_moving:
			animation_tree["parameters/conditions/is_run_on"] = true
			animation_tree["parameters/conditions/is_run_off"] = false
			animation_tree["parameters/conditions/is_idle_on"] = false
			animation_tree["parameters/conditions/is_idle_off"] = false
		elif is_idle:
			animation_tree["parameters/conditions/is_idle_on"] = true
			animation_tree["parameters/conditions/is_idle_off"] = false
			animation_tree["parameters/conditions/is_lick_on"] = false
			animation_tree["parameters/conditions/is_lick_off"] = false
	else:
		if play_moving:
			animation_tree["parameters/conditions/is_run_on"] = false
			animation_tree["parameters/conditions/is_run_off"] = true
			animation_tree["parameters/conditions/is_idle_on"] = false
			animation_tree["parameters/conditions/is_idle_off"] = false
		elif is_idle:
			animation_tree["parameters/conditions/is_idle_on"] = false
			animation_tree["parameters/conditions/is_idle_off"] = true
			animation_tree["parameters/conditions/is_lick_on"] = false
			animation_tree["parameters/conditions/is_lick_off"] = false
	
	animation_tree["parameters/idle_off/blend_position"] = direction
	animation_tree["parameters/idle_on/blend_position"] = direction
	animation_tree["parameters/lick_off/blend_position"] = direction
	animation_tree["parameters/lick_on/blend_position"] = direction
	animation_tree["parameters/run_off/blend_position"] = direction
	animation_tree["parameters/run_on/blend_position"] = direction

func _on_electric_area_body_entered(body):
	pass

func _on_electric_area_body_exited(body):
	pass
