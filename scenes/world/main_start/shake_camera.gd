extends Camera2D

@onready var timer = $Timer

@export var randomStrength: float = 10.0
@export var shakeFade = 5

@export var randomStrength_small: float = 2.0
@export var randomStrength_semi_small: float = 0.3
@export var randomStrength_super_small: float = 0.2
@export var shakeFade_small = 15

var rng = RandomNumberGenerator.new()

var shake_strength = 0
var small: bool = false
var endless_shake_enabled: bool = false  # Flag for endless shake

func apply_shake():
	small = false
	shake_strength = randomStrength

func apply_shake_smaller():
	small = false
	shake_strength = randomStrength_small

func apply_shake_semi_small():
	small = true
	shake_strength = randomStrength_semi_small

func apply_shake_super_small():
	small = true
	shake_strength = randomStrength_super_small

# Start endless semi-small shake
func start_endless_shake_semi_small():
	endless_shake_enabled = true
	shake_strength = randomStrength_semi_small
	small = true

# Stop endless semi-small shake
func stop_endless_shake():
	endless_shake_enabled = false

func _process(delta):
	# Keep applying semi-small shake if the endless flag is true
	if endless_shake_enabled:
		shake_strength = randomStrength_semi_small  # Reset shake strength to maintain semi-small shake
	
	# Handle the actual screen shake logic
	if shake_strength > 0:
		if small:
			shake_strength = lerpf(shake_strength, 0, shakeFade_small * delta)
		else:
			shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		
		offset = randomOffset()

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
