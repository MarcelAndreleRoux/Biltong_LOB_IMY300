extends Node2D

@export var group_name: String
@export var speed: float = 50.0  # Define the speed of the enemy
@export var eating_distance: float = 15.0  # Distance to start eating

var positions: Array = []
var temp_positions: Array = []
var current_position: Marker2D
var current_food_marker: Marker2D = null  # Track the current food marker

var direction: Vector2 = Vector2.ZERO
var is_eating: bool = false
var is_scared: bool = false
var food_visible: bool = false

var food_markers: Array = []  # Array to track active food markers
var marker_queue: Array = []  # Array to manage the turtle's movement through markers
var pending_food_markers: Array = []  # Array to store food markers that are not immediately visible
var projectile_buffer: Array = []

const STOPPING_DISTANCE = 10

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)
	_sort_positions()

	# If no markers are available initially, wait until a marker appears
	if positions.size() != 0:
		_get_positions()
		_get_next_position()

	SharedSignals.projectile_gone.connect(_remove_marker)
	SharedSignals.food_visibility_changed.connect(_on_food_visibility_changed)
	SharedSignals.turtle_is_scared.connect(_change_scared_status)

func _physics_process(delta):
	if is_eating or current_position == null:
		return  # If eating or no target, do not move

	var distance_to_target = global_position.distance_to(current_position.global_position)

	if distance_to_target <= STOPPING_DISTANCE:
		global_position = current_position.global_position
		_handle_reached_marker()
	else:
		move_towards_position(delta)

func _change_scared_status(status: bool):
	is_scared = status

func _on_food_visibility_changed(is_visible: bool):
	food_visible = is_visible

	if food_visible:
		# Move pending markers to active queue when they become visible
		for marker in pending_food_markers:
			if !food_markers.has(marker):
				food_markers.append(marker)
				marker_queue.push_front(marker)  # Prioritize the visible food marker
				pending_food_markers.erase(marker)  # Remove from pending list

		# Immediately switch to the first food marker if visible
		if food_markers.size() > 0:
			current_position = food_markers.front()  # Immediately switch to the food marker
			_update_direction()  # Start moving toward the food
			is_eating = false  # Make sure we are not in the eating state
			move_towards_position(0)  # Start moving immediately

func _get_positions():
	temp_positions = positions.duplicate()

func _get_next_position():
	# If there are no markers to move towards, do nothing and wait
	if temp_positions.is_empty() and marker_queue.is_empty() and projectile_buffer.is_empty():
		current_position = null
		return  # Wait for markers to be added
	
	# Prioritize buffered projectiles first
	if projectile_buffer.size() > 0:
		current_position = projectile_buffer.pop_front()  # Prioritize buffered food
		_update_direction()
		return

	if temp_positions.is_empty():
		_get_positions()

	current_position = temp_positions.pop_front()

	# Skip food markers that are no longer visible
	if current_position.name.begins_with("Projectile") and not GlobalValues.food_visible:
		_get_next_position()
	else:
		_update_direction()


func move_towards_position(delta):
	_update_direction()
	var move_amount = direction * delta * speed  # Use speed for consistent movement
	global_position += move_amount

	var distance_to_target = global_position.distance_to(current_position.global_position)
	if distance_to_target <= STOPPING_DISTANCE:
		global_position = current_position.global_position
		_handle_reached_marker()

func _update_direction():
	# Only update direction if not eating and if there is a current target
	if not is_eating and current_position != null:
		direction = (current_position.global_position - global_position).normalized()

func _handle_reached_marker():
	direction = Vector2.ZERO

	if current_position.name.begins_with("Projectile"):
		var distance_to_food = global_position.distance_to(current_position.global_position)
		if distance_to_food <= eating_distance:
			print("can eat")
			is_eating = true
			SharedSignals.start_eating.emit()
			_remove_current_marker()
			current_food_marker = null  # Reset the current food marker after eating
			is_eating = false  # Assume eating is instantaneous for this version
			_get_next_position()
		else:
			_get_next_position()
	else:
		_get_next_position()

func _remove_current_marker():
	if current_position and is_instance_valid(current_position):
		positions.erase(current_position)
		current_position.queue_free()
		current_position = null

func _remove_marker(projectile):
	for marker in positions:
		if marker.name == "Projectilespawnable" and marker.global_position == projectile.global_position:
			positions.erase(marker)
			marker.queue_free()
			if marker == current_position:
				_get_next_position()
			break

func _sort_positions():
	var spawnable_markers = []
	var regular_markers = []

	for marker in positions:
		if marker.name.begins_with("Projectile"):
			spawnable_markers.append(marker)
		else:
			regular_markers.append(marker)
	
	positions = spawnable_markers + regular_markers

func update_positions_with_new_marker(new_marker: Marker2D):
	# Check if the marker is already being processed
	if new_marker == current_food_marker or food_markers.has(new_marker) or pending_food_markers.has(new_marker):
		return

	# Add the marker to the queue based on visibility
	if GlobalValues.food_visible:
		food_markers.append(new_marker)
		
		# If the turtle is scared or eating, buffer the new marker
		if is_eating or is_scared:
			projectile_buffer.append(new_marker)  # Add to buffer
		else:
			marker_queue.push_front(new_marker)  # Prioritize food
	else:
		pending_food_markers.append(new_marker)

	# If previously waiting for a marker, resume movement now
	if current_position == null and marker_queue.size() > 0:
		_get_next_position()

