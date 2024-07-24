extends CharacterBody2D

@export var speed: float = 700.0  # Base Projectile speed
@export var speed_scale: float = 10.0  # Speed scaling factor

var _direction: Vector2
var _spawnPosition: Vector2
var _spawnRotation: float
var _trajectoryPoints: Array
var _currentPointIndex: int = 0

var gravity: float = -9.8  # Gravity should be negative for downwards acceleration
var num_of_points: int = 50

var time: float = 0.0
var time_mult: float = 6.0

@onready var projectile = $Projectile

signal update_shadow(direction: Vector2, distance: float)

func _ready():
	# Initialize position and rotation
	global_position = _spawnPosition
	global_rotation = _spawnRotation
	print("Projectile initialized at position: ", global_position)

func _physics_process(delta: float):
	if _trajectoryPoints != null and _currentPointIndex < _trajectoryPoints.size():
		time += delta * time_mult
		var target = _trajectoryPoints[_currentPointIndex]
		var direction = (target - global_position).normalized()
		var adjusted_speed = speed * speed_scale
		velocity = direction * adjusted_speed * delta

		# Move the projectile towards the target point
		move_and_slide()

		# Emit the shadow update signal
		var distance_travelled = (global_position - _spawnPosition).length()
		SharedSignals.shadow_update.emit(_direction, distance_travelled)

		# Check if the projectile has reached the target point
		if global_position.distance_to(target) < 1.0:
			_currentPointIndex += 1

func initialize(pos: Vector2, direction: Vector2, rot: float, end_position: Vector2):
	_spawnPosition = pos
	_direction = direction
	_spawnRotation = rot
	_trajectoryPoints = calculate_trajectory(end_position)
	_currentPointIndex = 0
	time = 0.0  # Reset time when initializing

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
		time = total_time * (float(point) / float(num_of_points))
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		points.append(_spawnPosition + Vector2(dx, dy))

	return points
