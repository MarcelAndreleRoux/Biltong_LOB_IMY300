extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D
@onready var action_button_press = $ActionButtonPress

var remove_box: bool = false
var player_in_area: bool = false
var shown_once: bool = false

func _ready():
	action_button_press.visible = false
	animatedSprite.play("idle")
	#SharedSignals.move_box.connect(move_in_direction)
	SharedSignals.drag_box.connect(_follow_player)
	SharedSignals.is_dragging_box.connect(_is_dragging)

func _integrate_forces(_state):
	rotation = 0
	angular_velocity = 0

func _is_dragging(state: bool):
	if state:
		animatedSprite.play("idle")
	else:
		animatedSprite.play("near_box")

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
	grow_timer.wait_time = 5.0
	grow_timer.one_shot = true
	grow_timer.timeout.connect(_show_timeout)
	add_child(grow_timer)
	grow_timer.start()

func _show_timeout():
	$show_timer.queue_free()
	action_button_press.visible = false

func _on_move_area_body_entered(body: Node2D):
	# Ensure the body is the player
	if body.is_in_group("player"):  # Check if the body belongs to the 'player' group
		if not shown_once:
			if not GlobalValues.has_pickeup_box_once:
				GlobalValues.has_pickeup_box_once = true
				action_button_press.play("default")
				action_button_press.visible = true
			else:
				action_button_press.visible = false
				
			_some_waiting_timer()
		
		player_in_area = true
		SharedSignals.player_move.emit()
		animatedSprite.play("near_box")
		shown_once = true

func _on_move_area_body_exited(body: Node2D):
	# Only change the state if the body leaving is the player
	if player_in_area and body.is_in_group("player"):
		player_in_area = false
		SharedSignals.player_exit.emit()
		animatedSprite.play("idle")

func _bounce_box(bounce_vector: Vector2):
	global_position += bounce_vector
