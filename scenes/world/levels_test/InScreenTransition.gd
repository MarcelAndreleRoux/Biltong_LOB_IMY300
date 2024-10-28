extends Area2D

signal player_entered(direction: Vector2, current_marker: Node2D)

@export_enum("horizontal", "vertical") var move_direction: String = "horizontal"

var player_body: CharacterBody2D = null
var last_position: Vector2 = Vector2.ZERO
var movement_buffer = []
const BUFFER_SIZE = 5
var is_transitioning: bool = false
var transition_direction: Vector2 = Vector2.ZERO

const MOVEMENT_THRESHOLD: float = 0.5  # Reduced from 1.0
const DIRECTION_THRESHOLD: float = 0.1  # Keep this for diagonal movement detection

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if !is_instance_valid(player_body) or is_transitioning:
		return
	
	var direction = Vector2.ZERO
	if is_instance_valid(player_body):
		direction = player_body.position - last_position
		
	if direction.length() > 0.1:  # Keep small movements for smoothness
		movement_buffer.push_back(direction)
		if movement_buffer.size() > BUFFER_SIZE:
			movement_buffer.pop_front()
		
		var avg_direction = Vector2.ZERO
		for dir in movement_buffer:
			avg_direction += dir
		avg_direction /= movement_buffer.size()
		
		# Check movement with lower threshold
		if avg_direction.length() > MOVEMENT_THRESHOLD:
			var normalized_dir = avg_direction.normalized()
			
			# Check if movement aligns with allowed direction
			if move_direction == "horizontal":
				if abs(normalized_dir.x) > DIRECTION_THRESHOLD:
					transition_direction = Vector2(sign(normalized_dir.x), 0).normalized()
					handle_transition()
			else: # vertical
				if abs(normalized_dir.y) > DIRECTION_THRESHOLD:
					transition_direction = Vector2(0, sign(normalized_dir.y)).normalized()
					handle_transition()
	
	if is_instance_valid(player_body):
		last_position = player_body.position

func handle_transition() -> void:
	is_transitioning = true
	var closest_marker = get_closest_marker()
	if closest_marker:
		player_entered.emit(transition_direction, closest_marker)
	await get_tree().create_timer(1.0).timeout
	is_transitioning = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and !is_transitioning:
		print("Player entered transition area - Direction: ", move_direction)
		player_body = body
		last_position = body.position
		movement_buffer.clear()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player exited transition area")
		if body == player_body:
			await get_tree().create_timer(0.5).timeout  # Wait before clearing
			movement_buffer.clear()
			player_body = null
			last_position = Vector2.ZERO
			is_transitioning = false

func get_closest_marker() -> Node2D:
	if !is_instance_valid(player_body):
		return null
		
	var markers = get_tree().get_nodes_in_group("camera_markers")
	var closest_marker = null
	var closest_distance = INF
	
	# Get the current camera position from CameraManager
	var current_pos = CameraManager.current_camera_marker.global_position if CameraManager.current_camera_marker else Vector2.ZERO
	
	for marker in markers:
		if !is_instance_valid(marker):
			continue
		
		var to_marker = marker.global_position - current_pos
		
		# Only consider markers in the correct direction
		if move_direction == "horizontal":
			# For horizontal transitions, marker should be primarily to the left or right
			if abs(to_marker.x) > abs(to_marker.y):
				var distance = marker.global_position.distance_to(player_body.global_position)
				if distance < closest_distance:
					closest_distance = distance
					closest_marker = marker
		else: # vertical
			# For vertical transitions, marker should be primarily above or below
			if abs(to_marker.y) > abs(to_marker.x):
				var distance = marker.global_position.distance_to(player_body.global_position)
				if distance < closest_distance:
					closest_distance = distance
					closest_marker = marker
	
	return closest_marker
