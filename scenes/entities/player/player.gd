extends CharacterBody2D

class_name player_class

signal update_health(health: int, position: Vector2)
signal update_inventory(item: String)
signal drag_box(position: Vector2, direction: Vector2)

# Nodes
@onready var animation_tree = $AnimationTree
@onready var trajectory_line = $TrajectoryLine

# Sounds
@onready var error = $error
@onready var pickup = $pickup
@onready var throw = $throw
@onready var box_drop = $box_drop
@onready var death_sound = $death_sound

# Movement
var currentVelocity: Vector2
var speed: int = 100
var bounce_back_strength: int = 50
var bounce_direction: Vector2 = Vector2.ZERO
var was_poped: bool = false

# Aim and Throw
var is_aiming: bool = false
var direction: Vector2 = Vector2.ZERO
var throw_clicked: bool = false
var is_on_cooldown: bool = false
var can_throw_proj: bool = false
var can_aim_throw: bool = false

# Box
var is_dragging: bool = false
var is_pushing: bool = false
var player_in_box_area: bool = false
var play_box_pickup_once: bool = false
var is_bouncing_back: bool = false

# Drag Toggle
var drag_toggle_mode: bool = false

# Trajectory Line
var points: Array = []

var _end
var my_local_pos

func _ready():
	animation_tree.active = true
	can_throw_proj = GlobalValues.can_throw
	can_aim_throw = GlobalValues.can_throw
	print("Player ready. Can throw:", GlobalValues.can_throw)
	SharedSignals.player_move.connect(_change_speed)
	SharedSignals.player_exit.connect(_change_speed_back)
	SharedSignals.player_push.connect(_is_push)
	SharedSignals.player_not_push.connect(_is_not_push)
	SharedSignals.can_throw_projectile.connect(_on_can_throw)
	SharedSignals.item_pickup.connect(_on_item_pickup)
	SharedSignals.player_killed.connect(_on_player_killed)

func _on_item_pickup():
	can_aim_throw = true

func _on_can_throw():
	can_throw_proj = true

func _change_speed():
	player_in_box_area = true
	# Speed is updated in update_speed()

func _change_speed_back():
	player_in_box_area = false
	is_dragging = false
	drag_toggle_mode = false
	update_speed()
	# Speed is updated in update_speed()

func _is_push():
	is_pushing = true
	update_speed()

func _is_not_push():
	is_pushing = false
	update_speed()

func update_speed():
	if is_dragging or is_pushing:
		speed = 40
	else:
		speed = 100

func _physics_process(_delta):
	_end = get_local_mouse_position()
	my_local_pos = to_local(global_position)
	
	if Input.is_action_pressed("aim"):
		calculate_trajectory()
	
	if not is_bouncing_back:
		_handle_action_input()
		_handle_movement_input()
		_play_movement_animation()
		_update_animation_parameters()

	velocity = currentVelocity
	move_and_slide()

	# Get the mouse position in the world space
	var mouse_position = get_global_mouse_position()

	# Emit the player's position and the direction toward the mouse
	if is_dragging and player_in_box_area:
		var direction_to_mouse = (mouse_position - global_position).normalized()
		SharedSignals.drag_box.emit(global_position, direction_to_mouse)

func _handle_movement_input():
	currentVelocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = currentVelocity.normalized()
	currentVelocity *= speed

func _on_player_killed(type: String):
	# Disable player input and actions
	set_physics_process(false)
	
	if type == "pop":
		animation_tree["parameters/conditions/is_death_pop"] = true
	elif type == "peg":
		animation_tree["parameters/conditions/is_dead"] = true
		death_sound.play()
	
	# Disable further input or actions after death
	is_on_cooldown = true
	can_aim_throw = false
	can_throw_proj = false

	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 0.9
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_death_finished)
	add_child(cooldown_timer)
	cooldown_timer.start()

func _death_finished():
	SharedSignals.death_finished.emit()

func _handle_action_input():
	# Toggle dragging mode when 'E' is pressed
	if player_in_box_area:
		if Input.is_action_just_pressed("toggle_drag"):
			drag_toggle_mode = !drag_toggle_mode  # Toggle the drag mode on/off

			# If we're in the area and toggled on, start dragging
			if drag_toggle_mode and player_in_box_area:
				is_dragging = true
				box_drop.play()
				print("Dragging started")
			else:
				is_dragging = false
				print("Dragging stopped")
			update_speed()  # Update speed when is_dragging changes

func _start_cooldown_timer():
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 0.3
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_end_cooldown)
	add_child(cooldown_timer)
	cooldown_timer.start()

func _end_cooldown():
	is_on_cooldown = false

func _update_animation_parameters():
	# Update blend positions for animations
	if direction != Vector2.ZERO:
		animation_tree["parameters/idle/blend_position"] = direction
		animation_tree["parameters/idle_aim/blend_position"] = direction
		animation_tree["parameters/idle_throw/blend_position"] = direction
		animation_tree["parameters/run/blend_position"] = direction
		animation_tree["parameters/run_aim/blend_position"] = direction
		animation_tree["parameters/run_throw/blend_position"] = direction
		animation_tree["parameters/Death/blend_position"] = direction
		animation_tree["parameters/Death_Pop/blend_position"] = direction

func calculate_trajectory():
	var DOT = Vector2(1.0, 0.0).dot((_end - my_local_pos).normalized())
	var angle = 90 - 45 * DOT
	var gravity = -9.8
	var num_of_points = 50

	var x_dis = _end.x - my_local_pos.x
	var y_dis = -1.0 * (_end.y - my_local_pos.y)

	var speed = sqrt((0.5 * gravity * x_dis * x_dis) / pow(cos(deg_to_rad(angle)), 2.0) / (y_dis - (tan(deg_to_rad(angle)) * x_dis)))
	
	var x_component = cos(deg_to_rad(angle)) * speed
	var y_component = sin(deg_to_rad(angle)) * speed

	var total_time = x_dis / x_component

	points.clear()
	for point in range(num_of_points):
		var time = total_time * (float(point) / float(num_of_points))
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		points.append(my_local_pos + Vector2(dx, dy))

	trajectory_line.points = points

func _play_movement_animation():
	if currentVelocity == Vector2.ZERO:
		if is_aiming and not is_on_cooldown:
			animation_tree["parameters/conditions/is_idle_aim"] = true
			animation_tree["parameters/conditions/is_run_aim"] = false
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
		else:
			animation_tree["parameters/conditions/idle"] = true
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
	else:
		if is_aiming and not is_on_cooldown:
			animation_tree["parameters/conditions/is_run_aim"] = true
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
		else:
			animation_tree["parameters/conditions/is_run"] = true
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run_aim"] = false

func _play_throw_animation():
	if throw_clicked:
		throw.play()
		animation_tree["parameters/conditions/is_idle_throw"] = currentVelocity == Vector2.ZERO
		animation_tree["parameters/conditions/is_run_throw"] = currentVelocity != Vector2.ZERO
		animation_tree["parameters/conditions/is_idle_throw"] = false
		animation_tree["parameters/conditions/is_run_throw"] = false
		throw_clicked = false
