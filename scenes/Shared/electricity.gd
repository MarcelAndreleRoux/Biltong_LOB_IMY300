# ElectricalOutputer.gd
extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D  # Declare as onready so it initializes when ready

func _ready():
	# Get the reference to animated_sprite_2d after the scene is added
	animated_sprite_2d = $AnimatedSprite2D
	animated_sprite_2d.visible = false

func output_charge(direction: Vector2):
	# Calculate the angle from the direction vector
	var angle = direction.angle()
	
	# Adjust the rotation based on the direction vector
	# Assuming the zap sprite faces right by default
	animated_sprite_2d.rotation = angle - deg_to_rad(90)  # Adjust based on sprite orientation
	
	# Debugging statement
	print("Zap Animation Angle: ", angle, " radians")
	
	# Play the zap animation
	animated_sprite_2d.play("zap")
	animated_sprite_2d.visible = true

func _on_animated_sprite_2d_animation_finished():
	# Hide the zap animation once it's done
	animated_sprite_2d.visible = false
	# Optionally, reset rotation
	animated_sprite_2d.rotation = 0
