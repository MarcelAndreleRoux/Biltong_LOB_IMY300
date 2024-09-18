extends CharacterBody2D

@export var wander_direction: Node2D
@export var turn_speed: float = 5.0
@onready var animation_tree = $AnimationTree

var should_eat: bool = false
var play_moving: bool = false
var target_marker: Marker2D
var direction_to_target: Vector2 = Vector2.ZERO
var is_idle: bool = false
var is_hungry: bool = false
var is_scared: bool = false
var scared_timer: Timer
var player_was_in_area: bool = false

func _ready():
	print("Enemy ready")
	animation_tree.active = true
	SharedSignals.start_eating.connect(_should_play_eating)
	SharedSignals.can_move_again.connect(_play_moving)
	SharedSignals.new_marker.connect(_set_new_target)

	# Add scared timer and connect its timeout signal
	scared_timer = Timer.new()
	scared_timer.wait_time = 5.0
	scared_timer.one_shot = true
	scared_timer.timeout.connect(_resume_movement_after_scared)
	add_child(scared_timer)

	_get_next_marker()

func _physics_process(_delta):
	if not is_scared and play_moving and not should_eat:
		_update_direction()
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_update_animation_parameters()

func _update_direction():
	if target_marker and is_instance_valid(target_marker):
		var target_position = target_marker.global_position
		direction_to_target = (target_position - global_position).normalized()

		velocity = direction_to_target * 43

		if global_position.distance_to(target_position) <= 10:
			_reach_marker()
	else:
		play_moving = false
		_get_next_marker()

func _set_new_target(new_marker: Marker2D):
	# Assign a new target (such as a mushroom), even if idle or turning
	target_marker = new_marker
	direction_to_target = Vector2.ZERO  # Reset direction
	# Immediately begin moving toward the target if not busy
	if not should_eat and not is_scared:
		play_moving = true

	# Stop movement and start the hungry animation before moving again
	play_moving = false
	is_hungry = true
	_start_delay_before_moving()

func _start_delay_before_moving():
	is_idle = false
	is_hungry = true

	# Delay before resuming movement
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_start_moving_after_delay)
	add_child(timer)
	timer.start()

func _start_moving_after_delay():
	is_hungry = false
	play_moving = true

func _reach_marker():
	# Reached the marker (could be the mushroom or another target)
	velocity = Vector2.ZERO
	play_moving = false

	# Check if the marker is a projectile (like the mushroom)
	if target_marker and is_instance_valid(target_marker) and target_marker.name.begins_with("Projectile"):
		should_eat = true
		_create_eating_timer()
	else:
		_create_turn_timer()

func _create_eating_timer():
	# Timer for eating the mushroom
	var timer = Timer.new()
	timer.wait_time = 5.0  # Eating duration
	timer.one_shot = true
	timer.timeout.connect(_finish_eating)
	add_child(timer)
	timer.start()

func _finish_eating():
	should_eat = false
	SharedSignals.can_move_again.emit()
	if target_marker and target_marker != null:
		target_marker.queue_free()  # Remove the mushroom after eating
	target_marker = null
	_get_next_marker()

func _create_turn_timer():
	# This is the section where it previously ignored items
	var timer = Timer.new()
	timer.wait_time = 1  # Pause duration before moving to the next marker
	timer.one_shot = true
	timer.timeout.connect(_can_move_again)
	add_child(timer)
	timer.start()

	# Force recheck for markers like the mushroom, even while turning
	_check_for_new_projectiles()

func _check_for_new_projectiles():
	# Force recheck of nearby projectiles (such as the mushroom) during idle/wait
	var markers = get_tree().get_nodes_in_group("FirstEnemy")
	for marker in markers:
		if marker.name.begins_with("Projectile"):
			_set_new_target(marker)
			break

func _can_move_again():
	_get_next_marker()

func _get_next_marker():
	var markers = get_tree().get_nodes_in_group("FirstEnemy")
	if markers.size() > 0:
		var next_marker_index = (markers.find(target_marker) + 1) % markers.size()
		target_marker = markers[next_marker_index]
		direction_to_target = Vector2.ZERO
		play_moving = true

func _should_play_eating():
	should_eat = true
	play_moving = false

func _play_moving():
	play_moving = true
	should_eat = false

func _update_animation_parameters():
	if is_scared:
		animation_tree["parameters/conditions/is_scared"] = true
		animation_tree["parameters/conditions/is_walking"] = false
		animation_tree["parameters/conditions/is_eating"] = false
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_hungry"] = false
	elif is_hungry:
		animation_tree["parameters/conditions/is_hungry"] = true
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_walking"] = false
		animation_tree["parameters/conditions/is_eating"] = false
		animation_tree["parameters/conditions/is_scared"] = false
	elif should_eat:
		animation_tree["parameters/conditions/is_eating"] = true
		animation_tree["parameters/conditions/is_walking"] = false
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_hungry"] = false
		animation_tree["parameters/conditions/is_scared"] = false
	elif play_moving:
		animation_tree["parameters/conditions/is_walking"] = true
		animation_tree["parameters/conditions/is_eating"] = false
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_hungry"] = false
		animation_tree["parameters/conditions/is_scared"] = false
	else:
		animation_tree["parameters/conditions/is_idle"] = true
		animation_tree["parameters/conditions/is_walking"] = false
		animation_tree["parameters/conditions/is_eating"] = false
		animation_tree["parameters/conditions/is_hungry"] = false
		animation_tree["parameters/conditions/is_scared"] = false

	# Update blend positions if necessary
	animation_tree["parameters/eat/blend_position"] = velocity
	animation_tree["parameters/walk/blend_position"] = velocity
	animation_tree["parameters/idle/blend_position"] = velocity
	animation_tree["parameters/hungry/blend_position"] = velocity
	animation_tree["parameters/Shell/blend_position"] = velocity

# Handle scared behavior: stop moving and start scared timer
func _on_scared_area_body_entered(body):
	if body.is_in_group("player"):
		is_scared = true
		player_was_in_area = true
		play_moving = false
		_update_animation_parameters()
		
		# Reset the timer if the player re-enters the scared area
		if scared_timer.is_stopped():
			scared_timer.start()
		else:
			scared_timer.stop()
			scared_timer.start()

# Handle player exiting the scared area
func _on_scared_area_body_exited(body):
	if body.is_in_group("player") and not player_was_in_area:
		is_scared = false 
		_update_animation_parameters()

# Resume movement after being scared
func _resume_movement_after_scared():
	is_scared = false
	play_moving = true
	player_was_in_area = false
	_update_animation_parameters()
