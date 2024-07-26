extends Node2D

@onready var sprite_2d = $Sprite2D
@onready var food = $Food

func _ready():
	SharedSignals.pickedup_item.connect(_remove_item)

func _remove_item():
	sprite_2d.visible = false
	food.visible = false
	SharedSignals.item_removed.emit()
