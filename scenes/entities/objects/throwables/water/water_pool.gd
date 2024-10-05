extends StaticBody2D

@onready var action_button = $ActionButton
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var pickup = $pickup

var already_picked: bool = false
var player_in_area: bool = false
var picked_up_once: bool = false

func _ready():
	# Disable collision if the item was already picked up in a previous life
	if GlobalValues.can_swap_water:
		collision_shape_2d.disabled = true
		already_picked = true
		return  # No need to do anything else if the item was picked up before

	collision_shape_2d.disabled = true
	action_button.visible = false
	animated_sprite_2d.play("idle")

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("pickup") and not already_picked:
		already_picked = true
		GlobalValues.can_swap_water = true
		SharedSignals.item_pickup.emit()
		GlobalValues.set_inventory_select(GlobalValues.INVENTORY_SELECT.WATER)
		SharedSignals.inventory_changed.emit(GlobalValues.INVENTORY_SELECT.WATER)
		action_button.visible = false
		animated_sprite_2d.play("pickup")
		pickup.play()

func _on_action_area_body_entered(body):
	if body.is_in_group("player") and not picked_up_once and not already_picked:
		player_in_area = true
		animated_sprite_2d.play("close")
		collision_shape_2d.disabled = false

func _on_action_area_body_exited(body):
	if body.is_in_group("player") and not picked_up_once and not already_picked:
		player_in_area = false
		action_button.visible = false
		animated_sprite_2d.play("idle")
