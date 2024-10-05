extends Camera2D

@onready var timer = $Timer

@export var randomStrength: float = 10.0
@export var shakeFade = 5.0

@export var randomStrength_small: float = 3.0

@export var randomStrength_super_small: float = 0.5

var rng = RandomNumberGenerator.new()

var shake_stength = 0

func apply_shake():
	shake_stength = randomStrength

func apply_shake_smaller():
	shake_stength = randomStrength_small

func apply_shake_super_small():
	shake_stength = randomStrength_super_small

func _process(delta):
	if shake_stength > 0:
		shake_stength = lerpf(shake_stength, 0, shakeFade * delta)
		
		offset = randomOffset()

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_stength, shake_stength), rng.randf_range(-shake_stength, shake_stength))
