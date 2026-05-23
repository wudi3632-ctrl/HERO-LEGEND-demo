extends Control

var bgm_slider: HSlider
var bgm_value: Label
var sfx_slider: HSlider
var sfx_value: Label
var back_button: Button

func _ready():
	# 获取节点引用
	bgm_slider = $VBoxContainer/BGMContainer/BGMSlider
	bgm_value = $VBoxContainer/BGMContainer/BGMValue
	sfx_slider = $VBoxContainer/SFXContainer/SFXSlider
	sfx_value = $VBoxContainer/SFXContainer/SFXValue
	back_button = $VBoxContainer/BackButton

	# 连接信号
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	back_button.pressed.connect(_on_back_pressed)

	# 从AudioManager加载当前音量
	if AudioManager:
		var current_bgm_volume = AudioManager.bgm_volume * 100
		bgm_slider.value = current_bgm_volume
		_update_bgm_label(current_bgm_volume)

func _on_bgm_slider_changed(value: float):
	if AudioManager:
		AudioManager.set_volume(value / 100.0)
	_update_bgm_label(value)

func _on_sfx_slider_changed(value: float):
	# SFX音量控制（预留，可后续添加）
	_update_sfx_label(value)

func _update_bgm_label(value: float):
	bgm_value.text = str(int(value)) + "%"

func _update_sfx_label(value: float):
	sfx_value.text = str(int(value)) + "%"

func _on_back_pressed():
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
