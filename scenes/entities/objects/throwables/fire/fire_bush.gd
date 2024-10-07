extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var action_button_press = $ActionButtonPress

var already_picked: bool = false
var player_in_area: bool = false
var picked_up_once: bool = false

func _ready():
	# Disable collision if the item was already picked up in a previous life
	if GlobalValues.can_swap_fire:
		collision_shape_2d.disabled = true
		already_picked = true
		animated_sprite_2d.play("pickup")
		return

	collision_shape_2d.disabled = true
	action_button_press.visible = false
	animated_sprite_2d.play("idle")

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("pickup") and not already_picked:
		already_picked = true
		GlobalValues.can_swap_fire = true  # Set global flag to track item
		SharedSignals.item_pickup.emit()
		GlobalValues.set_inventory_select(GlobalValues.INVENTORY_SELECT.FIRE)
		SharedSignals.inventory_changed.emit(GlobalValues.INVENTORY_SELECT.FIRE)
		action_button_press.visible = false
		animated_sprite_2d.play("pickup")
		AudioController.play_sfx("fire_pickup")

func _on_action_area_body_entered(body):
	if body.is_in_group("player") and not picked_up_once and not already_picked:
		player_in_area = true
		
		if not GlobalValues.has_pickeup_fire_once:
			GlobalValues.has_pickeup_fire_once = true
			action_button_press.visible = true
			action_button_press.play("default")
		else:
			action_button_press.visible = false
			
		_some_waiting_timer()
		animated_sprite_2d.play("close")
		collision_shape_2d.disabled = false

func _some_waiting_timer():
	var grow_timer = Timer.new()
	grow_timer.name = "show_timer"
	grow_timer.wait_time = 5.0
	grow_timer.one_shot = true
	grow_timer.timeout.connect(_show_timeout)
	add_child(grow_timer)
	grow_timer.start()

func _show_timeout():
	$show_timer.queue_free()
	action_button_press.visible = false

func _on_action_area_body_exited(body):
	if body.is_in_group("player") and not picked_up_once and not already_picked:
		player_in_area = false
		action_button_press.visible = false
		animated_sprite_2d.play("idle")
