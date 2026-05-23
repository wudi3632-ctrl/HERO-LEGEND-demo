extends Node2D

var pause_menu
var ui_layer: CanvasLayer
var health_ui
var _kill_y: float = 0.0

func _ready():
	# 创建UI层确保暂停菜单在最上层
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)

	# 实例化暂停菜单
	pause_menu = preload("res://scenes/ui/pause_menu.tscn").instantiate()
	pause_menu.name = "PauseMenu"
	ui_layer.add_child(pause_menu)

	# 实例化血量UI，定位到左下角（心形缩放2倍后高度约34px）
	health_ui = preload("res://scenes/ui/Player Life.tscn").instantiate()
	health_ui.name = "HealthUI"
	ui_layer.add_child(health_ui)
	var viewport_size = get_viewport().get_visible_rect().size
	health_ui.position = Vector2(35, viewport_size.y - 34)

	# 实例化Boss血条UI（默认隐藏）
	var boss_health_ui = preload("res://scenes/boss_health_bar.tscn").instantiate()
	boss_health_ui.name = "BossHealthBar"
	ui_layer.add_child(boss_health_ui)

	# 找到玩家并连接血量信号
	var hero = get_node_or_null("Hero")
	if hero:
		hero.player_health_changed.connect(_on_player_health_changed)
		hero.player_died.connect(_on_player_died)

	# 敌人随机生成
	var spawner = get_node_or_null("EnemySpawner")
	var spawn_points = get_node_or_null("SpawnPoints")
	if spawner and spawn_points:
		spawner.setup_and_spawn(spawn_points)

	# 计算底部边界的Y坐标作为死亡线
	var bottom_boundary = get_node_or_null("BoundaryBody/StaticBody2D/bottom")
	if bottom_boundary:
		_kill_y = bottom_boundary.global_position.y - 10.0

	# 确保游戏BGM正在播放
	if AudioManager:
		var current_bgm = AudioManager.get_current_bgm()
		if current_bgm != "pixel_adventure_action":
			AudioManager.play_bgm("pixel_adventure_action", 0)


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_ui:
		health_ui.on_player_health_changed(current_health, max_health)


func _on_player_died() -> void:
	# 等待一会儿再切换到死亡界面，让玩家感受死亡瞬间
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/death_screen.tscn")


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
