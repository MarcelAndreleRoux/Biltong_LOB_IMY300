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
var food_seen: bool = false
var can_see_food: bool = false
var moving_to_food: bool = false
var food_behind_wall: bool = false

var direction: Vector2 = Vector2.ZERO

var marker_queue: Array = []
var normal_markers: Array = []
var food_markers: Array = []
var pending_food_markers: Array = []
var projectile_buffer: Array = []

func _ready():
	print("Enemy ready")
	animation_tree.active = true
	SharedSignals.start_eating.connect(_should_play_eating)
	SharedSignals.can_move_again.connect(_play_moving)
	SharedSignals.new_marker.connect(_add_new_marker)
	SharedSignals.food_visibility_changed.connect(_on_food_visibility_changed)
	SharedSignals.turtle_spotted_food.connect(_on_turtle_spotted_food)
	SharedSignals.food_not_visible.connect(_on_food_not_visible)

	scared_timer = Timer.new()
	scared_timer.wait_time = 5.0
	scared_timer.one_shot = true
	scared_timer.timeout.connect(_resume_movement_after_scared)
	add_child(scared_timer)

	if marker_queue.size() > 1:
		_get_next_marker()
	else:
		play_moving = false
		is_idle = true

	_initialize_markers()

func _on_food_not_visible(marker: Marker2D):
	print("Food is not visible, ignoring this food marker:", marker.name)
	if food_markers.has(marker):
		food_markers.erase(marker)
		if not pending_food_markers.has(marker):  # Avoid duplicates
			pending_food_markers.append(marker)  # Add to pending
		print("Removed invisible food marker and added to pending:", marker.name)

func _initialize_markers():
	# Initialize normal markers and keep them separate
	normal_markers = get_tree().get_nodes_in_group("FirstEnemy")
	normal_markers = normal_markers.filter(func(marker): return not marker.name.begins_with("Projectile"))
	
	# Duplicate into marker_queue, but marker_queue can be modified during the game
	marker_queue = normal_markers.duplicate()
	
	if marker_queue.size() > 0:
		_get_next_marker()

func _physics_process(_delta):
	if not is_scared and (play_moving or moving_to_food) and not should_eat:
		_update_direction()
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_update_animation_parameters()

func _on_turtle_spotted_food(marker: Marker2D):
	if GlobalValues.food_visible:
		food_seen = true
		print("Food spotted by turtle")

		# Add the visible marker to the queue if it's not already there
		if not food_markers.has(marker):
			food_markers.append(marker)
			print("Visible food marker added, current food markers: ", food_markers)

		# Add the marker to the queue only if it's not already there
		if not marker_queue.has(marker):
			marker_queue.push_front(marker)
			print("Visible marker added to queue: ", marker.name)

		# Handle the turtle's behavior (stopping, playing animations, etc.)
		if can_see_food and GlobalValues.food_visible:
			print("Food is seen stop moving")
			is_hungry = true
			play_moving = false
			_start_delay_before_moving()
		else:
			print("Food is not seen move")
			is_hungry = false
			play_moving = true
			_update_animation_parameters()
	else:
		print("Food is not visible, ignoring this food marker:", marker.name)

func _on_food_visibility_changed(is_visible: bool):
	if is_visible:
		can_see_food = true
		print("Food became visible. Checking markers.")
		# Check the food markers and re-prioritize the turtle's actions
		if food_markers.size() > 0:
			_get_next_marker()
	else:
		can_see_food = false
		is_hungry = false
		play_moving = true
		print("Food is no longer visible. Turtle will ignore it.")

func _update_direction():
	if target_marker and is_instance_valid(target_marker):
		# Stop moving if the target marker becomes invisible
		if target_marker.name.begins_with("Projectile") and not GlobalValues.food_visible:
			print("Stopping movement towards invisible food.")
			is_hungry = false
			should_eat = false
			play_moving = false
			food_behind_wall = true
			_get_next_marker()
			return
		
		var target_position = target_marker.global_position
		direction_to_target = (target_position - global_position).normalized()
		
		direction = direction_to_target
		velocity = direction_to_target * 43

		if global_position.distance_to(target_position) <= 10:
			_reach_marker()
	else:
		play_moving = false
		_get_next_marker()


func _add_new_marker(new_marker: Marker2D):
	if GlobalValues.food_visible:
		# Check for duplicates before adding
		if food_markers.has(new_marker):
			print("Duplicate marker detected: ", new_marker.name)
			return

		# Add visible food markers only
		if new_marker.name.begins_with("Projectile") and GlobalValues.food_visible:
			food_markers.append(new_marker)
			print("Visible food marker added, current food markers: ", food_markers)

			# Trigger turtle to respond if it's not busy eating or scared
			if not is_scared and not should_eat and projectile_buffer.size() == 0:
				# If not scared or eating and no buffer, move to the new marker immediately
				marker_queue.push_front(new_marker)  # Prioritize the food marker
				_start_delay_before_moving()  # Wait 3 seconds before moving toward the food
			elif is_scared or should_eat or projectile_buffer.size() > 0:
				# Add the projectile to the buffer if scared or already eating
				projectile_buffer.append(new_marker)
		else:
			print("Invisible food marker ignored.")

func _start_delay_before_moving():
	is_idle = false
	is_hungry = true
	play_moving = false

	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_start_moving_after_delay)
	add_child(timer)
	timer.start()

