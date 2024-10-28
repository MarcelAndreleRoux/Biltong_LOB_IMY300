extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var fire_place = $FirePlace

func _ready():
	animated_sprite_2d.play("default")
	fire_place.play()

func _on_activation_area_body_entered(body):
	if body.is_in_group("lizard"):
		SharedSignals.lizard_in_camp_fire.emit()
	
	if body.is_in_group("throwables"):
		if body.is_in_group("fire"):
			fire_place.play()
		if body.is_in_group("water"):
			fire_place.stop()
