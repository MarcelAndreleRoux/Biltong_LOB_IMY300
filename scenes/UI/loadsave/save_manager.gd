# save_manager.gd
extends Node

const SAVE_DIR = "user://saves/"
const SCREENSHOT_DIR = "user://saves/screenshots/"
const SAVE_FILE_EXTENSION = ".save"
const SCREENSHOT_EXTENSION = ".png"
const SETTINGS_FILE = "user://settings.save"
const MAX_SAVES = 3

var current_active_save_slot: int = -1
var is_continuing_game: bool = false
var last_loaded_slot: int = -1

var is_transitioning: bool = false
var previous_save_data: Dictionary = {}

var force_slot: int = -1 

func _ready():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(SCREENSHOT_DIR):
		DirAccess.make_dir_absolute(SCREENSHOT_DIR)
	
	get_tree().auto_accept_quit = false
	get_tree().root.connect("close_requested", _handle_exit_save)
	
	var settings = load_settings()
	if not settings.is_empty():
		apply_settings(settings)

func should_autosave() -> bool:
	return LevelManager.current_level == 0

func initialize_new_game() -> int:
	# This should only be called when starting a brand new game
	is_continuing_game = false
	current_active_save_slot = find_empty_slot()
	if current_active_save_slot == -1:
		current_active_save_slot = get_oldest_save_slot()
	
	return current_active_save_slot

func initialize_new_save() -> int:
	# Find first empty slot or override oldest if full
	var slot = find_empty_slot()
	if slot == -1:
		slot = get_oldest_save_slot()
	
	current_active_save_slot = slot
	return slot

func continue_game() -> int:
	# Clear any forced slot
	force_slot = -1
	
	# Get the most recent save
	var source_slot = get_most_recent_save()
	if source_slot == -1:
		return -1
		
	# Get source save data
	var source_save = load_game(source_slot)
	if source_save.is_empty():
		return -1
	
	# Find the oldest save slot to override or an empty slot
	var target_slot = find_empty_slot()
	if target_slot == -1:
		target_slot = get_oldest_save_slot()
	
	# Set this as the new active slot and force saving to it
	current_active_save_slot = target_slot
	force_slot = target_slot
	
	# Copy the save data
	var file = FileAccess.open(SAVE_DIR + str(target_slot) + SAVE_FILE_EXTENSION, FileAccess.WRITE)
	if file:
		file.store_var(source_save)
	
	# Copy the screenshot if it exists
	var source_screenshot = SCREENSHOT_DIR + str(source_slot) + SCREENSHOT_EXTENSION
	var target_screenshot = SCREENSHOT_DIR + str(target_slot) + SCREENSHOT_EXTENSION
	if FileAccess.file_exists(source_screenshot):
		var dir = DirAccess.open(SCREENSHOT_DIR)
		if dir:
			dir.copy(source_screenshot, target_screenshot)
	
	print("Continued game: copied save from slot ", source_slot, " to new slot ", target_slot)
	return target_slot

func load_specific_save(slot: int) -> bool:
	var save_data = load_game(slot)
	if save_data.is_empty():
		return false
	
	# Force all future saves to use this slot until cleared
	force_slot = slot
	current_active_save_slot = slot
	last_loaded_slot = slot
	print("Loaded and forcing saves to slot: ", slot)
	return true

func update_current_save() -> bool:
	if current_active_save_slot == -1 and force_slot == -1:
		return false
		
	var slot_to_use = force_slot if force_slot != -1 else current_active_save_slot
	return await save_game(slot_to_use)

func set_active_save_slot(slot: int) -> void:
	current_active_save_slot = slot
	print("Set active save slot to: ", slot)

func clear_active_save_slot() -> void:
	current_active_save_slot = -1
	print("Cleared active save slot")

func get_oldest_save_slot() -> int:
	var oldest_slot = 0
	var oldest_time = float("inf")
	
	for slot in range(MAX_SAVES):
		var save_data = load_game(slot)
		if not save_data.is_empty() and save_data.has("timestamp"):
			if save_data.timestamp < oldest_time:
				oldest_time = save_data.timestamp
				oldest_slot = slot
	
	return oldest_slot

func _handle_exit_save():
	# Save game state on exit
	var slot = find_empty_slot()
	if slot == -1:  # If no empty slot, use the oldest save
		slot = 0  # You might want to implement a way to find the oldest save
	save_game(slot)
	get_tree().quit()

