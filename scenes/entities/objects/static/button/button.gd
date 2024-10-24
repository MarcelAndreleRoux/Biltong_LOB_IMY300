extends StaticBody2D

@export var door_link_id: String

var found_link: bool = false
var area2d_active: bool = false

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var click_area = $ClickArea
@onready var click = $click

var door_link_found: String

func _ready():
	SharedSignals.full_link.connect(_full_link)
	animated_sprite_2d.play("idle")

func _on_click_area_body_entered(body):
	if area2d_active:
		return

	if body.is_in_group("activation"):
		SharedSignals.check_link.emit(self, door_link_id)

		if found_link and door_link_id == door_link_found:
			click.play()
			animated_sprite_2d.play("click")
			# Pass the button's unique instance ID
			SharedSignals.doorState.emit(door_link_id, true, get_instance_id())

func _on_click_area_body_exited(body):
	if area2d_active:
		return

	if body.is_in_group("activation"):
		if found_link and door_link_id == door_link_found:
			animated_sprite_2d.play_backwards("click")
			# Pass the button's unique instance ID
			SharedSignals.doorState.emit(door_link_id, false, get_instance_id())

func _full_link(button_id: String, door_id: String):
	if button_id == door_link_id:
		door_link_found = door_id
		found_link = true

func _on_detect_box_area_entered(area: Area2D):
	if area.name == "ButtonArea":
		area2d_active = true
		SharedSignals.check_link.emit(self, door_link_id)

		if found_link and door_link_id == door_link_found:
			click.play()
			animated_sprite_2d.play("click")
			SharedSignals.doorState.emit(door_link_id, true, get_instance_id())

func _on_detect_box_area_exited(area: Area2D):
	if area.name == "ButtonArea":
		area2d_active = false
		if found_link and door_link_id == door_link_found:
			animated_sprite_2d.play_backwards("click")
			SharedSignals.doorState.emit(door_link_id, false, get_instance_id())

