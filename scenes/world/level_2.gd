extends BaseWorld

@onready var win_state = $WinState

func _ready():
	super()

func _physics_process(_delta):
	super(_delta)

func _on_game_finish_body_entered(body):
	if body.is_in_group("player"):
		win_state.game_win()
