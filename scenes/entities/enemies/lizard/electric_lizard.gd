extends CharacterBody2D

@export var group_name: String
@export var speed: float = 50.0  # Define the speed of the enemy
@export var turn_speed: float = 5.0  # Speed of turning toward target
var play_moving: bool = true  # Control when the lizard is moving

@onready var animation_tree = $AnimationTree
@onready var wander = $LizardWander

func _ready():
	print("Lizard ready")
	SharedSignals.lizard_marker_reached.connect(_on_marker_reached)
	SharedSignals.lizard_can_move_again.connect(_make_move_again)
	wander.start_wandering()

func _physics_process(delta):
	# Move only if the lizard is supposed to move
	if play_moving:
		wander.update_direction()
		velocity = wander.get_velocity() * speed
		
		# Pass velocity to move_and_slide()
		move_and_slide()
	else:
		velocity = Vector2.ZERO  # Stop movement if not moving

	_update_animation_parameters()

func _make_move_again():
	play_moving = true

func _on_marker_reached():
	print("Lizard reached a marker, stopping to wait.")
	play_moving = false  # Stop moving temporarily
	wander.start_stop_timer()  # Call stop timer in the wander script

func _update_animation_parameters():
	# Update animation parameters here (based on movement, idle, etc.)
	pass

func _on_electric_area_body_entered(body):
	pass

func _on_electric_area_body_exited(body):
	pass
