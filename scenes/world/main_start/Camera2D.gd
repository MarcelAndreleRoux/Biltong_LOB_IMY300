extends Camera2D

# Transition properties
@export var transition_speed: float = 1.0
@onready var tween: Tween = null

# Shake properties
@export var randomStrength: float = 5.0
@export var randomStrength_jump: float = 3.0
@export var randomStrength_small: float = 1.5
@export var randomStrength_semi_small: float = 0.6
@export var randomStrength_special_small: float = 0.55
@export var randomStrength_super_small: float = 0.3
@export var shakeFade = 4
@export var shakeFade_small = 2

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
	small = false
	shake_strength = get_adjusted_shake_strength(randomStrength)

func apply_shake_smaller():
	small = true
	shake_strength = get_adjusted_shake_strength(randomStrength_small)

func _process(delta):
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
