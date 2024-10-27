extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var pickup_sound = $pickup_sound
@onready var action_button_press = $ActionButtonPress

var needs_to_pickup: bool = false
var player_in_area: bool = false
var player_save = null

func _ready():
	action_button_press.visible = false
	
	if GlobalValues.hazmat_picked_up:
		animated_sprite_2d.play("gone")
	else:
		animated_sprite_2d.play("hang")

func _process(_delta):
	if player_in_area and Input.is_action_just_pressed("pickup"):
		needs_to_pickup = false
		pickup_sound.play()
		player_save.acquire_hazmat()
		animated_sprite_2d.play("gone")
		GlobalValues.hazmat_picked_up = true
		action_button_press.visible = false

func _on_pickup_area_body_entered(body): # Fixed method name
	if body.is_in_group("player"):
		if not GlobalValues.hazmat_picked_up:
			action_button_press.visible = true
			action_button_press.play("default")
			animated_sprite_2d.play("pickup")
			player_in_area = true
			player_save = body

# Add this to handle player leaving the area
func _on_pickup_area_body_exited(body):
	if body.is_in_group("player"):
		action_button_press.visible = false
		if not GlobalValues.hazmat_picked_up:
			animated_sprite_2d.play("hang")
		player_in_area = false
		player_save = null
