extends CharacterBody2D

# --- Exported Variables ---

@export var target_1: Node2D = null
@export var target_2: Node2D = null
@export var target_3: Node2D = null
@export var target_4: Node2D = null
@export var target_5: Node2D = null

@export var play_hungry_animation: bool = true  # Toggle for hungry animation
@export var speed: float = 50.0  # Speed of the turtle

# --- Onready Variables ---

@onready var animation_tree = $AnimationTree
@onready var navigation_agent_2d = $TurtleNav
@onready var scared_area = $ScaredArea  # Reference to the scared Area2D

# --- Internal Variables ---

var direction: Vector2 = Vector2.ZERO

var current_food_target: Node2D = null

var patrol_points: Array = []
var patrol_index: int = 0

# Define the turtle's possible states
enum State {
	PATROL,
	PATROL_WAIT,
	HUNGRY,
	GO_TO_FOOD,
	EATING,
	IDLE,
	SCARED
}

var state = State.IDLE

# Timers for handling state transitions
var patrol_wait_timer: Timer = null
var hungry_timer: Timer = null
var eating_timer: Timer = null
var scared_timer: Timer = null

# --- Ready Function ---

func _ready():
	print("Turtle ready")
	
	# Collect patrol points, skipping any that are not assigned
	_collect_patrol_points()
	
	# Set initial state based on the availability of patrol points
	if patrol_points.size() > 0:
		state = State.PATROL
		patrol_index = 0
		navigation_agent_2d.target_position = patrol_points[patrol_index]
		print("Initial State: PATROL | Targeting Patrol Point ", patrol_index + 1)
	else:
		state = State.IDLE
		print("Initial State: IDLE | No Patrol Points Assigned")

# --- Patrol Points Collection ---

func _collect_patrol_points():
	patrol_points.clear()
	for i in range(1, 6):
		var target = self.get("target_%d" % i)
		if target:
			patrol_points.append(target.global_position)
			print("Collected Patrol Point ", i, ": ", target.global_position)
		else:
			print("Patrol Point ", i, " is not assigned and will be skipped.")

# --- Physics Process ---

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
			idle_behavior()
		State.SCARED:
			scared_behavior()
	
	# Update movement based on velocity
	velocity = direction * speed if state in [State.PATROL, State.GO_TO_FOOD] else Vector2.ZERO
	move_and_slide()
	
	# Update direction for animations
	direction = velocity.normalized() if velocity.length() > 0 else Vector2.ZERO
	_update_animation_parameters()

# --- Patrol Behavior ---

func patrol_behavior():
	print("State: PATROL | Current Patrol Point: ", patrol_index + 1)
	
	# Check for food before continuing patrol
	if check_for_food():
		print("Food detected! Switching to HUNGRY or GO_TO_FOOD state.")
		velocity = Vector2.ZERO
		if play_hungry_animation:
			state = State.HUNGRY
			start_hungry_timer()
		else:
			state = State.GO_TO_FOOD
			navigation_agent_2d.target_position = current_food_target.global_position
		return
	
	# Continue moving towards the patrol point
	if navigation_agent_2d.is_navigation_finished():
		print("Reached Patrol Point ", patrol_index + 1, ". Switching to PATROL_WAIT.")
		state = State.PATROL_WAIT
		start_patrol_wait_timer()
	else:
		# Move towards patrol point
		var next_path_position = navigation_agent_2d.get_next_path_position()
		direction = (next_path_position - global_position).normalized()
		print("Navigating towards Patrol Point ", patrol_index + 1, " | Next Path Position: ", next_path_position)


# --- Patrol Wait Timer ---

func start_patrol_wait_timer():
	# Start a timer to wait for 1 second before moving to the next patrol point
	patrol_wait_timer = Timer.new()
	patrol_wait_timer.wait_time = 1.0  # Wait 1 second
	patrol_wait_timer.one_shot = true
	patrol_wait_timer.timeout.connect(_on_patrol_wait_timeout)
	add_child(patrol_wait_timer)
	patrol_wait_timer.start()
	print("Started Patrol Wait Timer for 1 second.")

