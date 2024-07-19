extends Node2D

@export var group_name: String

var positions: Array
var current_position_index: int = 0
var direction: Vector2 = Vector2.ZERO
var waiting: bool = false

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)
	if positions.size() > 0:
		_get_next_position()
	else:
		print("No positions found in group")

func _physics_process(delta):
	if waiting:
		return

	if global_position.distance_to(positions[current_position_index].global_position) < 10:
		_stop_and_wait()
	else:
		move_towards_position(delta)

func _get_next_position():
	current_position_index = (current_position_index + 1) % positions.size()
	direction = (positions[current_position_index].global_position - global_position).normalized()

func _stop_and_wait():
	waiting = true
	_create_timer()

func _create_timer():
	var timer = Timer.new()
	timer.wait_time = 3.0  # Set your desired wait time here
	timer.one_shot = true
	timer.timeout.connect(_on_wander_at_place_time_timeout)
	add_child(timer)
	timer.start()

func move_towards_position(delta):
	var move_amount = direction * delta  # Ensure speed is factored in
	if global_position.distance_to(positions[current_position_index].global_position) <= move_amount.length():
		global_position = positions[current_position_index].global_position
		_stop_and_wait()  # Stop and wait when reaching the marker
	else:
		global_position += move_amount

func _on_wander_at_place_time_timeout():
	waiting = false
	_get_next_position()
	var timer = get_node("Timer")
	if timer != null:
		timer.queue_free()  # Remove the timer node
