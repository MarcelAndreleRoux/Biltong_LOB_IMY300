extends Node2D

@onready var animation_player = $AnimationPlayer

func play_white_fade_in():
	animation_player.play("fade_in_white")

func play_white_fade_out():
	animation_player.play("fade_out_white")

func play_black_fade_in():
	animation_player.play("fade_in_black")

func play_black_fade_out():
	animation_player.play("fade_out_black")

func swtich_level():
	pass
