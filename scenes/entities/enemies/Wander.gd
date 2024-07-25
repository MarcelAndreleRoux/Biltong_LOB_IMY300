extends Node2D

@export var group_name: String

var positions: Array
var temp_positions: Array
var current_position: Marker2D

var direction: Vector2 = Vector2.ZERO

const STOPPING_DISTANCE = 10

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)
	_get_positions()
	_get_next_position()

func _physics_process(delta):
	check_update_positions_with_new_marker_signal()

	if global_position.distance_to(current_position.global_position) <= STOPPING_DISTANCE:
		global_position = current_position.global_position
		_get_next_position()
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
	var target_position = current_position.global_position
	var move_amount = direction * delta  # Scale movement by a speed factor
	global_position += move_amount

	if global_position.distance_to(target_position) <= STOPPING_DISTANCE:
		global_position = target_position
		_get_next_position()

func _update_direction():
	var target_direction = (current_position.global_position - global_position).normalized()
	direction = direction.move_toward(target_direction, 1.0)  # Ensure full direction change

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
	positions.append(new_marker)
	_sort_positions()
	_get_positions()
