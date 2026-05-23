extends Node2D

# ============================================================
# 敌人随机生成器
# 在预定的出生点随机生成敌人（随机类型、随机数量）
# ============================================================

@export var min_enemies: int = 8
@export var max_enemies: int = 12
@export var min_distance_from_player: float = 150.0
@export var min_enemy_spacing: float = 30.0
@export var max_spawn_attempts: int = 50

# 敌人类型权重（越大越常见）
@export var slime_weight: float = 3.0
@export var soldier_weight: float = 2.0
@export var goblin_weight: float = 2.5
@export var arrow_soldier_weight: float = 1.5

# 敌人场景
var _enemy_scenes: Dictionary = {}
# 出生点列表
var _spawn_points: Array[Marker2D] = []
# 已生成的敌人位置（用于间距检测）
var _spawned_positions: Array[Vector2] = []


func _ready() -> void:
	_preload_enemy_scenes()


func _preload_enemy_scenes() -> void:
	_enemy_scenes = {
		"slime": preload("res://scenes/characters/slime.tscn"),
		"soldier": preload("res://scenes/characters/soldier.tscn"),
		"goblin": preload("res://scenes/characters/goblin.tscn"),
		"arrow_soldier": preload("res://scenes/characters/arrow_soldier.tscn"),
	}


## 由 game_level.gd 调用，传入出生点容器引用
func setup_and_spawn(spawn_points_container: Node2D) -> void:
	_find_spawn_points(spawn_points_container)
	spawn_enemies()


func _find_spawn_points(container: Node2D) -> void:
	_spawn_points.clear()
	for child in container.get_children():
		if child is Marker2D:
			_spawn_points.append(child)


## 主生成入口
func spawn_enemies() -> void:
	if _spawn_points.is_empty():
		push_warning("EnemySpawner: 没有找到出生点！")
		return

	var enemy_count = randi_range(min_enemies, max_enemies)
	_spawned_positions.clear()
	var spawned = 0

	for i in range(enemy_count):
		var spawned_pos = _try_spawn_one()
		if spawned_pos != Vector2.ZERO:
			_spawned_positions.append(spawned_pos)
			spawned += 1

	print("EnemySpawner: 成功生成 %d / %d 个敌人" % [spawned, enemy_count])


## 尝试生成一个敌人，返回生成位置（失败返回 Vector2.ZERO）
func _try_spawn_one() -> Vector2:
	for attempt in range(max_spawn_attempts):
		var spawn_point = _spawn_points.pick_random()
		var pos = _get_offset_position(spawn_point.global_position)

		if _is_valid_position(pos):
			var enemy_type = _get_random_enemy_type()
			_spawn_enemy(enemy_type, pos)
			return pos

	return Vector2.ZERO


## 在出生点附近添加随机偏移
func _get_offset_position(center: Vector2) -> Vector2:
	var offset_x = randf_range(-20.0, 20.0)
	return Vector2(center.x + offset_x, center.y)


## 检测位置是否有效
func _is_valid_position(pos: Vector2) -> bool:
	# 检查与玩家的距离
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and pos.distance_to(player.global_position) < min_distance_from_player:
		return false

	# 检查与已有敌人的间距
	for existing_pos in _spawned_positions:
		if pos.distance_to(existing_pos) < min_enemy_spacing:
			return false

	return true


## 基于权重随机选择敌人类型
func _get_random_enemy_type() -> String:
	var weights = {
		"slime": slime_weight,
		"soldier": soldier_weight,
		"goblin": goblin_weight,
		"arrow_soldier": arrow_soldier_weight,
	}
	var total = 0.0
	for w in weights.values():
		total += w

	var roll = randf() * total
	var cumulative = 0.0
	for type in weights.keys():
		cumulative += weights[type]
		if roll < cumulative:
			return type

	return "slime"  # 默认


## 实例化敌人并添加到场景
func _spawn_enemy(enemy_type: String, pos: Vector2) -> void:
	if not _enemy_scenes.has(enemy_type):
		return

	var enemy = _enemy_scenes[enemy_type].instantiate()
	enemy.global_position = pos
	enemy.z_index = 2
	add_child(enemy)
