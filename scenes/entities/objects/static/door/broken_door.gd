extends StaticBody2D

@export var door_link_id: String
@export var required_connections: int = 1

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var audio_controler = $AudioControler
@onready var disconnect = $disconnect
@onready var cpu_particles_2d = $CPUParticles2D
@onready var cpu_particles_2d_2 = $CPUParticles2D2

var openString: String
var closeString: String

var closed_check: bool = true

var active_buttons: Dictionary = {}

func _ready():
	cpu_particles_2d.emitting = false
	cpu_particles_2d_2.emitting = false
	SharedSignals.doorState.connect(_on_door_stateChange)
	SharedSignals.check_link.connect(_check_link)
	make_string()

func make_string():
	animated_sprite_2d.play("start")

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
		closed_check = false
		disconnect.play()
		cpu_particles_2d.emitting = true
		cpu_particles_2d_2.emitting = true
		animated_sprite_2d.play("default")
	else:
		closed_check = true
		disconnect.stop()
		cpu_particles_2d.emitting = false
		cpu_particles_2d_2.emitting = false
		animated_sprite_2d.play("start")

func _check_link(button: StaticBody2D, button_id: String):
	if door_link_id == button_id:
		SharedSignals.full_link.emit(button_id, door_link_id)
