extends BaseWorld

func _ready():
	super()

func _on_yan_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.player_name_popup.emit("yan")

func _on_dave_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.player_name_popup.emit("dave")

func _on_diffie_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.player_name_popup.emit("diffie")

func _on_level_10_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.lizard_telling.emit()

func _on_new_lizard_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.lizard_new.emit()

func _on_breeding_room_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.breeding_room.emit()

func _on_lots_dead_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.lots_dead.emit()

func _on_whathappend_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.what_happend.emit()

func _on_final_dialog_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.final_dialog.emit()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		SharedSignals.metal_box_move.emit()
