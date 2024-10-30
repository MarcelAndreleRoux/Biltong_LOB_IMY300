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
@export var STOP_AT_PATROLE_POINT: float = 3.0

@onready var navigation_agent_2d = $LizardNav
@onready var animation_tree = $AnimationTree
@onready var wet_walk = $wet_walk
@onready var animated_sprite_2d = $ElectricArea/AnimatedSprite2D
@onready var electrical_field = $electrical_field

var direction: Vector2 = Vector2.ZERO
var was_water: bool = false

# Define the lizard's possible states
enum State {
	PATROL,
	PATROL_WAIT,
	LICK_EYE,
	POST_LICK_IDLE
}

var state = State.PATROL  # Initialize to PATROL by default

# Patrol variables
var patrol_points = []
var patrol_index = 0

# Timer for handling waiting periods
var patrol_wait_timer = null

# projectile
var nearby_objects = []

func _ready():
	print("Lizard ready")
	
	animated_sprite_2d.visible = false
	
	SharedSignals.lizard_connection.connect(_play_zap)
	SharedSignals.lizard_connection_made.connect(_play_zap_conductor)
	SharedSignals.lizard_in_water_puddle.connect(_turn_lizard_off)
	SharedSignals.lizard_in_camp_fire.connect(_turn_lizard_on)
	randomize()
	
	_update_electrical_field_sound()
	
	# Set up patrol points
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
	
	if patrol_points.size() > 0:
		navigation_agent_2d.target_position = patrol_points[patrol_index]
		set_physics_process(true)
	else:
		set_physics_process(false)

func _update_electrical_field_sound():
	if is_on:
		if not electrical_field.playing:
			electrical_field.play()
	else:
		electrical_field.max_distance = 40.0

func _physics_process(delta):
	match state:
		State.PATROL:
			patrol_behavior()
		State.PATROL_WAIT:
			pass
		State.LICK_EYE:
			pass
	
	# Update movement
	if state == State.PATROL:
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	
	# Update direction for animations
	if velocity.length() > 0:
		direction = velocity.normalized()
	else:
		direction = Vector2.ZERO
	_update_animation_parameters()

func patrol_behavior():
	if navigation_agent_2d.is_navigation_finished():
		state = State.PATROL_WAIT
		start_patrol_wait_timer()
	else:
		# Move towards patrol point
		var next_path_position = navigation_agent_2d.get_next_path_position()
		direction = (next_path_position - global_position).normalized()
		velocity = direction * speed

func start_patrol_wait_timer():
	_update_animation_parameters()
	
	patrol_wait_timer = Timer.new()
	patrol_wait_timer.wait_time = STOP_AT_PATROLE_POINT
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
	_update_animation_parameters()
	
	var lick_timer = Timer.new()
	lick_timer.wait_time = 1.0
	lick_timer.one_shot = true
	lick_timer.timeout.connect(_on_lick_eye_timeout)
	add_child(lick_timer)
	lick_timer.start()

func _on_lick_eye_timeout():
	# Instead of going directly to patrol, transition to post-lick idle
	state = State.POST_LICK_IDLE
	start_post_lick_idle_timer()

func start_post_lick_idle_timer():
	# Add a short idle period after licking
	var post_lick_timer = Timer.new()
	post_lick_timer.wait_time = 0.5  # Half second idle after licking
	post_lick_timer.one_shot = true
	post_lick_timer.timeout.connect(_on_post_lick_idle_timeout)
	add_child(post_lick_timer)
	post_lick_timer.start()

func _on_post_lick_idle_timeout():
	# Now proceed to next patrol point
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
			State.PATROL_WAIT, State.POST_LICK_IDLE:
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
			State.PATROL_WAIT, State.POST_LICK_IDLE:
				animated_sprite_2d.play("small_activation")
				animated_sprite_2d.visible = true
				animation_tree["parameters/conditions/is_idle_off"] = true
			State.LICK_EYE:
				animated_sprite_2d.play("small_activation")
				animated_sprite_2d.visible = true
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
	
	if is_on:
		if body.is_in_group("conductor"):
			_play_zap(body)
			body.receive_electricity()
		
		if body.is_in_group("m_board"):
			_play_zap(body)
			body.receive_electricity(false)

func _on_electric_area_body_exited(body):
	if body.is_in_group("m_board"):
		if body.connector_name != "none":
			body.stop_electricity(false)

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

func _play_zap_conductor(object):
	if is_on:
		var conductor_position = object.global_position
		var lizard_position = self.global_position
		var direction = (lizard_position - conductor_position).normalized()
		var electrical_zap = preload("res://scenes/Shared/electricity.tscn").instantiate()
		
		var offset_amount = -10
		electrical_zap.global_position = lizard_position + (direction * offset_amount)
		get_tree().current_scene.add_child(electrical_zap)
		electrical_zap.output_charge(direction)

func _play_zap(object):
	if is_on:
		var conductor_position = object.global_position
		var lizard_position = self.global_position
		var direction = (lizard_position - conductor_position).normalized()
		
		var electrical_zap = preload("res://scenes/Shared/electricity.tscn").instantiate()
		
		var offset_amount = -10
		electrical_zap.global_position = lizard_position + (direction * offset_amount)
		get_tree().current_scene.add_child(electrical_zap)
		electrical_zap.output_charge(direction)

func _turn_lizard_off():
	is_on = false
	wet_walk.play()
	_update_electrical_field_sound()

func _turn_lizard_on():
	is_on = true
	_update_electrical_field_sound()

func _on_throw_check_area_area_entered(area):
	if area.is_in_group("throwables"):
		if area.is_in_group("fire"):
			was_water = false
			_change_state()
		if area.is_in_group("water"):
			wet_walk.play()
			was_water = true
			_change_state()

func _on_throw_check_area_body_entered(body):
	if body.is_in_group("environment"):
		if body.is_in_group("fire"):
			was_water = false
			_change_state()
		if body.is_in_group("water"):
			wet_walk.play()
			was_water = true
			_change_state()
	
	if body.is_in_group("throwables"):
		
		if body.is_in_group("fire"):
			was_water = false
		if body.is_in_group("water"):
			wet_walk.play()
			was_water = true
		
		if body and body.get_vines_landed_state():
			body.projectile_landed.connect(_change_state)

func _change_state():
	var previous_state = is_on
	if was_water:
		is_on = false
	else:
		is_on = true
	
	if previous_state != is_on:
		SharedSignals.lizard_state_change.emit(is_on)
		_update_electrical_field_sound()
		
		# Find all bodies in electric area and update their states
		var bodies = $ElectricArea.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("m_board") and body.connector_name != "none":
				if is_on:
					body.receive_electricity(false)
				else:
					body.stop_electricity(false)
			elif body.is_in_group("conductor"):
				if is_on:
					body.receive_electricity()
				else:
					body.stop_electricity()

func _on_player_kill_area_entered(area):
	if area.is_in_group("death_area"):
		SharedSignals.player_killed.emit("pop")
