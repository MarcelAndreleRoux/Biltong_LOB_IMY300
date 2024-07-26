extends StaticBody2D

@export var door_side: String
@export var door_link_id: String

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var open = $open

var doorState: bool = false

var openString: String
var closeString: String

var closed_check: bool = true

func _ready():
	SharedSignals.doorState.connect(_on_door_stateChange)
	SharedSignals.check_link.connect(_check_link)
	make_string()

func make_string():
	openString = str(door_side, "_open")
	closeString = str(door_side, "_closed")
	animated_sprite_2d.play(closeString)

func _on_door_stateChange(door_id: String, state: bool):
	if door_id == door_link_id:
		if state:
			doorState = true
			closed_check = false
			open.play()
			animated_sprite_2d.play(openString)
		else:
			doorState = false
			open.play()
			animated_sprite_2d.play_backwards(openString)
	else:
		print("Invalid link for this door. Expected:", door_link_id, "Got:", door_id)

func _check_link(button: StaticBody2D, button_id: String):
	if door_link_id == button_id:
		SharedSignals.full_link.emit(button_id, door_link_id)

func _on_animated_sprite_2d_animation_finished():
	if doorState:
		collision_shape_2d.disabled = true
	else:
		collision_shape_2d.disabled = false
