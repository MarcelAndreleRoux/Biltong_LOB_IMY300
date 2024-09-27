extends CharacterBody2D

@onready var animation_tree = $AnimationTree
@onready var navigation_agent_2d = $TurtleNav

@export var target_1: Node2D = null
@export var target_2: Node2D = null
@export var target_3: Node2D = null
@export var target_4: Node2D = null
@export var target_5: Node2D = null

@export var play_hungry_animation: bool = true  # Toggle for hungry animation

var speed = 50

var direction: Vector2 = Vector2.ZERO
var current_food_target: Node2D = null

var patrol_points = []
var patrol_index = 0

var is_hungry: bool = false
var should_eat: bool = false

# Define the turtle's possible states
enum State {
	PATROL,
	PATROL_WAIT,
	HUNGRY,
	GO_TO_FOOD,
	EATING,
	IDLE
}

var state = State.IDLE

# Timers for handling waiting periods
var patrol_wait_timer = null
var hungry_timer = null
var eating_timer = null

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
	
	# Set initial state
	if patrol_points.size() > 0:
		state = State.PATROL
		navigation_agent_2d.target_position = patrol_points[patrol_index]
	else:
		state = State.IDLE

func _physics_process(delta):
	match state:
		State.PATROL:
			patrol_behavior()
		State.PATROL_WAIT:
			# Waiting at patrol point; timer will handle transition
			pass
		State.HUNGRY:
			# Playing hungry animation; timer will handle transition
			pass
		State.GO_TO_FOOD:
			go_to_food_behavior()
		State.EATING:
			# Eating food; timer will handle transition
			pass
		State.IDLE:
			# Idle state
			velocity = Vector2.ZERO

	# Update movement
	move_and_slide()

	# Update direction for animations
	if velocity.length() > 0:
		direction = velocity.normalized()
	_update_animation_parameters()

func patrol_behavior():
	# Check for food
	if check_for_food():
		# Found food, switch to HUNGRY or GO_TO_FOOD state
		velocity = Vector2.ZERO
		if play_hungry_animation:
			state = State.HUNGRY
			start_hungry_timer()
		else:
			state = State.GO_TO_FOOD
			navigation_agent_2d.target_position = current_food_target.global_position
	else:
		# Continue patrolling
		if navigation_agent_2d.is_navigation_finished():
			# Reached patrol point, start wait timer
			velocity = Vector2.ZERO
			state = State.PATROL_WAIT
			start_patrol_wait_timer()
		else:
			# Move towards patrol point
			var next_path_position = navigation_agent_2d.get_next_path_position()
			velocity = (next_path_position - global_position).normalized() * speed

func go_to_food_behavior():
	# Check if food is still valid
	if current_food_target == null or not is_instance_valid(current_food_target):
		# Food no longer exists, return to patrol
		state = State.PATROL
		navigation_agent_2d.target_position = patrol_points[patrol_index]
	else:
		if navigation_agent_2d.is_navigation_finished():
			# Reached food, start eating
			current_food_target.queue_free()
			current_food_target = null
			velocity = Vector2.ZERO
			state = State.EATING
			start_eating_timer()
		else:
			# Move towards food
			var next_path_position = navigation_agent_2d.get_next_path_position()
			velocity = (next_path_position - global_position).normalized() * speed

func check_for_food():
	var food_nodes = get_tree().get_nodes_in_group("food_to_eat")
	if food_nodes.size() > 0:
		# Find the closest food
		var closest_food = null
		var closest_distance = INF
		for food in food_nodes:
			var distance = global_position.distance_to(food.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_food = food
		if closest_food != null:
			if current_food_target == null:
				# This is the first food target, set it
				current_food_target = closest_food
				navigation_agent_2d.target_position = current_food_target.global_position
				return true
			else:
				# Already have a food target
				return false
	else:
		return false

func start_patrol_wait_timer():
	patrol_wait_timer = Timer.new()
	patrol_wait_timer.wait_time = 1.0  # Wait 1 second
	patrol_wait_timer.one_shot = true
	patrol_wait_timer.timeout.connect(_on_patrol_wait_timeout)
	add_child(patrol_wait_timer)
	patrol_wait_timer.start()

func _on_patrol_wait_timeout():
	patrol_wait_timer.queue_free()
	patrol_wait_timer = null
	# Move to next patrol point
	patrol_index = (patrol_index + 1) % patrol_points.size()
	navigation_agent_2d.target_position = patrol_points[patrol_index]
	state = State.PATROL

func start_hungry_timer():
	is_hungry = true
	hungry_timer = Timer.new()
	hungry_timer.wait_time = 3.0  # Wait 3 seconds
	hungry_timer.one_shot = true
	hungry_timer.timeout.connect(_on_hungry_timeout)
	add_child(hungry_timer)
	hungry_timer.start()

func _on_hungry_timeout():
	hungry_timer.queue_free()
	hungry_timer = null
	is_hungry = false
	if current_food_target != null and is_instance_valid(current_food_target):
		navigation_agent_2d.target_position = current_food_target.global_position
		state = State.GO_TO_FOOD
	else:
		# Food no longer exists, return to patrol
		state = State.PATROL
		navigation_agent_2d.target_position = patrol_points[patrol_index]

func start_eating_timer():
	should_eat = true
	eating_timer = Timer.new()
	eating_timer.wait_time = 3.0  # Wait 3 seconds
	eating_timer.one_shot = true
	eating_timer.timeout.connect(_on_eating_timeout)
	add_child(eating_timer)
	eating_timer.start()

func _on_eating_timeout():
	eating_timer.queue_free()
	eating_timer = null
	should_eat = false
	# Check for more food
	if check_for_food():
		# If hungry animation is enabled and we haven't played it yet, play it
		if play_hungry_animation and state != State.HUNGRY:
			state = State.HUNGRY
			velocity = Vector2.ZERO
			start_hungry_timer()
		else:
			state = State.GO_TO_FOOD
			navigation_agent_2d.target_position = current_food_target.global_position
	else:
		# No more food, return to patrol
		state = State.PATROL
		navigation_agent_2d.target_position = patrol_points[patrol_index]

func _update_animation_parameters():
	# Reset all conditions
	animation_tree["parameters/conditions/is_scared"] = false
	animation_tree["parameters/conditions/is_walking"] = false
	animation_tree["parameters/conditions/is_eating"] = false
	animation_tree["parameters/conditions/is_idle"] = false
	animation_tree["parameters/conditions/is_hungry"] = false

	if state == State.HUNGRY:
		animation_tree["parameters/conditions/is_hungry"] = true
	elif state == State.EATING or state == State.PATROL_WAIT:
		animation_tree["parameters/conditions/is_eating"] = true
	elif state == State.PATROL or state == State.GO_TO_FOOD:
		if velocity.length() > 0:
			animation_tree["parameters/conditions/is_walking"] = true
		else:
			animation_tree["parameters/conditions/is_idle"] = true
	elif state == State.IDLE:
		animation_tree["parameters/conditions/is_idle"] = true

	# Update blend positions
	animation_tree["parameters/eat/blend_position"] = direction
	animation_tree["parameters/walk/blend_position"] = direction
	animation_tree["parameters/idle/blend_position"] = direction
	animation_tree["parameters/hungry/blend_position"] = direction
	animation_tree["parameters/Shell/blend_position"] = direction
