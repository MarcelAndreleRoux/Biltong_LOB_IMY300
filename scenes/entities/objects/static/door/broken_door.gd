extends StaticBody2D

@export var door_link_id: String

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var audio_controler = $AudioControler

var openString: String
var closeString: String

var closed_check: bool = true

func _ready():
	SharedSignals.doorState.connect(_on_door_stateChange)
	SharedSignals.check_link.connect(_check_link)
	make_string()

func make_string():
	animated_sprite_2d.play("start")

func _on_door_stateChange(door_id: String, state: bool):
	if door_id == door_link_id:
		if state:
			closed_check = false
			audio_controler.error.play()
			animated_sprite_2d.play("default")
		else:
			closed_check = true
			animated_sprite_2d.play("start")

func _check_link(button: StaticBody2D, button_id: String):
	if door_link_id == button_id:
		SharedSignals.full_link.emit(button_id, door_link_id)
