extends StaticBody2D

@export var door_link_id: String
@export_enum("Normal", "Toggle") var button_mode: String = "Normal"
@export var start_pressed: bool = false  # Add this to set initial state

var found_link: bool = false
var area2d_active: bool = false
var is_toggled: bool = false
var last_activator = null
var shader_material: ShaderMaterial

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var click_area = $ClickArea
@onready var click = $click

var door_link_found: String

func _ready():
	SharedSignals.full_link.connect(_full_link)
	
	# Setup shader
	shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://scenes/entities/objects/static/button/button.gdshader")
	animated_sprite_2d.material = shader_material
	
	# Initialize button state
	if button_mode == "Toggle":
		is_toggled = start_pressed
		if start_pressed:
			animated_sprite_2d.play("click")
			SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
		else:
			animated_sprite_2d.play("idle")
	else:
		animated_sprite_2d.play("idle")
	
	# Update shader state
	update_shader_toggle()

func _on_click_area_body_entered(body):
	if area2d_active:
		return
		
	if body.is_in_group("activation"):
		if body.is_in_group("player") and not GlobalValues.hazmat_picked_up:
			# Player needs hazmat suit
			AudioController.play_sfx("error")  # Optional: Play error sound
			return
			
		SharedSignals.check_link.emit(self, door_link_id)
		
		if found_link and door_link_id == door_link_found:
			handle_button_press(body)

func update_shader_toggle():
	if shader_material:
		shader_material.set_shader_parameter("should_be_blue", button_mode == "Toggle")

func handle_button_press(activator):
	last_activator = activator
	click.play()
	
	if button_mode == "Toggle":
		is_toggled = !is_toggled
		if is_toggled:
			animated_sprite_2d.play("click")
			SharedSignals.doorState.emit(door_link_id, true, get_instance_id())
		else:
			animated_sprite_2d.play_backwards("click")
			SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
	else:
		# Normal mode behavior
		animated_sprite_2d.play("click")
		SharedSignals.doorState.emit(door_link_id, true, get_instance_id())

func _on_click_area_body_exited(body):
	if area2d_active:
		return
		
	if body.is_in_group("activation"):
		if button_mode == "Normal" and found_link and door_link_id == door_link_found:
			animated_sprite_2d.play_backwards("click")
			SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
		
		if body == last_activator:
			last_activator = null

func _full_link(button_id: String, door_id: String):
	if button_id == door_link_id:
		door_link_found = door_id
		found_link = true

func _on_detect_box_area_entered(area: Area2D):
	if area.name == "ButtonArea":
		area2d_active = true
		SharedSignals.check_link.emit(self, door_link_id)
		
		if found_link and door_link_id == door_link_found:
			handle_button_press(area)

func _on_detect_box_area_exited(area: Area2D):
	if area.name == "ButtonArea":
		area2d_active = false
		if button_mode == "Normal" and found_link and door_link_id == door_link_found:
			animated_sprite_2d.play_backwards("click")
			SharedSignals.doorState.emit(door_link_id, false, get_instance_id())
		
		if area == last_activator:
			last_activator = null
