extends Node2D

@export var group_name: String
@export var speed: float = 50.0

var positions: Array = []
var temp_positions: Array = []
var current_position: Marker2D

var direction: Vector2 = Vector2.ZERO

const STOPPING_DISTANCE = 10

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)

	# If no markers are available initially, wait until a marker appears
	if positions.size() != 0:
		_get_positions()
		_get_next_position()

func _physics_process(delta):
	if current_position == null:
		return  # If no target, do not move

	var distance_to_target = global_position.distance_to(current_position.global_position)

	if distance_to_target <= STOPPING_DISTANCE:
		global_position = current_position.global_position
		_handle_reached_marker()
	else:
		move_towards_position(delta)

func _get_positions():
	temp_positions = positions.duplicate()

func _get_next_position():
	# If there are no markers to move towards, do nothing and wait
	if temp_positions.is_empty():
		_get_positions()

	if temp_positions.is_empty():
		current_position = null
		return  # No more positions to move towards
	
	current_position = temp_positions.pop_front()
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
	# Only update direction if there is a current target
	if current_position != null:
		direction = (current_position.global_position - global_position).normalized()

func _handle_reached_marker():
	direction = Vector2.ZERO
	_get_next_position()

# Custom sorting method to sort markers by name, assuming you want specific order
func _sort_by_name(marker_a: Marker2D, marker_b: Marker2D) -> bool:
	return marker_a.name < marker_b.name

func update_positions_with_new_marker(new_marker: Marker2D):
	# Check if the marker is already being processed
	if positions.has(new_marker):
		return

	positions.append(new_marker)

	# If previously waiting for a marker, resume movement now
	if current_position == null:
		_get_next_position()
