extends Node2D

@onready var sprite_2d = $Sprite2D
@onready var food = $Food
@onready var action_button = $ActionButton

func _ready():
	action_button.visible = false
	SharedSignals.pickedup_item.connect(_remove_item)

func _remove_item():
	sprite_2d.visible = false
	food.visible = false
	SharedSignals.item_removed.emit()

func _on_food_area_entered(area):
	action_button.visible = true
