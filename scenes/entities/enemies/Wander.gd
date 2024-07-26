extends Node2D

@export var group_name: String

var positions: Array = []
var temp_positions: Array = []
var current_position: Marker2D

var direction: Vector2 = Vector2.ZERO
var is_eating: bool = false  # Flag to indicate if the enemy is eating

const STOPPING_DISTANCE = 10

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)
	_sort_positions()
	_get_positions()
	_get_next_position()

func _physics_process(delta):
	check_update_positions_with_new_marker_signal()

	if is_eating:
		return  # If eating, do not move

	var distance_to_target = global_position.distance_to(current_position.global_position)
	print("Distance to target: ", distance_to_target)

	if distance_to_target <= STOPPING_DISTANCE:
		print("Reached target: ", current_position.name)
		global_position = current_position.global_position
		_handle_reached_marker()
	else:
		move_towards_position(delta)

func check_update_positions_with_new_marker_signal():
	SharedSignals.new_marker.connect(update_positions_with_new_marker)

func _get_positions():
	temp_positions = positions.duplicate()

func _get_next_position():
	if temp_positions.is_empty():
		_get_positions()
	current_position = temp_positions.pop_front()
	_update_direction()

func move_towards_position(delta):
	_update_direction()
	var move_amount = direction * delta * 50  # Adjust movement speed as needed
	global_position += move_amount

	print("Moving towards: ", current_position.name, " Position: ", global_position)

	var distance_to_target = global_position.distance_to(current_position.global_position)
	if distance_to_target <= STOPPING_DISTANCE:
		print("Stopping at target: ", current_position.name)
		global_position = current_position.global_position
		_handle_reached_marker()

func _update_direction():
	var target_direction = (current_position.global_position - global_position).normalized()
	print("Updating direction towards: ", current_position.global_position)
	direction = target_direction

func _handle_reached_marker():
	if current_position.name.begins_with("spawnable"):
		# Enemy reaches food marker, start eating
		is_eating = true
		SharedSignals.start_eating.emit()
		_create_eating_timer()
	else:
		_get_next_position()

func _create_eating_timer():
	var timer = Timer.new()
	timer.wait_time = 5.0  # Duration of eating time
	timer.one_shot = true
	timer.timeout.connect(_on_eating_done)
	add_child(timer)
	timer.start()

func _on_eating_done():
	is_eating = false
	_remove_current_marker()
	_get_next_position()

func _remove_current_marker():
	if current_position:
		positions.erase(current_position)
		current_position.queue_free()
		current_position = null

func _sort_positions():
	var spawnable_markers = []
	var regular_markers = []

	for marker in positions:
		if marker.name.begins_with("spawnable"):
			spawnable_markers.append(marker)
		else:
			regular_markers.append(marker)
	
	positions = spawnable_markers + regular_markers

func update_positions_with_new_marker(new_marker: Marker2D):
	positions.append(new_marker)  # Add new marker at the front of the list
	_sort_positions()
	_get_positions()
