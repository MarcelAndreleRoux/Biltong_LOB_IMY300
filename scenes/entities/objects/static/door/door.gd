extends StaticBody2D

@export var door_side: String
@export var door_link: Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var open = $open

var doorState: bool = false
var button_link: Node2D

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

func _on_door_stateChange(state: bool):
	if state and door_link != null:
		doorState = true
		closed_check = false
		open.play()
		animated_sprite_2d.play(openString)
		print("door should be open")
	elif not state and door_link != null:
		doorState = false
		open.play()
		animated_sprite_2d.play_backwards(openString)
		print("door should be closed")

func _check_link(button: StaticBody2D, button_link: Node2D):
	if door_link != null:
		SharedSignals.found_link.emit(door_link, button_link)

func _on_animated_sprite_2d_animation_finished():
	if doorState and door_link != null:
		collision_shape_2d.disabled = true
	else:
		collision_shape_2d.disabled = false
