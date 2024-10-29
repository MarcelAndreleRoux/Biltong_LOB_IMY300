# load_save.gd
extends Control

@onready var save_backgrounds = [$SaveBackground, $SaveBackground2, $SaveBackground3]
@onready var chamber_labels = [$SaveBackground/ChamberLabel, $SaveBackground2/ChamberLabel, $SaveBackground3/ChamberLabel]
@onready var time_labels = [$SaveBackground/TimeLabel, $SaveBackground2/TimeLabel, $SaveBackground3/TimeLabel]
@onready var save_pictures = [$SaveBackground/SavePicture, $SaveBackground2/SavePicture, $SaveBackground3/SavePicture]
@onready var load_buttons = [$SaveBackground/LoadSaveButton, $SaveBackground2/LoadSaveButton, $SaveBackground3/LoadSaveButton]
@onready var load_texts = [$SaveBackground/LoadSaveButton/LoadSaveText, $SaveBackground2/LoadSaveButton/LoadSaveText, $SaveBackground3/LoadSaveButton/LoadSaveText]
@onready var no_save_backgrounds = [$SaveBackground/NoSaveBackground, $SaveBackground2/NoSaveBackground, $SaveBackground3/NoSaveBackground]
@onready var delete_buttons = [$SaveBackground/DeleteButton, $SaveBackground2/DeleteButton, $SaveBackground3/DeleteButton]
@onready var confirm_delete_text = $ConfirmDelete/TextureRect2/Label
@onready var confirm_delete_no = $ConfirmDelete/TextureRect2/HBoxContainer/Cancel
@onready var confirm_delete_yes = $ConfirmDelete/TextureRect2/HBoxContainer/Confirm
@onready var confirm_delete = $ConfirmDelete

signal back_pressed

var pending_delete_slot: int = -1

func _ready():
	# Add to your existing _ready() code
	confirm_delete.visible = false
	
	# Connect confirmation buttons
	confirm_delete_yes.pressed.connect(_on_confirm_delete_pressed)
	confirm_delete_no.pressed.connect(_on_cancel_delete_pressed)
	
	# Add hover sound effects
	confirm_delete_yes.mouse_entered.connect(_on_button_hover)
	confirm_delete_no.mouse_entered.connect(_on_button_hover)
	
	# Show all save backgrounds by default
	for background in save_backgrounds:
		if background != null:
			background.visible = true
	
	# Show "No Save" banners by default
	for banner in no_save_backgrounds:
		if banner != null:
			banner.visible = true
	
	# Connect signals
	for i in range(load_buttons.size()):
		if load_buttons[i]:
			load_buttons[i].pressed.connect(_on_load_save_pressed.bind(i))
	
	for i in range(delete_buttons.size()):
		if delete_buttons[i]:
			delete_buttons[i].pressed.connect(_on_delete_pressed.bind(i))
			delete_buttons[i].visible = false  # Hide delete buttons initially
	
	update_save_slots()

func _on_cancel_delete_pressed():
	AudioController.play_sfx("button_select")
	confirm_delete.visible = false
	pending_delete_slot = -1

func _on_button_hover():
	AudioController.play_sfx("button_hover")

# Your existing functions remain the same
func _on_back_pressed():
	AudioController.play_sfx("button_select")
	back_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")

func _on_back_mouse_entered():
	AudioController.play_sfx("button_hover")

func update_save_slots():
	for i in range(3):
		if i >= save_backgrounds.size() or save_backgrounds[i] == null:
			continue
		
		var save_data = SaveManager.load_game(i)
		var has_save = not save_data.is_empty()
		
		# Keep background visible but update its content
		if has_save:
			if i < chamber_labels.size() and chamber_labels[i] != null:
				chamber_labels[i].text = "Chamber %d" % save_data.level
				chamber_labels[i].visible = true
			
			if i < time_labels.size() and time_labels[i] != null:
				time_labels[i].text = "Saved: %s" % save_data.save_time
				time_labels[i].visible = true
			
			if i < save_pictures.size() and save_pictures[i] != null:
				var texture = SaveManager.load_screenshot_texture(i)
				if texture:
					save_pictures[i].texture = texture
				save_pictures[i].visible = true
			
			if i < load_buttons.size() and load_buttons[i] != null:
				load_buttons[i].disabled = false
				load_buttons[i].visible = true
			
			if i < no_save_backgrounds.size() and no_save_backgrounds[i] != null:
				no_save_backgrounds[i].visible = false
			
			if i < delete_buttons.size() and delete_buttons[i] != null:
				delete_buttons[i].visible = true
		else:
			# Show "No Save" state
			if i < chamber_labels.size() and chamber_labels[i] != null:
				chamber_labels[i].visible = false
			
			if i < time_labels.size() and time_labels[i] != null:
				time_labels[i].visible = false
			
			if i < save_pictures.size() and save_pictures[i] != null:
				save_pictures[i].visible = false
			
			if i < load_buttons.size() and load_buttons[i] != null:
				load_buttons[i].disabled = true
			
			if i < no_save_backgrounds.size() and no_save_backgrounds[i] != null:
				no_save_backgrounds[i].visible = true
			
			if i < delete_buttons.size() and delete_buttons[i] != null:
				delete_buttons[i].visible = false

