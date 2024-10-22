extends Node2D

@onready var aim = $Aim
@onready var throw = $Throw
@onready var animation_player = $AnimationPlayer

var is_aiming_click_hold: bool = false
var done_once: bool = false
var aimed_done_once: bool = false
var played_once: bool = false
var throw_clicked: bool = false

func _ready():
	aim.visible = false
	throw.visible = false

func _process(delta):
	if GlobalValues.can_throw:
		if not done_once:
			if not aimed_done_once:
				aim.visible = true
				aim.play("default")
				
				if Input.is_action_just_pressed("aim"):
					throw.visible = true
					is_aiming_click_hold = true
					
					if not played_once:
						played_once = true
						throw.play("default")
					
					_some_waiting_timer()
				elif Input.is_action_just_released("aim"):
					is_aiming_click_hold = false
			
			if Input.is_action_just_pressed("throw") and is_aiming_click_hold:
				throw_clicked = true
				_some_waiting_timer()

func _some_waiting_timer():
	var grow_timer = Timer.new()
	grow_timer.name = "aim_timer"
	grow_timer.wait_time = 5.0
	grow_timer.one_shot = true
	
	if throw_clicked:
		grow_timer.timeout.connect(_throw_timeout)
	else:
		grow_timer.timeout.connect(_aim_timeout)
	
	add_child(grow_timer)
	grow_timer.start()

func _aim_timeout():
	aim.stop()
	aim.visible = false
	aimed_done_once = true

func _throw_timeout():
	aim.stop()
	aim.visible = false
	throw.visible = false
	done_once = true
