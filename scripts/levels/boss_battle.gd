extends Node2D

# ============================================================
# Boss Battle 关卡管理脚本
# ============================================================
# 管理Boss战斗场景的UI连接和游戏逻辑

# ============================================================
# 节点引用
# ============================================================
@onready var hero: CharacterBody2D = $Hero
@onready var knight: Node = $Knight
@onready var player_life_ui: Node2D = $UI/PlayerLife

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
	# 连接玩家血量变化信号
	if hero and hero.has_signal("player_health_changed"):
		hero.player_health_changed.connect(_on_player_health_changed)
		print("BossBattle: Connected to player health signal")

	# 连接玩家死亡信号
	if hero and hero.has_signal("player_died"):
		hero.player_died.connect(_on_player_died)

	# 设置玩家初始生命值为3
	if hero and player_life_ui:
		if player_life_ui.has_method("set_health"):
			player_life_ui.set_health(3)
			print("BossBattle: Set player health to 3")

	# 设置PlayerLife UI的位置到左下角
	_set_player_life_position()

	# 延迟播放boss战BGM，确保场景完全加载
	call_deferred("_play_boss_battle_bgm")

func _play_boss_battle_bgm() -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		# 使用fade_duration=0立即切换，避免与场景切换冲突
		audio_manager.play_bgm("boss_entrance", 0)

func _set_player_life_position() -> void:
	if not player_life_ui:
		return

	# 获取视口大小
	var viewport_size = get_viewport().get_visible_rect().size

	# Player Life缩放了2倍，每个心形宽17px，三个心形共51px，缩放后102px
	# 高度约17px，缩放后34px
	# 定位到左下角，留一些边距
	player_life_ui.position = Vector2(35, viewport_size.y - 34)

	# 监听视口大小变化（可选）
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	_set_player_life_position()

# ============================================================
# 玩家血量变化回调
# ============================================================
func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if player_life_ui and player_life_ui.has_method("on_player_health_changed"):
		player_life_ui.on_player_health_changed(current_health, max_health)

# ============================================================
# 玩家死亡回调
# ============================================================
func _on_player_died() -> void:
	print("BossBattle: Player died!")

	# 缓存场景树引用（在节点可能被销毁之前）
	var tree = get_tree()
	if not tree:
		print("ERROR: SceneTree is null!")
		return

	# 存储当前关卡路径到GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_current_level"):
		game_manager.set_current_level(scene_file_path)

	# 等待一会儿再切换到死亡界面
	await tree.create_timer(1.0).timeout

	# 切换到死亡界面
	if tree and tree.current_scene:
		tree.change_scene_to_file("res://scenes/ui/death_screen.tscn")
	else:
		print("ERROR: Cannot change scene, SceneTree or current_scene is null")