func _on_load_save_pressed(slot: int):
	var save_data = SaveManager.load_game(slot)
	
	if not save_data.is_empty():
		# This will now force saving to this slot
		SaveManager.load_specific_save(slot)
		
		# Apply save data
		_apply_save_data(save_data)
		
		# Load the level
		var level_path = GlobalValues.LEVEL_PATHS[LevelManager.current_level]
		get_tree().change_scene_to_file(level_path)

func _apply_save_data(save_data: Dictionary):
	# First set level and position
	LevelManager.current_level = save_data.level

	# Then set gameplay state
	GlobalValues.can_throw = save_data.can_throw
	GlobalValues.can_swap_food = save_data.can_swap_food
	GlobalValues.can_swap_fire = save_data.can_swap_fire
	GlobalValues.can_swap_water = save_data.can_swap_water
	GlobalValues.has_pickeup_box_once = save_data.has_pickeup_box_once
	GlobalValues.has_pickeup_c_box_once = save_data.has_pickeup_c_box_once
	GlobalValues.has_pickeup_fire_once = save_data.has_pickeup_fire_once
	GlobalValues.has_pickeup_food_once = save_data.has_pickeup_food_once
	GlobalValues.has_pickup_water_once = save_data.has_pickup_water_once
	GlobalValues.box_pickup_once = save_data.box_pickup_once
	GlobalValues.food_already_picked = save_data.food_already_picked
	GlobalValues.hazmat_picked_up = save_data.hazmat_picked_up
	
	# Restore inventory state
	if save_data.has("inventory_select"):
		GlobalValues.set_inventory_select(save_data.inventory_select)

func _on_delete_pressed(slot: int):
	# Store the slot number and show confirmation dialog
	pending_delete_slot = slot
	
	# Get the save info for the confirmation message
	var save_data = SaveManager.load_game(slot)
	var chamber_num = save_data.get("level", 0)
	var save_time = save_data.get("save_time", "unknown")
	
	# Update confirmation text
	confirm_delete_text.text = "Are you sure you want to delete\nChamber %d Saved at %s?\nDeleteing a save can not be reverted!" % [chamber_num, save_time]
	
	# Show the confirmation dialog
	confirm_delete.visible = true

func _on_confirm_delete_pressed():
	AudioController.play_sfx("button_select")
	
	var slot = pending_delete_slot
	if slot == -1:
		return
		
	if SaveManager.delete_save(slot):
		# Hide confirmation dialog
		confirm_delete.visible = false
		
		# Show the "No Save" banner for this slot
		if slot < no_save_backgrounds.size() and no_save_backgrounds[slot] != null:
			no_save_backgrounds[slot].visible = true
		
		# Hide the save data
		if slot < save_pictures.size() and save_pictures[slot] != null:
			save_pictures[slot].texture = null
		if slot < chamber_labels.size() and chamber_labels[slot] != null:
			chamber_labels[slot].text = ""
		if slot < time_labels.size() and time_labels[slot] != null:
			time_labels[slot].text = ""
		if slot < load_buttons.size() and load_buttons[slot] != null:
			load_buttons[slot].disabled = true
		if slot < delete_buttons.size() and delete_buttons[slot] != null:
			delete_buttons[slot].visible = false
		
		# Check if this was the last save
		var any_saves_left = false
		for i in range(3):
			if not SaveManager.load_game(i).is_empty():
				any_saves_left = true
				break
		
		if not any_saves_left:
			get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
	
	pending_delete_slot = -1
