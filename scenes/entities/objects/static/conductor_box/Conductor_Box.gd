extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D
@onready var move_action = $MoveAction

var remove_box: bool = false
var player_in_area: bool = false
var shown_once: bool = false

var charged_state: bool = false

func _ready():
	move_action.visible = false
	animatedSprite.play("idle_off")
	#SharedSignals.move_box.connect(move_in_direction)
	SharedSignals.drag_box.connect(_follow_player)

func _integrate_forces(_state):
	rotation = 0
	angular_velocity = 0

func _follow_player(position: Vector2, direction: Vector2):
	if player_in_area:
		# Define a fixed distance from the player to the box
		var box_distance_from_player = 13  # Adjust this value for how far the box floats

		# Calculate the new position of the box, offset by the direction toward the mouse
		var target_position = position + direction * box_distance_from_player

		# Smoothly interpolate the box's position towards the target position
		global_position = global_position.lerp(target_position, 0.1)

		# Ensure the box does not rotate
		rotation = 0  # Keep the box from rotating

func _some_waiting_timer():
	var grow_timer = Timer.new()
	grow_timer.name = "show_timer"
	grow_timer.wait_time = 7.0
	grow_timer.one_shot = true
	grow_timer.timeout.connect(_show_timeout)
	add_child(grow_timer)
	grow_timer.start()

func _show_timeout():
	$show_timer.queue_free()
	move_action.visible = false

func _on_move_area_body_entered(body: Node2D):
	# Ensure the body is the player
	if body.is_in_group("player"):  # Check if the body belongs to the 'player' group
		if not shown_once:
			move_action.visible = true
			_some_waiting_timer()

		player_in_area = true
		SharedSignals.player_move.emit()
		if charged_state:
			animatedSprite.play("near_on_box")
		else:
			animatedSprite.play("near_off_box")
		shown_once = true

func _on_move_area_body_exited(body: Node2D):
	# Only change the state if the body leaving is the player
	if player_in_area and body.is_in_group("player"):
		player_in_area = false
		SharedSignals.player_exit.emit()
		
		if charged_state:
			animatedSprite.play("idle_on")
		else:
			animatedSprite.play("idle_off")

func _bounce_box(bounce_vector: Vector2):
	global_position += bounce_vector

# Restrict Movement
func _on_wall_detection_left_body_entered(body):
	if body.is_in_group("walls"):
		SharedSignals.wall_detected.emit(Vector2(-1, 0))

func _on_wall_detection_right_body_entered(body):
	if body.is_in_group("walls"):
		SharedSignals.wall_detected.emit(Vector2(1, 0))

func _on_wall_detection_up_body_entered(body):
	if body.is_in_group("walls"):
		SharedSignals.wall_detected.emit(Vector2(0, -1))

func _on_wall_detection_down_body_entered(body):
	if body.is_in_group("walls"):
		SharedSignals.wall_detected.emit(Vector2(0, 1))

func _on_push_area_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.player_push.emit()

func _on_push_area_body_exited(body):
	if player_in_area and body.is_in_group("player"):
		SharedSignals.player_not_push.emit()

func _on_conduction_area_body_entered(body):
	if body.is_in_group("lizard"):
		charged_state = true
		animatedSprite.play("turn_on")
		SharedSignals.lizard_connection.emit(true)

func _on_conduction_area_body_exited(body):
	if body.is_in_group("lizard"):
		charged_state = false
		animatedSprite.play("turn_off")
		SharedSignals.lizard_connection.emit(false)

func _on_animated_sprite_2d_animation_finished():
	if charged_state:
		animatedSprite.play("idle_on")
	else:
		animatedSprite.play("idle_off")