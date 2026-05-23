extends Node

# ============================================================
# 游戏管理器 - 全局单例
# ============================================================
# 管理游戏状态、关卡路径等全局信息

# ============================================================
# 当前关卡路径
# ============================================================
var current_level_path: String = ""

# ============================================================
# 设置当前关卡
# ============================================================
func set_current_level(path: String) -> void:
	current_level_path = path
	print("GameManager: Current level set to: ", path)

# ============================================================
# 获取当前关卡路径
# ============================================================
func get_current_level() -> String:
	return current_level_path

# ============================================================
# 重启当前关卡
# ============================================================
func restart_current_level() -> void:
	if current_level_path.is_empty():
		print("GameManager: No current level set, defaulting to node_2d")
		get_tree().change_scene_to_file("res://scenes/node_2d.tscn")
	else:
		print("GameManager: Restarting level: ", current_level_path)
		get_tree().change_scene_to_file(current_level_path)
