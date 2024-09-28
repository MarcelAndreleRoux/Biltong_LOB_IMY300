# MenuAudioController.gd
extends Node

# Array to hold all AudioStreamPlayer nodes
var audio_tracks: Array = []

# Total number of tracks
var TOTAL_TRACKS: int = 0

# Array to hold the indices of tracks
var indices: Array = []

# Current playing track index
var current_track_index: int = -1

func _ready():
	# Seed the random number generator for true randomness
	randomize()
	
	# Populate the audio_tracks array with all AudioStreamPlayer children
	for child in get_children():
		if child is AudioStreamPlayer:
			audio_tracks.append(child)
	
	# Update TOTAL_TRACKS based on the number of tracks found
	TOTAL_TRACKS = audio_tracks.size()
	
	if TOTAL_TRACKS == 0:
		push_error("No AudioStreamPlayer nodes found under MenuAudioController!")
		return
	else:
		print("Total Tracks Found: ", TOTAL_TRACKS)
	
	# Initialize the indices array with track indices (0-based)
	for i in range(TOTAL_TRACKS):
		indices.append(i)
	
	print("Initial Indices: ", indices)
	
	# Shuffle the indices to randomize the order
	shuffle_indices()
	
	# Connect the 'finished' signal of each track to the handler
	for track in audio_tracks:
		track.finished.connect(on_track_finished)
		print("Connected 'finished' signal for: ", track.name)
	
	# Start playing the first track
	play_next_track()

# Function to shuffle the indices array
func shuffle_indices():
	indices.shuffle()
	print("Shuffled Indices: ", indices)

# Function to get the next track index without repetition
func get_next_index() -> int:
	if indices.is_empty():
		# All tracks have been played; reshuffle for the next cycle
		for i in range(TOTAL_TRACKS):
			indices.append(i)
		print("Reshuffled Indices: ", indices)
		shuffle_indices()
		
		# Prevent immediate repeat
		if TOTAL_TRACKS > 1 and indices[0] == current_track_index:
			# Swap the first index with the next one to avoid immediate repeat
			var swap_index = 1  # Since TOTAL_TRACKS > 1, index 1 exists
			var temp = indices[0]
			indices[0] = indices[swap_index]
			indices[swap_index] = temp
			print("Adjusted Shuffled Indices to prevent immediate repeat: ", indices)
	
	# Get the first index from the shuffled list
	var next_index: int = indices.pop_front()
	print("Selected Track Index: ", next_index)
	return next_index

# Function to play the next track based on the shuffled indices
func play_next_track():
	var index: int = get_next_index()
	
	# If a track is currently playing, stop it
	if current_track_index != -1:
		var current_track = get_track_by_index(current_track_index)
		if current_track:
			print("Stopping Track: ", current_track.name)
			current_track.stop()
		else:
			print("Warning: Current track is null. Cannot stop.")
	
	# Update the current track index
	current_track_index = index
	
	# Play the selected track
	var selected_track: AudioStreamPlayer = get_track_by_index(index)
	if selected_track:
		print("Playing Track: ", selected_track.name)
		selected_track.play()
	else:
		print("Error: Selected track is null. Cannot play.")

# Handler for the 'finished' signal
func on_track_finished():
	print("Track Finished. Playing Next Track.")
	play_next_track()

# Utility function to get the AudioStreamPlayer by index
func get_track_by_index(index: int) -> AudioStreamPlayer:
	if index >= 0 and index < audio_tracks.size():
		return audio_tracks[index]
	else:
		push_error("Invalid track index: " + str(index))
		return null

# Function to manually trigger playback via external calls
func play_main_music():
	play_next_track()
