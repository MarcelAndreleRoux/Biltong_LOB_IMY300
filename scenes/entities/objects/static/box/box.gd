extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D
@onready var action_button_press = $ActionButtonPress
@onready var check_mark = $CheckMark

var is_being_dragged: bool = false
var distance_to_player: float = 0.0

var box_id: int

var remove_box: bool = false
var player_in_area: bool = false
var shown_once: bool = false

func _ready():
	box_id = get_instance_id()  # Get unique identifier for this box
	check_mark.visible = false  # Your existing code...
	action_button_press.visible = false
	animatedSprite.play("idle")  # or "idle_off" for conductor
	SharedSignals.drag_box.connect(_follow_player)
	SharedSignals.is_dragging_box.connect(_is_dragging)
	SharedSignals.drop_current_box.connect(_on_drop_box)

func _on_drop_box():
	if is_being_dragged:
		is_being_dragged = false
		animatedSprite.play("idle")

func _integrate_forces(_state):
	rotation = 0
	angular_velocity = 0
	
@onready var done = $Done

func _is_dragging(state: bool, target_box_id: int):
	if target_box_id != box_id:  # Ignore if not for this box
		return
	
	if state and player_in_area:
		is_being_dragged = true
		if not GlobalValues.box_pickup_once:
			GlobalValues.box_pickup_once = true
			check_mark.visible = true
			done.play("check")
		else:
			done.stop()
			check_mark.visible = false
		
		animatedSprite.play("idle")
	else:
		is_being_dragged = false
		animatedSprite.play("near_box")

func _follow_player(position: Vector2, direction: Vector2, target_box_id: int):
	if target_box_id != box_id:  # Ignore if not for this box
		return
		
	if player_in_area:
		var box_distance_from_player = 13
		var target_position = position + direction * box_distance_from_player
		global_position = global_position.lerp(target_position, 0.1)
		rotation = 0

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

func _on_move_area_body_entered(body: Node2D):
	# Ensure the body is the player
	if body.is_in_group("player"):  # Check if the body belongs to the 'player' group
		player_in_area = true
		
		distance_to_player = global_position.distance_to(body.global_position)
		SharedSignals.box_entered_area.emit(self)
		
		if not shown_once:
			if not GlobalValues.has_pickeup_box_once:
				GlobalValues.has_pickeup_box_once = true
				action_button_press.play("default")
				action_button_press.visible = true
				
				_some_waiting_timer()
			else:
				action_button_press.visible = false
		
		SharedSignals.player_move.emit()
		animatedSprite.play("near_box")
		shown_once = true

func _on_move_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		SharedSignals.box_exited_area.emit(self)
		if not is_being_dragged:
			animatedSprite.play("idle")

func _bounce_box(bounce_vector: Vector2):
	global_position += bounce_vector
