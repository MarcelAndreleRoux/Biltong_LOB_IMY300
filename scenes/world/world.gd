extends Node2D

@onready var player = $Player
@onready var trajectory_line = $TrajectoryLine
@onready var game_pause = $GamePause
@onready var keycaps = $Keycaps
@onready var mouse = $Mouse

var _main: Node2D
var _end: Vector2

var _projectileScene: PackedScene
var shadow_texture: Texture
var shadow: Sprite2D
var points: Array = []

var _isAiming: bool = false
var g_distance

@export var max_throw_distance: float = 500.0
@export var min_throw_distance: float = 50.0

var num_of_points: int = 50
var gravity: float = -9.8

var cantThrow: bool = false
var throw_start_position: Vector2 = Vector2.ZERO

func _ready():
	shadow_texture = preload("res://assets/sprites/objects/throwables/shadow/Shadow.png")
	_main = get_tree().root.get_node("World")
	_projectileScene = preload("res://scenes/entities/objects/throwables/tester_object.tscn")
	SharedSignals.cooldown_start.connect(_on_cooldown)
	SharedSignals.new_marker.connect(_on_new_marker)
	SharedSignals.item_removed.connect(_dislpay_mouse)
	_display_keycaps_start()

func _physics_process(_delta):
	_end = get_global_mouse_position()
	
	if Input.is_action_just_pressed("exit"):
		game_pause.game_over()
	
	if Input.is_action_just_pressed("aim"):
		_isAiming = not _isAiming
		trajectory_line.visible = _isAiming

		if _isAiming:
			calculate_trajectory()
		
	if Input.is_action_just_pressed("throw") and _isAiming and not cantThrow:
		_throw_item()

	if _isAiming:
		calculate_trajectory()

func _on_cooldown():
	cantThrow = true
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 12.0  # 10-second cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_end_cooldown)
	add_child(cooldown_timer)
	cooldown_timer.start()
	SharedSignals.cooldown_start_other.emit()

func _end_cooldown():
	cantThrow = false
	SharedSignals.cooldown_end_other.emit()

func _throw_item():
	if cantThrow:
		return  # Prevent throwing if cooldown is active

	var instance = _projectileScene.instantiate()
	throw_start_position = player.global_position

	var playerPosition = throw_start_position
	var mousePosition = _end
	var direction = (mousePosition - playerPosition).normalized()

	instance.initialize(playerPosition, direction, 0, mousePosition)
	_main.add_child(instance)
	
	var shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = shadow_texture
	shadow_sprite.global_position = throw_start_position
	shadow_sprite.z_index = -1
	instance.add_child(shadow_sprite)

	SharedSignals.shadow_update.connect(_on_update_shadow)
	SharedSignals.shadow_done.connect(_on_shadow_done)
	shadow = shadow_sprite

	# Trigger the cooldown
	SharedSignals.cooldown_start.emit()

	# Calculate and place the marker at the landing position
	var landing_position = calculate_landing_position(playerPosition, direction, get_global_mouse_position())
	place_marker_at_landing(landing_position)

func calculate_trajectory():
	var DOT = Vector2(1.0, 0.0).dot((_end - player.position).normalized())
	var angle = 90 - 45 * DOT

	var x_dis = _end.x - player.position.x
	var y_dis = -1.0 * (_end.y - player.position.y)

	var speed = sqrt((0.5 * gravity * x_dis * x_dis) / pow(cos(deg_to_rad(angle)), 2.0) / (y_dis - (tan(deg_to_rad(angle)) * x_dis)))
	
	var x_component = cos(deg_to_rad(angle)) * speed
	var y_component = sin(deg_to_rad(angle)) * speed

	var total_time = x_dis / x_component

	points.clear()
	for point in range(num_of_points):
		var time = total_time * (float(point) / float(num_of_points))
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		points.append(player.position + Vector2(dx, dy))

	trajectory_line.points = points

func _on_update_shadow(direction: Vector2, distance: float):
	g_distance = distance
	shadow.global_position = throw_start_position + direction * distance

func _on_shadow_done():
	shadow.hide()

func calculate_landing_position(start_position: Vector2, direction: Vector2, target_position: Vector2) -> Vector2:
	var distance = start_position.distance_to(target_position)
	var gravity = -9.8
	var angle = direction.angle()
	var speed = sqrt((distance * -gravity) / sin(2 * angle))
	var x_component = cos(angle) * speed
	var y_component = sin(angle) * speed

	var total_time = distance / x_component
	var landing_position = start_position + direction * (x_component * total_time)
	return landing_position

func place_marker_at_landing(landing_position: Vector2):
	var new_marker = Marker2D.new()
	new_marker.name = "Projectilespawnable"
	new_marker.global_position = landing_position
	new_marker.add_to_group("FirstEnemy")

	_main.add_child(new_marker)
	
	SharedSignals.new_marker.emit(new_marker)
	print("New marker placed at: ", landing_position)

func _on_new_marker(marker: Marker2D):
	# Handle new marker placement logic if needed
	print("Marker registered: ", marker.global_position)

func _display_keycaps_start():
	keycaps.visible = true
	var timer = Timer.new()
	timer.wait_time = 5.0  # 10-second cooldown
	timer.one_shot = true
	timer.timeout.connect(_end_timer)
	add_child(timer)
	timer.start()

func _end_timer():
	keycaps.visible = false

func _dislpay_mouse():
	mouse.visible = true
	var timer = Timer.new()
	timer.wait_time = 5.0  # 10-second cooldown
	timer.one_shot = true
	timer.timeout.connect(_end_timer_mouse)
	add_child(timer)
	timer.start()

func _end_timer_mouse():
	mouse.visible = false
