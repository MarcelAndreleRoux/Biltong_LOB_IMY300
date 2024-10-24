extends CharacterBody2D

class_name player_class

signal update_health(health: int, position: Vector2)
signal update_inventory(item: String)
signal drag_box(position: Vector2, direction: Vector2)

# Nodes
@onready var animation_tree = $AnimationTree
@onready var trajectory_line = $TrajectoryLine
@onready var base_world = get_parent()
@onready var throwhold = $throwhold
@onready var box_move_area_collider = $BoxMoveArea/CollisionShape2D

# Sounds
@onready var error = $error
@onready var pickup = $pickup
@onready var throw = $throw
@onready var box_drop = $box_drop
@onready var death_sound = $death_sound

@export var add_distance_blocker: bool = true

var cooldown_timer: Timer = null

# Dash variables
var is_dashing: bool = false
var dash_speed: float = 200.0  # Speed of the dash
var dash_time: float = 0.15    # How long the dash lasts (in seconds)
var dash_timer: float = 0.0    # Tracks dash time

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

var MIN_AIM_DISTANCE: float = ProjectileConstants.MIN_AIM_DISTANCE
var soft_max_distance: float = ProjectileConstants.SOFT_MAX_DISTANCE
var hard_max_distance: float = ProjectileConstants.HARD_MAX_DISTANCE

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
var trajectory_raycasts: Array[RayCast2D] = []
var first_collision_point: Vector2 = Vector2.ZERO

var min_db = -80  # Minimum volume in decibels (silence)
var max_db = 0    # Maximum volume in decibels (full volume)
var fade_speed = 0.1  # Speed of volume fade in and out

var throw_in_progress: bool = false
var throw_animation_played: bool = false  # Track if the throw animation was triggered
var throw_direction: Vector2 = Vector2.ZERO  # Store the direction of the throw

var _end
var my_local_pos

func _ready():
	animation_tree.active = true
	can_throw_proj = GlobalValues.can_throw
	can_aim_throw = GlobalValues.can_throw
	
	base_world.throw_action.connect(_on_throw_action)
	
	SharedSignals.player_move.connect(_change_speed)
	SharedSignals.player_exit.connect(_change_speed_back)
	
	SharedSignals.can_throw_projectile.connect(_on_can_throw)
	SharedSignals.item_pickup.connect(_on_item_pickup)
	SharedSignals.player_killed.connect(_on_player_killed)
	SharedSignals.push_player_forward.connect(start_dash)

func _on_item_pickup():
	can_aim_throw = true

func _on_can_throw():
	can_throw_proj = true

func _change_speed():
	player_in_box_area = true

func _change_speed_back():
	player_in_box_area = false
	is_dragging = false
	drag_toggle_mode = false
	update_speed()

func update_speed():
	if is_dragging or is_pushing:
		speed = 40
	else:
		speed = 100

func _physics_process(delta):
	if is_dashing:
		_perform_dash(delta)
	else:
		_handle_movement_input()

	update_box_collider_position()

	# Get mouse position and calculate the direction to the mouse from the player
	_end = get_local_mouse_position()
	my_local_pos = to_local(global_position)
	var aim_direction = _end - global_position
	var distance_to_mouse = aim_direction.length()

	if can_aim_throw:
		if Input.is_action_pressed("aim"):
			is_aiming = true
			trajectory_line.visible = true
			calculate_trajectory()
		elif not Input.is_action_pressed("aim"):
			reset_aiming_state()
			reset_throw_state()
	
	_handle_action_input()
	_play_movement_animation()
	_update_animation_parameters()

	# Apply the calculated velocity
	velocity = currentVelocity
	move_and_slide()

	if is_dragging and player_in_box_area:
		var direction_to_mouse = (get_global_mouse_position() - global_position).normalized()
		SharedSignals.drag_box.emit(global_position, direction_to_mouse)

func reset_throw_state():
	# Reset throw and aiming-related states
	throw_in_progress = false
	is_aiming = false

	# Reset throw animation parameters
	animation_tree["parameters/conditions/is_idle_throw"] = false
	animation_tree["parameters/conditions/is_run_throw"] = false
	
	if is_aiming:
		if currentVelocity == Vector2.ZERO:
			# Play the idle aiming animation if the player is stationary
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = true
			animation_tree["parameters/conditions/is_run_aim"] = false
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false
		else:
			# Play the running aiming animation if the player is moving
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/is_run_aim"] = true
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false
	else:
		# Otherwise, return to idle or running animation based on player state
		_play_movement_animation()

	# Hide trajectory and reset its color
	trajectory_line.visible = false
	trajectory_line.default_color = Color(1, 1, 1)

	# Stop any ongoing shake or sound effects
	SharedSignals.start_player_screen_shake.emit(false)
	fade_out_audio(throwhold)

