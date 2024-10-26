class_name OptionsMenu
extends Control

@onready var button_select_options = $ButtonSelectOptions

@onready var display_options = $DisplaySettings/VBoxContainer
@onready var resolution_option = $DisplaySettings/VBoxContainer/HBoxContainer/ResolutionOption
@onready var window_mode = $DisplaySettings/VBoxContainer/HBoxContainer2/WindowMode
@onready var vsync_toggle = $DisplaySettings/VBoxContainer/HBoxContainer3/VsyncToggle
@onready var fps_label = $DisplaySettings/VBoxContainer/HBoxContainer4/FPSLabel
@onready var screen_shake_toggle = $Other/HBoxContainer3/ShakeCheckBox

@onready var description = $Descrpition/Description

# Common 16:9 resolutions
const RESOLUTIONS = [
	Vector2i(480, 270),    # Game Res
	Vector2i(1280, 720),   # 720p
	Vector2i(1920, 1080),  # 1080p
	Vector2i(2560, 1440),  # 1440p
	Vector2i(3840, 2160)   # 4K
]

# Window modes
const WINDOW_MODES = {
	"Fullscreen": DisplayServer.WINDOW_MODE_FULLSCREEN,
	"Windowed": DisplayServer.WINDOW_MODE_WINDOWED
}

signal exit_options_menu

const DESCRIPTIONS = {
	# Existing descriptions
	"master_volume": "Controls the overall volume of the game, affecting both music and sound effects.",
	"music_volume": "Adjusts the volume of background music without affecting sound effects.",
	"sfx_volume": "Controls the volume of sound effects like button clicks and gameplay sounds.",
	"resolution": "Changes the display resolution of the game. Higher resolutions offer better image quality but may affect performance.",
	"window_mode": "Toggle between Windowed and Fullscreen modes:\nWindowed: Run game in a window\nFullscreen: Use entire screen",
	"vsync": "Vertical Sync synchronizes the game's frame rate with your monitor's refresh rate to prevent screen tearing.\nEnable this for the best gaming experience.",
	"fps_counter": "Displays the current Frames Per Second (FPS) the game is running at.",
	
	# New section descriptions
	"audio_settings": "Configure all sound-related options including master volume, music, and sound effects.",
	"display_settings": "Adjust visual settings such as resolution, window mode, and display sync options.",
	"gameplay_settings": "Customize gameplay-related options and preferences.",
	
	# Labels for resolution and window sections
	"res_label": "Screen Resolution - Determines how sharp and detailed the game appears on your display.",
	"window_label": "Window Mode - Choose how the game window is displayed on your screen.",
	"v_label": "VSync Setting - Helps prevent screen tearing during gameplay.",
	
	# Additional settings categories
	"volume_settings": "Adjust different volume levels to balance game audio to your preference.",
	"display_options": "Configure how the game is displayed on your screen.",
	"other_settings": "Additional game options and preferences.",
	"screen_shake": "Toggle screen shake effects. When disabled, the camera will still smoothly follow the action but without shake effects.",
	"censor": "Toggle content filtering for a more family-friendly experience.",
	"back": "Return to the previous menu.",
	"options_label": "Adjust various game settings to customize your experience.",
}

func _process(_delta):
	# Update FPS counter
	if fps_label:
		fps_label.text = str(Engine.get_frames_per_second())

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_display_options()
	load_current_settings()
	setup_label_mouse_properties()
	
	if has_node("/root/AudioController"):
		get_node("/root/AudioController").process_mode = Node.PROCESS_MODE_ALWAYS

func setup_label_mouse_properties():
	# Get all nodes in the "has_description" group
	for node in get_tree().get_nodes_in_group("has_description"):
		if node is Label:
			# Enable mouse properties for the label
			node.mouse_filter = Control.MOUSE_FILTER_STOP
			node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			# Ensure it can receive input
			node.gui_input.connect(_on_label_input.bind(node))

# Add this new function to handle input
func _on_label_input(event: InputEvent, label: Label):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Label clicked: ", label.name)

func add_to_description_group(nodes: Array):
	for node in nodes:
		if node:
			if not node.is_in_group("has_description"):
				node.add_to_group("has_description")

func clear_description():
	if description:
		description.text = ""

func _on_hover(description_key: String):
	if description and DESCRIPTIONS.has(description_key):
		description.text = DESCRIPTIONS[description_key]

