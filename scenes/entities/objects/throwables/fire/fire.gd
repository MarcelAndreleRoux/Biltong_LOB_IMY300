extends BaseThrowable

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var fire_area = $FireArea

func _ready():
	super()
	SharedSignals.fire_mango_land.connect(impact_landing)
	animated_sprite_2d.play("idle")

func _physics_process(delta: float):
	super(delta)

func impact_landing():
	animated_sprite_2d.play("land")

func _on_fire_area_area_entered(area):
	if area.is_in_group("burn"):
		pass
		
	if area.is_in_group("grow"):
		pass