func _on_patrol_wait_timeout():
	patrol_wait_timer.queue_free()
	patrol_wait_timer = null
	# Move to next patrol point
	patrol_index = (patrol_index + 1) % patrol_points.size()
	navigation_agent_2d.target_position = patrol_points[patrol_index]
	print("Patrol Wait Timer Ended. Moving to Patrol Point ", patrol_index + 1)
	# Switch back to PATROL state
	state = State.PATROL

# --- Idle Behavior ---

func idle_behavior():
	print("State: IDLE | Searching for Food.")
	# In IDLE state, continuously search for food
	if check_for_food():
		print("Food detected in IDLE state! Switching to HUNGRY or GO_TO_FOOD state.")
		velocity = Vector2.ZERO
		if play_hungry_animation:
			state = State.HUNGRY
			start_hungry_timer()
		else:
			state = State.GO_TO_FOOD
			navigation_agent_2d.target_position = current_food_target.global_position
	else:
		# Remain idle if no food is found
		velocity = Vector2.ZERO
		print("No food found. Remaining in IDLE state.")

# --- Go To Food Behavior ---

func go_to_food_behavior():
	print("State: GO_TO_FOOD | Moving towards Food.")
	
	# Check if food is still valid
	if current_food_target == null or not is_instance_valid(current_food_target):
		print("Food target no longer exists. Returning to PATROL state.")
		state = State.PATROL
		if patrol_points.size() > 0:
			navigation_agent_2d.target_position = patrol_points[patrol_index]
		else:
			state = State.IDLE
		return
	
	if navigation_agent_2d.is_navigation_finished():
		print("Reached Food. Switching to EATING state.")
		current_food_target.queue_free()
		current_food_target = null
		state = State.EATING
		start_eating_timer()
	else:
		# Continue moving towards food
		var next_path_position = navigation_agent_2d.get_next_path_position()
		direction = (next_path_position - global_position).normalized()
		print("Navigating towards Food at Position: ", next_path_position)

# --- Eating Timer ---

func start_eating_timer():
	# Start a timer to simulate eating duration
	eating_timer = Timer.new()
	eating_timer.wait_time = 3.0  # Wait 3 seconds
	eating_timer.one_shot = true
	eating_timer.timeout.connect(_on_eating_timeout)
	add_child(eating_timer)
	eating_timer.start()
	print("Started Eating Timer for 3 seconds.")

func _on_eating_timeout():
	eating_timer.queue_free()
	eating_timer = null
	print("Finished Eating. Checking for more food.")
	# After eating, check for more food
	if check_for_food():
		if play_hungry_animation:
			state = State.HUNGRY
			start_hungry_timer()
		else:
			state = State.GO_TO_FOOD
			navigation_agent_2d.target_position = current_food_target.global_position
	else:
		if patrol_points.size() > 0:
			state = State.PATROL
			navigation_agent_2d.target_position = patrol_points[patrol_index]
			print("No more food. Returning to PATROL state.")
		else:
			state = State.IDLE
			print("No patrol points. Switching to IDLE state.")

# --- Hungry Timer ---

func start_hungry_timer():
	# Start a timer to simulate being hungry before moving to food
	hungry_timer = Timer.new()
	hungry_timer.wait_time = 3.0  # Wait 3 seconds
	hungry_timer.one_shot = true
	hungry_timer.timeout.connect(_on_hungry_timeout)
	add_child(hungry_timer)
	hungry_timer.start()
	print("Started Hungry Timer for 3 seconds.")

func _on_hungry_timeout():
	hungry_timer.queue_free()
	hungry_timer = null
	print("Hungry Timer Ended. Moving to GO_TO_FOOD state.")
	if current_food_target != null and is_instance_valid(current_food_target):
		navigation_agent_2d.target_position = current_food_target.global_position
		state = State.GO_TO_FOOD
	else:
		print("No valid food target found. Returning to PATROL state.")
		state = State.PATROL
		if patrol_points.size() > 0:
			navigation_agent_2d.target_position = patrol_points[patrol_index]
		else:
			state = State.IDLE

