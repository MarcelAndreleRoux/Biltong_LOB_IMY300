extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var fire_place = $FirePlace

var on_state: bool = false

func _ready():
	# Start with the default animation
	animated_sprite_2d.play("default")
	fire_place.play()
	
	# Connect to the animation finished signal to handle transitions
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	# When turn_on animation finishes, transition to default
	if animated_sprite_2d.animation == "turn_on":
		animated_sprite_2d.play("default")

func turn_off_fire():
	animated_sprite_2d.play("turn_off")
	fire_place.stop()

func turn_on_fire():
	animated_sprite_2d.play("turn_on")
	fire_place.play()

func _on_activation_area_body_entered(body):
	if body.is_in_group("lizard"):
		if on_state:
			SharedSignals.lizard_in_camp_fire.emit()
	
	if body.is_in_group("throwables"):
		if body.is_in_group("fire") and not on_state and body.get_vines_landed_state():
			turn_on_fire()
			on_state = true
		if body.is_in_group("water") and on_state and body.get_vines_landed_state():
			turn_off_fire()
			on_state = false
