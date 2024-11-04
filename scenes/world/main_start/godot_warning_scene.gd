extends Node2D

@onready var animation_player = $AnimationPlayer
@onready var canvas_layer = $CanvasLayer

func _ready():
	canvas_layer.visible = true
	animation_player.play("fade_in")

func change_scene():
	get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
