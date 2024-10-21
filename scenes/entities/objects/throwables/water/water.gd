extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var audio_controler = $AudioControler

var landed: bool = false
var played_once: bool = false

func _ready():
	SharedSignals.distroy_throwable.connect(_remove_myself)
	super()
	projectile_landed.connect(_play_death)
	animated_sprite_2d.play("idle")

func _physics_process(delta: float):
	super(delta)
	
	if animated_sprite_2d.frame == 14:
		self.queue_free()

func _play_death():
	AudioController.play_sfx("water_land")
	animated_sprite_2d.play("land")

func _remove_myself():
	AudioController.play_sfx("water_land")
	animated_sprite_2d.play("land")
