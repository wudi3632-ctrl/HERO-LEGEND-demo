extends Node

# Deterministic A/B recording driver. Both LOCAL and JEV runs receive the
# same input schedule; only the boss decision source changes.
@onready var hero: CharacterBody2D = get_parent().get_node("Hero")
@onready var boss: CharacterBody2D = get_parent().get_node("Knight")

var elapsed := 0.0
var last_segment := -1

func _ready() -> void:
	seed(424242)
	hero.max_health = 99
	hero.current_health = 99
	print("A/B recording driver started")

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 24.0:
		_release_inputs()
		get_tree().quit()
		return

	# Repeat a fixed 8-second player pattern: approach, attack, retreat,
	# re-approach, attack/dash. This exposes offense and defense decisions.
	var segment := int(elapsed) % 8
	if segment != last_segment:
		last_segment = segment
		_apply_segment(segment)

	# Force phase two halfway through so one recording covers both phases.
	if elapsed >= 10.0 and boss.boss_phase == 1 and not boss.is_transitioning:
		boss.hp = boss.MAX_HP / 2

func _apply_segment(segment: int) -> void:
	_release_inputs()
	match segment:
		0, 1:
			Input.action_press("move_right")
		2:
			Input.action_press("attack-1")
		3:
			Input.action_press("move_left")
		4:
			Input.action_press("move_right")
		5:
			Input.action_press("attack-1")
		6:
			Input.action_press("flash")
		7:
			Input.action_press("move_left")

func _release_inputs() -> void:
	for action in ["move_left", "move_right", "attack-1", "flash", "jump"]:
		Input.action_release(action)
