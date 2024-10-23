extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var fire_area = $FireArea
@onready var land = $land

var landed: bool = false
var remove: bool = false

func _ready():
	SharedSignals.distroy_throwable.connect(_remove_myself)
	super()
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
