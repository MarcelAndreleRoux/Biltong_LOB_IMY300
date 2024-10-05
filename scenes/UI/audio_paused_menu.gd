class_name AudioPause
extends CanvasLayer

@onready var shake_camera = $ShakeCamera
@onready var button_select = $ButtonSelect
var back: bool = false

func _ready():
	self.hide()

func _on_back_pressed():
	shake_camera.apply_shake_smaller()
	back = true
	button_select.play()

func audio_options_selected():
	self.show()

func _on_button_select_finished():
	# Hide the audio options and return to the pause menu
	self.hide()
	var pause_menu = get_parent().get_node("GamePause")
	pause_menu.show()
