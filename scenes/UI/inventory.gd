extends Node2D

@onready var food = $Food
@onready var food_fire = $FoodFire
@onready var food_fire_water = $FoodFireWater

func _ready():
	# Make sure food is visible and playing "no_item" at the start
	food.visible = true
	food.play("no_item")
	
	# Hide the other items initially
	food_fire.visible = false
	food_fire_water.visible = false
	
	# Connect the signal
	SharedSignals.inventory_changed.connect(_on_inventory_changed)
	_set_visibility(GlobalValues.inventory_select)
	
	# Do not call _set_visibility here, because it will override the "no_item" state
	# _set_visibility(GlobalValues.INVENTORY_SELECT.FOOD) 

func _on_inventory_changed(new_selection: int):
	print("Inventory changed to: ", new_selection)  # Debug: Check if signal is received
	_set_visibility(new_selection)

func _set_visibility(selected: int):
	# Hide all animation players by default
	food.visible = false
	food_fire.visible = false
	food_fire_water.visible = false

	# Determine the correct animation based on the current selection and collected items
	match selected:
		GlobalValues.INVENTORY_SELECT.FOOD:
			# If water is collected, show the full `food_fire_water` animation
			if GlobalValues.can_swap_water:
				food_fire_water.visible = true
				food_fire_water.play("selected_food")
			# If only fire is collected, show the `food_fire` animation
			elif GlobalValues.can_swap_fire:
				food_fire.visible = true
				food_fire.play("selected_food")
			# If only food is collected, show the `food` animation
			else:
				food.visible = true
				food.play("selected_food")
				
		GlobalValues.INVENTORY_SELECT.FIRE:
			# If water is collected, show the full `food_fire_water` animation
			if GlobalValues.can_swap_water:
				food_fire_water.visible = true
				food_fire_water.play("selected_fire")
			# Otherwise, show the `food_fire` animation
			else:
				food_fire.visible = true
				food_fire.play("selected_fire")
				
		GlobalValues.INVENTORY_SELECT.WATER:
			# Always show the full `food_fire_water` animation when water is selected
			food_fire_water.visible = true
			food_fire_water.play("selected_water")
				
		GlobalValues.INVENTORY_SELECT.NONE:
			food.visible = true
			food.play("no_item")

func _on_inv_freez():
	_set_visibility(GlobalValues.INVENTORY_SELECT.NONE)
	food.play("no_item")
	food_fire.play("no_item")
	food_fire_water.play("no_item")
