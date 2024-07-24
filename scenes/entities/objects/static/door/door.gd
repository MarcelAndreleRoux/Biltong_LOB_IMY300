extends StaticBody2D

@export var door_side: String

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D

# False = closed | True = open
var doorState: bool = false

var openString: String
var closeString: String

func _ready():
	SharedSignals.doorState.connect(_on_door_stateChange)
	
	make_string()

func make_string():
	if door_side == "front":
		openString = str(door_side, "_open")
		closeString = str(door_side, "_close")
	elif door_side == "bottom":
		pass
	elif door_side == "left":
		pass
	elif door_side == "right":
		pass
	
	animated_sprite_2d.play(closeString)

func _on_door_stateChange(state: bool):
	if state:
		doorState = true
		animated_sprite_2d.play(openString)
		print("door should be open")
	else: 
		doorState = false
		animated_sprite_2d.play(closeString)
		collision_shape_2d.visible = true
		print("door should be closed")

func _on_animated_sprite_2d_animation_finished():
	if doorState:
		collision_shape_2d.visible = false
	else:
		collision_shape_2d.visible = true
