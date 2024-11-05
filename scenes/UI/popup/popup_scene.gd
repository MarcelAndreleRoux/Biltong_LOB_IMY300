# popup_scene.gd
extends Control

signal popup_closed(popup_instance)

@onready var label = $TextureRect/Label
@onready var texture_button = $TextureRect/TextureButton
@onready var popup = $popup

var time_alive = 0
const POPUP_LIFETIME = 7.0

func _ready():
	texture_button.pressed.connect(_close_popup)
	
	popup.play()
	
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = POPUP_LIFETIME
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_end_cooldown)
	add_child(cooldown_timer)
	cooldown_timer.start()

func setup(text: String):
	label.text = text

func _end_cooldown():
	_close_popup()

func _close_popup():
	popup_closed.emit(self)

func _on_texture_button_pressed():
	_close_popup()
