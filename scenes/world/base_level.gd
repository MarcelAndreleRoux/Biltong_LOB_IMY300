extends BaseWorld

@onready var transition = $Transition

func _ready():
	super()
	transition.connect("body_entered", Callable(self, "_on_area2d_body_entered"))

func _on_area2d_body_entered(body):
	if body.is_in_group("player"):  # Assuming your player is in the "player" group
		change_scene_to_next_level()
