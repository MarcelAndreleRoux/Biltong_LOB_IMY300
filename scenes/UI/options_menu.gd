class_name OptionsMenu
extends Control

@onready var button = $MarginContainer/VBoxContainer/Button

signal exit_options_menu

func _ready():
	AudioController.button_select.connect(_on_select_finished)
	set_process(false)

func _on_back_pressed():
	AudioController.play_sfx("button_select")

func _on_select_finished():
	exit_options_menu.emit()
