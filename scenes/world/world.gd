extends Node2D

@onready var player = $Player
@onready var trajectory_line = $TrajectoryLine

var _main: Node2D
var _end: Vector2

var _projectileScene: PackedScene
var shadow_texture: Texture
var shadow: Sprite2D
var points: Array = []

var _isAiming: bool = false

@export var max_throw_distance: float = 500.0  # Maximum throw distance
@export var min_throw_distance: float = 50.0   # Minimum throw distance

var num_of_points: int = 50
var gravity: float = -9.8

var throw_start_position: Vector2 = Vector2.ZERO

func _ready():
	shadow_texture = preload("res://assets/sprites/objects/throwables/shadow/Shadow.png")
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

	# Store the player's position at the time of the throw
	throw_start_position = player.global_position

	# Initialize the projectile with position and direction
	var playerPosition = throw_start_position
	var mousePosition = _end
	var direction = (mousePosition - playerPosition).normalized()

	instance.initialize(playerPosition, direction, 0, mousePosition)

	# Add the projectile to the scene
	_main.add_child(instance)
	
	# Create and configure the shadow sprite
	var shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = shadow_texture
	shadow_sprite.global_position = throw_start_position
	shadow_sprite.z_index = -1  # Ensure the shadow is rendered behind the projectile

	# Add the shadow sprite to the projectile node
	instance.add_child(shadow_sprite)

	# Connect the shadow update signal
	SharedSignals.shadow_update.connect(_on_update_shadow)
	SharedSignals.shadow_done.connect(_on_shadow_done)
	
	shadow = shadow_sprite

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
	# this should be redone
	shadow.global_position = throw_start_position + direction * distance

func _on_shadow_done():
	# should be freed later
	shadow.hide()
