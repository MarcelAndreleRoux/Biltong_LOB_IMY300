extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D
@onready var move_action = $MoveAction

var remove_box: bool = false
var player_in_area: bool = false
var shown_once: bool = false

func _ready():
	move_action.visible = false
	animatedSprite.play("idle")
	SharedSignals.move_box.connect(move_in_direction)

func _integrate_forces(_state):
	rotation = 0
	angular_velocity = 0

func move_in_direction(direction: Vector2):
	if player_in_area:
		var force = direction * 200  # Adjust the force value as needed
		apply_central_impulse(force)

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
	if body.is_in_group("player"):
		if not shown_once:
			move_action.visible = true
			_some_waiting_timer()
			
		player_in_area = true
		SharedSignals.player_move.emit()
		animatedSprite.play("near_box")
		shown_once = true
	
func _on_move_area_body_exited(_body: Node2D):
	if player_in_area:
		player_in_area = false
		SharedSignals.player_exit.emit()
		animatedSprite.play("idle")
