extends StaticBody2D

@onready var action_button = $ActionButton
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D

var eating: bool = false
var playing_grow: bool = false
var play_backwards: bool = false
var already_picked: bool = false
var player_in_area: bool = false

func _ready():
	collision_shape_2d.disabled = true
	action_button.visible = false
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
	$grow_timer.queue_free()
	
	var timer = Timer.new()
	timer.name = "regrow_timer"
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(_play_grow_animation)
	add_child(timer)
	timer.start()

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("pickup") and not eating and not already_picked:
		print("was here")
		already_picked = true
		SharedSignals.item_pickup.emit()
		SharedSignals.invertory_update.emit()
		SharedSignals.show_aim.emit()
		action_button.visible = false
		animated_sprite_2d.play("idle")  # Optionally, change the animation or do other actions here.

func _play_grow_animation():
	$regrow_timer.queue_free()
	
	playing_grow = true
	animated_sprite_2d.play("grow")

func _on_action_area_body_entered(body):
	if body.is_in_group("player") and not eating and not already_picked:
		player_in_area = true
		animated_sprite_2d.play("pickup")
		action_button.visible = true
	
	if body.is_in_group("enemy"):
		eating = true
		_play_grow_backwards()

func _on_action_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		if not eating and not already_picked:
			animated_sprite_2d.play("idle")
			action_button.visible = false

func _on_animated_sprite_2d_animation_finished():
	if playing_grow:
		eating = false
		playing_grow = false
	
	if play_backwards:
		_some_waiting_timer()
		play_backwards = false
