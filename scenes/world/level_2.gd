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
		# Calculate the direction from the enemy to the player
		var direction_to_player = (player.global_position - enemy_raycast.global_position).normalized()

		# Offset the RayCast2D's position slightly to avoid hitting the enemy itself
		var offset_distance = 5  # Adjust this value as needed
		enemy_raycast.global_position += direction_to_player * offset_distance

		# Set the RayCast2D's target position to the player's position
		enemy_raycast.target_position = (player.global_position - enemy_raycast.global_position)

		# Check if the raycast is colliding with anything
		if enemy_raycast.is_colliding():
			# If the RayCast2D hits something other than the player, consider the player "lost"
			SharedSignals.player_lost.emit()  # Signal that the player is no longer spotted
		else:
			# If RayCast2D does not hit anything, consider the player spotted
			SharedSignals.player_spotted.emit()  # Signal that the player is spotted

		# Reset RayCast2D position to its original position for the next frame
		enemy_raycast.global_position -= direction_to_player * offset_distance

func _on_game_finish_body_entered(body):
	win_state.death_lose()
