extends Control

var bgm_slider: HSlider
var bgm_value: Label
var sfx_slider: HSlider
var sfx_value: Label
var resume_button: Button
var quit_button: Button

var is_paused: bool = false
var nodes_initialized: bool = false

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

func _initialize_nodes():
	if nodes_initialized:
		return

	# 获取节点引用
	bgm_slider = $Panel/VBoxContainer/BGMContainer/BGMSlider
	bgm_value = $Panel/VBoxContainer/BGMContainer/BGMValue
	sfx_slider = $Panel/VBoxContainer/SFXContainer/SFXSlider
	sfx_value = $Panel/VBoxContainer/SFXContainer/SFXValue
	resume_button = $Panel/VBoxContainer/ResumeButton
	quit_button = $Panel/VBoxContainer/QuitButton

	# 连接信号
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 从AudioManager加载当前音量
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		var current_bgm_volume = audio_manager.bgm_volume * 100
		bgm_slider.value = current_bgm_volume
		_update_bgm_label(current_bgm_volume)
		var current_sfx_volume = audio_manager.sfx_volume * 100
		sfx_slider.value = current_sfx_volume
		_update_sfx_label(current_sfx_volume)

	nodes_initialized = true

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused

	if is_paused:
		if not nodes_initialized:
			_initialize_nodes()
		show()
		modulate = Color.WHITE
		move_to_front()
		call_deferred("_pause_game")
	else:
		hide()
		get_tree().paused = false

func _pause_game():
	get_tree().paused = true

func _on_bgm_slider_changed(value: float):
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.set_volume(value / 100.0)
		_update_bgm_label(value)

func _on_sfx_slider_changed(value: float):
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.set_sfx_volume(value / 100.0)
	_update_sfx_label(value)

func _update_bgm_label(value: float):
	if bgm_value:
		bgm_value.text = str(int(value)) + "%"

func _update_sfx_label(value: float):
	if sfx_value:
		sfx_value.text = str(int(value)) + "%"

func _on_resume_pressed():
	toggle_pause()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
