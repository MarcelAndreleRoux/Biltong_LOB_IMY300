extends Camera2D

@onready var timer = $Timer

@export var randomStrength: float = 10.0
@export var shakeFade = 5

@export var randomStrength_small: float = 2.0
@export var randomStrength_semi_small: float = 0.3
@export var randomStrength_super_small: float = 0.2
@export var shakeFade_small = 15

var rng = RandomNumberGenerator.new()

var shake_stength = 0
var small: bool = false

func apply_shake():
	small = false
	shake_stength = randomStrength

func apply_shake_smaller():
	small = false
	shake_stength = randomStrength_semi_small

func apply_shake_semi_small():
	small = true
	shake_stength = randomStrength_semi_small

func apply_shake_super_small():
	small = true
	shake_stength = randomStrength_super_small

func _process(delta):
	if shake_stength > 0:
		if small:
			shake_stength = lerpf(shake_stength, 0, shakeFade_small * delta)
		else:
			shake_stength = lerpf(shake_stength, 0, shakeFade * delta)
		
		offset = randomOffset()

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_stength, shake_stength), rng.randf_range(-shake_stength, shake_stength))
