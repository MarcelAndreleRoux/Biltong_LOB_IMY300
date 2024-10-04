extends StaticBody2D

var is_powered: bool = false
@export var next_wire: NodePath  # The next wire in the chain, if applicable
@export var connects_to: NodePath  # The node it connects to, e.g., a door
@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	# Connect the wire activation signal
	if next_wire:
		var next_wire_node = get_node(next_wire)
		next_wire_node.activated.connect(_on_wire_activated)

# Called when wire is activated
func _on_wire_activated():
	is_powered = true
	update_wire_visuals()

	# Pass the signal to the next wire in the chain
	if next_wire:
		var next_wire_node = get_node(next_wire)
		next_wire_node.emit_signal("activated")

	# If the wire connects to something like a door, activate it
	if connects_to:
		var door_node = get_node(connects_to)
		door_node.call("open_door")

func update_wire_visuals():
	animated_sprite_2d.play("on")
