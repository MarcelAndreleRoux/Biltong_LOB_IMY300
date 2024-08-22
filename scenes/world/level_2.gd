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

		# Offset the RayCast2D's position slightly to avoid hitting the player or the enemy itself
		var offset_distance = 5  # Adjust this value as needed
		enemy_raycast.global_position += direction_to_player * offset_distance

		# Set the RayCast2D's target position to the player's position
		enemy_raycast.target_position = (player.global_position - enemy_raycast.global_position)

		if enemy_raycast.is_colliding():
			print("RayCast2D hit something. Stopping firing.")
			SharedSignals.player_lost.emit()  # Stop shooting if something is in the way
		else:
			print("RayCast2D did not hit anything. Start firing.")
			SharedSignals.player_spotted.emit()  # Start shooting if the path is clear

		# Reset RayCast2D position to its original position for the next frame
		enemy_raycast.global_position -= direction_to_player * offset_distance




