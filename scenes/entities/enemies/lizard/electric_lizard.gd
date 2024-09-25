extends CharacterBody2D

@onready var animation_tree = $AnimationTree
@onready var electricity = $Electricity

func _on_electric_area_body_entered(body):
	pass

func _on_electric_area_body_exited(body):
	pass
	
func update_animation_parameters():
	pass
