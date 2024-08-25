extends StaticBody2D

@onready var sprite_2d = $Sprite2D
@export var SpriteName = "0"

func _ready():
	if SpriteName == "1":
		sprite_2d.frame = 1
	else:
		sprite_2d.frame = 0


