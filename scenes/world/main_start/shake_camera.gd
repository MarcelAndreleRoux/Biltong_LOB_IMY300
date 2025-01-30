extends Camera2D
# Transition properties
@export var transition_speed: float = 0.5
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

	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func apply_shake():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = false
	shake_strength = randomStrength

func apply_shake_jump():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = false
	shake_strength = randomStrength_jump

func apply_shake_smaller():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = false
	shake_strength = randomStrength_small

func apply_shake_semi_small():
	if not CameraManager.is_screen_shake_enabled():
		stop_endless_shake()
		return
	small = true
	shake_strength = randomStrength_semi_small

func apply_shake_super_small():
	if not CameraManager.is_screen_shake_enabled():
		return
	small = true
	shake_strength = randomStrength_super_small

func start_endless_shake_semi_small():
	if not CameraManager.is_screen_shake_enabled():
		return
	endless_shake_enabled = true
	shake_strength = randomStrength_special_small
	small = true

func stop_endless_shake():
	endless_shake_enabled = false
	shake_strength = 0
	offset = Vector2.ZERO

func _on_player_entered_transition(direction: Vector2, currentmarker: Node2D) -> void:
	var next_marker = CameraManager.get_next_marker(global_position, direction)
	if next_marker and next_marker != CameraManager.current_camera_marker:
		if is_transitioning:
			pending_marker = next_marker
		else:
			transition_to_marker(next_marker)

func transition_to_marker(marker: Node2D) -> void:
	if !is_instance_valid(marker):
		return

	if is_transitioning:
		pending_marker = marker
		return

	is_transitioning = true

	if tween and tween.is_valid():
		tween.kill()

	# Calculate movement parameters
	var move_direction = (marker.global_position - global_position).normalized()
	var base_position = marker.global_position
	
	# Bounce parameters (slightly faster)
	var initial_overshoot = 12.0
	var secondary_overshoot = 4.0
	var tertiary_overshoot = 1.5
	var timing_ratio = 0.7  # Increased from 0.6 for faster overall movement

	# Create positions
	var overshoot1 = base_position + (move_direction * initial_overshoot)
	var overshoot2 = base_position - (move_direction * secondary_overshoot)
	var overshoot3 = base_position + (move_direction * tertiary_overshoot)

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Main movement sequence (faster)
	tween.tween_property(self, "global_position", overshoot1, transition_speed * timing_ratio * 0.6).set_ease(Tween.EASE_OUT)  # Reduced from 0.7
	tween.tween_property(self, "global_position", base_position, transition_speed * timing_ratio * 0.2).set_ease(Tween.EASE_IN)  # Reduced from 0.3
	
	# Secondary bounce (faster)
	tween.tween_property(self, "global_position", overshoot2, transition_speed * (1 - timing_ratio) * 0.3).set_ease(Tween.EASE_OUT)  # Reduced from 0.4
	tween.tween_property(self, "global_position", base_position, transition_speed * (1 - timing_ratio) * 0.2).set_ease(Tween.EASE_IN)  # Reduced from 0.3
	
	# Final tiny shake (faster)
	tween.tween_property(self, "global_position", overshoot3, transition_speed * (1 - timing_ratio) * 0.1).set_ease(Tween.EASE_OUT)  # Reduced from 0.2
	tween.tween_property(self, "global_position", base_position, transition_speed * (1 - timing_ratio) * 0.05).set_ease(Tween.EASE_IN)  # Reduced from 0.1

	tween.finished.connect(_on_tween_completed.bind(marker))

func _on_tween_completed(marker: Node2D) -> void:
	is_transitioning = false

	if is_instance_valid(pending_marker) and pending_marker != marker:
		var next_marker = pending_marker
		pending_marker = null
		transition_to_marker(next_marker)

func _process(delta):
	if not CameraManager.is_screen_shake_enabled():
		shake_strength = 0
		endless_shake_enabled = false
		offset = Vector2.ZERO
		return

	if endless_shake_enabled:
		shake_strength = randomStrength_special_small

	if shake_strength > 0:
		if small:
			shake_strength = lerpf(shake_strength, 0, shakeFade_small * delta)
		else:
			shake_strength = lerpf(shake_strength, 0, shakeFade * delta)

		offset = randomOffset()
	else:
		offset = Vector2.ZERO

func randomOffset() -> Vector2:
	return Vector2(
		round(rng.randf_range(-shake_strength, shake_strength)),
		round(rng.randf_range(-shake_strength, shake_strength))
	)