func update_box_collider_position():
	var offset = Vector2.ZERO

	if currentVelocity.x > 0:  # Moving right
		offset.x = 5
	elif currentVelocity.x < 0:  # Moving left
		offset.x = -5

	if currentVelocity.y > 0:  # Moving down
		offset.y = 4
	elif currentVelocity.y < 0:  # Moving up
		offset.y = -4

	box_move_area_collider.position = offset

func _on_throw_action():
	if not is_on_cooldown:
		throw_clicked = true
		throw_in_progress = true
		throw_animation_played = false  # Reset for the new throw
		throw_direction = (get_global_mouse_position() - global_position).normalized()
		direction = throw_direction  # Player faces the throw direction
		_start_cooldown_timer()

func stop_throwhold_sound():
	# Fade out the throwhold sound and stop it
	if throwhold.playing:
		# Convert min_db to a float to ensure all arguments are the same type
		throwhold.volume_db = lerp(throwhold.volume_db, float(min_db), fade_speed)
		if throwhold.volume_db <= float(min_db) + 0.01:
			throwhold.stop()

func _handle_movement_input():
	currentVelocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if currentVelocity != Vector2.ZERO:
		direction = currentVelocity.normalized()
		currentVelocity *= speed
	else:
		currentVelocity = Vector2.ZERO

func start_dash():
	is_dashing = true
	dash_timer = dash_time
	currentVelocity = Vector2(0, 1) * dash_speed

func _perform_dash(delta):
	if dash_timer > 0:
		dash_timer -= delta
		currentVelocity = Vector2(0, 1) * dash_speed
	else:
		is_dashing = false
		currentVelocity = Vector2.ZERO

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
				pickup.play()
				SharedSignals.is_dragging_box.emit(true)
				print("Dragging started")
			else:
				is_dragging = false
				box_drop.play()
				SharedSignals.is_dragging_box.emit(false)
				print("Dragging stopped")
			update_speed()  # Update speed when is_dragging changes

func _start_cooldown_timer():
	is_on_cooldown = true
	if cooldown_timer == null:
		cooldown_timer = Timer.new()
		cooldown_timer.wait_time = 0.5
		cooldown_timer.one_shot = true
		cooldown_timer.timeout.connect(_end_cooldown)
		add_child(cooldown_timer)
	else:
		cooldown_timer.stop()
		cooldown_timer.wait_time = 0.5  # Reset the wait time
	cooldown_timer.start()

func _end_cooldown():
	# Reset cooldown and stop the throw animation
	is_on_cooldown = false
	throw_clicked = false
	throw_in_progress = false
	throw_animation_played = false
	# Allow direction changes only after cooldown ends
	direction = currentVelocity.normalized() if currentVelocity != Vector2.ZERO else direction
	# Check if the player is still aiming after the throw
	if is_aiming:
		if currentVelocity == Vector2.ZERO:
			# Play the idle aiming animation if the player is stationary
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = true
			animation_tree["parameters/conditions/is_run_aim"] = false
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false
		else:
			# Play the running aiming animation if the player is moving
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/is_run_aim"] = true
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false
	else:
		# Otherwise, return to idle or running animation based on player state
		_play_movement_animation()

func _update_animation_parameters():
	# Update blend positions for animations
	if direction != Vector2.ZERO:
		animation_tree["parameters/idle/blend_position"] = direction
		animation_tree["parameters/idle_aim/blend_position"] = direction
		animation_tree["parameters/idle_throw/blend_position"] = throw_direction
		animation_tree["parameters/run/blend_position"] = direction
		animation_tree["parameters/run_aim/blend_position"] = direction
		animation_tree["parameters/run_throw/blend_position"] = throw_direction
		animation_tree["parameters/Death/blend_position"] = direction
		animation_tree["parameters/Death_Pop/blend_position"] = direction

func fade_in_audio(audio_player: AudioStreamPlayer2D):
	if not audio_player.playing:
		audio_player.play()  # Start the audio if it's not playing
	audio_player.volume_db = lerp(audio_player.volume_db, float(max_db), fade_speed)

# Audio fade-out function
func fade_out_audio(audio_player: AudioStreamPlayer2D):
	if audio_player.playing:
		audio_player.volume_db = lerp(audio_player.volume_db, float(min_db), fade_speed)
		if audio_player.volume_db <= float(min_db) + 0.01:
			audio_player.stop()

