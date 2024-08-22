extends BaseWorld

@onready var win_state = $WinState
@onready var enemy_raycast = $Hedgehog/RayCast2D

func _ready():
	super()
	enemy_raycast.enabled = true

func _physics_process(_delta):
	super(_delta)
	if player:
		GlobalValues.update_player_position(player.global_position)
	_update_enemy_raycast()

func _update_enemy_raycast():
	if player and enemy_raycast:
		# Make the RayCast2D look at the player's current position
		enemy_raycast.target_position = player.global_position - enemy_raycast.global_position
		
		if enemy_raycast.is_colliding():
			var collider = enemy_raycast.get_collider()
			if collider.is_in_group("player"):  # Ensure it only triggers for the player
				SharedSignals.player_spotted.emit()

func _on_game_finish_body_entered(body):
	if body.is_in_group("player"):
		win_state.game_win()
