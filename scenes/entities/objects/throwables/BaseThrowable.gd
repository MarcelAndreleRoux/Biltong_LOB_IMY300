extends CharacterBody2D

class_name BaseThrowable

@export var add_distance_blocker: bool = true
@export var speed: float = 600.0
@export var speed_scale: float = 10.0
@export var despawn_time: float = 8.0

signal projectile_landed

var num_of_points: int = 15
var gravity: float = -9.8
var _direction: Vector2
var _spawnPosition: Vector2
var _spawnRotation: float
var _trajectoryPoints: Array
var _currentPointIndex: int = 0
var can_be_eaten: bool = false
var shadow_sprite: Sprite2D
var shadow_offset: float = 10.0

var MIN_AIM_DISTANCE: float = 20.0
var MAX_AIM_DISTANCE: float = 200.0

var time: float = 0.0
var time_mult: float = 6.0

var start_place: Vector2 = Vector2.ZERO

func _ready():
	global_position = _spawnPosition
	global_rotation = _spawnRotation
	SharedSignals.shadow_update.connect(_player_gp)

func _player_gp(player_global_pos):
	start_place = player_global_pos

func _physics_process(delta: float):
	if _trajectoryPoints != null and _currentPointIndex < _trajectoryPoints.size():
		time += delta * time_mult
		var target = _trajectoryPoints[_currentPointIndex]
		var direction = (target - global_position).normalized()
		var adjusted_speed = speed * speed_scale
		velocity = direction * adjusted_speed * delta

		move_and_slide()

		var distance_travelled = (global_position - _spawnPosition).length()
		$shadow_sprite.global_position = start_place + (_direction * distance_travelled)

		if global_position.distance_to(target) < 1.0:
			_currentPointIndex += 1
		
		if _currentPointIndex >= _trajectoryPoints.size():
			projectile_landed.emit()
			$shadow_sprite.queue_free()
		
		if _currentPointIndex >= _trajectoryPoints.size():
			can_be_eaten = true
			_start_despawn_timer()
	else:
		if _trajectoryPoints == null:
			print("Error: Trajectory points are null")

func initialize(position: Vector2, direction: Vector2, rotation: float, end_position: Vector2):
	_spawnPosition = position
	_direction = direction
	_spawnRotation = rotation
	_trajectoryPoints = calculate_trajectory(end_position)
	_currentPointIndex = 0
	time = 0.0

func calculate_trajectory(_End: Vector2) -> Array:
	var aim_direction = _End - _spawnPosition
	var aim_distance = aim_direction.length()
	
	# Clamp the aim distance between MIN_AIM_DISTANCE and MAX_AIM_DISTANCE
	if add_distance_blocker:
		if aim_distance < MIN_AIM_DISTANCE:
			aim_direction = aim_direction.normalized() * MIN_AIM_DISTANCE
			_End = _spawnPosition + aim_direction
		elif aim_distance > MAX_AIM_DISTANCE:
			aim_direction = aim_direction.normalized() * MAX_AIM_DISTANCE
			_End = _spawnPosition + aim_direction
	
	# Proceed with the original trajectory calculations using the adjusted _End
	var DOT = Vector2(1.0, 0.0).dot(aim_direction.normalized())
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

func _start_despawn_timer():
	var timer = Timer.new()
	timer.wait_time = despawn_time
	timer.one_shot = true
	timer.timeout.connect(_despawn_time)
	add_child(timer)
	timer.start()

func _despawn_time():
	SharedSignals.projectile_gone.emit(self)
	SharedSignals.food_was_eaten.emit()
	queue_free()
