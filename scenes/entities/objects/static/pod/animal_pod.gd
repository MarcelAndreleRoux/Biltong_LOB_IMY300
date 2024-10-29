extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D

@export_enum("Normal", "Broken") var pod_mode: String = "Normal"
@export_enum("Turtle", "HedgeHog", "Lizard") var pod_animal: String = "Turtle"

func _ready():
	if pod_mode == "Normal":
		if pod_animal == "Turtle":
			animated_sprite_2d.play("turtle")
		elif pod_animal == "HedgeHog":
			animated_sprite_2d.play("hedgehog")
		elif pod_animal == "Lizard":
			animated_sprite_2d.play("lizard")
	else:
		animated_sprite_2d.play("broken")
