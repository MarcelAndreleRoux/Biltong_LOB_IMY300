extends BaseThrowable

@onready var mushroom_sprite = $MushroomSprite

var landed: bool = false  # Keeps track of whether the mushroom has landed
var remove: bool = false

func _ready():
	SharedSignals.distroy_throwable.connect(_remove_myself)
	mushroom_sprite.play("eat")
	projectile_landed.connect(_play_death)
	super()

func _physics_process(delta: float):
	super(delta)
	
	if remove and not landed:
		if mushroom_sprite.frame == 5:
			self.queue_free()

func _play_death():
	if not landed:
		AudioController.play_sfx("food_land")
		mushroom_sprite.play("land")
		landed = true

func _remove_myself():
	mushroom_sprite.play("land")
	remove = true