# --- Scared State Handling ---

func _on_scared_area_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered Scared Area. Switching to SCARED state.")
		state = State.SCARED
		velocity = Vector2.ZERO  # Stop movement
		_update_animation_parameters()

func _on_scared_area_body_exited(body):
	if body.is_in_group("player"):
		print("Player exited Scared Area. Starting Scared Timer to return to normal state.")
		if scared_timer == null:
			scared_timer = Timer.new()
			scared_timer.wait_time = 3.0  # Wait 3 seconds
			scared_timer.one_shot = true
			scared_timer.timeout.connect(_on_scared_timeout)
			add_child(scared_timer)
			scared_timer.start()

func scared_behavior():
	print("State: SCARED | Turtle is scared and not moving.")
	velocity = Vector2.ZERO
	# Optionally, add logic to move away from the player

func _on_scared_timeout():
	scared_timer.queue_free()
	scared_timer = null
	print("Scared Timer Ended. Returning to previous state.")
	# After being scared, return to previous behavior
	if check_for_food():
		if play_hungry_animation:
			state = State.HUNGRY
			start_hungry_timer()
		else:
			state = State.GO_TO_FOOD
			navigation_agent_2d.target_position = current_food_target.global_position
	else:
		if patrol_points.size() > 0:
			state = State.PATROL
			navigation_agent_2d.target_position = patrol_points[patrol_index]
			print("Returning to PATROL state after SCARED.")
		else:
			state = State.IDLE
			print("No patrol points. Switching to IDLE state after SCARED.")

# --- Food Detection Function ---

func check_for_food() -> bool:
	var food_nodes = get_tree().get_nodes_in_group("food_to_eat")
	
	if food_nodes.size() > 0:
		# Find the closest food
		var closest_food: Node2D = null
		var closest_distance: float = INF
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
				print("Found new food target at: ", current_food_target.global_position)
				return true
			else:
				# Already have a food target
				return false
	
	return false

# --- Animation Handling ---

func _update_animation_parameters():
	# Reset all animation conditions
	animation_tree.set("parameters/conditions/is_scared", false)
	animation_tree.set("parameters/conditions/is_walking", false)
	animation_tree.set("parameters/conditions/is_eating", false)
	animation_tree.set("parameters/conditions/is_idle", false)
	animation_tree.set("parameters/conditions/is_hungry", false)
	animation_tree.set("parameters/conditions/is_patrol_wait", false)  # New parameter
	
	match state:
		State.SCARED:
			animation_tree.set("parameters/conditions/is_scared", true)
			print("Animation: is_scared set to true")
		State.HUNGRY:
			animation_tree.set("parameters/conditions/is_hungry", true)
			print("Animation: is_hungry set to true")
		State.EATING:
			animation_tree.set("parameters/conditions/is_eating", true)
			print("Animation: is_eating set to true")
		State.PATROL_WAIT:
			animation_tree.set("parameters/conditions/is_patrol_wait", true)  # Set new parameter
			print("Animation: is_patrol_wait set to true")
		State.PATROL, State.GO_TO_FOOD:
			if velocity.length() > 0:
				animation_tree.set("parameters/conditions/is_walking", true)
				print("Animation: is_walking set to true")
			else:
				animation_tree.set("parameters/conditions/is_idle", true)
				print("Animation: is_idle set to true")
		State.IDLE:
			animation_tree.set("parameters/conditions/is_idle", true)
			print("Animation: is_idle set to true")
	
	# Update blend positions (if applicable)
	animation_tree.set("parameters/walk/blend_position", direction)
	animation_tree.set("parameters/eat/blend_position", direction)
	animation_tree.set("parameters/idle/blend_position", direction)
	animation_tree.set("parameters/hungry/blend_position", direction)
	
	print("Blend Positions Updated | Direction: ", direction)
