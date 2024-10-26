extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var fire_area = $FireArea
@onready var land = $land

var landed: bool = false
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
	
	if animated_sprite_2d.frame == 8:
		self.queue_free()

func _play_death():
	landed = true
	AudioController.play_sfx("fire_land")
	animated_sprite_2d.play("land")

func _remove_myself():
	AudioController.play_sfx("fire_land")
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
	if area.is_in_group("dart"):
		_delete_throwable()
	
	if not I_landed:
		return
		
	var parent = area.get_parent()
	if parent is StaticBody2D and "plant_type" in parent:  # Check if it's a vine
		print("Fire hit vine, notifying vine to burn")
		parent._on_burn()  # Call new method on vine
