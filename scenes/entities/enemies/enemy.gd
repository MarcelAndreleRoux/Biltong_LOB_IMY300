extends CharacterBody2D

@export var wander_direction: Node2D
@export var turn_speed: float = 5.0  # Adjust this value to control turning speed

func _physics_process(delta):
	if wander_direction.waiting:
		velocity = Vector2.ZERO
	else:
		velocity = wander_direction.direction * 100
		
		# Smoothly rotate the enemy to face the movement direction
		var target_angle = velocity.angle()
		rotation = lerp_angle(rotation, target_angle, turn_speed * delta)
	
	move_and_slide()
