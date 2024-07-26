extends CharacterBody2D

@export var wander_direction: Node2D
@export var turn_speed: float = 5.0
@onready var animation_tree = $AnimationTree

var should_eat: bool = false
var play_moving: bool = true
var target_marker: Marker2D

func _ready():
	animation_tree.active = true
	SharedSignals.start_eating.connect(_should_play_eating)
	SharedSignals.can_move_again.connect(_play_moving)
	SharedSignals.new_marker.connect(_set_new_target)

func _physics_process(delta):
	_update_direction(delta)
	_update_animation_parameters()
	if play_moving and not should_eat:
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _update_direction(delta):
	var target_position: Vector2
	if target_marker:
		target_position = target_marker.global_position
	else:
		target_position = wander_direction.global_position

	var direction_to_target = (target_position - global_position).normalized()
	velocity = direction_to_target * 45  # Use appropriate speed here

	# If close enough to the target_marker, start eating
	if target_marker and global_position.distance_to(target_position) <= 10:
		_start_eating()

func _set_new_target(new_marker: Marker2D):
	target_marker = new_marker

func _start_eating():
	if target_marker:
		should_eat = true
		play_moving = false
		SharedSignals.start_eating.emit()
		# Optionally remove the marker here if needed
		target_marker.queue_free()
		target_marker = null

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
