extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var audio_controler = $AudioControler

var landed: bool = false

func _ready():
	super()
	SharedSignals.water_land.connect(impact_landing)
	animated_sprite_2d.play("idle")

func _physics_process(delta: float):
	super(delta)

func impact_landing():
	landed = true
	audio_controler.land.play()
	animated_sprite_2d.play("land")

func _on_fire_area_area_entered(area):
	if area.is_in_group("burn"):
		pass
		
	if area.is_in_group("grow"):
		pass


func _on_animated_sprite_2d_animation_finished():
	if landed:
		animated_sprite_2d.visible = false
