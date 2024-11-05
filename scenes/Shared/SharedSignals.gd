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
signal detact_hazmat_now

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
signal lizard_in_water_puddle
signal lizard_in_camp_fire

# Button
signal button_active

# Throw
signal throw_direction

# Hedgehog
signal shake_hedgehog

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
signal food_projectile_thrown
signal projectile_despawned
signal food_thrown
signal is_scared_signal

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
signal play_pickup_notification

# Fire Mango
signal fire_mango_land

signal connected_to_mboard

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

signal player_name_popup
signal metal_box_move
signal metal_box_conduct

signal box_entered_area
signal box_exited_area
signal drop_current_box

# popups
signal move_mouse_around
signal trowable
signal fire_trowable
signal water_trowable
signal turtle_scared_popup

signal lizard_telling
signal lizard_new
signal breeding_room
signal lots_dead
signal what_happend
signal final_dialog

signal IfeelFree
signal dont_show_inventory
