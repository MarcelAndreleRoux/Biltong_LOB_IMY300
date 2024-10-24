extends StaticBody2D

@export var door_link_id: String
@export var required_connections: int = 1

@onready var animation_tree = $AnimationTree

var doorState: bool = false
# Keep track of which buttons are currently pressed using a dictionary
var active_buttons: Dictionary = {}

func _ready():
	SharedSignals.doorState.connect(_on_door_stateChange)
	SharedSignals.check_link.connect(_check_link)
	update_door_animation()

func _on_door_stateChange(door_id: String, state: bool, button_instance_id: int):
	if door_id != door_link_id:
		return
		
	if state:
		# Add button to active buttons
		active_buttons[button_instance_id] = true
	else:
		# Remove button from active buttons
		active_buttons.erase(button_instance_id)
	
	# Check if we have enough active buttons
	if active_buttons.size() >= required_connections:
		open_door()
	else:
		close_door()

func open_door():
	if doorState:
		return
	doorState = true
	AudioController.play_sfx("door_open")
	animation_tree.set("parameters/conditions/is_opening", true)
	animation_tree.set("parameters/conditions/is_closing", false)

func close_door():
	if !doorState:
		return
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
