extends CharacterBody2D

class_name player_class

signal update_health(health: int, position: Vector2)
signal update_inventory(item: String)

@onready var animation_tree = $AnimationTree
@onready var error = $error
@onready var pickup = $pickup
@onready var throw = $throw

var currentVelocity: Vector2
var speed: int = 100

var is_aiming: bool = false
var direction: Vector2 = Vector2.ZERO
var throw_clicked: bool = false
var is_on_cooldown: bool = false

var points: Array = []

func _ready():
	animation_tree.active = true
	SharedSignals.player_move.connect(_change_speed)
	SharedSignals.player_exit.connect(_change_speed_back)

func _change_speed():
	speed = 50

func _change_speed_back():
	speed = 100

func _handle_item_pickup(_item: String):
	pass 
	# emit_signal("update_inventory", item)

func _physics_process(_delta):
	_handle_action_input()
	_handle_movement_input()
	_play_movement_animation()
	_update_animation_parameters()

	velocity = currentVelocity

	move_and_slide()

func _handle_movement_input():
	currentVelocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = currentVelocity.normalized()
	currentVelocity *= speed

func _handle_action_input():
	# Handle aim toggling
	if Input.is_action_just_pressed("aim"):
		is_aiming = true
	elif Input.is_action_just_released("aim"):
		is_aiming = false
	
	# Handle throwing action
	if is_aiming and not is_on_cooldown:
		if Input.is_action_just_pressed("throw") and not throw_clicked:
			throw_clicked = true
			is_on_cooldown = true  # Start cooldown
			_play_throw_animation()
			_start_cooldown_timer()
	else:
		if Input.is_action_just_pressed("throw"):
			error.play()

func _start_cooldown_timer():
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 5.0
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

func _play_movement_animation():
	# Movement
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
	# Throw animation logic
	if throw_clicked:
		throw.play()
		animation_tree["parameters/conditions/is_idle_throw"] = currentVelocity == Vector2.ZERO
		animation_tree["parameters/conditions/is_run_throw"] = currentVelocity != Vector2.ZERO
		animation_tree["parameters/conditions/is_idle_throw"] = false
		animation_tree["parameters/conditions/is_run_throw"] = false
		throw_clicked = false

func _on_pickup_area_body_entered(body):
	if body.name == "Food":
		if Input.is_action_just_pressed("pickup"):
			pickup.play()

func _on_pickup_finished():
	SharedSignals.pickedup_item.emit()

func _on_pickup_area_area_entered(area):
	if area.name == "Food":
		if Input.is_action_just_pressed("pickup"):
			pickup.play()

func _dislpay_mouse():
	var timer = Timer.new()
	timer.wait_time = 5.0  # 10-second cooldown
	timer.one_shot = true
	timer.timeout.connect(_end_timer_mouse)
	add_child(timer)
	timer.start()

func _end_timer_mouse():
	pass
