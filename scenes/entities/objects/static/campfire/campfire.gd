extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var fire_place = $FirePlace

func _ready():
	animated_sprite_2d.play("default")
	fire_place.play()
