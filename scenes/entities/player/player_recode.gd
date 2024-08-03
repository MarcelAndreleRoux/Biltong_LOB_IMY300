extends CharacterBody2D

signal update_health(health: int, position: Vector2)
signal update_inventory(item: String)

@onready var animation_tree = $AnimationTree
@onready var error = $error
@onready var pickup = $pickup

var currentVelocity: Vector2
var speed: int = 150

var is_aiming: bool = false
var has_throw: bool = false
var direction: Vector2 = Vector2.ZERO
var cantThrow: bool = false

var points: Array = []

func _ready():
	animation_tree.active = true

func _handle_damage_player(_damage_amount: int):
	pass
	#_health -= damage_amount
	#emit_signal("update_health", _health, position)

func _handle_item_pickup(_item: String):
	pass 
	#emit_signal("update_inventory", item)

func _physics_process(_delta):
	_update_animation_parameters()
	_handle_input()

	#if Input.is_action_just_pressed("pickup") and _itemToPickUp != null:
		#SharedSignals.pickup_item.emit(_itemToPickUp.name)
	velocity = currentVelocity
	
	move_and_slide()

func _throw_item():
	pass
	#if _itemToPickUp != null:
		#SharedSignals.item_throw.emit()

func _handle_input():
	currentVelocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = currentVelocity.normalized()
	currentVelocity *= speed

func _start_throw_cooldown():
	cantThrow = true

func _end_throw_cooldown():
	cantThrow = false

func _update_animation_parameters():
	# Handle aim toggling
	if Input.is_action_just_pressed("aim"):
		is_aiming = not is_aiming
	
	# Handle throwing action
	if not cantThrow:
		if Input.is_action_just_pressed("throw") and is_aiming:
			_play_throw_animation()
		else:
			has_throw = false
			_play_movement_animation()
	elif cantThrow and has_throw:
		if Input.is_action_just_pressed("throw") and is_aiming  and has_throw:
			error.play()
		elif Input.is_action_just_pressed("throw") and has_throw:
			error.play()

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
	has_throw = true
	if velocity == Vector2.ZERO:
		if is_aiming:
			animation_tree["parameters/conditions/is_idle_aim"] = true
			animation_tree["parameters/conditions/is_run_aim"] = false
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
		else:
			animation_tree["parameters/conditions/idle"] = true
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
	else:
		if is_aiming:
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
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/is_idle_throw"] = true
		animation_tree["parameters/conditions/is_run_throw"] = false
	else:
		animation_tree["parameters/conditions/is_run_throw"] = true
		animation_tree["parameters/conditions/is_idle_throw"] = false

	# Resetting throw state after playing the animation
	_start_throw_reset_timer()

func _start_throw_reset_timer():
	# Create a Timer node
	var timer = Timer.new()
	timer.wait_time = 0.6  # 1 second
	timer.one_shot = true
	timer.timeout.connect(_on_throw_reset_timeout)
	add_child(timer)
	timer.start()

func _on_throw_reset_timeout():
	# Reset throw conditions
	animation_tree["parameters/conditions/is_idle_throw"] = false
	animation_tree["parameters/conditions/is_run_throw"] = false

	# Return to aiming state if still aiming
	if is_aiming:
		if velocity == Vector2.ZERO:
			animation_tree["parameters/conditions/is_idle_aim"] = true
		else:
			animation_tree["parameters/conditions/is_run_aim"] = true
	else:
		if velocity == Vector2.ZERO:
			animation_tree["parameters/conditions/idle"] = true
		else:
			animation_tree["parameters/conditions/is_run"] = true

	## Clean up the timer
	#var timer = $Timer
	#if timer != null:
		#timer.queue_free()

func _on_pickup_area_body_entered(body):
	if body.name == "Food":
		pickup.play()

func _on_pickup_finished():
	SharedSignals.pickedup_item.emit()

func _on_pickup_area_area_entered(area):
	if area.name == "Food":
		pickup.play()
