extends Node2D

@onready var food = $Food
@onready var food_fire = $FoodFire
@onready var food_fire_water = $FoodFireWater

func _ready():
	food.play("no_item")
	SharedSignals.invertory_update.connect(_on_inv_update)
	SharedSignals.inventory_freez.connect(_on_inv_freez)

func _on_inv_update():
	food.play("selected_food")

func _on_inv_freez():
	food.play("no_item")
