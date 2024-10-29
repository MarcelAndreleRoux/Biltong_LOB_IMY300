# load_save.gd
extends Control

@onready var save_backgrounds = [$SaveBackground, $SaveBackground2, $SaveBackground3]
@onready var chamber_labels = [$SaveBackground/ChamberLabel, $SaveBackground2/ChamberLabel, $SaveBackground3/ChamberLabel]
@onready var time_labels = [$SaveBackground/TimeLabel, $SaveBackground2/TimeLabel, $SaveBackground3/TimeLabel]
@onready var save_pictures = [$SaveBackground/SavePicture, $SaveBackground2/SavePicture, $SaveBackground3/SavePicture]
@onready var load_buttons = [$SaveBackground/LoadSaveButton, $SaveBackground2/LoadSaveButton, $SaveBackground3/LoadSaveButton]
@onready var load_texts = [$SaveBackground/LoadSaveButton/LoadSaveText, $SaveBackground2/LoadSaveButton/LoadSaveText, $SaveBackground3/LoadSaveButton/LoadSaveText]
@onready var no_save_background = $NoSaveBackground
@onready var no_save_label = $NoSaveBackground/NoSaveLabel

# Add delete buttons if you haven't already
@onready var delete_buttons = [$SaveBackground/DeleteButton, $SaveBackground2/DeleteButton, $SaveBackground3/DeleteButton]

signal back_pressed

func _ready():
	update_save_slots()
	# Connect delete button signals
	for i in range(delete_buttons.size()):
		delete_buttons[i].pressed.connect(_on_delete_pressed.bind(i))

func update_save_slots():
	for i in range(3):
		var save_data = SaveManager.load_game(i)
		var has_save = not save_data.empty()
		
		save_backgrounds[i].visible = has_save
		
		if has_save:
			# Update labels
			chamber_labels[i].text = "Chamber %d" % save_data.level
			time_labels[i].text = "Saved: %s" % save_data.save_time
			
			# Load and set screenshot
			var texture = SaveManager.load_screenshot_texture(i)
			if texture:
				save_pictures[i].texture = texture
			
			# Enable load button
			load_buttons[i].disabled = false
			load_texts[i].text = "Load Save"
			delete_buttons[i].visible = true
		else:
			# Show "No Save" state
			chamber_labels[i].text = ""
			time_labels[i].text = ""
			save_pictures[i].texture = null
			load_buttons[i].disabled = true
			load_texts[i].text = "No Save"
			delete_buttons[i].visible = false

func _on_load_save_pressed(slot: int):
	var save_data = SaveManager.load_game(slot)
	if not save_data.empty():
		# Apply save data
		LevelManager.current_level = save_data.level - 1 # Subtract 1 because we added 1 when saving
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
		
		# Load the level
		get_tree().change_scene_to_file(GlobalValues.LEVEL_PATHS[LevelManager.current_level])

func _on_delete_pressed(slot: int):
	if SaveManager.delete_save(slot):
		update_save_slots()

func _on_back_pressed():
	back_pressed.emit()
