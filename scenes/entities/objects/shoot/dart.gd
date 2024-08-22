extends CharacterBody2D

@export var speed: float = 100.0

@onready var animated_sprite_2d = $AnimatedSprite2D

var target_position: Vector2

func _ready():
	# Calculate the initial rotation and velocity towards the target
	rotation = (target_position - global_position).angle()
	velocity = (target_position - global_position).normalized() * speed

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	
	# Check if a collision occurred
	if collision:
		# Access the collider using `get_collider()`
		var collider = collision.get_collider()

		# Handle collision with the player or other objects
		if collider.is_in_group("player"):
			queue_free()
		else:
			queue_free()
