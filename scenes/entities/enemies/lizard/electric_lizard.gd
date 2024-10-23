extends CharacterBody2D

# Exported variables for patrol points (markers)
@export var target_1: Node2D = null
@export var target_2: Node2D = null
@export var target_3: Node2D = null
@export var target_4: Node2D = null
@export var target_5: Node2D = null

# Export variable to toggle 'lick_eye' animation
@export var enable_lick_eye_animation: bool = true
@export var is_on: bool = true
@export var speed = 50

@onready var navigation_agent_2d = $LizardNav
@onready var animation_tree = $AnimationTree
@onready var wet_walk = $wet_walk
@onready var animated_sprite_2d = $ElectricArea/AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
var was_water: bool = false

# Define the lizard's possible states
enum State {
	PATROL,
	PATROL_WAIT,
	LICK_EYE
}

var state = State.PATROL  # Initialize to PATROL by default

# Patrol variables
var patrol_points = []
var patrol_index = 0

# Timer for handling waiting periods
var patrol_wait_timer = null

# projectile
var projectile: BaseThrowable = null
var nearby_objects = []

func _ready():
	print("Lizard ready")
	
	animated_sprite_2d.visible = false
	
	SharedSignals.lizard_connection.connect(_play_zap)
	
	# Seed the random number generator for randomness in animations
	randomize()
	
	# Collect patrol points
	if target_1:
		patrol_points.append(target_1.global_position)
	if target_2:
		patrol_points.append(target_2.global_position)
	if target_3:
		patrol_points.append(target_3.global_position)
	if target_4:
		patrol_points.append(target_4.global_position)
	if target_5:
		patrol_points.append(target_5.global_position)
	
	# Start processing if there are patrol points
	if patrol_points.size() > 0:
		# Set the initial target position for the navigation agent
		navigation_agent_2d.target_position = patrol_points[patrol_index]
		set_physics_process(true)
	else:
		set_physics_process(false)
		print("No patrol points set for lizard.")

func _physics_process(delta):
	match state:
		State.PATROL:
			patrol_behavior()
		State.PATROL_WAIT:
			# Waiting at patrol point; timer will handle transition
			pass
		State.LICK_EYE:
			# Lick eye behavior; timer will handle transition
			pass
	
	# Update movement
	if state == State.PATROL:
		move_and_slide()
	else:
		velocity = Vector2.ZERO  # Ensure the lizard stops moving when not patrolling
	
	# Update direction for animations
	if velocity.length() > 0:
		direction = velocity.normalized()
	else:
		direction = Vector2.ZERO
	_update_animation_parameters()

func patrol_behavior():
	# Continue moving towards the patrol point
	if navigation_agent_2d.is_navigation_finished():
		# Reached patrol point, start wait timer
		state = State.PATROL_WAIT
		start_patrol_wait_timer()
	else:
		# Move towards patrol point
		var next_path_position = navigation_agent_2d.get_next_path_position()
		direction = (next_path_position - global_position).normalized()
		velocity = direction * speed

func start_patrol_wait_timer():
	# Start a timer to wait for 2 seconds before deciding the next action
	_update_animation_parameters()
	
	patrol_wait_timer = Timer.new()
	patrol_wait_timer.wait_time = 2.0  # 2 seconds wait
	patrol_wait_timer.one_shot = true
	patrol_wait_timer.timeout.connect(_on_patrol_wait_timeout)
	add_child(patrol_wait_timer)
	patrol_wait_timer.start()

func _on_patrol_wait_timeout():
	patrol_wait_timer.queue_free()
	patrol_wait_timer = null
	
	# Decide whether to play 'lick_eye' animation based on 20% chance
	if enable_lick_eye_animation and randf() < 0.2:
		state = State.LICK_EYE
		start_lick_eye_timer()
	else:
		# Proceed to next patrol point
		patrol_index = (patrol_index + 1) % patrol_points.size()
		navigation_agent_2d.target_position = patrol_points[patrol_index]
		state = State.PATROL

func start_lick_eye_timer():
	# Play 'lick_eye' animation for 2 seconds
	_update_animation_parameters()
	
	var lick_timer = Timer.new()
	lick_timer.wait_time = 2.0  # 2 seconds for 'lick_eye' animation
	lick_timer.one_shot = true
	lick_timer.timeout.connect(_on_lick_eye_timeout)
	add_child(lick_timer)
	lick_timer.start()

