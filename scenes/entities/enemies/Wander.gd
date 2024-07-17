extends Node2D

@export var group_name: String

@onready var wander_at_place_time = $WanderAtPlaceTime

var positions: Array
var temp_positions: Array
var current_position: Marker2D

var direction: Vector2 = Vector2.ZERO
var waiting: bool = false

func _ready():
	positions = get_tree().get_nodes_in_group(group_name)
	_get_positions()
	_get_next_position()

func _physics_process(delta):
	if waiting:
		return

	if global_position.distance_to(current_position.position) < 10:
		_stop_and_wait()
	else:
		move_towards_position(delta)

func _get_positions():
	temp_positions = positions.duplicate()
	temp_positions.shuffle()

func _get_next_position():
	if temp_positions.is_empty():
		_get_positions()
	current_position = temp_positions.pop_front()
	direction = (current_position.position - global_position).normalized()

func _stop_and_wait():
	waiting = true
	wander_at_place_time.start()

func move_towards_position(delta):
	var move_amount = direction * delta
	if global_position.distance_to(current_position.position) <= move_amount.length():
		global_position = current_position.position
	else:
		global_position += move_amount

func _on_wander_at_place_time_timeout():
	waiting = false
	_get_next_position()
