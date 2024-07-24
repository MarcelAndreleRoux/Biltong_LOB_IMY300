extends CharacterBody2D

signal update_health(health: int, position: Vector2)
signal update_inventory(item: String)

@onready var animation_tree = $AnimationTree

var currentVelocity: Vector2
var speed: int = 150

var is_aiming: bool
var direction: Vector2 = Vector2.ZERO

#var _itemToPickUp: Node2D
# Used to know what item is selected to be thrown
#var _selectedItem: Node2D
# Will only not be able to throw if you throw too fast
#var _canThrowItem: bool = true
#var _isAiming: bool = false

func _ready():
	animation_tree.active = true

func _handle_damage_player(_damage_amount: int):
	pass
	#_health -= damage_amount
	#emit_signal("update_health", _health, position)

func _handle_item_pickup(_item: String):
	pass 
	#emit_signal("update_inventory", item)

func _physics_process(_delta):
	_update_animation_parameters()
	_handle_input()

	#if Input.is_action_just_pressed("pickup") and _itemToPickUp != null:
		#SharedSignals.pickup_item.emit(_itemToPickUp.name)
	velocity = currentVelocity
	
	move_and_slide()

func _throw_item():
	pass
	#if _itemToPickUp != null:
		#SharedSignals.item_throw.emit()

func _handle_input():
	currentVelocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	currentVelocity *= speed

func _update_animation_parameters():
	# Movement
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_run"] = false
		animation_tree["parameters/conditions/is_idle_throw"] = false
		animation_tree["parameters/conditions/is_run_throw"] = false
		animation_tree["parameters/conditions/is_idle_aim"] = false
		animation_tree["parameters/conditions/is_run_aim"] = false
	else:
		animation_tree["parameters/conditions/is_run"] = true
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_idle_throw"] = false
		animation_tree["parameters/conditions/is_run_throw"] = false
		animation_tree["parameters/conditions/is_idle_aim"] = false
		animation_tree["parameters/conditions/is_run_aim"] = false

	# Aim
	if Input.is_action_just_pressed("aim"):
		is_aiming = not is_aiming
		
		if velocity == Vector2.ZERO:
			animation_tree["parameters/conditions/is_idle_aim"] = true
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_run_aim"] = false
		else:
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/is_run"] = false
			animation_tree["parameters/conditions/is_run_aim"] = true
	
	# Throw while aiming
	if Input.is_action_just_pressed("throw") and is_aiming:
		if velocity == Vector2.ZERO:
			animation_tree["parameters/conditions/is_idle_throw"] = true
			animation_tree["parameters/conditions/is_run_throw"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/is_run_aim"] = false
		else:
			animation_tree["parameters/conditions/is_run_throw"] = true
			animation_tree["parameters/conditions/is_idle_throw"] = false
			animation_tree["parameters/conditions/is_idle_aim"] = false
			animation_tree["parameters/conditions/is_run_aim"] = false
	
	animation_tree["parameters/idle/blend_position"] = direction
	animation_tree["parameters/idle_aim/blend_position"] = direction
	animation_tree["parameters/idle_throw/blend_position"] = direction
	animation_tree["parameters/run/blend_position"] = direction
	animation_tree["parameters/run_aim/blend_position"] = direction
	animation_tree["parameters/run_throw/blend_position"] = direction

func _on_pickup_area_body_entered(_item: Node2D):
	pass
	#if item:
		#_itemToPickUp = item
		#_selectedItem = item

