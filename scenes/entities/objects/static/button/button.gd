extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var click_area = $ClickArea

func _ready():
	animated_sprite_2d.play("idle")

func _on_click_area_area_entered(area):
	animated_sprite_2d.play("click")
	SharedSignals.doorState.emit(true)

func _on_click_area_area_exited(area):
	animated_sprite_2d.play_backwards("click")
	
	SharedSignals.doorState.emit(false)
