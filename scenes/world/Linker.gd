extends Node2D

@export var identifier: String

func _ready():
	SharedSignals.found_link.connect(_found_link)
	
func _found_link(door_id: String, button_id: String):
	if identifier == door_id and identifier == button_id:
		print("Links match. Emitting full_link signal.")
		SharedSignals.full_link.emit(button_id, door_id)
	else:
		print("Links do not match or are incorrect. No action taken.")
