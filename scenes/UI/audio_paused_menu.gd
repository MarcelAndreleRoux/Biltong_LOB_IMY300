class_name AudioPause
extends CanvasLayer

@onready var shake_camera = $ShakeCamera
var back: bool = false

func _ready():
	self.hide()
	AudioController.button_select.connect(_on_select_finished)

func _on_back_pressed():
	shake_camera.apply_shake_smaller()
	back = true
	AudioController.play_sfx("button_select")

func audio_options_selected():
	self.show()

func _on_select_finished():
	# Hide the audio options and return to the pause menu
	self.hide()
	var pause_menu = get_parent().get_node("GamePause")
	pause_menu.show()

func _on_back_mouse_entered():
	AudioController.play_sfx("button_hover")
