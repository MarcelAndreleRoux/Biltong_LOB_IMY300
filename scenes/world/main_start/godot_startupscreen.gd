extends Node2D

@onready var animation_player = $AnimationPlayer
@onready var change_scene = $ChangeScene
@onready var animation_player_timer = $AnimationPlayerTimer
@onready var partical = $Partical

# Called when the node enters the scene tree for the first time.
func _ready():
	MenuAudioController.stop_music()
	animation_player.play("splash")

func _on_change_scene_timeout():
	get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
