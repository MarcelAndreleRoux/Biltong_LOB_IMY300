extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D
@onready var action_button_press = $ActionButtonPress
@onready var near = $near

var is_being_dragged: bool = false
var distance_to_player: float = 0.0

@export var CHARGE_TIME: float = 7.5

var box_id: int
var remove_box: bool = false
var player_in_area: bool = false
var shown_once: bool = false
var charged_state: bool = false
var charge_timer: Timer
var turning_off: bool = false
var current_frame: int = 0

var connected_mboard = null
var last_emitted_state: bool = false 

func _ready():
	near.visible = false
	box_id = get_instance_id()
	action_button_press.visible = false
	animatedSprite.play("idle_off")
	SharedSignals.drag_box.connect(_follow_player)
	SharedSignals.is_dragging_box.connect(_is_dragging)
	SharedSignals.drop_current_box.connect(_on_drop_box)
	SharedSignals.conductor_connection.connect(_play_zap)

func _integrate_forces(_state):
	rotation = 0
	angular_velocity = 0

func _follow_player(position: Vector2, direction: Vector2, target_box_id: int):
	if target_box_id != box_id:  # Ignore if not for this box
		return
		
	if player_in_area:
		var box_distance_from_player = 13
		var target_position = position + direction * box_distance_from_player
		global_position = global_position.lerp(target_position, 0.1)
		rotation = 0

func _on_drop_box():
	if is_being_dragged:
		is_being_dragged = false
	
	if player_in_area:
		near.visible = true
	else:
		near.visible = false

func _is_dragging(state: bool, target_box_id: int):
	if target_box_id != box_id:
		return
	
	action_button_press.visible = false
	
	if not GlobalValues.was_metal_box_picked_up:
		SharedSignals.metal_box_conduct.emit()
	
	if state and player_in_area:
		is_being_dragged = state
		if turning_off:
			near.visible = false
		else:
			animatedSprite.play("idle_off")
	else:
		is_being_dragged = false
		if turning_off:
			near.visible = true
		elif player_in_area:
			near.visible = true
			animatedSprite.play("near_off")
		else:
			near.visible = true
			animatedSprite.play("idle_off")

func _on_move_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		near.visible = true
		player_in_area = true
		distance_to_player = global_position.distance_to(body.global_position)
		SharedSignals.box_entered_area.emit(self)
		
		if not shown_once:
			if not GlobalValues.has_pickeup_c_box_once:
				GlobalValues.has_pickeup_c_box_once = true
				action_button_press.play("default")
				action_button_press.visible = true
				_some_waiting_timer()
			else:
				action_button_press.visible = false
		
		if turning_off:
			near.visible = true
		else:
			animatedSprite.play("near_off")
		
		shown_once = true
		SharedSignals.player_move.emit()

func _on_move_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		near.visible = false
		if turning_off:
			near.visible = false
		else:
			animatedSprite.play("idle_off")
		
		SharedSignals.box_exited_area.emit(self)
		SharedSignals.player_exit.emit()

func _process(_delta):
	if connected_mboard != null:
		# Only emit if state has changed
		if last_emitted_state != charged_state:
			last_emitted_state = charged_state
			SharedSignals.connected_to_mboard.emit(charged_state, connected_mboard.get_instance_id())
	
	# Clear last state if no m_board is connected
	if connected_mboard == null and last_emitted_state != false:
		last_emitted_state = false

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

func _check_and_zap_electrical():
	# Only zap if we have a connected m_board
	if connected_mboard != null:
		_play_zap_to_mboard(connected_mboard)
		connected_mboard.receive_electricity(true)

func _play_zap_to_mboard(object):
	if charged_state:
		var mboard_position = object.global_position
		var box_position = self.global_position
		var direction = (box_position - mboard_position).normalized()
		
		var electrical_zap = preload("res://scenes/Shared/conductor_box_electricity.tscn").instantiate()
		
		var offset_amount = -10
		electrical_zap.global_position = box_position + (direction * offset_amount)
		get_tree().current_scene.add_child(electrical_zap)
		electrical_zap.output_charge(direction)

func receive_electricity():
	if turning_off:
		# If turning off, start turn_on animation from current frame
		current_frame = animatedSprite.frame
		charged_state = true
		animatedSprite.play("turn_on")
		animatedSprite.frame = current_frame
	else:
		# Normal turn on sequence
		charged_state = true
		animatedSprite.play("turn_on")
	
	SharedSignals.lizard_connection_made.emit(self)
	_check_and_zap_electrical()

func stop_electricity():
	if charge_timer:
		charge_timer.queue_free()
	charge_timer = Timer.new()
	charge_timer.wait_time = CHARGE_TIME
	charge_timer.one_shot = true
	charge_timer.timeout.connect(_on_charge_timer_timeout)
	add_child(charge_timer)
	charge_timer.start()
	
	# Stop electricity to connected m_board if it exists
	if connected_mboard != null:
		connected_mboard.stop_electricity(true)

func _on_charge_timer_timeout():
	charged_state = false
	animatedSprite.play("idle_off")
	charge_timer.queue_free()
	charge_timer = null
	
	# Emit state change immediately
	if connected_mboard != null:
		SharedSignals.connected_to_mboard.emit(false, connected_mboard.get_instance_id())
		connected_mboard.stop_electricity(true)

func _bounce_box(bounce_vector: Vector2):
	global_position += bounce_vector

func _on_animated_sprite_2d_animation_finished():
	if animatedSprite.animation == "turn_on":
		# After turn_on finishes, immediately start turn_off
		animatedSprite.play("turn_off")
		turning_off = true
		stop_electricity()  # Start the charge timer
	elif animatedSprite.animation == "turn_off":
		turning_off = false
		charged_state = false
		if player_in_area:
			animatedSprite.play("near_off")
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
			SharedSignals.lizard_connection_made.emit(self)
			_check_and_zap_electrical()
	elif body.is_in_group("m_board"):
		# Only connect if it's not a default board
		if not body.is_default_board():
			if connected_mboard == null:
				connected_mboard = body
				# Emit initial state when connecting
				SharedSignals.connected_to_mboard.emit(charged_state, body.get_instance_id())
				if charged_state:
					_play_zap_to_mboard(body)
					body.receive_electricity(true)

func _on_conduction_area_body_exited(body):
	if body.is_in_group("lizard"):
		if body.get_electrical_state():
			animatedSprite.play("turn_off")
	elif body.is_in_group("m_board") and body == connected_mboard:
		# Emit false state when disconnecting
		SharedSignals.connected_to_mboard.emit(false, body.get_instance_id())
		body.stop_electricity(true)
		connected_mboard = null
