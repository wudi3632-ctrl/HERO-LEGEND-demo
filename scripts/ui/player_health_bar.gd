extends Control

# ============================================================
# Player血条UI脚本
# ============================================================
# 固定在屏幕左下角，实时显示玩家血量

# ============================================================
# 节点引用（从场景文件中获取）
# ============================================================
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var player_label: Label = $PlayerLabel

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
	# 只在游戏运行时显示血条，编辑器预览时也保持可见以便调试
	if not Engine.is_editor_hint():
		visible = false

	# 设置血条样式
	_setup_health_bar_style()

	# 查找玩家并连接信号
	_connect_to_player()

func _setup_health_bar_style() -> void:
	# 创建蓝色血条样式
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.6, 1.0)  # 蓝色
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8

	# 设置血条背景样式（深灰色，带边框）
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)  # 深灰色背景
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.5, 0.5, 0.5)  # 灰色边框

	# 应用样式
	health_bar.add_theme_stylebox_override("fill", fill_style)
	health_bar.add_theme_stylebox_override("background", bg_style)

func _connect_to_player() -> void:
	# 查找玩家节点
	var player = _find_player()
	if player and player.has_signal("player_health_changed"):
		if not player.player_health_changed.is_connected(_on_player_health_changed):
			player.player_health_changed.connect(_on_player_health_changed)
			print("PlayerHealthBar: Connected to player health signal")

		# 初始化当前血量
		if player.has_method("get"):
			var max_hp = player.get("max_health")
			var current_hp = player.get("current_health")
			if max_hp != null and current_hp != null:
				_update_health_bar(current_hp, max_hp)
	else:
		print("Warning: Player not found or has no player_health_changed signal")

func _find_player() -> CharacterBody2D:
	# 从当前场景查找玩家
	var current_scene = get_tree().current_scene
	if current_scene:
		# 直接查找名为 "Hero" 的节点
		var hero = current_scene.get_node_or_null("Hero")
		if hero:
			return hero

		# 如果找不到，遍历场景树
		return _find_node_by_name(current_scene, "Hero")

	return null

func _find_node_by_name(root: Node, node_name: String) -> Node:
	# 广度优先搜索
	var queue = []
	queue.append(root)

	while queue.size() > 0:
		var current = queue.pop_front()
		if current.name == node_name:
			return current
		for child in current.get_children():
			queue.append(child)

	return null

# ============================================================
# 玩家血量变化回调
# ============================================================
func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	_update_health_bar(current_hp, max_hp)

	# 血量低时改变颜色（更鲜艳的红色）
	if current_hp <= max_hp * 0.3:
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style is StyleBoxFlat:
			fill_style.bg_color = Color(1.0, 0.3, 0.3)  # 警告红色
			health_bar.add_theme_stylebox_override("fill", fill_style)

	# 打印调试信息
	print("=== Player Health Updated ===")
	print("Current HP: ", current_hp, "/", max_hp)

func _update_health_bar(current_hp: int, max_hp: int) -> void:
	# 更新血条值
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_label.text = "%d/%d" % [current_hp, max_hp]

	# 显示血条（首次受伤时显示）
	if not visible:
		visible = true
