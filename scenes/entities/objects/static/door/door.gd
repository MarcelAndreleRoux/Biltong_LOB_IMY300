extends StaticBody2D

@export var door_side: String
@export var door_link_id: String

@onready var animation_tree = $AnimationTree

var doorState: bool = false

var openString: String
var closeString: String

var closed: bool = true
var closing_door: bool = false
var opening_door: bool = false

var closed_check: bool = true

func _ready():
	SharedSignals.doorState.connect(_on_door_stateChange)
	SharedSignals.check_link.connect(_check_link)
	update_door_animation()

func _on_door_stateChange(door_id: String, state: bool):
	if door_id == door_link_id:
		if state:
			doorState = true
			closed_check = false
			AudioController.play_sfx("door_open")
			opening_door = true
			closing_door = false
			closed = false
			update_door_animation()
		else:
			doorState = false
			AudioController.play_sfx("door_open")
			closing_door = true
			opening_door = false
			closed = false
			update_door_animation()

func update_door_animation():
	if opening_door:
		animation_tree.set("parameters/conditions/is_closed", false)
		animation_tree.set("parameters/conditions/is_closing", false)
		animation_tree.set("parameters/conditions/is_opening", true)
	elif closing_door:
		animation_tree.set("parameters/conditions/is_closed", false)
		animation_tree.set("parameters/conditions/is_closing", true)
		animation_tree.set("parameters/conditions/is_opening", false)
	else:
		animation_tree.set("parameters/conditions/is_closed", true)
		animation_tree.set("parameters/conditions/is_closing", false)
		animation_tree.set("parameters/conditions/is_opening", false)

func _check_link(button: StaticBody2D, button_id: String):
	if door_link_id == button_id:
		SharedSignals.full_link.emit(button_id, door_link_id)

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "closing":
		closed = true
		closing_door = false
		opening_door = false
		update_door_animation()