func get_next_empty_or_oldest_slot() -> int:
	# First try to find an empty slot
	var empty_slot = find_empty_slot()
	if empty_slot != -1:
		return empty_slot
		
	# If no empty slots, find the oldest one
	return get_oldest_save_slot()

func load_game(slot: int) -> Dictionary:
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	if not FileAccess.file_exists(save_path):
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		print("Loaded save data: ", save_data)
		return save_data
	return {}

func get_most_recent_save() -> int:
	var most_recent_slot = -1
	var most_recent_time = 0
	
	for slot in range(MAX_SAVES):
		var save_data = load_game(slot)
		if not save_data.is_empty() and save_data.has("timestamp"):
			if save_data.timestamp > most_recent_time:
				most_recent_time = save_data.timestamp
				most_recent_slot = slot
	
	return most_recent_slot

# Find first empty save slot
func find_empty_slot() -> int:
	for slot in range(MAX_SAVES):
		var save_data = load_game(slot)
		if save_data.is_empty():
			return slot
	return -1

func apply_settings(settings: Dictionary) -> void:
	if settings.has("resolution"):
		DisplayServer.window_set_size(settings.resolution)
	
	if settings.has("window_mode"):
		DisplayServer.window_set_mode(settings.window_mode)
	
	if settings.has("vsync"):
		DisplayServer.window_set_vsync_mode(settings.vsync)
	
	if settings.has("screen_shake"):
		CameraManager.toggle_screen_shake(settings.screen_shake)
	
	if settings.has("censorship"):
		GlobalValues.set_censorship_enabled(settings.censorship)
	
	if settings.has("master_volume"):
		AudioController.set_master_volume(settings.master_volume)
	
	if settings.has("music_volume"):
		AudioController.set_music_volume(settings.music_volume)
	
	if settings.has("sfx_volume"):
		AudioController.set_sfx_volume(settings.sfx_volume)

func save_settings() -> bool:
	var settings_data = {
		"resolution": DisplayServer.window_get_size(),
		"window_mode": DisplayServer.window_get_mode(),
		"vsync": DisplayServer.window_get_vsync_mode(),
		"screen_shake": CameraManager.is_screen_shake_enabled(),
		"censorship": GlobalValues.get_censorship_enabled(),
		# Add volume settings
		"master_volume": AudioController.get_master_volume(),
		"music_volume": AudioController.get_music_volume(),
		"sfx_volume": AudioController.get_sfx_volume()
	}
	
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_var(settings_data)
		print("Settings saved successfully")  # Debug print
		return true
	print("Failed to save settings")  # Debug print
	return false

func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_FILE):
		print("No settings file found")  # Debug print
		return {}
	
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file:
		var settings = file.get_var()
		print("Settings loaded successfully: ", settings)  # Debug print
		return settings
	print("Failed to load settings")  # Debug print
	return {}

# Take a screenshot of the current game state
func take_screenshot(slot: int) -> bool:
	# Wait for frames to ensure UI is hidden and scene is fully rendered
	await get_tree().process_frame
	await get_tree().process_frame
	
	var viewport = get_tree().get_root().get_viewport()
	if not viewport:
		print("Failed to get viewport for screenshot")
		return false
	
	var image = viewport.get_texture().get_image()
	var screenshot_path = SCREENSHOT_DIR + str(slot) + SCREENSHOT_EXTENSION
	
	# Ensure the screenshot directory exists
	if not DirAccess.dir_exists_absolute(SCREENSHOT_DIR):
		DirAccess.make_dir_absolute(SCREENSHOT_DIR)
	
	# Calculate aspect-ratio preserving dimensions
	var target_width = 320
	var target_height = 180
	var original_aspect = float(image.get_width()) / float(image.get_height())
	var target_aspect = float(target_width) / float(target_height)
	
	var new_width
	var new_height
	
	if original_aspect > target_aspect:
		# Image is wider than target
		new_width = target_width
		new_height = int(target_width / original_aspect)
	else:
		# Image is taller than target
		new_height = target_height
		new_width = int(target_height * original_aspect)
	
	# Resize while maintaining aspect ratio
	image.resize(new_width, new_height, Image.INTERPOLATE_LANCZOS)
	
	var error = image.save_png(screenshot_path)
	if error != OK:
		print("Failed to save screenshot: ", error)
		return false
	
	return true

