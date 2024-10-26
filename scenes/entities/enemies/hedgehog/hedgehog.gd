extends Node2D

# Enumerate possible states for clarity
enum HedgehogState {
	IDLE,
	ANGRY,
	SHOOTING,
	ANGRY_UP,
	STOMP
}

@export var dart_scene: PackedScene
@export var fire_rate: float = 0.5  # Time between each shot when shooting
@export var cone_angle_offset: float = 10.0  # Angle offset for side darts
@export var angry_duration: float = 0.6  # Duration to stay angry before shooting
@export var angry_up_duration: float = 0.6
@onready var shoot_sound = $shoot

@onready var animation_tree = $AnimationTree
@onready var detection_area = $DetectionArea

var current_state: HedgehogState = HedgehogState.IDLE
var direction: Vector2 = Vector2.ZERO  # Direction the hedgehog is facing

var can_kill_player: bool = false

var tracked_projectiles: Array = []
var should_despawn: bool = false

# Throwable
var can_spike_throwable: bool = true

# Timers
var angry_timer: Timer
var shoot_timer: Timer
var angry_up_timer: Timer
var throwable_spike_timer: Timer

var player_visible: bool = false
var shoot: bool = false
var projectile: BaseThrowable = null

var has_throwable_to_stomp: bool = false
var can_stomp: bool = true

var pending_stomp_projectile: BaseThrowable = null
var stomp: bool = false

func _ready():
	animation_tree.active = true
	
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
	
	angry_up_timer = Timer.new()
	angry_up_timer.wait_time = angry_up_duration
	angry_up_timer.one_shot = true
	angry_up_timer.timeout.connect(_on_angry_up_timer_timeout)
	add_child(angry_up_timer)
	
	throwable_spike_timer = Timer.new()
	throwable_spike_timer.wait_time = 0.3
	throwable_spike_timer.one_shot = true
	throwable_spike_timer.timeout.connect(_on_throwable_spike_timer_timeout)
	add_child(throwable_spike_timer)
	
	# Connect to global signals
	SharedSignals.player_spotted.connect(_on_player_spotted)
	SharedSignals.player_lost.connect(_on_player_lost)
	
	# Ensure dart_scene is loaded
	if dart_scene == null:
		dart_scene = preload("res://scenes/entities/objects/shoot/dart.tscn")
	
	# Initialize in IDLE state
	_set_state(HedgehogState.IDLE)

func _on_angry_up_timer_timeout():
	if current_state == HedgehogState.ANGRY_UP:
		_set_state(HedgehogState.IDLE)

# Set the state of the hedgehog
func _set_state(new_state: HedgehogState):
	if new_state == HedgehogState.SHOOTING and current_state != HedgehogState.ANGRY:
		shoot_sound.play()
		return

	current_state = new_state

	match current_state:
		HedgehogState.IDLE:
			shoot = false
			_stop_all_timers()
			_update_animation_parameters()
			# Check for throwables to stomp
			_check_for_throwables_to_stomp()
		HedgehogState.ANGRY:
			shoot = false
			_stop_all_timers()
			angry_timer.start()
			_update_animation_parameters()
		HedgehogState.SHOOTING:
			if player_visible:
				shoot = true
				shoot_timer.start()
				_update_animation_parameters()
		HedgehogState.ANGRY_UP:
			shoot = false
			_stop_all_timers()
			if not angry_up_timer.is_stopped():
				angry_up_timer.stop()
			angry_up_timer.start()
			_update_animation_parameters()
		HedgehogState.STOMP:
			stomp = true
			shoot = false
			_stop_all_timers()
			_update_animation_parameters()
			await get_tree().create_timer(0.9).timeout
			has_throwable_to_stomp = false
			_set_state(HedgehogState.IDLE)

func _physics_process(_delta):
	if current_state == HedgehogState.IDLE:
		_check_for_throwables_to_stomp()
	
	# Check all tracked projectiles
	if not shoot:
		var i = tracked_projectiles.size() - 1
		while i >= 0:
			var projectile = tracked_projectiles[i]
			if is_instance_valid(projectile):
				if projectile.get_landed_state():
					projectile._remove_myself()
					tracked_projectiles.remove_at(i)
			else:
				# Remove invalid projectiles
				tracked_projectiles.remove_at(i)
			i -= 1

