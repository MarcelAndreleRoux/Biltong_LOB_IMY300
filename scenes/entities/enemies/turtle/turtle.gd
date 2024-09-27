extends CharacterBody2D

@onready var animation_tree = $AnimationTree
@onready var navigation_agent_2d = $TurtleNav

# Exported variables for patrol points (markers)
@export var target_1: Node2D = null
@export var target_2: Node2D = null
@export var target_3: Node2D = null
@export var target_4: Node2D = null
@export var target_5: Node2D = null

var speed: float = 50.0  # Speed of the turtle

# State enumeration for managing turtle's behavior
enum State {
	PATROLLING,
	WAITING,
	GOING_TO_FOOD,
	EATING_FOOD
}

var state = State.PATROLLING  # Initial state
var patrol_points = []
var patrol_index = 0

var current_food_target: Node2D = null  # Reference to the food instance
var direction: Vector2 = Vector2.ZERO  # Direction of movement

# Animation flags
var is_scared: bool = false
var is_hungry: bool = false

func _ready():
	# Collect patrol points
	if target_1:
		patrol_points.append(target_1.global_position)
	if target_2:
		patrol_points.append(target_2.global_position)
	if target_3:
		patrol_points.append(target_3.global_position)
	if target_4:
		patrol_points.append(target_4.global_position)
	if target_5:
		patrol_points.append(target_5.global_position)
	
	if patrol_points.size() > 0:
		# Set the initial target position for the navigation agent
		navigation_agent_2d.target_position = patrol_points[patrol_index]
		set_physics_process(true)
	else:
		set_physics_process(false)
		print("No patrol points set for turtle.")
	
	# Connect to the signal emitted when food is thrown
	SharedSignals.food_projectile_thrown.connect(_on_food_thrown)

func _physics_process(delta):
	match state:
		State.PATROLLING:
			if navigation_agent_2d.is_navigation_finished():
				_on_patrol_point_reached()
			else:
				_move_along_path()
		State.WAITING:
			# Waiting at patrol point; do nothing
			pass
		State.GOING_TO_FOOD:
			if current_food_target == null or not is_instance_valid(current_food_target):
				# Food is gone; resume patrolling
				navigation_agent_2d.target_position = patrol_points[patrol_index]
				state = State.PATROLLING
				is_hungry = false
			else:
				navigation_agent_2d.target_position = current_food_target.global_position
				if navigation_agent_2d.is_navigation_finished():
					_on_food_reached()
				else:
					_move_along_path()
		State.EATING_FOOD:
			# Eating food; do nothing
			pass

	_update_animation_parameters()

func _move_along_path():
	var next_path_position = navigation_agent_2d.get_next_path_position()
	var current_position = global_position
	direction = (next_path_position - current_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _on_patrol_point_reached():
	state = State.WAITING
	velocity = Vector2.ZERO
	# Start a timer to wait for 1 second (eating animation)
	var wait_timer = Timer.new()
	wait_timer.wait_time = 1.0
	wait_timer.one_shot = true
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	add_child(wait_timer)
	wait_timer.start()
	# Set flag to play the eating animation
	# Note: In the animation parameters, 'is_eating' will be set based on the state

func _on_wait_timer_timeout():
	if state == State.WAITING:
		# Finished waiting at patrol point; move to next point
		patrol_index = (patrol_index + 1) % patrol_points.size()
		navigation_agent_2d.target_position = patrol_points[patrol_index]
		state = State.PATROLLING
	elif state == State.EATING_FOOD:
		# Finished eating food; resume patrol
		patrol_index = (patrol_index + 1) % patrol_points.size()
		navigation_agent_2d.target_position = patrol_points[patrol_index]
		state = State.PATROLLING

func _on_food_thrown(food_instance):
	# React to thrown food
	current_food_target = food_instance
	navigation_agent_2d.target_position = current_food_target.global_position
	state = State.GOING_TO_FOOD
	is_hungry = true  # Set flag to play the hungry animation

func _on_food_reached():
	state = State.EATING_FOOD
	velocity = Vector2.ZERO
	is_hungry = false  # No longer hungry; will stop playing hungry animation
	# Remove the food instance
	if current_food_target and is_instance_valid(current_food_target):
		current_food_target.queue_free()
		current_food_target = null
	# Start a timer to wait for 4 seconds (eating animation)
	var eat_timer = Timer.new()
	eat_timer.wait_time = 4.0
	eat_timer.one_shot = true
	eat_timer.timeout.connect(_on_wait_timer_timeout)
	add_child(eat_timer)
	eat_timer.start()
	# Set flag to play the eating animation

func _update_animation_parameters():
	# Reset all animation conditions
	animation_tree["parameters/conditions/is_scared"] = false
	animation_tree["parameters/conditions/is_hungry"] = false
	animation_tree["parameters/conditions/is_eating"] = false
	animation_tree["parameters/conditions/is_walking"] = false
	animation_tree["parameters/conditions/is_idle"] = false

	if is_scared:
		animation_tree["parameters/conditions/is_scared"] = true
	elif state == State.PATROLLING:
		animation_tree["parameters/conditions/is_walking"] = true
	elif state == State.WAITING:
		animation_tree["parameters/conditions/is_eating"] = true  # Play eat animation
	elif state == State.GOING_TO_FOOD:
		animation_tree["parameters/conditions/is_walking"] = true
		if is_hungry:
			animation_tree["parameters/conditions/is_hungry"] = true
	elif state == State.EATING_FOOD:
		animation_tree["parameters/conditions/is_eating"] = true  # Play eat animation
	else:
		animation_tree["parameters/conditions/is_idle"] = true  # Default to idle

	# Update blend positions for directional animations
	animation_tree["parameters/eat/blend_position"] = direction
	animation_tree["parameters/walk/blend_position"] = direction
	animation_tree["parameters/idle/blend_position"] = direction
	animation_tree["parameters/hungry/blend_position"] = direction
	animation_tree["parameters/Shell/blend_position"] = direction
