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

func _full_link(button_id: String, door_id: String):
	if button_id == door_link_id:
		door_link_found = door_id
		found_link = true

func _check_link(button: StaticBody2D, button_id: String):
	if door_link_id == button_id:
		SharedSignals.full_link.emit(button_id, door_link_id)

func _on_button_change(state: bool):
	if animation_name == "default":
		if state:
			animated_sprite_2d.play("default_on")
			connected_sound.play()
		else:
			animated_sprite_2d.play("default_off")
			disconnect_sound.play()

func _on_connection_check(state: bool):
	if has_conductor_box and state:
		is_conductor_charged = true
		SharedSignals.conductor_connection.emit(self)
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_on")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, true)
			connected_sound.play()
		elif animation_name == "two_connector":
			connected_bodies += 1
			if connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				connect_sound.play()
			elif connected_bodies >= 2:
				animated_sprite_2d.play("two_connector_on")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, true)
				connected_sound.play()
	else:
		is_conductor_charged = false
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_off")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, false)
			disconnect_sound.play()
		elif animation_name == "two_connector":
			connected_bodies -= 1
			if connected_bodies <= 0:
				connected_bodies = 0
				animated_sprite_2d.play("two_connector_off")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, false)
				disconnect_sound.play()
			elif connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				disconnect_sound.play()

func receive_electricity():
	is_conductor_charged = true
	SharedSignals.lizard_connection.emit(self)
	if animation_name == "one_connector":
		animated_sprite_2d.play("one_connector_on")
		if found_link and door_link_id == door_link_found:
			SharedSignals.doorState.emit(door_link_id, true)
		connected_sound.play()
	elif animation_name == "two_connector":
		connected_bodies += 1
		if connected_bodies == 1:
			animated_sprite_2d.play("two_connector_semi")
			connect_sound.play()
		elif connected_bodies >= 2:
			animated_sprite_2d.play("two_connector_on")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, true)
			connected_sound.play()

func stop_electricity():
	is_conductor_charged = false
	if animation_name == "one_connector":
		animated_sprite_2d.play("one_connector_off")
		if found_link and door_link_id == door_link_found:
			SharedSignals.doorState.emit(door_link_id, false)
		disconnect_sound.play()
	elif animation_name == "two_connector":
		connected_bodies -= 1
		if connected_bodies <= 0:
			connected_bodies = 0
			animated_sprite_2d.play("two_connector_off")
			disconnect_sound.play()
		elif connected_bodies == 1:
			animated_sprite_2d.play("two_connector_semi")
			disconnect_sound.play()

func _on_connection_area_body_entered(body):
	if body.is_in_group("conductor"):
		has_conductor_box = true
	
	if body.is_in_group("electrical"):
		var lizard_state = body.get_electrical_state()
		if lizard_state:
			is_conductor_charged = true
			SharedSignals.lizard_connection.emit(self)
			if animation_name == "one_connector":
				animated_sprite_2d.play("one_connector_on")
				if found_link and door_link_id == door_link_found:
					SharedSignals.doorState.emit(door_link_id, true)
				connected_sound.play()
			elif animation_name == "two_connector":
				connected_bodies += 1
				if connected_bodies == 1:
					animated_sprite_2d.play("two_connector_semi")
					connect_sound.play()
				elif connected_bodies >= 2:
					animated_sprite_2d.play("two_connector_on")
					if found_link and door_link_id == door_link_found:
						SharedSignals.doorState.emit(door_link_id, true)
					connected_sound.play()

func _on_connection_area_body_exited(body):
	if body.is_in_group("conductor"):
		has_conductor_box = false
		is_conductor_charged = false
	
	if body.is_in_group("electrical"):
		is_conductor_charged = false
		if animation_name == "one_connector":
			animated_sprite_2d.play("one_connector_off")
			if found_link and door_link_id == door_link_found:
				SharedSignals.doorState.emit(door_link_id, false)
			disconnect_sound.play()
		elif animation_name == "two_connector":
			connected_bodies -= 1
			if connected_bodies <= 0:
				connected_bodies = 0
				animated_sprite_2d.play("two_connector_off")
				disconnect_sound.play()
			elif connected_bodies == 1:
				animated_sprite_2d.play("two_connector_semi")
				disconnect_sound.play()
