extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D

@export_enum("Normal", "Broken") var pod_mode: String = "Normal"

func _ready():
	if pod_mode == "Normal":
		animated_sprite_2d.play("normal")
	else:
		animated_sprite_2d.play("broken")
