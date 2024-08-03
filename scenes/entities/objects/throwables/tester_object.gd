extends CharacterBody2D

@export var speed: float = 700.0
@export var speed_scale: float = 10.0
@export var gravity: float = -9.8
@export var num_of_points: int = 50
@export var eating_distance: float = 15.0  # Distance to start eating

var _direction: Vector2
var _spawnPosition: Vector2
var _spawnRotation: float
var _trajectoryPoints: Array
var _currentPointIndex: int = 0
var can_be_eaten: bool = false

var time: float = 0.0
var time_mult: float = 6.0

func _ready():
	global_position = _spawnPosition
	global_rotation = _spawnRotation

func _physics_process(delta: float):
	if _trajectoryPoints != null and _currentPointIndex < _trajectoryPoints.size():
		time += delta * time_mult
		var target = _trajectoryPoints[_currentPointIndex]
		var direction = (target - global_position).normalized()
		var adjusted_speed = speed * speed_scale
		velocity = direction * adjusted_speed * delta

		move_and_slide()

		var distance_travelled = (global_position - _spawnPosition).length()
		SharedSignals.shadow_update.emit(_direction, distance_travelled)

		if global_position.distance_to(target) < 1.0:
			_currentPointIndex += 1
		
		if _currentPointIndex >= _trajectoryPoints.size():
			SharedSignals.shadow_done.emit()
			can_be_eaten = true
			print("Projectile landed, can be eaten:", can_be_eaten)
			_create_eating_timer()

func initialize(position: Vector2, direction: Vector2, rotation: float, end_position: Vector2):
	_spawnPosition = position
	_direction = direction
	_spawnRotation = rotation
	_trajectoryPoints = calculate_trajectory(end_position)
	_currentPointIndex = 0
	time = 0.0

func calculate_trajectory(_End: Vector2):
	var DOT = Vector2(1.0, 0.0).dot((_End - _spawnPosition).normalized())
	var angle = 90 - 45 * DOT
	
	var x_dis = _End.x - _spawnPosition.x
	var y_dis = -1.0 * (_End.y - _spawnPosition.y)
	
	var speed = sqrt((0.5 * gravity * x_dis * x_dis) / pow(cos(deg_to_rad(angle)), 2.0) / (y_dis - (tan(deg_to_rad(angle)) * x_dis)))
	
	var x_component = cos(deg_to_rad(angle)) * speed
	var y_component = sin(deg_to_rad(angle)) * speed
	
	var total_time = x_dis / x_component

	var points = []
	for point in range(num_of_points):
		var time = total_time * (float(point) / float(num_of_points))
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		points.append(_spawnPosition + Vector2(dx, dy))

	return points

func _create_eating_timer():
	# Create a timer to allow eating after a short delay
	var timer = Timer.new()
	timer.wait_time = 5.0  # Duration before the item can be eaten
	timer.one_shot = true
	timer.timeout.connect(_can_be_eaten)
	add_child(timer)
	timer.start()

func _can_be_eaten():
	can_be_eaten = true
	_start_eating_sequence()

func _start_eating_sequence():
	# Ensure this function only proceeds if the item can be eaten
	if can_be_eaten:
		SharedSignals.start_eating.emit()
		_create_timer()

func _create_timer():
	var timer = Timer.new()
	timer.wait_time = 5.0  # Duration of eating time
	timer.one_shot = true
	timer.timeout.connect(_can_move_again)
	add_child(timer)
	timer.start()

func _can_move_again():
	SharedSignals.can_move_again.emit()
	queue_free()
