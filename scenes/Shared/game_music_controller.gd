extends Node

@onready var track_1 = $Track1

@export var fade_in_out_time: float = 2.0

var available_tracks: Array[AudioStreamPlayer] = []
var played_tracks: Array[AudioStreamPlayer] = []
var current_track: AudioStreamPlayer = null
var is_playing: bool = false

var min_volume: float = -80.0
var playing_vol: float = -10.0

func _ready():
	# Initialize available tracks
	available_tracks = [track_1]
	# Shuffle initial playlist
	available_tracks.shuffle()
	
	# Connect finished signals for all tracks
	for track in available_tracks:
		track.finished.connect(_on_track_finished)

func play_music():
	if is_playing:
		return
	
	if available_tracks.is_empty():
		# Reset and reshuffle if all tracks have been played
		available_tracks = played_tracks.duplicate()
		played_tracks.clear()
		available_tracks.shuffle()
	
	# Stop current track if one is playing
	if current_track and current_track.playing:
		current_track.stop()
	
	# Get next random track
	current_track = available_tracks.pop_back()
	played_tracks.append(current_track)
	
	fade_in_music()
	is_playing = true

func _on_track_finished():
	# When current track ends, crossfade to next track
	if is_playing:
		var prev_track = current_track
		# Start fading out current track
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(prev_track, "volume_db", min_volume, fade_in_out_time)
		
		# Start next track
		if available_tracks.is_empty():
			available_tracks = played_tracks.duplicate()
			played_tracks.clear()
			available_tracks.shuffle()
		
		current_track = available_tracks.pop_back()
		played_tracks.append(current_track)
		
		# Start new track at low volume and fade in
		current_track.volume_db = min_volume
		current_track.play()
		var fade_in_tween = create_tween()
		fade_in_tween.tween_property(current_track, "volume_db", playing_vol, fade_in_out_time)
		
		# Stop the previous track after fade out
		fade_out_tween.tween_callback(func(): prev_track.stop())

func fade_in_music(duration: float = fade_in_out_time):
	if not current_track:
		return
	
	current_track.volume_db = min_volume
	current_track.play()
	var tween = create_tween()
	tween.tween_property(current_track, "volume_db", playing_vol, duration)

func stop_music():
	fade_out_music()

func fade_out_music(duration: float = fade_in_out_time):
	if not current_track:
		return
	
	var tween = create_tween()
	tween.tween_property(current_track, "volume_db", min_volume, duration)
	tween.tween_callback(_on_fade_out_finished)

func _on_fade_out_finished():
	if current_track:
		current_track.stop()
	is_playing = false
