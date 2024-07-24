extends Node2D

var initial_speed: float
var throw_angle_degrees: float
var gravity: float
var time: float = 0.0

var initial_position: Vector2
var throw_direction: Vector2

var z_axis = 0.0
var is_launch: bool = false

var time_mult: float = 6.0

func _process(delta):
	if is_launch:
		time += delta * time_mult
		
		var z_axis = initial_speed * sin(deg_to_rad(throw_angle_degrees)) * time - 0.5 * gravity * pow(time, 2)
		if z_axis > 0:
			var x_axis: float = initial_speed * cos(deg_to_rad(throw_angle_degrees)) * time
			global_position = initial_position + throw_direction * x_axis # Move along the x-axis
			$Projectile.position.y = -z_axis # Move the projectile along the y-axis based on the simulated z-axis

func LaunchProjectile(): 
	is_launch = true
	time = 0.0
