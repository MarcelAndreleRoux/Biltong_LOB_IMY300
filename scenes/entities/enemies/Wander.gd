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

func _physics_process(delta):
	if is_eating:
		return  # If eating, do not move

	var distance_to_target = global_position.distance_to(current_position.global_position)
	#print("Distance to target: ", distance_to_target)
	#print("Enemy global_position: ", global_position)
	#print("Target global_position: ", current_position.global_position)

	if distance_to_target <= STOPPING_DISTANCE:
		#print("Reached target: ", current_position.name)
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
	var move_amount = direction * delta * speed  # Use speed for consistent movement
	global_position += move_amount

	#print("Moving towards: ", current_position.name, " Position: ", global_position)

	var distance_to_target = global_position.distance_to(current_position.global_position)
	if distance_to_target <= STOPPING_DISTANCE:
		#print("Stopping at target: ", current_position.name)
		global_position = current_position.global_position
		_handle_reached_marker()

func _update_direction():
	# Only update direction if not eating
	if not is_eating:
		direction = (current_position.global_position - global_position).normalized()
		#print("Updating direction towards: ", current_position.global_position)

func _handle_reached_marker():
	direction = Vector2.ZERO

	if current_position.name.begins_with("Projectile"):
		var distance_to_food = global_position.distance_to(current_position.global_position)
		if distance_to_food <= eating_distance:
			print("can eat")
			#print("Starting to eat at marker:", current_position.name)
			is_eating = true
			SharedSignals.start_eating.emit()
			#_create_eating_timer()
		else:
			#print("Too far to eat. Distance:", distance_to_food)
			_get_next_position()
	else:
		_get_next_position()

#func _create_eating_timer():
	#print("created eating timer")
	#var timer = Timer.new()
	#timer.wait_time = 5.0  # Duration of eating time
	#timer.one_shot = true
	#timer.timeout.connect(_can_move_again)
	#add_child(timer)
	#timer.start()

func _can_move_again():
	is_eating = false
	SharedSignals.can_move_again.emit()
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
		if marker.name.begins_with("Projectile"):
			spawnable_markers.append(marker)
		else:
			regular_markers.append(marker)
	
	positions = spawnable_markers + regular_markers

func update_positions_with_new_marker(new_marker: Marker2D):
	positions.append(new_marker)
	_sort_positions()
	_get_positions()
