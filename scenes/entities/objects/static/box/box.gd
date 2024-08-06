extends RigidBody2D

@onready var Area = $MoveArea
@onready var animatedSprite = $AnimatedSprite2D

var remove_box: bool = false

func _ready():
    animatedSprite.play("idle")

func _integrate_forces(_state):
    rotation = 0
    angular_velocity = 0

func _on_move_area_body_entered(body:Node2D):
    if body.is_in_group("player"):
        SharedSignals.player_move.emit()
        animatedSprite.play("near_box")

    # if body.is_in_group("enemy"):
    #     remove_box = true
    #     animatedSprite.play("squash_box")
    
func _on_move_area_body_exited(_body:Node2D):
    SharedSignals.player_exit.emit()
    animatedSprite.play("idle")

# func _on_animated_sprite_2d_animation_finished():
#     if remove_box:
#         remove_box = false
#         queue_free()