func _check_for_throwables_to_stomp():
	# Check for any landed throwables in the detection area
	has_throwable_to_stomp = false
	for projectile in tracked_projectiles:
		if projectile.get_landed_state():
			has_throwable_to_stomp = true
			break
	
	if has_throwable_to_stomp and can_stomp:
		_set_state(HedgehogState.STOMP)

# Update animation parameters based on current direction and state
func _update_animation_parameters():
	direction = (GlobalValues.player_position - global_position).normalized()

	# Reset all conditions
	animation_tree.set("parameters/conditions/is_idle", false)
	animation_tree.set("parameters/conditions/is_stomp", false)
	animation_tree.set("parameters/conditions/is_angry", false)
	animation_tree.set("parameters/conditions/is_shooting", false)
	animation_tree.set("parameters/conditions/is_angry_up", false)

	# Set animation conditions based on the current state
	match current_state:
		HedgehogState.STOMP:
			animation_tree.set("parameters/conditions/is_stomp", true)
			var playback = animation_tree.get("parameters/playback")
			if playback:
				playback.travel("stomp")
		HedgehogState.IDLE:
			animation_tree.set("parameters/conditions/is_idle", true)
		HedgehogState.ANGRY:
			animation_tree.set("parameters/conditions/is_angry", true)
		HedgehogState.SHOOTING:
			animation_tree.set("parameters/conditions/is_shooting", true)
		HedgehogState.ANGRY_UP:
			animation_tree.set("parameters/conditions/is_angry_up", true)

	_update_blend_positions(direction)

func _update_blend_positions(dir: Vector2):
	var blend_nodes = ["idle", "angry", "shoot", "angry_up", "stomp"]
	for node in blend_nodes:
		var path = "parameters/" + node + "/blend_position"
		animation_tree.set(path, dir)

# Handle player spotted
func _on_player_spotted():
	player_visible = true
	if current_state == HedgehogState.IDLE:
		_set_state(HedgehogState.ANGRY)

# Handle player lost
func _on_player_lost():
	player_visible = false
	shoot = false
	# Only transition to ANGRY_UP if we're not already in ANGRY_UP or IDLE
	if current_state != HedgehogState.ANGRY_UP and current_state != HedgehogState.IDLE:
		_set_state(HedgehogState.ANGRY_UP)

# Timeout for ANGRY state, transition to SHOOTING if player is visible
func _on_angry_timer_timeout():
	if current_state == HedgehogState.ANGRY:
		if player_visible:
			_set_state(HedgehogState.SHOOTING)
		else:
			_set_state(HedgehogState.ANGRY_UP)

# Handle shooting with a timer, revert to IDLE if player is lost
func _on_shoot_timer_timeout():
	if current_state == HedgehogState.SHOOTING and shoot:
		if player_visible:
			_shoot_at_player()
			shoot_timer.start()
		else:
			_set_state(HedgehogState.ANGRY_UP)

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
	dart_instance.target_position = GlobalValues.player_position
	get_tree().current_scene.add_child(dart_instance)

func shake_camera_call():
	SharedSignals.shake_hedgehog.emit()

# Stop all active timers
func _stop_all_timers():
	angry_timer.stop()
	shoot_timer.stop()
	angry_up_timer.stop()

func _change_state():
	projectile._remove_myself()

func _on_throwable_spike_timer_timeout():
	can_spike_throwable = true

func check_player_kill():
	if can_kill_player:
		SharedSignals.player_killed.emit("peg")

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		can_kill_player = true
		_set_state(HedgehogState.STOMP)
	else:
		can_kill_player = false
	
	if body.is_in_group("throwables"):
		if not tracked_projectiles.has(body):
			tracked_projectiles.append(body)

func _on_area_2d_body_exited(body):
	tracked_projectiles.erase(body)

func _on_animation_tree_animation_finished(anim_name: StringName):
	if stomp:
		_set_state(HedgehogState.IDLE)
