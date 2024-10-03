extends CanvasLayer

@onready var button_select = $ButtonSelect
var back: bool = false

func _ready():
	self.hide()

func _on_back_pressed():
	back = true
	button_select.play()

func audio_options_selected():
	self.show()

func _on_button_select_finished():
	self.hide()
	# Ensure that the game pause menu is shown again
	var pause_menu = get_parent().get_node("GamePause")
	pause_menu.show()