func _start_moving_after_delay():
	is_hungry = false
	moving_to_food = true
	_get_next_marker()

func _reach_marker():
	velocity = Vector2.ZERO
	moving_to_food = false
	play_moving = false

	if target_marker and is_instance_valid(target_marker) and target_marker.name.begins_with("Projectile"):
		should_eat = true
		_create_eating_timer()
	else:
		if marker_queue.size() > 1:
			should_eat = true
			_create_turn_timer()
		else:
			should_eat = false
			is_idle = true
			play_moving = false

func _create_eating_timer():
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(_finish_eating)
	add_child(timer)
	timer.start()
	
func _finish_eating():
	should_eat = false
	moving_to_food = false
	food_behind_wall = false
	SharedSignals.can_move_again.emit()

	_on_food_eaten()

	# Reset food_seen and can_see_food to ensure the turtle only targets new food
	food_seen = false
	can_see_food = false

	# Call to get the next marker after food is finished
	_get_next_marker()

func _on_food_eaten():
	if target_marker and is_instance_valid(target_marker):
		print("Removing eaten food marker: ", target_marker.name)

		# Remove only the specific marker from food_markers
		for marker in food_markers:
			if marker == target_marker:
				food_markers.erase(marker)
				break  # Exit the loop after removing the specific marker

		# Remove the marker from marker_queue if it's present
		for marker in marker_queue:
			if marker == target_marker:
				marker_queue.erase(marker)
				break  # Exit the loop after removing the specific marker

		# Now free the specific marker
		target_marker.queue_free()
		target_marker = null  # Ensure target_marker is set to null to avoid further access

	# After the food is eaten, get the next marker
	_get_next_marker()

func _create_turn_timer():
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(_can_move_again)
	add_child(timer)
	timer.start()

func _can_move_again():
	should_eat = false
	_get_next_marker()

func _get_next_marker():
	print("Getting next marker...")
	print("Food markers: ", food_markers)
	print("Marker queue: ", marker_queue)
	print("Projectile buffer: ", projectile_buffer)

	# Clean up any freed objects in food_markers, marker_queue, and projectile_buffer
	food_markers = food_markers.filter(func(marker): return is_instance_valid(marker))
	marker_queue = marker_queue.filter(func(marker): return is_instance_valid(marker))
	projectile_buffer = projectile_buffer.filter(func(marker): return is_instance_valid(marker))

	# Process the buffer first if it has entries
	if projectile_buffer.size() > 0:
		if is_instance_valid(projectile_buffer.front()):
			print("Processing projectile from buffer: ", projectile_buffer.front().name)
			target_marker = projectile_buffer.pop_front()
			play_moving = true
			return
		else:
			print("Invalid buffered projectile, skipping.")

	# If the buffer is empty, revert to processing food markers or normal markers
	if food_markers.size() == 0 and marker_queue.size() == 0:
		print("No markers available.")
		target_marker = null
		play_moving = false  # Stop moving if no markers are available
		return

	# Prioritize food markers if they are visible
	if food_markers.size() > 0 and GlobalValues.food_visible and not food_behind_wall:
		if is_instance_valid(food_markers.front()):
			print("Food marker found, moving towards: ", food_markers.front().name)
			target_marker = food_markers.pop_front()
			play_moving = true
			return
		else:
			print("Invalid food marker detected, skipping.")

	# No valid or visible food markers, revert to normal markers
	if marker_queue.size() > 0 and is_instance_valid(marker_queue.front()):
		print("No food markers, selecting normal marker: ", marker_queue.front().name)
		target_marker = marker_queue.front()

		# Manual rotation: Move the first element to the end to keep the patrol order
		var first_marker = marker_queue.pop_front()
		if is_instance_valid(first_marker):
			marker_queue.append(first_marker)
		play_moving = true  # Start moving toward the normal marker
	else:
		print("No more markers left, waiting for markers...")
		food_behind_wall = false
		target_marker = null
		play_moving = false  # Stop moving if no valid markers exist

	direction_to_target = Vector2.ZERO

	# Check target_marker validity before printing
	if is_instance_valid(target_marker):
		print("Target marker is now: ", target_marker.name)
	else:
		print("No valid target marker found.")

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
	elif play_moving or moving_to_food:
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
	animation_tree["parameters/eat/blend_position"] = direction
	animation_tree["parameters/walk/blend_position"] = direction
	animation_tree["parameters/idle/blend_position"] = direction
	animation_tree["parameters/hungry/blend_position"] = direction
	animation_tree["parameters/Shell/blend_position"] = direction

func _on_scared_area_body_entered(body):
	if body.is_in_group("player"):
		is_scared = true
		SharedSignals.turtle_is_scared.emit(true)
		player_was_in_area = true
		play_moving = false
		_update_animation_parameters()
		
		if scared_timer.is_stopped():
			scared_timer.start()
		else:
			scared_timer.stop()
			scared_timer.start()

func _on_scared_area_body_exited(body):
	if body.is_in_group("player") and not player_was_in_area:
		is_scared = false 
		SharedSignals.turtle_is_scared.emit(false)
		_update_animation_parameters()

func _resume_movement_after_scared():
	is_scared = false
	play_moving = true
	player_was_in_area = false
	_update_animation_parameters()
