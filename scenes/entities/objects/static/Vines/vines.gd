extends StaticBody2D

@export var plant_type = "big"

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D

var was_burned: bool = false
var was_grown: bool = false

var already_burned: bool = false
var already_grown: bool = false

var default_collision_shape: Vector2 = Vector2.ZERO
var default_collision_size: Vector2 = Vector2.ZERO

func _ready():
	if has_node("Area2D"):
		$Area2D.collision_layer = 1
		$Area2D.collision_mask = 128  # Only look for layer 7 (fire effect area)
	
	if plant_type == "small":
		animated_sprite_2d.play("small_plant_idle")
		collision_shape_2d.disabled = true
		already_grown = false
	else:
		animated_sprite_2d.play("large_plant_idle")
		collision_shape_2d.disabled = false
		already_grown = true
	
	GlobalValues.vinesSize = plant_type

func _on_area_2d_area_entered(area):
	if area.get_parent():
		var parent = area.get_parent()
		if parent.is_in_group("burn") and parent.has_method("get_landed_state") and parent.get_vines_landed_state():
			_on_burn()
		elif parent.is_in_group("grow") and parent.has_method("get_landed_state") and parent.get_vines_landed_state():
			_on_grow()

func _on_grow():
	if not already_grown:
		already_burned = false
		already_grown = true
		AudioController.play_sfx("grow")
		was_grown = true
		
		# Delay enabling the collision shape slightly to ensure the growth animation updates first
		await get_tree().create_timer(0.3).timeout
		_update_collision_shape_size()
		
		if was_burned:
			animated_sprite_2d.play("grow_burn")
		else:
			animated_sprite_2d.play("grow_no_burn")

func _on_burn():
	if not already_burned:
		already_burned = true
		already_grown = false
		AudioController.play_sfx("burn")
		was_burned = true
		
		if was_grown or plant_type == "big":
			animated_sprite_2d.play("burn_large")
		else:
			animated_sprite_2d.play("burn_small")

func _update_collision_shape_size():
	# Example: Adjust the collision shape size based on growth
	if was_grown:
		var new_shape = RectangleShape2D.new()
		new_shape.extents = Vector2(8, 20)
		collision_shape_2d.shape = new_shape
	else:
		var default_shape = RectangleShape2D.new()
		default_shape.extents = Vector2(8, 8)
		collision_shape_2d.shape = default_shape

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite_2d.animation == "burn_large" or animated_sprite_2d.animation == "burn_small":
		collision_shape_2d.disabled = true
	elif animated_sprite_2d.animation == "grow_burn" or animated_sprite_2d.animation == "grow_no_burn":
		collision_shape_2d.disabled = false
