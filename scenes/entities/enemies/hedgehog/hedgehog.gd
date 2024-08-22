extends Node2D

@export var dart_scene: PackedScene
@export var fire_rate: float = 0.5
@export var cone_attack_rate: float = 100.0  # Adjust as needed
@export var cone_angle_offset: float = 10.0  # Angle offset for side darts

var _is_shooting: bool = false

func _ready():
	# Connect to the global signal that the player is spotted
	SharedSignals.player_spotted.connect(_on_player_spotted)
	dart_scene = preload("res://scenes/entities/objects/shoot/dart.tscn")

func _on_player_spotted():
	if not _is_shooting:
		_is_shooting = true
		_start_firing()

func _start_firing():
	_shoot_dart()

func _shoot_dart():
	if randi() % 2 == 0:
		# Regular single dart attack
		_spawn_dart(global_position, GlobalValues.player_position)
	else:
		# Cone attack
		_shoot_cone_attack()

	# Continue firing at the specified fire rate
	_start_timer()

func _spawn_dart(start_position: Vector2, target_position: Vector2):
	var dart_instance = dart_scene.instantiate()
	dart_instance.global_position = start_position
	dart_instance.target_position = target_position
	get_tree().current_scene.add_child(dart_instance)

func _shoot_cone_attack():
	var player_position = GlobalValues.player_position
	
	# Middle dart
	_spawn_dart(global_position, player_position)
	
	# Left dart
	var left_direction = (player_position - global_position).rotated(deg_to_rad(cone_angle_offset))
	_spawn_dart(global_position, global_position + left_direction)
	
	# Right dart
	var right_direction = (player_position - global_position).rotated(deg_to_rad(-cone_angle_offset))
	_spawn_dart(global_position, global_position + right_direction)

func _start_timer():
	# Randomly choose between single dart and cone attack
	var attack_timer = Timer.new()
	attack_timer.wait_time = fire_rate  # Fire rate for each dart shot
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_shoot_dart)
	add_child(attack_timer)
	attack_timer.start()

func stop_firing():
	# Stop firing and clear any active timers
	_is_shooting = false
	# You can optionally implement logic here to stop all timers if needed
