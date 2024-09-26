extends Node2D

# Enumerate possible states for clarity
enum HedgehogState {
	IDLE,
	ANGRY,
	SHOOTING
}

@export var dart_scene: PackedScene
@export var fire_rate: float = 0.5  # Time between each shot when shooting
@export var cone_angle_offset: float = 10.0  # Angle offset for side darts
@export var angry_duration: float = 0.5  # Duration to stay angry before shooting
@onready var shoot_sound = $shoot

@onready var animation_tree = $AnimationTree

var current_state: HedgehogState = HedgehogState.IDLE
var direction: Vector2 = Vector2.ZERO  # Direction the hedgehog is facing
var angry_timer: Timer
var shoot_timer: Timer
var player_visible: bool = false  # Track player visibility
var shoot: bool = false  # Fail-safe to ensure shooting only when allowed

func _ready():
	# Initialize timers
	angry_timer = Timer.new()
	angry_timer.wait_time = angry_duration
	angry_timer.one_shot = true
	angry_timer.timeout.connect(_on_angry_timer_timeout)
	add_child(angry_timer)
	
	shoot_timer = Timer.new()
	shoot_timer.wait_time = fire_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	
	# Connect to global signals
	SharedSignals.player_spotted.connect(_on_player_spotted)
	SharedSignals.player_lost.connect(_on_player_lost)
	
	# Ensure dart_scene is loaded
	if dart_scene == null:
		dart_scene = preload("res://scenes/entities/objects/shoot/dart.tscn")
	
	# Initialize in IDLE state
	_set_state(HedgehogState.IDLE)

# Set the state of the hedgehog
func _set_state(new_state: HedgehogState):
	if new_state == HedgehogState.SHOOTING and current_state != HedgehogState.ANGRY:
		# Prevent transitioning directly to SHOOTING unless already ANGRY
		shoot_sound.play()
		return

	current_state = new_state

	match current_state:
		HedgehogState.IDLE:
			shoot = false  # Ensure shooting is disabled
			_stop_all_timers()  # Stop all timers when in idle state
			_update_animation_parameters()
		HedgehogState.ANGRY:
			shoot = false  # Disable shooting until ready
			_stop_all_timers()  # Stop timers until ready
			angry_timer.start()  # Start the angry timer
			_update_animation_parameters()
		HedgehogState.SHOOTING:
			if player_visible:  # Only start shooting if the player is visible
				shoot = true  # Enable shooting
				shoot_timer.start()
				_update_animation_parameters()


# Update animation parameters based on current direction and state
func _update_animation_parameters():
	direction = (GlobalValues.player_position - global_position).normalized()

	# Set animation conditions based on the current state
	if current_state == HedgehogState.IDLE:
		animation_tree["parameters/conditions/is_idle"] = true
		animation_tree["parameters/conditions/is_angry"] = false
		animation_tree["parameters/conditions/is_shooting"] = false
	elif current_state == HedgehogState.ANGRY:
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_angry"] = true
		animation_tree["parameters/conditions/is_shooting"] = false
	elif current_state == HedgehogState.SHOOTING:
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_angry"] = false
		animation_tree["parameters/conditions/is_shooting"] = true
	
	animation_tree["parameters/idle/blend_position"] = direction
	animation_tree["parameters/angry/blend_position"] = direction
	animation_tree["parameters/shoot/blend_position"] = direction

# Handle player spotted
func _on_player_spotted():
	player_visible = true
	if current_state == HedgehogState.IDLE:
		_set_state(HedgehogState.ANGRY)

# Handle player lost
func _on_player_lost():
	player_visible = false
	shoot = false  # Disable shooting when the player is lost
	if current_state != HedgehogState.IDLE:
		_set_state(HedgehogState.IDLE)

# Timeout for ANGRY state, transition to SHOOTING if player is visible
func _on_angry_timer_timeout():
	if current_state == HedgehogState.ANGRY and player_visible:
		_set_state(HedgehogState.SHOOTING)

# Handle shooting with a timer, revert to IDLE if player is lost
func _on_shoot_timer_timeout():
	if current_state == HedgehogState.SHOOTING and shoot:
		if player_visible:
			_shoot_at_player()
			shoot_timer.start()  # Restart the timer for continuous shooting
		else:
			_set_state(HedgehogState.IDLE)  # Transition to IDLE if the player is no longer visible

# Logic for shooting darts
func _shoot_at_player():
	if dart_scene == null or !shoot:  # Check fail-safe before shooting
		return  # Can't shoot without a dart scene or if shooting is disabled
	
	_spawn_dart(direction)
	
	var left_direction = direction.rotated(deg_to_rad(cone_angle_offset))
	_spawn_dart(left_direction)
	
	var right_direction = direction.rotated(deg_to_rad(-cone_angle_offset))
	_spawn_dart(right_direction)

# Instantiate and shoot a dart
func _spawn_dart(direction: Vector2):
	var dart_instance = dart_scene.instantiate()
	dart_instance.global_position = global_position
	dart_instance.target_position = GlobalValues.player_position  # Set the target position to the player's position
	get_tree().current_scene.add_child(dart_instance)

# Stop all active timers
func _stop_all_timers():
	angry_timer.stop()
	shoot_timer.stop()
