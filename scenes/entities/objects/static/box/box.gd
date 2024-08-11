extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D

var remove_box: bool = false
var player_in_area: bool = false

func _ready():
	animatedSprite.play("idle")
	SharedSignals.move_box.connect(move_in_direction)

func _integrate_forces(_state):
	rotation = 0
	angular_velocity = 0

func move_in_direction(direction: Vector2):
	if player_in_area:
		var force = direction * 300  # Adjust the force value as needed
		apply_central_impulse(force)

func _on_move_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true
		SharedSignals.player_move.emit()
		animatedSprite.play("near_box")

	# if body.is_in_group("enemy"):
	#     remove_box = true
	#     animatedSprite.play("squash_box")
	
func _on_move_area_body_exited(_body: Node2D):
	if player_in_area:
		player_in_area = false
		SharedSignals.player_exit.emit()
		animatedSprite.play("idle")

# func _on_animated_sprite_2d_animation_finished():
#     if remove_box:
#         remove_box = false
#         queue_free()
