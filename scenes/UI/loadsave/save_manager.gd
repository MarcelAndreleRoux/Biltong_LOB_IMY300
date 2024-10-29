# save_manager.gd
extends Node

const SAVE_DIR = "user://saves/"
const SCREENSHOT_DIR = "user://saves/screenshots/"
const SAVE_FILE_EXTENSION = ".save"
const SCREENSHOT_EXTENSION = ".png"
const SETTINGS_FILE = "user://settings.save"
const MAX_SAVES = 3

func _ready():
	# Create necessary directories
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(SCREENSHOT_DIR):
		DirAccess.make_dir_absolute(SCREENSHOT_DIR)
	
	# Load settings on startup
	var settings = load_settings()
	if not settings.is_empty():
		apply_settings(settings)

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

func save_settings() -> bool:
	var settings_data = {
		"resolution": DisplayServer.window_get_size(),
		"window_mode": DisplayServer.window_get_mode(),
		"vsync": DisplayServer.window_get_vsync_mode(),
		"screen_shake": CameraManager.is_screen_shake_enabled(),
		"censorship": GlobalValues.get_censorship_enabled()
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
func take_screenshot(slot: int) -> void:
	await RenderingServer.frame_post_draw # Wait for frame to complete
	var image = get_viewport().get_texture().get_image()
	var screenshot_path = SCREENSHOT_DIR + str(slot) + SCREENSHOT_EXTENSION
	image.save_png(screenshot_path)

# Save game with screenshot
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVES:
		return false
	
	# Take screenshot first
	take_screenshot(slot)
	
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	var current_time = Time.get_datetime_dict_from_system()
	var time_string = "%02d:%02d" % [current_time.hour, current_time.minute]
	
	var save_data = {
		"level": LevelManager.current_level + 1,
		"timestamp": Time.get_unix_time_from_system(),
		"save_time": time_string,
		"screenshot_path": SCREENSHOT_DIR + str(slot) + SCREENSHOT_EXTENSION,
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
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		return true
	return false

# Load the screenshot for a save slot
func load_screenshot_texture(slot: int) -> ImageTexture:
	var screenshot_path = SCREENSHOT_DIR + str(slot) + SCREENSHOT_EXTENSION
	if not FileAccess.file_exists(screenshot_path):
		return null
		
	var image = Image.new()
	if image.load(screenshot_path) == OK:
		return ImageTexture.create_from_image(image)
	return null

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
