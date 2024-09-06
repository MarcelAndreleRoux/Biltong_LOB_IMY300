extends Node2D

@onready var food = $Food
@onready var food_fire = $FoodFire
@onready var food_fire_water = $FoodFireWater

func _ready():
	# Initialize with no item visible and the "no_item" animation
	food.visible = true
	food.play("no_item")
	food_fire.visible = false
	food_fire_water.visible = false

	# Connect the signal for inventory changes
	SharedSignals.inventory_changed.connect(_on_inventory_changed)
	_set_visibility(GlobalValues.inventory_select)

func _on_inventory_changed(new_selection: int):
	print("Inventory changed to: ", new_selection)  # Debug: Check if signal is received
	_set_visibility(new_selection)

func _set_visibility(selected: int):
	# Hide all items initially
	food.visible = false
	food_fire.visible = false
	food_fire_water.visible = false

	# Handle inventory selection and collected items
	match selected:
		GlobalValues.INVENTORY_SELECT.FOOD:
			# Display the appropriate inventory based on collected items
			if GlobalValues.can_swap_water:
				food_fire_water.visible = true
				food_fire_water.play("selected_food")
			elif GlobalValues.can_swap_fire:
				food_fire.visible = true
				food_fire.play("selected_food")
			else:
				food.visible = true
				food.play("selected_food")

		GlobalValues.INVENTORY_SELECT.FIRE:
			# Display fire animations if fire is collected
			if GlobalValues.can_swap_water:
				food_fire_water.visible = true
				food_fire_water.play("selected_fire")
			elif GlobalValues.can_swap_fire:
				food_fire.visible = true
				food_fire.play("selected_fire")
			else:
				# Play error if fire is not collected
				food.visible = true
				food.play("error")

		GlobalValues.INVENTORY_SELECT.WATER:
			# Display water animations if water is collected
			if GlobalValues.can_swap_water:
				food_fire_water.visible = true
				food_fire_water.play("selected_water")
			else:
				# Play error if water is not collected
				food_fire.visible = true
				food_fire.play("error")

		GlobalValues.INVENTORY_SELECT.NONE:
			# Default state when nothing is selected
			food.visible = true
			food.play("no_item")

# Function to reset the inventory to the "no_item" state
func _on_inv_freez():
	_set_visibility(GlobalValues.INVENTORY_SELECT.NONE)
	food.play("no_item")
	food_fire.play("no_item")
	food_fire_water.play("no_item")
