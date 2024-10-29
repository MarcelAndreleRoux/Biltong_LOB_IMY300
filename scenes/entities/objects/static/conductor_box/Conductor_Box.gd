extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D
@onready var action_button_press = $ActionButtonPress

@export var CHARGE_TIME: float = 7.5

var remove_box: bool = false
var player_in_area: bool = false
var shown_once: bool = false
var charged_state: bool = false
var charge_timer: Timer

func _ready():
	action_button_press.visible = false
	animatedSprite.play("idle_off")
	SharedSignals.drag_box.connect(_follow_player)
	SharedSignals.is_dragging_box.connect(_is_dragging)
	SharedSignals.conductor_connection.connect(_play_zap)

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
		rotation = 0

func _is_dragging(state: bool):
	if state and charged_state:
		animatedSprite.play("idle_on")
	elif state and not charged_state:
		animatedSprite.play("idle_off")
	elif not state and charged_state:
		animatedSprite.play("near_on_box")
	elif not state and not charged_state:
		animatedSprite.play("near_off_box")

func _on_move_area_body_entered(body: Node2D):
	# Ensure the body is the player
	if body.is_in_group("player"):
		if not shown_once:
			if not GlobalValues.has_pickeup_c_box_once:
				GlobalValues.has_pickeup_c_box_once = true
				action_button_press.play("default")
				action_button_press.visible = true
				_some_waiting_timer()
			else:
				action_button_press.visible = false
		
		player_in_area = true
		SharedSignals.player_move.emit()
		
		if charged_state:
			animatedSprite.play("near_on_box")
		else:
			animatedSprite.play("near_off_box")
		shown_once = true

func _on_move_area_body_exited(body: Node2D):
	if player_in_area and body.is_in_group("player"):
		player_in_area = false
		SharedSignals.player_exit.emit()
		
		if charged_state:
			animatedSprite.play("idle_on")
		else:
			animatedSprite.play("idle_off")

func _some_waiting_timer():
	var grow_timer = Timer.new()
	grow_timer.name = "show_timer"
	grow_timer.wait_time = 5.0
	grow_timer.one_shot = true
	grow_timer.timeout.connect(_show_timeout)
	add_child(grow_timer)
	grow_timer.start()

func _show_timeout():
	action_button_press.visible = false

func receive_electricity():
	if not charged_state:
		charged_state = true
		animatedSprite.play("turn_on")
		SharedSignals.lizard_connection.emit(self)
		SharedSignals.lizard_connection_made.emit(true)

func stop_electricity():
	if charge_timer:
		charge_timer.queue_free()
	charge_timer = Timer.new()
	charge_timer.wait_time = CHARGE_TIME  # 1.5 second delay
	charge_timer.one_shot = true
	charge_timer.timeout.connect(_on_charge_timer_timeout)
	add_child(charge_timer)
	charge_timer.start()

func _on_charge_timer_timeout():
	charged_state = false
	animatedSprite.play("idle_off")
	SharedSignals.lizard_connection_made.emit(false)
	charge_timer.queue_free()
	charge_timer = null

func _bounce_box(bounce_vector: Vector2):
	global_position += bounce_vector

func _on_animated_sprite_2d_animation_finished():
	if charged_state:
		animatedSprite.play("idle_on")
	else:
		animatedSprite.play("idle_off")

func _play_zap(object):
	if charged_state:
		var conductor_position = object.global_position
		var lizard_position = self.global_position
		var direction = (lizard_position - conductor_position).normalized()
		
		var electrical_zap = preload("res://scenes/Shared/electricity.tscn").instantiate()
		var offset_amount = -10
		electrical_zap.global_position = lizard_position + (direction * offset_amount)
		get_tree().current_scene.add_child(electrical_zap)
		electrical_zap.output_charge(direction)

func _on_conduction_area_body_entered(body):
	if body.is_in_group("lizard"):
		if body.get_electrical_state():
			charged_state = true
			animatedSprite.play("turn_on")
			SharedSignals.lizard_connection.emit(self)
			SharedSignals.lizard_connection_made.emit(true)
		else:
			charged_state = false
			SharedSignals.lizard_connection_made.emit(false)

func _on_conduction_area_body_exited(body):
	if body.is_in_group("lizard"):
		if body.get_electrical_state():
			charged_state = false
			animatedSprite.play("turn_off")
			SharedSignals.lizard_connection_made.emit(false)
