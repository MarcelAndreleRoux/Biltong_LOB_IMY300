extends Node2D

@onready var electric_zap = $electric_zap
@onready var animated_sprite_2d = $AnimatedSprite2D

# need the direction so you can correctly rotate the animated_sprite_2d to the node you are sending charge to

func output_charge(direction: Vector2):
	SharedSignals.sent_input_charge.emit()
	# rotate the animation to the output conductor
	animated_sprite_2d.play("zap")
	pass

func _create_wait_timer():
	pass