func update_trajectory_raycasts():
	# Clear old raycasts
	for raycast in trajectory_raycasts:
		raycast.queue_free()
	trajectory_raycasts.clear()
	first_collision_point = Vector2.ZERO
	
	# No points to check
	if points.size() < 2:
		return
		
	var has_collision = false
	
	# Create raycasts between consecutive points
	for i in range(points.size() - 1):
		var raycast = RayCast2D.new()
		add_child(raycast)
		raycast.collision_mask = 1  # Adjust this to match your collision layers
		raycast.exclude_parent = true
		
		# Check if entities exist in the base world before adding exceptions
		if base_world.has_node("Turtle") and base_world.turtle != null:
			raycast.add_exception(base_world.turtle)
		
		if base_world.has_node("Hedgehog") and base_world.hedgehog != null:
			raycast.add_exception(base_world.hedgehog)
			
		# Optional: Check for vines group
		for vine in get_tree().get_nodes_in_group("vines"):
			raycast.add_exception(vine)
		
		trajectory_raycasts.append(raycast)
		
		# Get current point and next point
		var current_point = points[i]
		var next_point = points[i + 1]
		
		# Calculate direction and distance between points
		var direction = next_point - current_point
		var distance = direction.length()
		
		# Position raycast at the current point and point it towards the next point
		raycast.global_position = to_global(current_point)
		raycast.target_position = direction
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			has_collision = true
			if first_collision_point == Vector2.ZERO:
				first_collision_point = raycast.get_collision_point()
				points = points.slice(0, i + 2)
				points[-1] = to_local(first_collision_point)
				break
	
	get_parent().trajectory_collision_state.emit(has_collision)
	trajectory_line.points = points

func calculate_trajectory():
	var aim_direction = _end - my_local_pos
	var aim_distance = aim_direction.length()
	var is_at_max_distance = false
	
	var collision_found = false
	var collision_point = Vector2.ZERO
	var collision_index = -1
	var original_points = []
	
	# Initial shader parameter update
	if trajectory_line.material is ShaderMaterial:
		trajectory_line.material.set_shader_parameter("distance", aim_distance)
	
	# Handle distance constraints
	if add_distance_blocker:
		if is_aiming:
			if aim_distance < MIN_AIM_DISTANCE:
				aim_direction = aim_direction.normalized() * MIN_AIM_DISTANCE
				_end = my_local_pos + aim_direction
				aim_distance = MIN_AIM_DISTANCE
			elif aim_distance > soft_max_distance:
				var extra_distance = aim_distance - soft_max_distance
				var stretch_factor = (hard_max_distance - soft_max_distance) / (extra_distance + (hard_max_distance - soft_max_distance))
				aim_distance = soft_max_distance + extra_distance * stretch_factor
				aim_distance = min(aim_distance, hard_max_distance)
				aim_direction = aim_direction.normalized() * aim_distance
				_end = my_local_pos + aim_direction
				is_at_max_distance = true
				SharedSignals.start_player_screen_shake.emit(true)
				fade_in_audio(throwhold)
			else:
				is_at_max_distance = false
			
			# Update audio based on aim distance
			var aim_volume = (aim_distance - MIN_AIM_DISTANCE) / (hard_max_distance - MIN_AIM_DISTANCE)
			aim_volume = clamp(aim_volume, 0.0, 1.0)
			var volume_db = lerp(float(min_db), float(max_db), aim_volume)
			throwhold.volume_db = lerp(throwhold.volume_db, volume_db, fade_speed)
		else:
			reset_aiming_state()
			return
	
	if not is_at_max_distance:
		SharedSignals.start_player_screen_shake.emit(false)
		fade_out_audio(throwhold)
	
	# Calculate trajectory points
	var DOT = Vector2(1.0, 0.0).dot(aim_direction.normalized())
	var angle = 90 - 45 * DOT
	var gravity = -9.8
	var num_of_points = 50
	
	var x_dis = _end.x - my_local_pos.x
	var y_dis = -1.0 * (_end.y - my_local_pos.y)
	
	var speed = sqrt((0.5 * gravity * x_dis * x_dis) / pow(cos(deg_to_rad(angle)), 2.0) / (y_dis - (tan(deg_to_rad(angle)) * x_dis)))
	
	var x_component = cos(deg_to_rad(angle)) * speed
	var y_component = sin(deg_to_rad(angle)) * speed
	
	var total_time = x_dis / x_component
	
	# Generate trajectory points
	points.clear()
	for point in range(num_of_points):
		var time = total_time * (float(point) / float(num_of_points))
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		var new_point = my_local_pos + Vector2(dx, dy)
		points.append(new_point)
		original_points.append(new_point)  # Keep a copy of the full trajectory
	
	# Update raycasts and check for collisions
	update_trajectory_raycasts()
	
	# Process raycast collisions
	for i in range(trajectory_raycasts.size()):
		if trajectory_raycasts[i].is_colliding():
			collision_found = true
			collision_point = trajectory_raycasts[i].get_collision_point()
			collision_index = i
			break
	
	# Get baseworld reference
	var baseworld = get_parent()
	
	# Only truncate the trajectory if both systems detect a collision
	if collision_found and baseworld.player_raycast_collision:
		# Convert collision point to local coordinates
		var local_collision_point = to_local(collision_point)
		
		# Truncate trajectory at collision
		points = points.slice(0, collision_index + 2)
		points[-1] = local_collision_point
	else:
		# Use full trajectory
		points = original_points
	
	# Update trajectory line
	trajectory_line.points = points
	
	# Update shader parameters
	if trajectory_line.material is ShaderMaterial:
		var both_colliding = collision_found and baseworld.player_raycast_collision
		trajectory_line.material.set_shader_parameter("is_colliding", both_colliding)
		trajectory_line.material.set_shader_parameter("distance", aim_distance)
	
	# Emit collision state to BaseWorld
	get_parent().trajectory_collision_state.emit(collision_found)