func setup_display_options():
	# Setup resolution options
	if resolution_option:
		resolution_option.clear()
		for resolution in RESOLUTIONS:
			# Fixed string formatting
			resolution_option.add_item(str(resolution.x) + "x" + str(resolution.y))
	
	# Setup window mode options
	if window_mode:
		window_mode.clear()
		for mode in WINDOW_MODES.keys():
			window_mode.add_item(mode)

func load_current_settings():
	# Set current resolution option
	var current_window_size = DisplayServer.window_get_size()
	var current_res_index = 0
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i] == current_window_size:
			current_res_index = i
			break
	if resolution_option:
		resolution_option.selected = current_res_index
	
	# Set current window mode
	var current_window_mode = DisplayServer.window_get_mode()
	var mode_index = 0
	for i in WINDOW_MODES.keys().size():
		if WINDOW_MODES.values()[i] == current_window_mode:
			mode_index = i
			break
	if window_mode:
		window_mode.selected = mode_index
	
	# Set current VSync state
	if vsync_toggle:
		vsync_toggle.button_pressed = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
	
	if screen_shake_toggle:
		screen_shake_toggle.button_pressed = CameraManager.is_screen_shake_enabled()

func _on_resolution_option_item_selected(index):
	var new_resolution = RESOLUTIONS[index]
	
	# Get the current screen size
	var screen_size = DisplayServer.screen_get_size()
	
	# Calculate the maximum scale factor that will fit on the screen
	var scale_factor = min(
		floor(screen_size.x / RESOLUTIONS[0].x),
		floor(screen_size.y / RESOLUTIONS[0].y)
	)
	
	# Set the window size to the selected resolution
	DisplayServer.window_set_size(new_resolution)
	
	# Center the window
	var centered_position = (screen_size - new_resolution) / 2
	DisplayServer.window_set_position(centered_position)

func _on_window_mode_item_selected(index):
	var mode = WINDOW_MODES.values()[index]
	DisplayServer.window_set_mode(mode)

func _on_vsync_toggle_toggled(button_pressed):
	if button_pressed:
		# Enable VSync
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		# Optional: Set max FPS to monitor refresh rate
		Engine.max_fps = DisplayServer.screen_get_refresh_rate()
	else:
		# Disable VSync
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Optional: Set a high max FPS when VSync is off
		Engine.max_fps = 0  # 0 means unlimited

func _on_back_pressed():
	button_select_options.play()

func _on_volume_slider_3_value_changed(value):
	AudioController.play_sfx("TICKSOUND_MASTER")

func _on_volume_slider_value_changed(value):
	AudioController.play_sfx("TICKSOUND_MUSIC")

func _on_volume_slider_2_value_changed(value):
	AudioController.play_sfx("TICKSOUND_SFX")

func _on_button_select_options_finished():
	exit_options_menu.emit()


# --------------------------------- LABEL MOUSE ENTERED ---------------------------------------

# Audio Settings
func _on_audio_label_mouse_entered():
	print("hovered over audio label")
	_on_hover("audio_settings")

func _on_master_volume_mouse_entered():
	_on_hover("master_volume")

func _on_music_volume_mouse_entered():
	_on_hover("music_volume")

func _on_sfx_volume_mouse_entered():
	_on_hover("sfx_volume")

# Display Settings
func _on_display_label_mouse_entered():
	_on_hover("display_settings")

func _on_res_label_mouse_entered():
	_on_hover("resolution")

func _on_window_label_mouse_entered():
	_on_hover("window_mode")
	
func _on_v_label_mouse_entered():
	_on_hover("vsync")

func _on_fps_label_mouse_entered():
	_on_hover("fps_counter")

# Other Settings
func _on_gameplay_label_mouse_entered():
	_on_hover("gameplay_settings")

func _on_censorship_label_mouse_entered():
	_on_hover("censor")

# General UI
func _on_options_label_mouse_entered():
	_on_hover("options_label")

func _on_shake_label_mouse_entered():
	_on_hover("screen_shake")

func _on_back_mouse_entered():
	AudioController.play_sfx("button_hover")
	_on_hover("back")

func _on_shake_check_box_toggled(button_pressed: bool):
	print("toggle shake:", button_pressed)
	CameraManager.toggle_screen_shake(button_pressed)
