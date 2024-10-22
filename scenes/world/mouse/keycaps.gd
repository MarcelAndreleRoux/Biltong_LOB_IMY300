extends Node2D

@onready var w = $W
@onready var s = $S
@onready var a = $A
@onready var d = $D
@onready var done = $Done
@onready var check_mark = $CheckMark

var w_clicked: bool = false
var s_clicked: bool = false
var a_clicked: bool = false
var d_clicked: bool = false
var played_once: bool = false

func _ready():
	w.visible = true
	s.visible = true
	a.visible = true
	d.visible = true
	check_mark.visible = false
	
	w.play("default")
	s.play("default")
	a.play("default")
	d.play("default")

func _process(delta):
	if not played_once:
		if Input.is_action_just_pressed("move_up"):
			w_clicked = true
			w.visible = false
		
		if Input.is_action_just_pressed("move_down"):
			s_clicked = true
			s.visible = false
		
		if Input.is_action_just_pressed("move_left"):
			a_clicked = true
			a.visible = false
		
		if Input.is_action_just_pressed("move_right"):
			d_clicked = true
			d.visible = false
		
		if w_clicked and s_clicked and a_clicked and d_clicked:
			done.play("check")
			check_mark.visible = true
			_display_keycaps_start()

func _display_keycaps_start():
	played_once = true
	var timer = Timer.new()
	timer.name = "display_keycaps_timer"
	timer.wait_time = 1
	timer.one_shot = true
	timer.timeout.connect(_end_timer)
	add_child(timer)
	timer.start()

func _end_timer():
	check_mark.visible = false
	w.visible = false
	s.visible = false
	a.visible = false
	d.visible = false
