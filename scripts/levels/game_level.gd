extends Node2D

var pause_menu
var ui_layer: CanvasLayer
var health_ui
var _kill_y: float = 0.0
var total_enemies: int = 0
var defeated_enemies: int = 0
var level_completed: bool = false

func _ready():
	print("=== GameLevel._ready() START ===")

	# 创建UI层确保暂停菜单在最上层
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)
	print("  UILayer created")

	# 实例化暂停菜单
	pause_menu = preload("res://scenes/ui/pause_menu.tscn").instantiate()
	pause_menu.name = "PauseMenu"
	ui_layer.add_child(pause_menu)
	print("  PauseMenu created")

	# 实例化血量UI，定位到左下角（心形缩放2倍后高度约34px）
	health_ui = preload("res://scenes/ui/Player Life.tscn").instantiate()
	health_ui.name = "HealthUI"
	ui_layer.add_child(health_ui)
	var viewport_size = get_viewport().get_visible_rect().size
	health_ui.position = Vector2(35, viewport_size.y - 34)
	print("  HealthUI created")

	# 实例化Boss血条UI（默认隐藏）
	var boss_health_ui = preload("res://scenes/boss_health_bar.tscn").instantiate()
	boss_health_ui.name = "BossHealthBar"
	ui_layer.add_child(boss_health_ui)
	print("  BossHealthUI created")

	# 实例化CombatFeedback系统
	var combat_feedback = preload("res://scenes/combat_feedback.tscn").instantiate()
	combat_feedback.name = "CombatFeedback"
	add_child(combat_feedback)
	print("  CombatFeedback created")

	# 找到玩家并连接血量信号
	var hero = get_node_or_null("Hero")
	if hero:
		hero.player_health_changed.connect(_on_player_health_changed)
		hero.player_died.connect(_on_player_died)
		print("  Hero connected")
	else:
		print("  WARNING: Hero not found!")

	# 敌人随机生成
	var spawner = get_node_or_null("EnemySpawner")
	var spawn_points = get_node_or_null("SpawnPoints")
	if spawner and spawn_points:
		spawner.setup_and_spawn(spawn_points)
		print("  Spawning enemies...")
	else:
		print("  WARNING: Spawner or SpawnPoints not found!")

	# 延迟调用，确保敌人生成完成后再计数
	print("  Calling _count_enemies() deferred...")
	call_deferred("_count_enemies")

	# 计算底部边界的Y坐标作为死亡线
	var bottom_boundary = get_node_or_null("BoundaryBody/StaticBody2D/bottom")
	if bottom_boundary:
		_kill_y = bottom_boundary.global_position.y - 10.0

	# 确保游戏BGM正在播放
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		var current_bgm = audio_manager.get_current_bgm() if audio_manager.has_method("get_current_bgm") else ""
		if current_bgm != "pixel_adventure_action":
			audio_manager.play_bgm("pixel_adventure_action", 0)

	print("=== GameLevel._ready() END ===")

func _count_enemies():
	# 计算场景中的敌人数量
	var enemies = get_tree().get_nodes_in_group("enemies")
	total_enemies = enemies.size()
	defeated_enemies = 0
	print("=== Level Start ===")
	print("Total enemies found: ", total_enemies)

	# 为每个敌人连接死亡信号
	for enemy in enemies:
		if is_instance_valid(enemy):
			# 断开之前的连接（避免重复）
			if enemy.tree_exiting.is_connected(_on_enemy_defeated):
				enemy.tree_exiting.disconnect(_on_enemy_defeated)
			# 连接信号
			enemy.tree_exiting.connect(_on_enemy_defeated)
			print("  Connected enemy: ", enemy.name)

func _on_enemy_defeated():
	defeated_enemies += 1
	print("Enemy defeated! Progress: ", defeated_enemies, "/", total_enemies)

	# 检查是否所有敌人都被击败
	if defeated_enemies >= total_enemies and not level_completed:
		_complete_level()

func _complete_level():
	level_completed = true
	print("=== Level Completed! ===")
	print("All enemies defeated! Transitioning to boss battle...")

	# 等待一小段时间让玩家看到最后一个敌人倒下
	await get_tree().create_timer(1.0).timeout

	# 切换到boss战场景
	get_tree().change_scene_to_file("res://scenes/levels/boss_battle.tscn")


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_ui:
		health_ui.on_player_health_changed(current_health, max_health)


func _on_player_died() -> void:
	print("GameLevel: Player died!")

	# 缓存场景树引用（在节点可能被销毁之前）
	var tree = get_tree()
	if not tree:
		print("ERROR: SceneTree is null!")
		return

	# 存储当前关卡路径到GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_current_level"):
		game_manager.set_current_level(scene_file_path)

	# 等待一会儿再切换到死亡界面，让玩家感受死亡瞬间
	await tree.create_timer(1.0).timeout

	# 切换到死亡界面
	if tree and tree.current_scene:
		tree.change_scene_to_file("res://scenes/ui/death_screen.tscn")
	else:
		print("ERROR: Cannot change scene, SceneTree or current_scene is null")


func _process(_delta: float) -> void:
	if _kill_y <= 0.0:
		return
	# 检查玩家是否触碰底部边界
	var hero = get_node_or_null("Hero")
	if hero and not hero.is_dead and hero.global_position.y > _kill_y:
		hero.instant_kill()
	# 检查敌人是否触碰底部边界
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("instant_kill"):
			if not enemy.is_dead and enemy.global_position.y > _kill_y:
				enemy.instant_kill()
