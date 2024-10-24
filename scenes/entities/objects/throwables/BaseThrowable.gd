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

var MIN_POINTS: int = ProjectileConstants.MIN_POINTS
var MAX_POINTS: int = ProjectileConstants.MAX_POINTS

var time: float = 0.0
var time_mult: float = 6.0

# Define the soft maximum distance where pulling becomes harder and the hard max distance
var soft_max_distance = 180.0
var hard_max_distance = 215.0  # Hard max distance where pulling is almost impossible

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
	# Use ProjectileConstants
	aim_distance = clamp(aim_distance, ProjectileConstants.MIN_AIM_DISTANCE, ProjectileConstants.HARD_MAX_DISTANCE)
	return int(lerp(MIN_POINTS, MAX_POINTS, 
		(aim_distance - ProjectileConstants.MIN_AIM_DISTANCE) / 
		(ProjectileConstants.HARD_MAX_DISTANCE - ProjectileConstants.MIN_AIM_DISTANCE)))

func calculate_trajectory(_End: Vector2) -> Array:
	var aim_direction = _End - _spawnPosition
	var aim_distance = aim_direction.length()
	var is_at_max_distance = false
	
	if add_distance_blocker:
		if aim_distance < ProjectileConstants.MIN_AIM_DISTANCE:
			aim_direction = aim_direction.normalized() * ProjectileConstants.MIN_AIM_DISTANCE
			_End = _spawnPosition + aim_direction
			aim_distance = ProjectileConstants.MIN_AIM_DISTANCE
		elif aim_distance > ProjectileConstants.SOFT_MAX_DISTANCE:
			var extra_distance = aim_distance - ProjectileConstants.SOFT_MAX_DISTANCE
			
			var stretch_factor = (ProjectileConstants.HARD_MAX_DISTANCE - ProjectileConstants.SOFT_MAX_DISTANCE) / (extra_distance + (ProjectileConstants.HARD_MAX_DISTANCE - ProjectileConstants.SOFT_MAX_DISTANCE))
			aim_distance = ProjectileConstants.SOFT_MAX_DISTANCE + extra_distance * stretch_factor
			
			aim_distance = min(aim_distance, ProjectileConstants.HARD_MAX_DISTANCE)
			aim_direction = aim_direction.normalized() * aim_distance
			_End = _spawnPosition + aim_direction
			is_at_max_distance = true
		else:
			is_at_max_distance = false

	# Rest of your trajectory calculation code...
	var num_of_points = calculate_number_of_points(aim_distance)
	
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
