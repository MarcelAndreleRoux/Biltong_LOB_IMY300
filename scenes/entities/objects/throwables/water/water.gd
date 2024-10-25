extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D

var landed: bool = false
var played_once: bool = false
var remove: bool = false

func _ready():
	SharedSignals.distroy_throwable.connect(_remove_myself)
	super()
	
	add_to_group("grow")
	if has_node("EffectArea"):
		$EffectArea.add_to_group("grow")
		$EffectArea.collision_layer = 128
		$EffectArea.collision_mask = 1
	
	projectile_landed.connect(_play_death)
	animated_sprite_2d.play("idle")

func _physics_process(delta: float):
	super(delta)
	
	if animated_sprite_2d.frame == 13:
		self.queue_free()

func _play_death():
	AudioController.play_sfx("water_land")
	animated_sprite_2d.play("land")

func _remove_myself():
	AudioController.play_sfx("water_land")
	animated_sprite_2d.play("land")
	remove = true

func _on_animated_sprite_2d_animation_finished():
	if remove:
		_delete_throwable()

func _on_effect_area_area_entered(area):
	if area.is_in_group("hedgehog_area"):
		print("Found hedgehog")
	
	if area.is_in_group("dart"):
		_remove_myself()
	
	if not I_landed:
		return
		
	var parent = area.get_parent()
	if parent is StaticBody2D and "plant_type" in parent:  # Check if it's a vine
		print("Water hit vine, notifying vine to grow")
		parent._on_grow()  # Call new method on vine


func _on_effect_area_body_entered(body):
	print("body found", body)
