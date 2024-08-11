extends Node2D

@export var group_name: String
@export var speed: float = 50.0  # Define the speed of the enemy
@export var eating_distance: float = 15.0  # Distance to start eating

var positions: Array = []
var temp_positions: Array = []
var current_position: Marker2D

var direction: Vector2 = Vector2.ZERO
var is_eating: bool = false

const STOPPING_DISTANCE = 10

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)
	_sort_positions()
	_get_positions()
	_get_next_position()

	# Listen for the projectile_gone signal to remove the corresponding marker
	SharedSignals.projectile_gone.connect(_remove_marker)

func _physics_process(delta):
	if is_eating:
		return  # If eating, do not move

	var distance_to_target = global_position.distance_to(current_position.global_position)

	if distance_to_target <= STOPPING_DISTANCE:
		global_position = current_position.global_position
		_handle_reached_marker()
	else:
		move_towards_position(delta)

func _get_positions():
	temp_positions = positions.duplicate()

func _get_next_position():
	if temp_positions.is_empty():
		_get_positions()
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
	# Only update direction if not eating
	if not is_eating:
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
			is_eating = false  # Assume eating is instantaneous for this version
			_get_next_position()
		else:
			_get_next_position()
	else:
		_get_next_position()

func _remove_current_marker():
	if current_position:
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
	positions.append(new_marker)
	_sort_positions()
	_get_positions()
