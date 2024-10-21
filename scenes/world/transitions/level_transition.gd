extends Area2D

@onready var animation_player = $AnimationPlayer
@onready var canvas_layer = $CanvasLayer

func _ready():
	canvas_layer.visible = true
	animation_player.play("fade_in_black")

func _on_body_entered(body):
	if body.is_in_group("player"):
		canvas_layer.visible = true
		animation_player.play("fade_out_black")

func switch_scene():
	GlobalValues.change_scene_to_next_level()

func _on_animation_player_animation_finished(anim_name):
	canvas_layer.visible = false
