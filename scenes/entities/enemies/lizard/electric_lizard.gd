extends CharacterBody2D

@export var speed: float = 50.0  # Speed of the lizard

# Exported variables for patrol points (markers)
@export var target_1: Node2D = null
@export var target_2: Node2D = null
@export var target_3: Node2D = null
@export var target_4: Node2D = null
@export var target_5: Node2D = null

@onready var navigation_agent_2d = $LizardNav
@onready var animation_tree = $AnimationTree

# State variables
var play_moving: bool = true
var direction: Vector2 = Vector2.ZERO
var is_on: bool = true
var is_idle: bool = false

# Patrol variables
var patrol_points = []
var patrol_index = 0

func _ready():
	print("Lizard ready")
	
	# Collect patrol points if any
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
	if play_moving:
		if navigation_agent_2d.is_navigation_finished():
			_on_marker_reached()
		else:
			# Update velocity based on navigation agent
			var next_path_position = navigation_agent_2d.get_next_path_position()
			var current_position = global_position
			direction = (next_path_position - current_position).normalized()
			velocity = direction * speed
			move_and_slide()
	else:
		velocity = Vector2.ZERO
	
	_update_animation_parameters()

func _on_marker_reached():
	print("Lizard reached a marker, stopping to wait.")
	play_moving = false
	is_idle = true
	velocity = Vector2.ZERO
	
	# Start a timer to wait before moving to the next patrol point
	var wait_timer = Timer.new()
	wait_timer.wait_time = 2.0  # Adjust the wait time as needed
	wait_timer.one_shot = true
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	add_child(wait_timer)
	wait_timer.start()

func _on_wait_timer_timeout():
	# After waiting, proceed to the next patrol point
	patrol_index = (patrol_index + 1) % patrol_points.size()
	navigation_agent_2d.target_position = patrol_points[patrol_index]
	play_moving = true
	is_idle = false

func _update_animation_parameters():
	if is_on:
		if play_moving:
			animation_tree["parameters/conditions/is_run_on"] = true
			animation_tree["parameters/conditions/is_run_off"] = false
			animation_tree["parameters/conditions/is_idle_on"] = false
			animation_tree["parameters/conditions/is_idle_off"] = false
		elif is_idle:
			animation_tree["parameters/conditions/is_idle_on"] = true
			animation_tree["parameters/conditions/is_idle_off"] = false
			animation_tree["parameters/conditions/is_lick_on"] = false
			animation_tree["parameters/conditions/is_lick_off"] = false
	else:
		if play_moving:
			animation_tree["parameters/conditions/is_run_on"] = false
			animation_tree["parameters/conditions/is_run_off"] = true
			animation_tree["parameters/conditions/is_idle_on"] = false
			animation_tree["parameters/conditions/is_idle_off"] = false
		elif is_idle:
			animation_tree["parameters/conditions/is_idle_on"] = false
			animation_tree["parameters/conditions/is_idle_off"] = true
			animation_tree["parameters/conditions/is_lick_on"] = false
			animation_tree["parameters/conditions/is_lick_off"] = false
	
	# Update blend positions for animations
	animation_tree["parameters/idle_off/blend_position"] = direction
	animation_tree["parameters/idle_on/blend_position"] = direction
	animation_tree["parameters/lick_off/blend_position"] = direction
	animation_tree["parameters/lick_on/blend_position"] = direction
	animation_tree["parameters/run_off/blend_position"] = direction
	animation_tree["parameters/run_on/blend_position"] = direction

func _on_electric_area_body_entered(body):
	pass

func _on_electric_area_body_exited(body):
	pass
