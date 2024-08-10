extends CharacterBody2D

@export var wander_direction: Node2D
@export var turn_speed: float = 5.0
@onready var animation_tree = $AnimationTree

var should_eat: bool = false
var play_moving: bool = false  # Initially not moving
var target_marker: Marker2D
var direction_to_target: Vector2 = Vector2.ZERO
var is_idle: bool = false  # Flag to track if the enemy is idling

func _ready():
	print("Enemy ready")
	animation_tree.active = true
	SharedSignals.start_eating.connect(_should_play_eating)
	SharedSignals.can_move_again.connect(_play_moving)
	SharedSignals.new_marker.connect(_set_new_target)

	_get_next_marker()

func _physics_process(_delta):
	print("Physics process - is_idle:", is_idle, "play_moving:", play_moving, "should_eat:", should_eat)
	if play_moving and not should_eat:
		_update_direction()
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_update_animation_parameters()

func _update_direction():
	if target_marker:
		var target_position = target_marker.global_position
		direction_to_target = (target_position - global_position).normalized()
		velocity = direction_to_target * 45  # Set speed as needed

		if global_position.distance_to(target_position) <= 10:
			_reach_marker()

func _set_new_target(new_marker: Marker2D):
	print("New target set:", new_marker.name)
	target_marker = new_marker
	direction_to_target = Vector2.ZERO  # Reset direction

	# Stop movement and start the idle animation before moving again
	play_moving = false
	is_idle = true  # Set idle to true
	_start_delay_before_moving()

func _start_delay_before_moving():
	print("Starting delay before moving")
	var delay_timer = Timer.new()
	delay_timer.wait_time = 5.0  # 5 seconds delay
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_start_moving_after_delay)
	add_child(delay_timer)
	delay_timer.start()

func _start_moving_after_delay():
	print("Delay finished, starting movement")
	is_idle = false  # End idle state
	play_moving = true  # Resume movement after the delay

func _reach_marker():
	print("Reached marker:", target_marker.name)
	velocity = Vector2.ZERO
	play_moving = false

	# Ensure this marker is correctly identified as a projectile
	if target_marker and target_marker.name.begins_with("Projectile"):
		should_eat = true
		_create_eating_timer()
	else:
		_create_turn_timer()

func _create_eating_timer():
	print("Creating eating timer")
	var timer = Timer.new()
	timer.wait_time = 5.0  # Eating duration
	timer.one_shot = true
	timer.timeout.connect(_finish_eating)
	add_child(timer)
	timer.start()

func _finish_eating():
	print("Finished eating")
	should_eat = false
	SharedSignals.can_move_again.emit()
	if target_marker:
		target_marker.queue_free()  # Remove the projectile after eating
	target_marker = null
	_get_next_marker()

func _create_turn_timer():
	print("Creating turn timer")
	var timer = Timer.new()
	timer.wait_time = 1  # Pause duration before moving to the next marker
	timer.one_shot = true
	timer.timeout.connect(_can_move_again)
	add_child(timer)
	timer.start()

func _can_move_again():
	print("Can move again")
	_get_next_marker()

func _get_next_marker():
	var markers = get_tree().get_nodes_in_group("FirstEnemy")
	if markers.size() > 0:
		var next_marker_index = (markers.find(target_marker) + 1) % markers.size()
		target_marker = markers[next_marker_index]
		direction_to_target = Vector2.ZERO
		play_moving = true
		print("Next marker set:", target_marker.name)

func _should_play_eating():
	print("Should play eating")
	should_eat = true
	play_moving = false

func _play_moving():
	print("Playing moving animation")
	play_moving = true
	should_eat = false

func _update_animation_parameters():
	print("Updating animation parameters - is_idle:", is_idle, "play_moving:", play_moving, "should_eat:", should_eat)

	if is_idle:
		print("Playing idle animation")
		animation_tree["parameters/conditions/is_idle"] = true
		animation_tree["parameters/conditions/is_walking"] = false
		animation_tree["parameters/conditions/is_eating"] = false
	elif should_eat:
		print("Playing eating animation")
		animation_tree["parameters/conditions/is_eating"] = true
		animation_tree["parameters/conditions/is_walking"] = false
		animation_tree["parameters/conditions/is_idle"] = false
	elif play_moving:
		print("Playing walking animation")
		animation_tree["parameters/conditions/is_walking"] = true
		animation_tree["parameters/conditions/is_eating"] = false
		animation_tree["parameters/conditions/is_idle"] = false
	else:
		# If none of the above, default to idle (safety net)
		animation_tree["parameters/conditions/is_idle"] = true
		animation_tree["parameters/conditions/is_walking"] = false
		animation_tree["parameters/conditions/is_eating"] = false

	# Update blend positions if necessary (depends on your blend tree setup)
	animation_tree["parameters/eat/blend_position"] = velocity
	animation_tree["parameters/walk/blend_position"] = velocity
	animation_tree["parameters/idle/blend_position"] = velocity