# Add this function to clean up raycasts when needed
func clear_trajectory_raycasts():
	for raycast in trajectory_raycasts:
		raycast.queue_free()
	trajectory_raycasts.clear()
	first_collision_point = Vector2.ZERO

# Modify your reset_aiming_state function to include raycast cleanup:
func reset_aiming_state():
	clear_trajectory_raycasts()
	is_aiming = false
	trajectory_line.visible = false
	get_parent().trajectory_collision_state.emit(false)  # Reset collision state
	
	var aim_direction = (_end - global_position).normalized() * MIN_AIM_DISTANCE
	_end = global_position + aim_direction
	trajectory_line.default_color = Color(1, 1, 1)
	
	SharedSignals.start_player_screen_shake.emit(false)
	fade_out_audio(throwhold)

# New function to apply shaking effect to trajectory line
func apply_trajectory_shake():
	var shake_intensity = 5.0  # Adjust the intensity of the shake
	var shake_speed = 0.1      # How fast the shaking occurs

	# Apply a random offset to each point of the trajectory
	for i in range(points.size()):
		var random_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity)) * shake_speed
		points[i] += random_offset

	# Update the trajectory line with shaken points
	trajectory_line.points = points

func _play_movement_animation():
	if is_on_cooldown and throw_clicked:
		if not throw_animation_played:
			throw_animation_played = true
			
			if currentVelocity == Vector2.ZERO:
				animation_tree["parameters/conditions/idle"] = false
				animation_tree["parameters/conditions/is_run"] = false
				animation_tree["parameters/conditions/is_idle_aim"] = false
				animation_tree["parameters/conditions/is_run_aim"] = false
				animation_tree["parameters/conditions/is_run_throw"] = false
				animation_tree["parameters/conditions/is_idle_throw"] = true
			else:
				animation_tree["parameters/conditions/idle"] = false
				animation_tree["parameters/conditions/is_run"] = false
				animation_tree["parameters/conditions/is_run_aim"] = false
				animation_tree["parameters/conditions/is_idle_aim"] = false
				animation_tree["parameters/conditions/is_idle_throw"] = false
				animation_tree["parameters/conditions/is_run_throw"] = true
		return  # Ensure no other animations play during cooldown

	# Normal movement and aiming animations after cooldown
	if currentVelocity == Vector2.ZERO:
		if is_aiming:
			animation_tree["parameters/conditions/is_idle_aim"] = true
			animation_tree["parameters/conditions/is_run_aim"] = false
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			# Ensure throw animations are false
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false
		else:
			animation_tree["parameters/conditions/idle"] = true
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/is_run_aim"] = false
			# Ensure throw animations are false
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false
	else:
		if is_aiming:
			animation_tree["parameters/conditions/is_run_aim"] = true
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			# Ensure throw animations are false
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false
		else:
			animation_tree["parameters/conditions/is_run"] = true
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/is_run_aim"] = false
			# Ensure throw animations are false
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_run_throw"] = false



func _on_box_move_area_area_entered(area):
	if area.is_in_group("box_collider"):
		is_pushing = true
		update_speed()

func _on_box_move_area_area_exited(area):
	if area.is_in_group("box_collider"):
		is_pushing = false
		update_speed()
