extends Parallax2D

@export var bob_amplitude: float = 8.0
@export var bob_speed: float = 1.5

var _base_y: float

func _ready():
	_base_y = position.y

func _process(_delta: float) -> void:
	position.y = _base_y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amplitude
