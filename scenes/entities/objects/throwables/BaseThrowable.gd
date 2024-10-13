extends CharacterBody2D

class_name BaseThrowable

@export var add_distance_blocker: bool = true
@export var speed: float = 600.0
@export var speed_scale: float = 10.0
@export var despawn_time: float = 8.0

signal projectile_landed

var gravity: float = -9.8
var _direction: Vector2
var _spawnPosition: Vector2
var _spawnRotation: float
var _trajectoryPoints: Array
var _currentPointIndex: int = 0
var can_be_eaten: bool = false
var shadow_sprite: Sprite2D
var shadow_offset: float = 10.0
var projectile_landed_boolean: bool = false

var MIN_AIM_DISTANCE: float = 20.0
var MAX_AIM_DISTANCE: float = 215.0

var MIN_POINTS: int = 15
var MAX_POINTS: int = 50

var time: float = 0.0
var time_mult: float = 6.0

var I_landed: bool = false
var start_place: Vector2 = Vector2.ZERO

var rotation_time: float = 1.0

var has_been_eaten: bool = false

func _ready():
	add_to_group("throwables")
	global_position = _spawnPosition
	global_rotation = _spawnRotation
	SharedSignals.shadow_update.connect(_player_gp)

func _player_gp(player_global_pos):
	start_place = player_global_pos

func _delete_throwable():
	queue_free()

func _physics_process(delta: float):
	if _trajectoryPoints != null and _currentPointIndex < _trajectoryPoints.size():
		time += delta * time_mult
		var target = _trajectoryPoints[_currentPointIndex]
		var direction = (target - global_position).normalized()
		var adjusted_speed = speed * speed_scale
		velocity = direction * adjusted_speed * delta

		move_and_slide()
		
		rotation += (2 * PI / rotation_time) * delta

		var distance_travelled = (global_position - _spawnPosition).length()
		$shadow_sprite.global_position = start_place + (_direction * distance_travelled)

		if global_position.distance_to(target) < 1.0:
			_currentPointIndex += 1
		
		I_landed = _currentPointIndex >= _trajectoryPoints.size() - 10
		
		if _currentPointIndex >= _trajectoryPoints.size():
			rotation = 0.0
			can_be_eaten = true
			I_landed = true
			projectile_landed.emit()
			$shadow_sprite.queue_free()
			_start_despawn_timer()
	else:
		if _trajectoryPoints == null:
			print("Error: Trajectory points are null")

func get_landed_state():
	return I_landed

func initialize(position: Vector2, direction: Vector2, rotation: float, end_position: Vector2):
	_spawnPosition = position
	_direction = direction
	_spawnRotation = rotation
	_trajectoryPoints = calculate_trajectory(end_position)
	_currentPointIndex = 0
	time = 0.0

func calculate_number_of_points(aim_distance: float) -> int:
	# Ensure the aim_distance is clamped between MIN_AIM_DISTANCE and MAX_AIM_DISTANCE
	aim_distance = clamp(aim_distance, MIN_AIM_DISTANCE, MAX_AIM_DISTANCE)

	# Linear interpolation between MIN_POINTS and MAX_POINTS based on aim distance
	return int(lerp(MIN_POINTS, MAX_POINTS, (aim_distance - MIN_AIM_DISTANCE) / (MAX_AIM_DISTANCE - MIN_AIM_DISTANCE)))

func calculate_trajectory(_End: Vector2) -> Array:
	var aim_direction = _End - _spawnPosition
	var aim_distance = aim_direction.length()

	# Define the soft maximum distance where pulling becomes harder and the hard max distance
	var soft_max_distance = 180.0
	var hard_max_distance = 215.0  # Hard max distance where pulling is almost impossible

	# Track whether the projectile has reached max distance
	var is_at_max_distance = false
	
	# Apply distance blocking and progressive stretching
	if add_distance_blocker:
		if aim_distance < MIN_AIM_DISTANCE:
			aim_direction = aim_direction.normalized() * MIN_AIM_DISTANCE
			_End = _spawnPosition + aim_direction
			aim_distance = MIN_AIM_DISTANCE
		elif aim_distance > soft_max_distance:
			# Gradually slow down the progress towards hard_max_distance
			var extra_distance = aim_distance - soft_max_distance

			# Progressive slow-down logic as we approach the hard max
			var stretch_factor = (hard_max_distance - soft_max_distance) / (extra_distance + (hard_max_distance - soft_max_distance))
			aim_distance = soft_max_distance + extra_distance * stretch_factor

			# Ensure that we never exceed hard_max_distance
			aim_distance = min(aim_distance, hard_max_distance)

			aim_direction = aim_direction.normalized() * aim_distance
			_End = _spawnPosition + aim_direction
			is_at_max_distance = true
		else:
			is_at_max_distance = false

	# Determine number of trajectory points based on the adjusted aim distance
	var num_of_points = calculate_number_of_points(aim_distance)

	# Proceed with trajectory calculations
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

func mark_as_eaten():
	has_been_eaten = true
	# Optionally remove from group
	remove_from_group("food_to_eat")
	SharedSignals.food_was_eaten.emit()
	# Proceed to queue_free or other logic
	queue_free()

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
