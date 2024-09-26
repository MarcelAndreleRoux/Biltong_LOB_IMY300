extends CharacterBody2D

class_name player_class

signal update_health(health: int, position: Vector2)
signal update_inventory(item: String)
signal drag_box(position: Vector2, direction: Vector2)

# Nodes
@onready var animation_tree = $AnimationTree

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

# Aim and Throw
var is_aiming: bool = false
var direction: Vector2 = Vector2.ZERO
var throw_clicked: bool = false
var is_on_cooldown: bool = false
var can_throw_proj: bool = false
var can_aim_throw: bool = false

# Box
var is_dragging: bool = false
var player_in_box_area: bool = false
var play_box_pickup_once: bool = false
var is_bouncing_back: bool = false

# Drag Toggle
var drag_toggle_mode: bool = false  # New variable to track the toggle mode

# Trajectory Line
var points: Array = []

func _ready():
	animation_tree.active = true
	can_throw_proj = GlobalValues.can_throw
	can_aim_throw = GlobalValues.can_throw
	print("Player ready. Can throw:", GlobalValues.can_throw)
	SharedSignals.player_move.connect(_change_speed)
	SharedSignals.player_exit.connect(_change_speed_back)
	SharedSignals.can_throw_projectile.connect(_on_can_throw)
	SharedSignals.item_pickup.connect(_on_item_pickup)
	SharedSignals.player_killed.connect(_on_player_killed)

func _on_item_pickup():
	can_aim_throw = true

func _on_can_throw():
	can_throw_proj = true

func _change_speed():
	player_in_box_area = true
	speed = 40

func _change_speed_back():
	player_in_box_area = false
	speed = 100

func _physics_process(_delta):
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

func _on_player_killed():
	# Disable player input and actions
	set_physics_process(false)
	
	# Play the death animation
	animation_tree["parameters/conditions/is_dead"] = true
	
	# Optionally, play a death sound or other effects
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

	# Only drag the box if we're in drag mode and in the area
	if drag_toggle_mode and player_in_box_area:
		is_dragging = true
	else:
		is_dragging = false

	# Handle other actions like aiming and throwing
	if can_aim_throw:
		if Input.is_action_just_pressed("aim"):
			is_aiming = true
		elif Input.is_action_just_released("aim"):
			is_aiming = false

		if is_aiming and not is_on_cooldown and can_throw_proj:
			if Input.is_action_just_pressed("throw") and not throw_clicked:
				throw_clicked = true
				is_on_cooldown = true
				_play_throw_animation()
				_start_cooldown_timer()
		else:
			if Input.is_action_just_pressed("throw"):
				error.play()

func _start_cooldown_timer():
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 10.0
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
