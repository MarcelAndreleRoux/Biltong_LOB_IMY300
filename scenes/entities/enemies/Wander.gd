extends Node2D

@export var group_name: String

var positions: Array
var temp_positions: Array
var current_position: Marker2D

var direction: Vector2 = Vector2.ZERO
var waiting: bool = false

const STOPPING_DISTANCE = 10

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)
	_get_positions()
	_get_next_position()

func _physics_process(delta):
	if waiting:
		return

	if global_position.distance_to(current_position.global_position) < STOPPING_DISTANCE:
		_stop_and_wait()
	else:
		move_towards_position(delta)

func _get_positions():
	temp_positions = positions.duplicate()

func _get_next_position():
	if temp_positions.is_empty():
		_get_positions()
	current_position = temp_positions.pop_front()
	_update_direction()

func _stop_and_wait():
	waiting = true
	_create_timer()

func _create_timer():
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_on_wander_at_place_time_timeout)
	add_child(timer)
	timer.start()

func move_towards_position(delta):
	_update_direction()
	var move_amount = direction * delta
	if global_position.distance_to(current_position.global_position) <= move_amount.length():
		global_position = current_position.global_position
		_stop_and_wait()
	else:
		global_position += move_amount

func _update_direction():
	var target_direction = (current_position.global_position - global_position).normalized()
	direction = direction.move_toward(target_direction, 0.1)

func _on_wander_at_place_time_timeout():
	waiting = false
	_get_next_position()
	for child in get_children():
		if child is Timer:
			child.queue_free()
