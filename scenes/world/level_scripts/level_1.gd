extends BaseWorld

@onready var keycaps = $Keycaps

func _ready():
	super()
	print("Entered world. Current scene:", GlobalValues.current_scene)
	_display_keycaps_start()

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
