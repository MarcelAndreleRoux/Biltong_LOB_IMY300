extends Node2D

@onready var player = $Player
@onready var trajectory_line = $TrajectoryLine
@onready var shadow = $Shadow

var _main: Node2D
var _end: Vector2

var _projectileScene: PackedScene
var points: Array = []

#var _canThrowItem: bool = true
var _isAiming: bool = false

var num_of_points: int = 50
var gravity: float = -9.8

func _ready():
	_main = get_tree().root.get_node("World")
	_projectileScene = preload("res://scenes/entities/objects/throwables/tester_object.tscn")

func _physics_process(_delta):
	_end = get_global_mouse_position()
	
	if Input.is_action_just_pressed("aim"):
		# Toggle aiming
		_isAiming = not _isAiming
		trajectory_line.visible = _isAiming

		if _isAiming:
			calculate_trajectory()
		
	if Input.is_action_just_pressed("throw") and _isAiming:
		_throw_item()

	if _isAiming:
		calculate_trajectory()

func _throw_item():
	var instance = _projectileScene.instantiate()

	# Initialize the projectile with position and direction
	var playerPosition = player.global_position
	var mousePosition = _end
	var direction = (mousePosition - playerPosition).normalized()

	instance.initialize(playerPosition, direction, 0, mousePosition)

	_main.add_child(instance)
	
	# Move the shadow to the player's position and make it visible
	shadow.global_position = player.global_position
	shadow.visible = true

	# Connect the shadow update signal
	SharedSignals.shadow_update.connect(_on_update_shadow)

func calculate_trajectory():
	# Getting dot product of the target (end position) - start (player position) to see if it is positive or negative
	var DOT = Vector2(1.0, 0.0).dot((_end - player.position).normalized())
	# We add 45 degrees if we want it to be to the left and minus 45 degrees if we want it to be to the right
	var angle = 90 - 45 * DOT

	# These only measure the total distance
	var x_dis = _end.x - player.position.x
	var y_dis = -1.0 * (_end.y - player.position.y)

	var speed = sqrt((0.5 * gravity * x_dis * x_dis) / pow(cos(deg_to_rad(angle)), 2.0) / (y_dis - (tan(deg_to_rad(angle)) * x_dis)))
	
	var x_component = cos(deg_to_rad(angle)) * speed
	var y_component = sin(deg_to_rad(angle)) * speed

	var total_time = x_dis / x_component

	points.clear()
	for point in range(num_of_points):
		var time = total_time * (float(point) / float(num_of_points))  # Ensure correct division
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		points.append(player.position + Vector2(dx, dy))

	trajectory_line.points = points

func _on_update_shadow(direction: Vector2, distance: float):
	shadow.global_position = player.global_position + direction * distance
