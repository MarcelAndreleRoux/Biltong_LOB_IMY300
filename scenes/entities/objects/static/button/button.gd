extends StaticBody2D

@export var door_link_id: String

var found_link: bool = false

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var click_area = $ClickArea
@onready var click = $click

var door_link_found: String

func _ready():
	SharedSignals.full_link.connect(_full_link)
	animated_sprite_2d.play("idle")

func _on_click_area_body_entered(body):
	if body.name == "Enemy" or body.name == "Player":
		SharedSignals.check_link.emit(self, door_link_id)
	
	if found_link and door_link_id == door_link_found:
		click.play()
		animated_sprite_2d.play("click")
		SharedSignals.doorState.emit(door_link_id, true)
	else:
		print("No link found or incorrect link. found_link:", found_link, "door_link_id:", door_link_id, "door_link_found:", door_link_found)

func _on_click_area_body_exited(body):
	if body.name == "Enemy" or body.name == "Player":
		if found_link and door_link_id == door_link_found:
			animated_sprite_2d.play_backwards("click")
			SharedSignals.doorState.emit(door_link_id, false)

func _full_link(button_id: String, door_id: String):
	if button_id == door_link_id:
		door_link_found = door_id
		found_link = true
