extends StaticBody2D

@onready var sprite_2d = $Sprite2D
@onready var electric_area = $DetectionAreaOpenBoard
@onready var cpu_particles_2d = $CPUParticles2D
@onready var static_sound = $StaticSound

var nearby_objects = []
var is_on: bool = true

func _ready():
	static_sound.play()
	cpu_particles_2d.emitting = true
	add_to_group("electrical")

func get_electrical_state() -> bool:
	return is_on

func _player_zap(object):
	if is_on:
		var player_position = object.global_position
		var wire_position = self.global_position
		var direction = (player_position - wire_position).normalized()

		var electrical_zap = preload("res://scenes/Shared/electricity.tscn").instantiate()

		var offset_amount = 30

		electrical_zap.global_position = wire_position + (direction * offset_amount)

		get_tree().current_scene.add_child(electrical_zap)

		electrical_zap.output_charge(direction)

func _play_zap(object):
	if is_on:
		var conductor_position = object.global_position
		var wire_position = self.global_position
		var direction = (wire_position - conductor_position).normalized()
		
		var electrical_zap = preload("res://scenes/Shared/electricity.tscn").instantiate()
		
		var offset_amount = -10
		
		electrical_zap.global_position = wire_position + (direction * offset_amount)
		
		get_tree().current_scene.add_child(electrical_zap)
		
		electrical_zap.output_charge(direction)

func _on_detection_area_open_board_body_entered(body):
	if body.is_in_group("player") and is_on:
		SharedSignals.player_killed.emit("pop")
		_player_zap(body)
	
	if body.is_in_group("conductor"):
		nearby_objects.append(body)
		if is_on:
			body.receive_electricity()
			_play_zap(body)

func _on_detection_area_open_board_body_exited(body):
	if body in nearby_objects:
		nearby_objects.erase(body)
		body.stop_electricity()
