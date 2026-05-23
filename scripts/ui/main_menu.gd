extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 播放主菜单角色idle动画
	animated_sprite.play("idle")

	# 播放菜单BGM
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_bgm("warm_fantasy_rpg_menu")

func _on_start_pressed():
	# 切换到游戏BGM并加载游戏场景
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_bgm("pixel_adventure_action", 0)  # 0 = 不使用淡入淡出
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_settings_pressed():
	# 切换到设置菜单
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_quit_pressed():
	# 退出游戏
	get_tree().quit()
