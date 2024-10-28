extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var activivation_area = $ActivivationArea

var water_dead: bool = false
const DESPAWN_TIME: float = 20.0

func _ready():
	animated_sprite_2d.play("idle")
	_start_despawn_timer()

func _process(delta):
	if water_dead:
		if animated_sprite_2d.frame == 6:
			queue_free()

func _on_activivation_area_body_entered(body):
	if body.is_in_group("lizard"):
		SharedSignals.lizard_in_water_puddle.emit()
	
	if body.is_in_group("throwables"):
		if body.is_in_group("fire") and body.get_vines_landed_state():
			water_dead = true
			animated_sprite_2d.play("death")

func _start_despawn_timer():
	var timer = Timer.new()
	timer.wait_time = DESPAWN_TIME
	timer.one_shot = true
	timer.timeout.connect(_on_despawn_timeout)
	add_child(timer)
	timer.start()

func _on_despawn_timeout():
	water_dead = true
	animated_sprite_2d.play("death")
