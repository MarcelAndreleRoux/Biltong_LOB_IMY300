extends BaseWorld

@onready var keycaps = $Keycaps
@onready var transition = $Transition

func _ready():
	super()
	_display_keycaps_start()
	transition.connect("body_entered", Callable(self, "_on_area2d_body_entered"))

func _on_area2d_body_entered(body):
	if body.is_in_group("player"):  # Assuming your player is in the "player" group
		change_scene_to_next_level()

func _physics_process(_delta):
	super(_delta)

func _display_keycaps_start():
	keycaps.visible = true
	var timer = Timer.new()
	timer.name = "display_keycaps_timer"
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(_end_timer)
	add_child(timer)
	timer.start()

func _end_timer():
	$display_keycaps_timer.queue_free()
	keycaps.visible = false
