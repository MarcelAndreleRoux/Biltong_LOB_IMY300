extends Node2D

@export var group_name: String
@export var speed: float = 50.0  # Define speed for movement
@export var stop_duration: float = 2.0  # Time to wait after reaching a marker

var target_marker: Marker2D
var direction_to_target: Vector2 = Vector2.ZERO
var marker_queue: Array = []
var is_moving: bool = false

var stop_timer: Timer  # Timer for the stop-and-go behavior

const STOPPING_DISTANCE = 15  # Adjust this distance to stop before the marker

func _ready():
	stop_timer = Timer.new()
	stop_timer.wait_time = stop_duration
	stop_timer.one_shot = true
	stop_timer.timeout.connect(_on_stop_timer_timeout)
	add_child(stop_timer)

func start_wandering():
	# Initialize markers in the group and start the movement
	marker_queue = get_tree().get_nodes_in_group(group_name).duplicate()
	print("The current markers", marker_queue)

	if marker_queue.size() > 0:
		get_next_marker()
	else:
		print("No markers found.")

func update_direction():
	if target_marker != null and is_moving:
		var target_position = target_marker.global_position
		direction_to_target = (target_position - global_position).normalized()  # Update direction to target
		
		# Test if the lizard has reached the target marker
		if global_position.distance_to(target_marker.global_position) <= STOPPING_DISTANCE:
			_reach_marker()

func get_velocity() -> Vector2:
	return direction_to_target  # Return the normalized direction vector for movement

func get_next_marker():
	if marker_queue.size() > 0 and is_instance_valid(marker_queue.front()):
		target_marker = marker_queue.pop_front()  # Get the next marker in the queue
		marker_queue.append(target_marker)  # Re-add the marker to the end of the queue
		print("Next marker: ", target_marker.name)
		
		is_moving = true
	else:
		is_moving = false

func _reach_marker():
	is_moving = false
	print("Reached marker: ", target_marker.name)
	SharedSignals.lizard_marker_reached.emit()  # Notify that the lizard has reached a marker
	start_stop_timer()  # Start the stop timer before moving to the next marker

func start_stop_timer():
	# Start the timer for the stop-and-go behavior
	stop_timer.start()

func _on_stop_timer_timeout():
	print("Lizard ready to move to the next marker.")
	is_moving = true
	SharedSignals.lizard_can_move_again.emit()
	get_next_marker()
