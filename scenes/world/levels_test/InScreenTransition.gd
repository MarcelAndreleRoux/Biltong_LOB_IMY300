extends Area2D
signal player_entered(direction: Vector2)
@export_enum("horizontal", "vertical") var move_direction: String = "horizontal"
@export var root_marker: Node2D
@export var destination_marker: Node2D
var player_body: CharacterBody2D = null
var last_position: Vector2 = Vector2.ZERO
var is_transitioning: bool = false
var transition_direction: Vector2 = Vector2.ZERO
const MOVEMENT_THRESHOLD: float = 0.001

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("transition_areas")
	if !root_marker or !destination_marker:
		push_warning("InScreenTransition: Both root_marker and destination_marker must be set!")

func _physics_process(delta: float) -> void:
	if !is_instance_valid(player_body) or is_transitioning:
		return

	var direction = player_body.position - last_position
	if direction.length() > MOVEMENT_THRESHOLD:
		if move_direction == "horizontal" and abs(direction.x) > MOVEMENT_THRESHOLD:
			transition_direction = Vector2(sign(direction.x), 0)
			handle_transition()
		elif move_direction == "vertical" and abs(direction.y) > MOVEMENT_THRESHOLD:
			transition_direction = Vector2(0, sign(direction.y))
			handle_transition()
	last_position = player_body.position

func handle_transition() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var camera = get_viewport().get_camera_2d()
	var target: Node2D = null

	if move_direction == "horizontal":
		target = destination_marker if transition_direction.x > 0 else root_marker
	else:
		target = destination_marker if transition_direction.y > 0 else root_marker

	if target:
		camera.transition_to_marker(target)
		await get_tree().create_timer(camera.transition_speed).timeout  # Match camera's transition duration
	is_transitioning = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and !is_transitioning:
		player_body = body
		last_position = body.position

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body == player_body:
		player_body = null
		last_position = Vector2.ZERO
		is_transitioning = false
