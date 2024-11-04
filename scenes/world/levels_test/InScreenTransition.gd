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
var current_side: String = "" 

const MOVEMENT_THRESHOLD: float = 0.01
const DIRECTION_THRESHOLD: float = 0.1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("transition_areas")
	
	if !root_marker or !destination_marker:
		push_warning("InScreenTransition: Both root_marker and destination_marker must be set!")

func _physics_process(_delta: float) -> void:
	if !is_instance_valid(player_body) or is_transitioning:
		return
	
	var direction = Vector2.ZERO
	if is_instance_valid(player_body):
		direction = player_body.position - last_position
		
		# Only check for transition if there's actual movement
		if direction.length() > 0.1:
			if move_direction == "horizontal":
				if direction.x != 0:
					transition_direction = Vector2(sign(direction.x), 0).normalized()
					handle_transition()
			else: # vertical
				if direction.y != 0:
					transition_direction = Vector2(0, sign(direction.y)).normalized()
					handle_transition()
		
		last_position = player_body.position

func handle_transition() -> void:
	if is_transitioning:
		return
		
	is_transitioning = true
	
	var camera = get_viewport().get_camera_2d()
	var target = get_target_marker(camera.global_position)
	
	if target:
		# Update current side based on which marker we're transitioning to
		current_side = "root" if target == root_marker else "destination"
		camera.transition_to_marker(target)
	
	await get_tree().create_timer(1.0).timeout
	is_transitioning = false

func get_target_marker(current_pos: Vector2) -> Node2D:
	# If we already transitioned to a side, stay there until player moves away
	if current_side == "root":
		return destination_marker
	elif current_side == "destination":
		return root_marker
		
	# Initial transition - choose based on position
	var dist_to_root = current_pos.distance_to(root_marker.global_position)
	var dist_to_dest = current_pos.distance_to(destination_marker.global_position)
	return destination_marker if dist_to_root < dist_to_dest else root_marker

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and !is_transitioning:
		player_body = body
		last_position = body.position
		current_side = ""

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body == player_body:
			await get_tree().create_timer(0.5).timeout
			player_body = null
			last_position = Vector2.ZERO
			is_transitioning = false
			current_side = ""
