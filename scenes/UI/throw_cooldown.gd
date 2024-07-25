extends Control

@onready var progress_bar = $ProgressBar
@onready var cooldown_timer = $CooldownTimer

func _ready():
	progress_bar.value = 100
	cooldown_timer.start()

func _physics_process(delta):
	# remove a piece of the progress bar every second the timer is counting
