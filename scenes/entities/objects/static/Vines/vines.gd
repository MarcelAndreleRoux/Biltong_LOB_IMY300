extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var grow = $Grow
@onready var burn = $Burn
@onready var collision_shape_2d = $CollisionShape2D

var was_burned: bool = false
var was_grown: bool = false

func _ready():
	animated_sprite_2d.play("idle")
	collision_shape_2d.disabled = true

func _on_area_2d_area_entered(area):
	if area.is_in_group("burn"):
		burn.play()
		collision_shape_2d.disabled = true
		was_burned = true
		if was_grown:
			animated_sprite_2d.play("burn_large")
		else:
			animated_sprite_2d.play("burn_small")
	
	if area.is_in_group("grow"):
		grow.play()
		was_grown = true
		# Delay enabling the collision shape slightly to ensure the growth animation updates first
		await get_tree().create_timer(0.5).timeout
		_update_collision_shape_size()
		collision_shape_2d.disabled = false
		if was_burned:
			animated_sprite_2d.play("grow_burn")
		else:
			animated_sprite_2d.play("grow_no_burn")

func _update_collision_shape_size():
	# Example: Adjust the collision shape size based on growth
	if was_grown:
		# Assuming the collision shape is a rectangle, increase its size
		var new_shape = RectangleShape2D.new()
		collision_shape_2d.shape = new_shape
	else:
		# Default shape size
		var default_shape = RectangleShape2D.new()
		collision_shape_2d.shape = default_shape
