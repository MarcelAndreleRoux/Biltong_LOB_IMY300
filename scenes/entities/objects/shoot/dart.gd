extends CharacterBody2D

@export var speed: float = 250.0

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var shake_camera = $ShakeCamera

var target_position: Vector2

func _ready():
	# Ensure target_position is set before calculating rotation
	if target_position != Vector2.ZERO:
		update_rotation_and_velocity()

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	
	# Check if a collision occurred
	if collision:
		# Access the collider using `get_collider()`
		var collider = collision.get_collider()
		
		SharedSignals.dart_hit_wall.emit()
		
		# Handle collision with the player or other objects
		if collider.is_in_group("player"):
			queue_free()
		else:
			queue_free()

func update_rotation_and_velocity():
	# Calculate the rotation towards the target position
	rotation = (target_position - global_position).angle()
	
	# Adjust the rotation by -PI/2 (or 90 degrees) if your sprite's forward direction is along the Y-axis
	rotation -= PI / 2
	
	# Rotate 180 degrees to flip the sprite
	rotation += PI

	velocity = (target_position - global_position).normalized() * speed

# Example function to set the target position dynamically
func set_target_position(new_target_position: Vector2):
	target_position = new_target_position
	update_rotation_and_velocity()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.dart_hit_wall.emit()
		SharedSignals.player_killed.emit("peg")
