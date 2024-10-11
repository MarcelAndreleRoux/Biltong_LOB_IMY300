extends BaseThrowable

@onready var mushroom_sprite = $MushroomSprite

var landed: bool = false
var remove: bool = false
var remove_food: bool = false

func _ready():
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
	remove_food = true
	mushroom_sprite.play("land")

func _on_mushroom_sprite_animation_finished():
	if remove_food:
		_delete_throwable()