func _on_lick_eye_timeout():
	# After 'lick_eye' animation, proceed to next patrol point
	patrol_index = (patrol_index + 1) % patrol_points.size()
	navigation_agent_2d.target_position = patrol_points[patrol_index]
	state = State.PATROL

func _update_animation_parameters():
	# Reset all animation conditions
	animation_tree["parameters/conditions/is_run_on"] = false
	animation_tree["parameters/conditions/is_run_off"] = false
	animation_tree["parameters/conditions/is_idle_on"] = false
	animation_tree["parameters/conditions/is_idle_off"] = false
	animation_tree["parameters/conditions/is_lick_on"] = false
	animation_tree["parameters/conditions/is_lick_off"] = false
	
	if is_on:
		match state:
			State.PATROL:
				animated_sprite_2d.visible = false
				animation_tree["parameters/conditions/is_run_on"] = true
			State.PATROL_WAIT:
				animated_sprite_2d.play("activate")
				animated_sprite_2d.visible = true
				animation_tree["parameters/conditions/is_idle_on"] = true
			State.LICK_EYE:
				animated_sprite_2d.play("activate")
				animated_sprite_2d.visible = true
				animation_tree["parameters/conditions/is_lick_on"] = true
	else:
		match state:
			State.PATROL:
				animated_sprite_2d.visible = false
				animation_tree["parameters/conditions/is_run_off"] = true
			State.PATROL_WAIT:
				animated_sprite_2d.stop()
				animated_sprite_2d.visible = false
				animation_tree["parameters/conditions/is_idle_off"] = true
			State.LICK_EYE:
				animated_sprite_2d.visible = false
				animation_tree["parameters/conditions/is_lick_off"] = true
	
	# Update blend positions for animations
	animation_tree["parameters/idle_off/blend_position"] = direction
	animation_tree["parameters/idle_on/blend_position"] = direction
	animation_tree["parameters/lick_off/blend_position"] = direction
	animation_tree["parameters/lick_on/blend_position"] = direction
	animation_tree["parameters/run_off/blend_position"] = direction
	animation_tree["parameters/run_on/blend_position"] = direction

func _on_electric_area_body_entered(body):
	if body.is_in_group("player") and is_on:
		SharedSignals.player_killed.emit("pop")
		_player_zap(body)
	
	if body.is_in_group("conductor") or body.is_in_group("m_board"):
		nearby_objects.append(body)
		if is_on:
			body.receive_electricity() 

func _on_electric_area_body_exited(body):
	if body in nearby_objects:
		nearby_objects.erase(body)
		body.stop_electricity()

func get_electrical_state() -> bool:
	return is_on

func _player_zap(object):
	if is_on:
		var player_position = object.global_position
		var lizard_position = self.global_position
		var direction = (player_position - lizard_position).normalized()

		var electrical_zap = preload("res://scenes/Shared/electricity.tscn").instantiate()

		var offset_amount = 30

		electrical_zap.global_position = lizard_position + (direction * offset_amount)

		get_tree().current_scene.add_child(electrical_zap)

		electrical_zap.output_charge(direction)

func _play_zap(object):
	if is_on:
		var conductor_position = object.global_position
		var lizard_position = self.global_position
		var direction = (lizard_position - conductor_position).normalized()
		
		# Instantiate the zap scene independently
		var electrical_zap = preload("res://scenes/Shared/electricity.tscn").instantiate()
		
		# Define the offset amount (10px)
		var offset_amount = -10
		
		# Offset the spawn position by 10px in the direction vector
		electrical_zap.global_position = lizard_position + (direction * offset_amount)
		
		# Add the zap to the current scene first, before calling output_charge
		get_tree().current_scene.add_child(electrical_zap)
		
		# Now that it's added to the scene, call the charge
		electrical_zap.output_charge(direction)

func _on_throw_check_area_area_entered(area):
	if area.is_in_group("throwables"):
		if area.is_in_group("fire"):
			was_water = false
		if area.is_in_group("water"):
			wet_walk.play()
			was_water = true
		
		projectile = area.get_parent()
		
		if projectile and projectile.get_landed_state():
			projectile.projectile_landed.connect(_change_state)

func _change_state():
	if was_water:
		is_on = false
	else:
		is_on = true
	
	SharedSignals.lizard_state_change.emit(is_on)
	
	# Immediately handle the connection/disconnection of nearby objects
	if is_on:
		for obj in nearby_objects:
			obj.receive_electricity()
	else:
		for obj in nearby_objects:
			obj.stop_electricity()
