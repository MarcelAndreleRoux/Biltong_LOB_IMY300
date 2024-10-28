extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var water_land = $water_land

var water_puddle_instance = null
var landed: bool = false
var played_once: bool = false
var remove: bool = false

func _ready():
	SharedSignals.distroy_throwable.connect(_remove_myself)
	super()
	
	water_puddle_instance = preload("res://scenes/entities/objects/static/waterpod/water_puddle.tscn")
	
	add_to_group("grow")
	if has_node("EffectArea"):
		$EffectArea.add_to_group("grow")
		$EffectArea.collision_layer = 128
		$EffectArea.collision_mask = 1
	
	projectile_landed.connect(_play_death)
	animated_sprite_2d.play("idle")

func _on_projectile_landed():
	if has_node("EffectArea"):
		$EffectArea.monitoring = true
		$EffectArea.monitorable = true
		# Add the burn group to the effect area
		$EffectArea.add_to_group("grow")
	super._on_projectile_landed()

func _physics_process(delta: float):
	super(delta)
	
	if I_landed and animated_sprite_2d.frame == 8 and not played_once:
		played_once = true
		var puddle = water_puddle_instance.instantiate()
		puddle.global_position = global_position
		get_parent().add_child(puddle)
		queue_free()

func _play_death():
	water_land.play()
	animated_sprite_2d.play("land")

func _remove_myself():
	water_land.play()
	animated_sprite_2d.play("land")
	remove = true

func _on_effect_area_area_entered(area):
	if not I_landed:
		return
		
	var parent = area.get_parent()
	if parent is StaticBody2D and "plant_type" in parent:
		parent._on_grow()