# Save game with screenshot
func save_game(slot: int) -> bool:
	# If we have a forced slot, use it instead
	if force_slot != -1:
		slot = force_slot
		print("Using forced save slot: ", slot)
	
	if slot < 0 or slot >= MAX_SAVES:
		return false
	
	# Store previous save data for comparison
	previous_save_data = load_game(slot)
	
	# Take screenshot first
	await take_screenshot(slot)
	
	# Ensure we have the latest player position
	var current_player_position = GlobalValues.player_position
	print("Saving player position: ", current_player_position)
	
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	var current_time = Time.get_datetime_dict_from_system()
	var time_string = "%02d:%02d:%02d" % [current_time.hour, current_time.minute, current_time.second]
	
	var save_data = {
		"level": LevelManager.current_level,
		"timestamp": Time.get_unix_time_from_system(),
		"save_time": time_string,
		"screenshot_path": SCREENSHOT_DIR + str(slot) + SCREENSHOT_EXTENSION,
		"player_position": current_player_position,
		"spawn_position": current_player_position,
		# Global values
		"can_throw": GlobalValues.can_throw,
		"can_swap_food": GlobalValues.can_swap_food,
		"can_swap_fire": GlobalValues.can_swap_fire,
		"can_swap_water": GlobalValues.can_swap_water,
		"has_pickeup_box_once": GlobalValues.has_pickeup_box_once,
		"has_pickeup_c_box_once": GlobalValues.has_pickeup_c_box_once,
		"has_pickeup_fire_once": GlobalValues.has_pickeup_fire_once,
		"has_pickeup_food_once": GlobalValues.has_pickeup_food_once,
		"has_pickup_water_once": GlobalValues.has_pickup_water_once,
		"box_pickup_once": GlobalValues.box_pickup_once,
		"food_already_picked": GlobalValues.food_already_picked,
		"hazmat_picked_up": GlobalValues.hazmat_picked_up
	}
	
	print("Saving game data to slot ", slot, ": ", save_data)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		print("Save successful to slot: ", slot)
		return true
	print("Save failed")
	return false

func begin_scene_transition():
	is_transitioning = true
	# Store the current save slot data before transition
	if current_active_save_slot != -1:
		previous_save_data = load_game(current_active_save_slot)

func end_scene_transition():
	is_transitioning = false



func delete_all_saves() -> void:
	for slot in range(MAX_SAVES):
		delete_save(slot)

func has_any_saves() -> bool:
	for slot in range(MAX_SAVES):
		var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
		if FileAccess.file_exists(save_path):
			return true
	return false

func get_next_sequential_slot(current_slot: int) -> int:
	# Try to get next slot in sequence
	var next_slot = current_slot + 1
	if next_slot >= MAX_SAVES:
		# If we've reached max saves, find oldest
		return get_oldest_save_slot()
	elif not has_save(next_slot):
		# If next slot is empty, use it
		return next_slot
	else:
		# If next slot is taken but we're not at max, recursively try next
		return get_next_sequential_slot(next_slot)

# Check if a specific slot has a save
func has_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVES:
		return false
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	return FileAccess.file_exists(save_path)

# Load the screenshot for a save slot
func load_screenshot_texture(slot: int) -> ImageTexture:
	var screenshot_path = SCREENSHOT_DIR + str(slot) + SCREENSHOT_EXTENSION
	if not FileAccess.file_exists(screenshot_path):
		print("No screenshot found at: ", screenshot_path)
		return null
		
	var image = Image.new()
	var error = image.load(screenshot_path)
	if error == OK:
		# Create ImageTexture with the correct format
		var texture = ImageTexture.create_from_image(image)
		return texture
	else:
		print("Failed to load screenshot image with error: ", error)
		return null

func create_new_save_from_most_recent() -> bool:
	var most_recent_slot = get_most_recent_save()
	if most_recent_slot == -1:
		return false
		
	# Get source save data
	var source_save = load_game(most_recent_slot)
	if source_save.is_empty():
		return false
	
	# Get next slot in sequence
	var next_slot = get_next_sequential_slot(most_recent_slot)
	
	# Set this as current active slot
	current_active_save_slot = next_slot
	
	# Save the data to new slot
	return await save_game(next_slot)

# Delete save and its screenshot
func delete_save(slot: int) -> bool:
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	var screenshot_path = SCREENSHOT_DIR + str(slot) + SCREENSHOT_EXTENSION
	var success = true
	
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir.remove(str(slot) + SAVE_FILE_EXTENSION) != OK:
			success = false
			
	if FileAccess.file_exists(screenshot_path):
		var dir = DirAccess.open(SCREENSHOT_DIR)
		if dir.remove(str(slot) + SCREENSHOT_EXTENSION) != OK:
			success = false
			
	return success
