# CameraManager.gd
extends Node

signal camera_marker_changed(marker: Node2D)

var current_camera_marker: Node2D = null
var previous_camera_marker: Node2D = null
var transition_cooldown: float = 0.0
var can_transition: bool = true
var last_transition_time: float = 0.0

# Screen shake settings
var screen_shake_enabled: bool = true
var base_resolution = Vector2(480, 270)
var current_scale_factor = 1.0

func _ready() -> void:
	load_preferences()
	print("Screen shake enabled: ", screen_shake_enabled)
	
	get_tree().root.size_changed.connect(_update_scale_factor)
	_update_scale_factor()

func _update_scale_factor() -> void:
	var window_size = DisplayServer.window_get_size()
	var window_mode = DisplayServer.window_get_mode()
	
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
	
	current_scale_factor = max(current_scale_factor, 1)

func set_current_marker(marker: Node2D) -> void:
	if !is_instance_valid(marker):
		return
	
	previous_camera_marker = current_camera_marker
	current_camera_marker = marker
	last_transition_time = Time.get_unix_time_from_system()
	camera_marker_changed.emit(marker)

func get_next_marker(player_pos: Vector2, direction: Vector2) -> Node2D:
	if !is_instance_valid(current_camera_marker):
		return null
	
	var markers = get_tree().get_nodes_in_group("camera_markers")
	var best_marker = null
	var best_score = INF
	
	var current_pos = current_camera_marker.global_position
	
	for marker in markers:
		if !is_instance_valid(marker) or marker == current_camera_marker:
			continue
		
		var to_marker = marker.global_position - current_pos
		var dot = direction.normalized().dot(to_marker.normalized())
		
		# Consider markers in the general direction of movement
		if dot > 0.5:
			var distance_score = to_marker.length()
			var direction_score = (1.0 - dot) * 1000  # Weight for directional alignment
			var total_score = distance_score + direction_score
			
			if total_score < best_score:
				best_score = total_score
				best_marker = marker
	
	return best_marker

# Screen shake management
func toggle_screen_shake(enabled: bool) -> void:
	print("Toggling screen shake to: ", enabled)  # Debug print
	screen_shake_enabled = enabled
	save_preferences()

func is_screen_shake_enabled() -> bool:
	return screen_shake_enabled

# Save/load preferences
func save_preferences() -> void:
	var config = ConfigFile.new()
	config.set_value("camera", "screen_shake_enabled", screen_shake_enabled)
	config.save("user://camera_settings.cfg")

func load_preferences() -> void:
	var config = ConfigFile.new()
	if config.load("user://camera_settings.cfg") == OK:
		screen_shake_enabled = config.get_value("camera", "screen_shake_enabled", true)

# Get current scale factor for shake calculations
func get_current_scale_factor() -> float:
	return current_scale_factor
