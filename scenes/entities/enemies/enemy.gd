extends CharacterBody2D

@export var wander_direction: Node2D
@export var turn_speed: float = 5.0
@onready var animation_tree = $AnimationTree

var should_eat: bool = false
var play_moving: bool = true

func _ready():
	animation_tree.active = true
	SharedSignals.start_eating.connect(_should_play_eating)
	SharedSignals.can_move_again.connect(_play_moving)

func _physics_process(delta):
	if wander_direction:
		_update_direction(delta)
		_update_animation_parameters()
		if play_moving and not should_eat:
			move_and_slide()
	else:
		velocity = Vector2.ZERO

func _update_direction(delta):
	var target_position = wander_direction.global_position
	var direction_to_target = (target_position - global_position).normalized()

	velocity = direction_to_target * 45

func _update_animation_parameters():
	if should_eat:
		animation_tree["parameters/conditions/is_eating"] = true
		animation_tree["parameters/conditions/is_walking"] = false
	elif play_moving:
		animation_tree["parameters/conditions/is_walking"] = true
		animation_tree["parameters/conditions/is_eating"] = false
	
	animation_tree["parameters/eat/blend_position"] = velocity
	animation_tree["parameters/walk/blend_position"] = velocity

func _should_play_eating():
	should_eat = true
	play_moving = false

func _play_moving():
	play_moving = true
	should_eat = false
