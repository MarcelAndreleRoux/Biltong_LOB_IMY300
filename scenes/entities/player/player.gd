extends CharacterBody2D

signal update_health(health: int, position: Vector2)
signal update_inventory(item: String)

var currentVelocity: Vector2
var speed: int = 150
var _health: int = 100

var _trajectoryLine: Line2D

var _player: Sprite2D
var _line: Line2D

var _End: Sprite2D

var _itemToPickUp: Node2D
# Used to know what item is selected to be thrown
var _selectedItem: Node2D
# Will only not be able to throw if you throw too fast
var _canThrowItem: bool = true
var _isAiming: bool = false

func _ready():
	pass

func _handle_damage_player(damage_amount: int):
	pass
	#_health -= damage_amount
	#emit_signal("update_health", _health, position)

func _handle_item_pickup(item: String):
	pass 
	#emit_signal("update_inventory", item)

func _physics_process(delta: float):
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
	currentVelocity *= speed

func _on_pickup_area_body_entered(item: Node2D):
	pass
	#if item:
		#_itemToPickUp = item
		#_selectedItem = item

