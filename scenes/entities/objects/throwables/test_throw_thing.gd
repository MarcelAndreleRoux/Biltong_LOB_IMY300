extends Node2D

@export var gravity: float = -9.8  # Gravity value
@export var min_distance: float = 50.0
@export var max_distance: float = 300.0

var speed = 10.0
var velocity: Vector2

func _ready():
	SharedSignals.ThrowObject.connect(on_throw_emit)
	print("Projectile ready and listening for ThrowObject signal")

func _process(delta):
	if velocity != Vector2.ZERO:
		velocity.y += gravity * delta
		position += velocity * delta
		print("Projectile position: ", position, " | Velocity: ", velocity)

	if position.y > get_viewport().size.y or position.x < 0 or position.x > get_viewport().size.x:  # Simple check to remove the projectile when it goes off-screen
		print("Projectile out of bounds, removing")
		queue_free()

func on_throw_emit(initial_pos: Vector2, local_mouse_pos: Vector2, target_pos: Vector2):
	position = initial_pos
	print("Throw signal received")
	print("Initial position: ", initial_pos, " | Local mouse position: ", local_mouse_pos, " | Target position: ", target_pos)
	
	var direction = (local_mouse_pos - initial_pos).normalized()
	var raw_distance: float = initial_pos.distance_to(local_mouse_pos)
	var clamped_distance: float = clamp(raw_distance, min_distance, max_distance)
	
	var end = initial_pos + direction * clamped_distance
	print("Clamped distance: ", clamped_distance, " | End position: ", end)
	
	var angle = atan2((end.y - initial_pos.y), (end.x - initial_pos.x))
	print("Calculated angle: ", angle)
	
	var x_dis = end.x - initial_pos.x
	var y_dis = end.y - initial_pos.y
	print("X distance: ", x_dis, " | Y distance: ", y_dis)
	
	# Check if y_dis and x_dis lead to valid speed calculation
	if y_dis == tan(angle) * x_dis:
		print("Invalid calculation: y_dis equals tan(angle) * x_dis, setting default speed")
		var speed = 300.0  # Default speed or handle this edge case as needed
	else:
		var speed = sqrt((x_dis * x_dis * -gravity) / (2 * (y_dis - (tan(angle) * x_dis))))
		print("Calculated speed: ", speed)
	
	var x_component = cos(angle) * speed
	var y_component = sin(angle) * speed

	velocity = Vector2(x_component, y_component)
	print("Initial velocity: ", velocity)
