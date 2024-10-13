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
signal push_player_forward

# Projectile Signals
signal projectile_gone
signal distroy_throwable

# Object Signals
signal shadow_update
signal shadow_done

# Door Signals
signal doorState
signal check_link
signal found_link
signal full_link

# Lizard
signal sent_input_charge

# Button
signal button_active

# Throw
signal throw_direction

# C_box
signal lizard_connection
signal conductor_connection
signal lizard_connection_made
signal lizard_state_change

# Shake Camera Signals
signal start_player_screen_shake

# Dart
signal dart_hit_wall

# Trutle Enemy Signals
signal shake_turtle
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
signal food_projectile_thrown(marker: Marker2D)
signal projectile_despawned(marker: Marker2D)
signal food_thrown

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

# Water
signal water_land

# Box
signal player_move
signal player_exit
signal player_push
signal player_not_push
signal box_hit_wall
signal move_box
signal drag_box
signal wall_detected
signal is_dragging_box
