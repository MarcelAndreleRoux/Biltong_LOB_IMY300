extends StaticBody2D

@export var door_link_id: String
@export var required_connections: int = 1

@onready var animation_tree = $AnimationTree

var doorState: bool = false
var received_signals: int = 0  # Track how many buttons are pressed

func _ready():
	SharedSignals.doorState.connect(_on_door_stateChange)
	SharedSignals.check_link.connect(_check_link)
	update_door_animation()

func _on_door_stateChange(door_id: String, state: bool):
	if door_id == door_link_id:
		if state:
			received_signals += 1
			print("Received signals:", received_signals)
			if received_signals >= required_connections:
				open_door()
		else:
			received_signals = max(received_signals - 1, 0)  # Decrement but prevent negative values
			print("Signal removed. Current signals:", received_signals)
			if received_signals < required_connections:
				close_door()

func open_door():
	doorState = true
	AudioController.play_sfx("door_open")
	animation_tree.set("parameters/conditions/is_opening", true)
	animation_tree.set("parameters/conditions/is_closing", false)

func close_door():
	doorState = false
	AudioController.play_sfx("door_close")
	animation_tree.set("parameters/conditions/is_opening", false)
	animation_tree.set("parameters/conditions/is_closing", true)

func update_door_animation():
	if doorState:
		animation_tree.set("parameters/conditions/is_opening", true)
		animation_tree.set("parameters/conditions/is_closed", false)
	else:
		animation_tree.set("parameters/conditions/is_closed", true)
		animation_tree.set("parameters/conditions/is_opening", false)

func _check_link(button: StaticBody2D, button_id: String):
	if door_link_id == button_id:
		SharedSignals.full_link.emit(button_id, door_link_id)

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "closing":
		animation_tree.set("parameters/conditions/is_closed", true)
