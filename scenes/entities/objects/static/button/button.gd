extends StaticBody2D

@export var door_link: Node2D

var found_link: bool = false

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var click_area = $ClickArea
@onready var click = $click

var door_link_found: Node2D

func _ready():
	SharedSignals.full_link.connect(_full_link)
	animated_sprite_2d.play("idle")

func _on_click_area_body_entered(body):
	if body.name == "Enemy" or body.name == "Player":
		SharedSignals.check_link.emit(self, door_link)
	
		if found_link and door_link == door_link_found:
			click.play()
			animated_sprite_2d.play("click")
			SharedSignals.doorState.emit(true)

func _on_click_area_body_exited(body):
	if body.name == "Enemy" or body.name == "Player":
		if found_link and door_link == door_link_found:
			animated_sprite_2d.play_backwards("click")
			SharedSignals.doorState.emit(false)

func _full_link(door_link: Node2D):
	door_link_found = door_link
	found_link = true
