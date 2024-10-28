extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var fire_area = $FireArea
@onready var fire_land = $fire_land

var landed: bool = false
var played_once: bool = false
var remove: bool = false

func _ready():
	SharedSignals.distroy_throwable.connect(_remove_myself)
	super()
	
	add_to_group("burn")
	if has_node("EffectArea"):
		$EffectArea.add_to_group("burn")
		$EffectArea.collision_layer = 128
		$EffectArea.collision_mask = 1
	
	projectile_landed.connect(_play_death)
	animated_sprite_2d.play("idle")

func _physics_process(delta: float):
	super(delta)
	
	if I_landed and animated_sprite_2d.frame == 8 and not played_once:
		played_once = true
		# Apply any final effects here if needed
		queue_free()

func _play_death():
	fire_land.play()
	animated_sprite_2d.play("land")
	landed = true

func _remove_myself():
	fire_land.play()
	animated_sprite_2d.play("land")
	remove = true

func _on_animated_sprite_2d_animation_finished():
	if remove:
		_delete_throwable()

func _on_projectile_landed():
	if has_node("EffectArea"):
		$EffectArea.monitoring = true
		$EffectArea.monitorable = true
		# Add the burn group to the effect area
		$EffectArea.add_to_group("burn")
	super._on_projectile_landed()

func _on_effect_area_area_entered(area):
	if not I_landed:
		return
		
	var parent = area.get_parent()
	if parent is StaticBody2D and "plant_type" in parent:
		parent._on_burn()
