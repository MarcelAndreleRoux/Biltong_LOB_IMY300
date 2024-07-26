extends Node2D

func _ready():
	SharedSignals.found_link.connect(_found_link)
	
func _found_link(door_link: Node2D, button_link: Node2D):
	if door_link == button_link and door_link.name == "Linker" and button_link.name == "Linker":
		SharedSignals.full_link.emit(door_link)
	elif door_link == button_link and door_link.name == "Linker2" and button_link.name == "Linker2":
		SharedSignals.full_link2.emit(door_link)
