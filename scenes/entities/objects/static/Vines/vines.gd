extends StaticBody2D

@export var plant_type = "large"

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var grow = $Grow
@onready var burn = $Burn
@onready var collision_shape_2d = $CollisionShape2D

var was_burned: bool = false
var was_grown: bool = false

func _ready():
	if plant_type == "small":
		animated_sprite_2d.play("small_plant_idle")
		collision_shape_2d.disabled = true
	else:
		animated_sprite_2d.play("large_plant_idle")
		collision_shape_2d.disabled = false

func _on_area_2d_area_entered(area):
	if area.is_in_group("burn"):
		burn.play()
		was_burned = true
		
		if was_grown or plant_type == "large":
			animated_sprite_2d.play("burn_large")
		else:
			animated_sprite_2d.play("burn_small")
	
	if area.is_in_group("grow"):
		grow.play()
		was_grown = true
		# Delay enabling the collision shape slightly to ensure the growth animation updates first
		await get_tree().create_timer(0.5).timeout
		_update_collision_shape_size()

		if was_burned:
			animated_sprite_2d.play("grow_burn")
		else:
			animated_sprite_2d.play("grow_no_burn")

func _update_collision_shape_size():
	# Example: Adjust the collision shape size based on growth
	if was_grown:
		var new_shape = RectangleShape2D.new()
		new_shape.extents = Vector2(20, 20)  # Adjust size as needed
		collision_shape_2d.shape = new_shape
	else:
		var default_shape = RectangleShape2D.new()
		default_shape.extents = Vector2(10, 10)  # Default size
		collision_shape_2d.shape = default_shape

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite_2d.animation == "burn_large" or animated_sprite_2d.animation == "burn_small":
		collision_shape_2d.disabled = true
	elif animated_sprite_2d.animation == "grow_burn" or animated_sprite_2d.animation == "grow_no_burn":
		collision_shape_2d.disabled = false
