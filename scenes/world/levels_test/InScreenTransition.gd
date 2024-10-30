extends Area2D

signal player_entered(direction: Vector2)

@export_enum("horizontal", "vertical") var move_direction: String = "horizontal"
@export var root_marker: Node2D
@export var destination_marker: Node2D

var player_body: CharacterBody2D = null
var last_position: Vector2 = Vector2.ZERO
var movement_buffer = []
const BUFFER_SIZE = 5
var is_transitioning: bool = false
var transition_direction: Vector2 = Vector2.ZERO

const MOVEMENT_THRESHOLD: float = 0.5
const DIRECTION_THRESHOLD: float = 0.1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("transition_areas")
	
	# Validate that both markers are set
	if !root_marker or !destination_marker:
		push_warning("InScreenTransition: Both root_marker and destination_marker must be set!")

func _physics_process(_delta: float) -> void:
	if !is_instance_valid(player_body) or is_transitioning:
		return
	
	var direction = Vector2.ZERO
	if is_instance_valid(player_body):
		direction = player_body.position - last_position
		
	if direction.length() > 0.1:
		movement_buffer.push_back(direction)
		if movement_buffer.size() > BUFFER_SIZE:
			movement_buffer.pop_front()
		
		var avg_direction = Vector2.ZERO
		for dir in movement_buffer:
			avg_direction += dir
		avg_direction /= movement_buffer.size()
		
		if avg_direction.length() > MOVEMENT_THRESHOLD:
			var normalized_dir = avg_direction.normalized()
			
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
	
	# Get the target marker based on current camera position
	var camera = get_viewport().get_camera_2d()
	var target = get_target_marker(camera.global_position)
	
	if target:
		camera.transition_to_marker(target)
	
	await get_tree().create_timer(1.0).timeout
	is_transitioning = false

func get_target_marker(current_pos: Vector2) -> Node2D:
	# Get the marker that's furthest from the current position
	var dist_to_root = current_pos.distance_to(root_marker.global_position)
	var dist_to_dest = current_pos.distance_to(destination_marker.global_position)
	
	# If we're closer to root, go to destination, and vice versa
	return destination_marker if dist_to_root < dist_to_dest else root_marker

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
			await get_tree().create_timer(0.5).timeout
			movement_buffer.clear()
			player_body = null
			last_position = Vector2.ZERO
			is_transitioning = false
