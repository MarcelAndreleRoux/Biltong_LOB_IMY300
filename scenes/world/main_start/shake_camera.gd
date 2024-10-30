extends Camera2D

# Transition properties
@export var transition_speed: float = 1.0
@onready var tween: Tween = null

# Shake properties
@export var randomStrength: float = 6.0
@export var randomStrength_jump: float = 3.0
@export var randomStrength_small: float = 1.0
@export var randomStrength_semi_small: float = 0.6
@export var randomStrength_special_small: float = 0.55
@export var randomStrength_super_small: float = 0.3
@export var shakeFade = 2
@export var shakeFade_small = 6

# Screen resolution handling
var base_resolution = Vector2(480, 270)
var current_scale_factor = 1.0

var rng = RandomNumberGenerator.new()
var shake_strength = 0
var small: bool = false
var endless_shake_enabled: bool = false

var pending_marker = null
var is_transitioning: bool = false

func _ready() -> void:
	var transition_areas = get_tree().get_nodes_in_group("transition_areas")
	for area in transition_areas:
		area.player_entered.connect(_on_player_entered_transition)
	
	var markers = get_tree().get_nodes_in_group("camera_markers")
	if markers.size() > 0:
		CameraManager.set_current_marker(markers[0])
		global_position = markers[0].global_position
	
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Initialize scale factor
	_update_scale_factor()
	
	# Connect to window size changes
	get_tree().root.size_changed.connect(_on_window_size_changed)

func _update_scale_factor() -> void:
	var window_size = DisplayServer.window_get_size()
	var window_mode = DisplayServer.window_get_mode()
	
	# Calculate scale factor based on window mode
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		var screen_size = DisplayServer.screen_get_size()
		current_scale_factor = min(
			floor(screen_size.x / base_resolution.x),
			floor(screen_size.y / base_resolution.y)
		)
	else:
		current_scale_factor = min(
			floor(window_size.x / base_resolution.x),
			floor(window_size.y / base_resolution.y)
		)
	
	# Ensure minimum scale factor
	current_scale_factor = max(current_scale_factor, 1)

func _on_window_size_changed():
	_update_scale_factor()

func get_adjusted_shake_strength(base_strength: float) -> float:
	# For pixel art, we want to ensure our shake is at least 1 pixel
	var minimum_shake = 1.0
	var scaled_strength = base_strength * CameraManager.get_current_scale_factor()
	
	if base_strength <= randomStrength_semi_small:
		return max(minimum_shake, scaled_strength)
	else:
		return scaled_strength

func apply_shake():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = false
	shake_strength = get_adjusted_shake_strength(randomStrength)

func apply_shake_jump():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = false
	shake_strength = get_adjusted_shake_strength(randomStrength_jump)

func apply_shake_smaller():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = false
	shake_strength = get_adjusted_shake_strength(randomStrength_small)

func apply_shake_semi_small():
	if not CameraManager.is_screen_shake_enabled():
		stop_endless_shake()
		return
	small = true
	shake_strength = get_adjusted_shake_strength(randomStrength_semi_small)

func apply_shake_super_small():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = true
	shake_strength = get_adjusted_shake_strength(randomStrength_super_small)

func start_endless_shake_semi_small():
	if not CameraManager.is_screen_shake_enabled():
		return
	endless_shake_enabled = true
	shake_strength = get_adjusted_shake_strength(randomStrength_special_small)
	small = true

func stop_endless_shake():
	endless_shake_enabled = false
	shake_strength = 0
	offset = Vector2.ZERO  # Important: reset the offset

# Camera Transition Methods
func _on_player_entered_transition(direction: Vector2, _current_marker: Node2D) -> void:
	var next_marker = CameraManager.get_next_marker(global_position, direction)
	if next_marker and next_marker != CameraManager.current_camera_marker:
		if is_transitioning:
			# Buffer the next transition
			pending_marker = next_marker
		else:
			transition_to_marker(next_marker)

func transition_to_marker(marker: Node2D) -> void:
	if !is_instance_valid(marker):
		return
		
	print("Transitioning to marker: ", marker.name)
	
	if is_transitioning:
		# Buffer the next transition
		pending_marker = marker
		return
		
	is_transitioning = true
	
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", marker.global_position, transition_speed)
	
	# Connect to tween completion
	tween.finished.connect(_on_tween_completed.bind(marker))

func _on_tween_completed(marker: Node2D) -> void:
	is_transitioning = false
	
	# Handle pending transition if exists
	if is_instance_valid(pending_marker) and pending_marker != marker:
		var next_marker = pending_marker
		pending_marker = null
		transition_to_marker(next_marker)

# Combined Process Method
func _process(delta):
	# If screen shake is disabled, reset everything
	if not CameraManager.is_screen_shake_enabled():
		shake_strength = 0
		endless_shake_enabled = false
		offset = Vector2.ZERO
		return
		
	# Handle endless shake with scale factor
	if endless_shake_enabled:
		shake_strength = get_adjusted_shake_strength(randomStrength_special_small)
	
	# Handle shake fadeout
	if shake_strength > 0:
		if small:
			shake_strength = lerpf(shake_strength, 0, shakeFade_small * delta)
		else:
			shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		
		# Apply shake offset
		offset = randomOffset()
	else:
		offset = Vector2.ZERO

func randomOffset() -> Vector2:
	# Get the random offset
	var shake_amount = shake_strength / current_scale_factor
	
	# Round to nearest pixel for pixel-perfect movement
	return Vector2(
		round(rng.randf_range(-shake_amount, shake_amount)),
		round(rng.randf_range(-shake_amount, shake_amount))
	)
