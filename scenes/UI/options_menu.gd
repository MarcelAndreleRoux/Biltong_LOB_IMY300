class_name OptionsMenu
extends Control

signal exit_options_menu

func _ready():
	AudioController.button_select.connect(_on_select_finished)

func _on_back_pressed():
	AudioController.play_sfx("button_select")

func _on_select_finished():
	exit_options_menu.emit()

func _on_volume_slider_3_value_changed(value):
	AudioController.play_sfx("TICKSOUND_MASTER")

func _on_volume_slider_value_changed(value):
	AudioController.play_sfx("TICKSOUND_MUSIC")

func _on_volume_slider_2_value_changed(value):
	AudioController.play_sfx("TICKSOUND_SFX")
