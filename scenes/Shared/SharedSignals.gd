extends Node

# Player Signals
signal item_pickup
signal pickup_item
signal item_throw
signal can_throw_projectile
signal cooldown_start
signal cooldown_start_other
signal cooldown_end
signal cooldown_end_other
signal calculate_landing_position
signal request_spawn_projectile
signal player_killed
signal death_finished

# Projectile Signals
signal projectile_gone

# Object Signals
signal shadow_update
signal shadow_done

# Door Signals
signal doorState
signal check_link
signal found_link
signal full_link

# Button
signal button_active

# Trutle Enemy Signals
signal start_eating
signal new_marker
signal can_move_again
signal marker_spotted
signal turtle_spotted_food
signal food_visibility_changed
signal food_not_visible
signal food_was_eaten
signal marker_removed
signal turtle_is_scared

#Lizard Signals
signal lizard_marker_reached
signal lizard_can_move_again

# Hedgehog Enemy Signals
signal player_spotted
signal player_lost

# Inventory Signals
signal invertory_update
signal inventory_changed
signal inventory_freez

# Mouse UI signals
signal show_aim
signal show_throw

# Item Pickup
signal pickedup_item
signal item_removed

# Food
signal eaten_ground_food

# Fire Mango
signal fire_mango_land

# Box
signal player_move
signal player_exit
signal player_push
signal player_not_push
signal box_hit_wall
signal move_box
signal drag_box
signal wall_detected
