extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var click_area = $ClickArea
@onready var click = $click

func _ready():
	animated_sprite_2d.play("idle")

func _on_click_area_body_entered(body):
	if body.name == "Enemy" or body.name == "Player":
		click.play()
		animated_sprite_2d.play("click")
		SharedSignals.doorState.emit(true)

func _on_click_area_body_exited(body):
	if body.name == "Enemy" or body.name == "Player":
		animated_sprite_2d.play_backwards("click")
		
		SharedSignals.doorState.emit(false)
