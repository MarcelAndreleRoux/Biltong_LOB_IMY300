extends StaticBody2D

@export var door_link_id: String
@export_enum("Normal", "Toggle") var button_mode: String = "Normal"
@export var start_pressed: bool = false  # Add this to set initial state

signal hazmat_warning

var found_link: bool = false
var area2d_active: bool = false
var is_toggled: bool = false
var last_activator = null
var shader_material: ShaderMaterial
var is_pressed: bool = false

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var click_area = $ClickArea
@onready var click = $click
@onready var error = $error

var door_link_found: String
var activators: Array = []

func _ready():
	SharedSignals.full_link.connect(_full_link)
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://scenes/entities/objects/static/button/button.gdshader")
	animated_sprite_2d.material = shader_material
	
	if button_mode == "Toggle":
		is_toggled = start_pressed
		if start_pressed:
			animated_sprite_2d.play("click")
			SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
			SharedSignals.button_active.emit(true)
		else:
			SharedSignals.button_active.emit(false)
			animated_sprite_2d.play("idle")
	else:
		SharedSignals.button_active.emit(false)
		animated_sprite_2d.play("idle")
	
	update_shader_toggle()

func _on_click_area_body_entered(body):
	if body.is_in_group("activation"):
		if body.is_in_group("player") and not GlobalValues.hazmat_picked_up:
			hazmat_warning.emit()
			error.play()
			return
		
		if not activators.has(body):
			activators.append(body)
			
		SharedSignals.check_link.emit(self, door_link_id)
		
		if found_link and door_link_id == door_link_found:
			handle_button_press(body)
			# After initial press, switch to stay_on animation
			if animated_sprite_2d.animation == "click":
				await animated_sprite_2d.animation_finished
				if not activators.is_empty():
					animated_sprite_2d.play("stay_on")

func _on_click_area_body_exited(body):
	if body.is_in_group("activation"):
		activators.erase(body)
		
		if activators.is_empty():  # When last object leaves
			is_pressed = false
			if button_mode == "Normal":  # Only change state for normal buttons
				animated_sprite_2d.play_backwards("click")
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				SharedSignals.button_active.emit(false, door_link_id)
		
		if body == last_activator:
			last_activator = null

func update_shader_toggle():
	if shader_material:
		shader_material.set_shader_parameter("should_be_blue", button_mode == "Toggle")

func handle_button_press(activator):
	last_activator = activator
	
	if button_mode == "Toggle":
		if not is_pressed or (animated_sprite_2d.animation == "idle"):
			is_pressed = true
			is_toggled = !is_toggled
			click.play()
			if is_toggled:
				animated_sprite_2d.play("stay_on")
				SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
				SharedSignals.button_active.emit(true, door_link_id)
			else:
				animated_sprite_2d.play("idle")
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				SharedSignals.button_active.emit(false, door_link_id)
	else:
		# Normal mode behavior
		if not is_pressed:
			is_pressed = true
			click.play()
			animated_sprite_2d.play("click")
			SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
			SharedSignals.button_active.emit(true, door_link_id)

func _full_link(button_id: String, door_id: String):
	if button_id == door_link_id:
		door_link_found = door_id
		found_link = true

func _on_detect_box_area_entered(area: Area2D):
	if area.name == "ButtonArea":
		area2d_active = true
		
		if not activators.has(area):
			activators.append(area)
			
		SharedSignals.check_link.emit(self, door_link_id)
		
		if found_link and door_link_id == door_link_found:
			handle_button_press(area)
			# After initial press, switch to stay_on animation
			if animated_sprite_2d.animation == "click":
				await animated_sprite_2d.animation_finished
				if not activators.is_empty():
					animated_sprite_2d.play("stay_on")

func _on_detect_box_area_exited(area: Area2D):
	if area.name == "ButtonArea":
		area2d_active = false
		activators.erase(area)
		
		if activators.is_empty():  # When last object leaves
			is_pressed = false
			if button_mode == "Normal":  # Only change state for normal buttons
				animated_sprite_2d.play_backwards("click")
				SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
				SharedSignals.button_active.emit(false)
		
		if area == last_activator:
			last_activator = null

func _on_animated_sprite_2d_animation_finished():
	if button_mode == "Toggle":
		if is_toggled:
			animated_sprite_2d.play("stay_on")
		else:
			animated_sprite_2d.play("idle")
	else:  # Normal button
		if animated_sprite_2d.animation == "click" and not activators.is_empty():
			animated_sprite_2d.play("stay_on")
		elif animated_sprite_2d.animation_finished and activators.is_empty():
			animated_sprite_2d.play("idle")
