extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var action_button_press = $ActionButtonPress

var eating: bool = false
var playing_grow: bool = false
var play_backwards: bool = false
var player_in_area: bool = false
var can_still_pickup: bool = false

func _ready():
	collision_shape_2d.disabled = true
	action_button_press.visible = false
	animated_sprite_2d.play("idle")

func _play_grow_backwards():
	play_backwards = true
	animated_sprite_2d.play_backwards("grow")
	
func _some_waiting_timer():
	var grow_timer = Timer.new()
	grow_timer.name = "grow_timer"
	grow_timer.wait_time = 3.0
	grow_timer.one_shot = true
	grow_timer.timeout.connect(_wait_before_grow_timer)
	add_child(grow_timer)
	grow_timer.start()

func _wait_before_grow_timer():
	var timer = Timer.new()
	timer.name = "regrow_timer"
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(_play_grow_animation)
	add_child(timer)
	timer.start()

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("pickup") and not eating and not GlobalValues.food_already_picked:
		action_button_press = true
		GlobalValues.food_already_picked = true
		SharedSignals.item_pickup.emit()
		GlobalValues.set_inventory_select(GlobalValues.INVENTORY_SELECT.FOOD)
		SharedSignals.show_aim.emit()
		GlobalValues.can_swap_food = true
		animated_sprite_2d.play("idle")
		AudioController.play_sfx("food_pickup")
	
	if can_still_pickup and Input.is_action_just_pressed("pickup") and not GlobalValues.food_already_picked:
			action_button_press = true
			GlobalValues.food_already_picked = true
			SharedSignals.item_pickup.emit()
			GlobalValues.set_inventory_select(GlobalValues.INVENTORY_SELECT.FOOD)
			SharedSignals.show_aim.emit()
			GlobalValues.can_swap_food = true
			animated_sprite_2d.play("idle")
			AudioController.play_sfx("food_pickup")

func _play_grow_animation():
	playing_grow = true
	animated_sprite_2d.play("grow")

func _on_action_area_body_entered(body):
	if body.is_in_group("player") and eating:
		SharedSignals.play_pickup_notification.emit()
	
	if body.is_in_group("player") and not eating and not GlobalValues.food_already_picked:
		player_in_area = true
		animated_sprite_2d.play("pickup")
		if not GlobalValues.has_pickeup_food_once:
			GlobalValues.has_pickeup_food_once = true
			action_button_press.play("default")
			action_button_press.visible = true
	
	if body.is_in_group("enemy"):
		eating = true
		_play_grow_backwards()

func _on_action_area_body_exited(body):
	if body.is_in_group("player"):
		can_still_pickup = false
		player_in_area = false
		if not eating and not GlobalValues.food_already_picked:
			animated_sprite_2d.play("idle")

func _on_animated_sprite_2d_animation_finished():
	if playing_grow:
		eating = false
		playing_grow = false
		
		if player_in_area:
			eating = false
			playing_grow = false
			animated_sprite_2d.play("idle")
		else:
			eating = false
			playing_grow = false
			can_still_pickup = true
			animated_sprite_2d.play("pickup")
		
		if player_in_area and not GlobalValues.food_already_picked:
			animated_sprite_2d.play("pickup")
			if not GlobalValues.has_pickeup_food_once:
				GlobalValues.has_pickeup_food_once = true
				action_button_press.play("default")
				action_button_press.visible = true
	
	if play_backwards:
		_some_waiting_timer()
		play_backwards = false
