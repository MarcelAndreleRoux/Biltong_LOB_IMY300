# BaseWorld.gd
extends Node2D

class_name BaseWorld

# Common Nodes
@onready var player = $Player
@onready var trajectory_line = $TrajectoryLine
@onready var game_pause = $GamePause
@onready var ray_cast_2d = $Player/RayCast2D

# Common Variables
var _main: Node2D
var _end: Vector2
var _projectileScene: PackedScene
var shadow_texture: Texture
var shadow: Sprite2D
var points: Array = []
var throw_start_position: Vector2

var _isAiming: bool = false
var is_on_cooldown: bool = false
var active_marker: Marker2D = null

var num_of_points: int = 50
var gravity: float = -9.8

func _ready():
	# Initialize common functionality
	shadow_texture = preload("res://assets/sprites/objects/throwables/shadow/Shadow.png")
	_main = get_tree().current_scene
	_projectileScene = preload("res://scenes/entities/objects/throwables/tester_object.tscn")
	SharedSignals.new_marker.connect(_on_new_marker)
	ray_cast_2d.enabled = true
	SharedSignals.projectile_gone.connect(_remove_marker)
	SharedSignals.item_pickup.connect(_on_item_pickup)

func _physics_process(_delta):
	if Input.is_action_just_pressed("exit"):
		game_pause.game_over()
	
	_update_raycast_position()
	change_scene()
	if GlobalValues.can_throw:
		_handle_aiming_and_throwing()

func _update_raycast_position():
	ray_cast_2d.global_position = player.global_position
	var mouse_position = get_global_mouse_position()
	var relative_mouse_position = mouse_position - ray_cast_2d.global_position
	ray_cast_2d.target_position = relative_mouse_position
	_end = get_global_mouse_position()

func _handle_aiming_and_throwing():
	if Input.is_action_pressed("aim") and not is_on_cooldown:
		_isAiming = true
	elif Input.is_action_just_released("aim"):
		_isAiming = false
	
	trajectory_line.visible = _isAiming

	if _isAiming:
		SharedSignals.show_throw.emit()
		calculate_trajectory()
		
	# Check if the raycast is not colliding before allowing a throw
	if Input.is_action_just_pressed("throw") and _isAiming and not is_on_cooldown:
		if not ray_cast_2d.is_colliding():
			SharedSignals.can_throw_projectile.emit()
			_isAiming = false
			trajectory_line.visible = false
			_throw_item()
			_start_cooldown_timer()
		else:
			print("Cannot throw, something is in the way!")

func _on_item_pickup():
	GlobalValues.can_throw = true

func _throw_item():
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

	# Calculate and place the marker at the landing position
	var landing_position = calculate_landing_position(playerPosition, direction, get_global_mouse_position())
	place_marker_at_landing(landing_position)

func _start_cooldown_timer():
	SharedSignals.inventory_freez.emit()
	is_on_cooldown = true
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 5.0
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_end_cooldown)
	add_child(cooldown_timer)
	cooldown_timer.start()

func _end_cooldown():
	SharedSignals.invertory_update.emit()
	is_on_cooldown = false

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
	shadow.global_position = throw_start_position + direction * distance

func _on_shadow_done():
	shadow.hide()

func calculate_landing_position(start_position: Vector2, direction: Vector2, target_position: Vector2) -> Vector2:
	var distance = start_position.distance_to(target_position)
	var gravity = 9.8
	var angle = direction.angle()
	
	# Ensure the angle is not too close to 0 or 180 degrees
	if abs(sin(2 * angle)) < 0.0001:
		angle += deg_to_rad(1)  # Slightly adjust the angle to avoid zero sin value
	
	var speed = sqrt((distance * gravity) / max(abs(sin(2 * angle)), 0.0001))  # Prevent division by zero
	
	# Ensure the speed is a valid number
	if speed != speed:
		speed = 100.0  # Set a default safe value or some appropriate fallback
	
	var x_component = cos(angle) * speed
	
	# Avoid division by zero in total_time calculation
	var total_time = 0.0
	if x_component != 0:
		total_time = distance / x_component
	
	var landing_position = start_position + direction * (x_component * total_time)
	return landing_position

func place_marker_at_landing(landing_position: Vector2):
	if active_marker != null:
		active_marker.queue_free()
	var new_marker = Marker2D.new()
	new_marker.name = "Projectilespawnable"
	new_marker.global_position = landing_position
	new_marker.add_to_group("FirstEnemy")

	_main.add_child(new_marker)
	active_marker = new_marker
	
	SharedSignals.new_marker.emit(new_marker)
	print("New marker placed at: ", landing_position)

func _on_new_marker(marker: Marker2D):
	print("Marker registered: ", marker.global_position)

func _remove_marker():
	if active_marker != null:
		active_marker.queue_free()
		active_marker = null

func _on_transition_body_entered(body):
	if body.is_in_group("player"):
		GlobalValues.transition_scene = true

func change_scene():
	if GlobalValues.transition_scene:
		if GlobalValues.current_scene == "World":
			get_tree().change_scene_to_file("res://scenes/world/level_2.tscn")
			GlobalValues.finish_changingscene()
