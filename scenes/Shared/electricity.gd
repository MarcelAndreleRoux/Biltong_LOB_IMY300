# ElectricalOutputer.gd
extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D

# Export variable to identify the connector (useful if multiple connectors exist)
@export var connector_name: String = "none"

func _ready():
	animated_sprite_2d.visible = false
	# Connect to the animation_finished signal to reset visibility
	
	# Connect to the lizard_connection signal
	SharedSignals.lizard_connection.connect(output_charge)

func output_charge(direction: Vector2):
	SharedSignals.sent_input_charge.emit()
	
	# Calculate the angle from the direction vector
	var angle = direction.angle()
	
	# Adjust rotation based on sprite's default orientation
	# Example: If sprite faces right (0 radians) by default, no adjustment needed
	# If sprite faces up (-PI/2 radians) by default, subtract PI/2 radians
	# Modify the rotation adjustment as per your sprite's orientation
	# For instance, if facing up by default:
	# animated_sprite_2d.rotation = angle - deg2rad(90)
	
	animated_sprite_2d.rotation = angle  # Adjust if necessary
	
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
