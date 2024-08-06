extends Node

# Player Signals
signal item_pickup
signal pickup_item
signal item_throw
signal cooldown_start
signal cooldown_start_other
signal cooldown_end
signal cooldown_end_other
signal calculate_landing_position
signal request_spawn_projectile

# Object Signals
signal shadow_update
signal shadow_done

# Door Signals
signal doorState
signal check_link
signal found_link
signal full_link

# Enemy Signals
signal start_eating
signal new_marker
signal can_move_again
signal marker_spotted

# Inventory Signals
signal invertory_update

# Item Pickup
signal pickedup_item
signal item_removed

# Box
signal player_move
signal player_exit
signal box_hit_wall
