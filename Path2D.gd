extends Path2D

@export var num_of_points = 50.0
@export var gravity = -9.8
@onready var path_follow_2d = $PathFollow2D

func _ready():
	SharedSignals.ObjectLaunched.connect(_object_launch)

func _object_launch(_pos, _target):
	position = _pos
	calculate_trajectory(_pos, _target)

func calculate_trajectory(_Start, _End):
	var DOT = Vector2(1, 0).dot((_End - _Start).normalized())
	var angle = 90 - 45 * DOT

	var x_dis = _End.x - _Start.x
	var y_dis = -1.0 * (_End.y - _Start.y)

	var speed = sqrt(((0.5 * gravity * x_dis * x_dis) / pow(cos(deg_to_rad(angle)), 2.0)) / (y_dis - (tan(deg_to_rad(angle)) * x_dis)))
	var x_component = (cos(deg_to_rad(angle)) * speed)
	var y_component = (sin(deg_to_rad(angle)) * speed)

	var total_time = x_dis / x_component
	var new_curve = Curve2D.new()

	for i in range(num_of_points):
		var time = total_time * (i / float(num_of_points))
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		new_curve.add_point(Vector2(dx, dy))

	self.curve = new_curve

	# Reset the PathFollow2D progress and start the tween
	path_follow_2d.progress = 0.0

	var tween = create_tween()
	tween.tween_property(path_follow_2d, "progress_ratio", _End, 1)

	# Start the tween
	tween.start()
