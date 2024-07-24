extends Node2D

var initial_speed: float
var throw_angle_degrees: float
const gravity: float = 9.8
var time: float = 0.0

var initial_position: Vector2
var throw_direction: Vector2

var z_axis = 0.0
var is_launch: bool = false

# This is to increase the speed
var time_mult: float = 6.0

func _process(delta):
	time += delta * time_mult

	if Input.is_action_just_pressed("DEBUG"):
		LaunchProjectile(global_position, Vector2(1, 0), 100, 60)

	if is_launch:
		z_axis = initial_speed * sin(deg_to_rad(throw_angle_degrees)) * time - 0.5 * gravity * pow(time, 2)
		
		# Not touched the ground yet
		if z_axis > 0:
			var x_axis: float = initial_speed * cos(deg_to_rad(throw_angle_degrees)) * time
			global_position = initial_position + throw_direction * x_axis
			$Projectile.position.y = -z_axis

func LaunchProjectile(initial_pos: Vector2, direction: Vector2, desired_distance: float, desired_angle_deg: float):
	initial_position = initial_pos
	throw_direction = direction.normalized()

	throw_angle_degrees = desired_angle_deg
	initial_speed = pow(desired_distance * gravity / sin(2 * deg_to_rad(desired_angle_deg)), 0.5)

	global_position = initial_position
	time = 0.0
	is_launch = true  # Ensure launch is set to true when launching
