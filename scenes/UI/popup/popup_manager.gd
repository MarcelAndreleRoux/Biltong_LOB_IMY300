# popup_manager.gd
extends Control

const PopupScene = preload("res://scenes/UI/popup/popup_scene.tscn")
const ANIMATION_DURATION = 0.3
const SLIDE_OFFSET = -300  # How far left the popup starts/ends (adjust as needed)

@onready var popup_container = $VBoxContainer

var current_popup = null
var pending_popup_text = null
var is_animating = false

func create_popup(text: String) -> bool:
	if is_animating:
		return false
		
	# If there's already a popup showing, animate it out first
	if current_popup != null:
		pending_popup_text = text
		_animate_out(current_popup)
		return true
	
	# Create and setup new popup
	var popup_instance = PopupScene.instantiate()
	popup_container.add_child(popup_instance)
	
	popup_instance.setup(text)
	popup_instance.popup_closed.connect(_on_popup_closed)
	
	# Set initial position
	popup_instance.position.x = SLIDE_OFFSET
	current_popup = popup_instance
	
	# Animate in
	_animate_in(popup_instance)
	return true

func _animate_in(popup: Control):
	is_animating = true
	
	# Fade and slide in
	popup.modulate.a = 0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:x", 0, ANIMATION_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 1.0, ANIMATION_DURATION)\
		.set_trans(Tween.TRANS_CUBIC)
	
	# Reset animating flag and check for pending popups when done
	tween.chain().tween_callback(func():
		is_animating = false
		_check_pending_popup()
	)

func _animate_out(popup: Control):
	is_animating = true
	
	# Fade and slide out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:x", SLIDE_OFFSET, ANIMATION_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(popup, "modulate:a", 0.0, ANIMATION_DURATION)\
		.set_trans(Tween.TRANS_CUBIC)
	
	# Clean up after animation
	tween.chain().tween_callback(func():
		is_animating = false
		current_popup = null
		_check_pending_popup()
	)

func _check_pending_popup():
	if pending_popup_text != null:
		var text = pending_popup_text
		pending_popup_text = null
		create_popup(text)

func _on_popup_closed(popup_instance):
	if current_popup == popup_instance:
		_animate_out(popup_instance)
