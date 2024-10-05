extends Area2D

func _process(delta):
	check_for_bodies()

func check_for_bodies():
	var overlapping_bodies = get_overlapping_bodies()
	
	var player_present = false
	var door_present = false
	
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			player_present = true
		
		if body.is_in_group("door"):
			door_present = true
	
	if player_present and door_present:
		SharedSignals.push_player_forward.emit()
