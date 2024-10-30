extends StaticBody2D

@export var connector_name: String = "none"
@export var door_link_id: String

# Nodes
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var connect_sound = $Connect
@onready var connected_sound = $Connected
@onready var disconnect_sound = $Disconnect

# Variables
var animation_name: String = "default"
var connected_bodies: int = 0  # Keeps track of connected bodies

var has_conductor_box: bool = false
var is_conductor_charged: bool = false  # Track if the conductor is charged
var found_link: bool = false
var door_link_found: String

func _ready():
	add_to_group("m_board")
	if connector_name == "one":
		animation_name = "one_connector"
		animated_sprite_2d.play("one_connector_off")
	elif connector_name == "two":
		animation_name = "two_connector"
		animated_sprite_2d.play("two_connector_off")
	else:
		animation_name = "default"
		animated_sprite_2d.play("default_off")
	
	SharedSignals.button_active.connect(_on_button_change)
	SharedSignals.full_link.connect(_full_link)
	SharedSignals.check_link.connect(_check_link)
	SharedSignals.check_link.emit(self, door_link_id)
	SharedSignals.lizard_connection_made.connect(_on_connection_check)
	# Add this new signal connection for default boards
	SharedSignals.doorState.connect(_on_door_state_change)

func _full_link(button_id: String, door_id: String):
	if button_id == door_link_id:
		door_link_found = door_id
		found_link = true

func _check_link(button: StaticBody2D, button_id: String):
	if door_link_id == button_id:
		SharedSignals.full_link.emit(button_id, door_link_id)

func _on_button_change(state: bool, button_id: String):
	pass

func _on_connection_check(state: bool):
	if has_conductor_box and state:
		is_conductor_charged = true
		SharedSignals.conductor_connection.emit(self)
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_on")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
			connected_sound.play()
		elif animation_name == "two_connector":
			connected_bodies += 1
			if connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				connect_sound.play()
			elif connected_bodies >= 2:
				animated_sprite_2d.play("two_connector_on")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
				connected_sound.play()
	else:
		is_conductor_charged = false
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_off")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
			disconnect_sound.play()
		elif animation_name == "two_connector":
			connected_bodies -= 1
			if connected_bodies <= 0:
				connected_bodies = 0
				animated_sprite_2d.play("two_connector_off")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				disconnect_sound.play()
			elif connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				disconnect_sound.play()

func _on_door_state_change(door_id: String, state: bool, _button_instance_id: int):
	if connector_name == "none" and door_id == door_link_id:
		if state:
			animated_sprite_2d.play("default_on")
			connected_sound.play()
		else:
			animated_sprite_2d.play("default_off")
			disconnect_sound.play()

func receive_electricity(from_conductor: bool = false):
	# Only handle electricity for non-default boards
	if connector_name == "none":
		return
		
	if not is_conductor_charged:
		is_conductor_charged = true
		
		# Only emit signals if the electricity is coming from the appropriate source
		if from_conductor:
			SharedSignals.conductor_connection.emit(self)  # Only conductor box should listen
		else:
			SharedSignals.lizard_connection.emit(self)  # Only lizard should listen
			
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_on")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
			connected_sound.play()
		elif animation_name == "two_connector":
			connected_bodies += 1
			if connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				connect_sound.play()
			elif connected_bodies >= 2:
				animated_sprite_2d.play("two_connector_on")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
				connected_sound.play()

func stop_electricity():
	if connector_name == "none":
		return
		
	is_conductor_charged = false
	if animation_name == "one_connector":
		animated_sprite_2d.play("one_connector_off")
		if found_link and door_link_id == door_link_found:
			SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
		disconnect_sound.play()
	elif animation_name == "two_connector":
		connected_bodies -= 1
		if connected_bodies <= 0:
			connected_bodies = 0
			animated_sprite_2d.play("two_connector_off")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
			disconnect_sound.play()
		elif connected_bodies == 1:
			animated_sprite_2d.play("two_connector_semi")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
			disconnect_sound.play()

func _on_connection_area_body_entered(body):
	# Only accept conductor boxes for non-default boards
	if connector_name == "none":
		return
		
	if body.is_in_group("conductor"):
		has_conductor_box = true
		# Check if conductor is already charged
		if body.charged_state:
			receive_electricity(true)
	
	elif body.is_in_group("electrical"):
		if body.get_electrical_state():
			receive_electricity(false)

func _on_connection_area_body_exited(body):
	if connector_name == "none":
		return
	
	if body.is_in_group("conductor"):
		has_conductor_box = false
		is_conductor_charged = false
		
		# Reset animations based on connector type
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_off")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
			disconnect_sound.play()
		elif animation_name == "two_connector":
			connected_bodies -= 1
			if connected_bodies <= 0:
				connected_bodies = 0
				animated_sprite_2d.play("two_connector_off")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				disconnect_sound.play()
			elif connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				disconnect_sound.play()
	
	if body.is_in_group("electrical"):
		is_conductor_charged = false
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_off")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
			disconnect_sound.play()
		elif animation_name == "two_connector":
			connected_bodies -= 1
			if connected_bodies <= 0:
				connected_bodies = 0
				animated_sprite_2d.play("two_connector_off")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				disconnect_sound.play()
			elif connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				disconnect_sound.play()
