extends Node2D

@onready var throw = $Throw
@onready var aim = $Aim

var shown_aim_once: bool = false
var shown_throw_once: bool = false

func _ready():
	aim.visible = false
	throw.visible = false
	SharedSignals.show_aim.connect(_show_aim)
	SharedSignals.show_throw.connect(_show_throw)

func _show_aim():
	if not shown_aim_once:
		aim.visible = true
		shown_aim_once = true
		_some_waiting_timer()

func _some_waiting_timer():
	var grow_timer = Timer.new()
	grow_timer.name = "aim_timer"
	grow_timer.wait_time = 7.0
	grow_timer.one_shot = true
	grow_timer.timeout.connect(_aim_timeout)
	add_child(grow_timer)
	grow_timer.start()

func _aim_timeout():
	$aim_timer.queue_free()
	
	aim.visible = false

func _some_waiting_timer_throw():
	var grow_timer = Timer.new()
	grow_timer.name = "throw_timer"
	grow_timer.wait_time = 7.0
	grow_timer.one_shot = true
	grow_timer.timeout.connect(_throw_timer_timeout)
	add_child(grow_timer)
	grow_timer.start()

func _throw_timer_timeout():
	$throw_timer.queue_free()
	
	throw.visible = false

func _show_throw():
	if not shown_throw_once:
		throw.visible = true
		shown_throw_once = true
		_some_waiting_timer_throw()


