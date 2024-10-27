extends StaticBody2D

@export var door_link_id: String
@export var required_connections: int = 1

@onready var animation_tree = $AnimationTree
@onready var door_close = $door_close
@onready var door_open = $door_open

var doorState: bool = false

# Keep track of which buttons and m_boards are currently pressed using a dictionary
var active_buttons: Dictionary = {}
var active_electrical: Dictionary = {}

func _ready():
	SharedSignals.doorState.connect(_on_door_stateChange)
	SharedSignals.check_link.connect(_check_link)
	update_door_animation()

func _on_door_stateChange(door_id: String, state: bool, button_instance_id: int):
	if door_id != door_link_id:
		return
	
	# Safety check for scene tree
	if not is_instance_valid(self) or not is_inside_tree():
		return
		
	var m_boards = []
	# Get all m_boards in the scene with null check
	if get_tree() != null:
		m_boards = get_tree().get_nodes_in_group("m_board")
	
	# Find if this instance_id belongs to an m_board with matching door_link_id
	var is_matching_mboard = false
	for board in m_boards:
		if is_instance_valid(board) and board.get_instance_id() == button_instance_id and board.door_link_id == door_link_id:
			is_matching_mboard = true
			break
	
	if state:
		if is_matching_mboard:
			active_electrical[button_instance_id] = true
		else:
			active_buttons[button_instance_id] = true
	else:
		if button_instance_id in active_electrical:
			active_electrical.erase(button_instance_id)
		if button_instance_id in active_buttons:
			active_buttons.erase(button_instance_id)
	
	check_connections()

func check_connections():
	var total_connections = active_buttons.size() + active_electrical.size()
	
	# Simple check - total connections must meet or exceed required connections
	if total_connections >= required_connections:
		open_door()
	else:
		close_door()

func open_door():
	if doorState:
		return
	doorState = true
	door_open.play()
	animation_tree.set("parameters/conditions/is_opening", true)
	animation_tree.set("parameters/conditions/is_closing", false)

func close_door():
	if !doorState:
		return
	doorState = false
	door_close.play()
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
