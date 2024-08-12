extends Node2D

@onready var inventory = $AnimatedSprite2D

func _ready():
	inventory.play("no_item")
	SharedSignals.invertory_update.connect(_on_inv_update)
	SharedSignals.inventory_freez.connect(_on_inv_freez)

func _on_inv_update():
	inventory.play("selected_food")

func _on_inv_freez():
	inventory.play("no_item")
