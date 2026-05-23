extends Control

# ============================================================
# Boss血条UI脚本
# ============================================================
# 显示在屏幕正上方的boss血条，实时反应boss血量

# ============================================================
# 节点引用（从场景文件中获取）
# ============================================================
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var boss_name_label: Label = $BossNameLabel

# ============================================================
# Boss血量数据
# ============================================================
var boss_max_hp: int = 0
var boss_current_hp: int = 0
var boss_name: String = "BOSS"

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
	# 只在游戏运行时隐藏血条，编辑器预览时保持可见
	if not Engine.is_editor_hint():
		visible = false

	# 设置血条样式
	_setup_health_bar_style()

func _setup_health_bar_style() -> void:
	# 创建红色血条样式
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.1, 0.1)  # 鲜红色
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

# ============================================================
# 初始化boss血条
# ============================================================
func setup_boss_health(max_hp: int, name: String = "BOSS") -> void:
	boss_max_hp = max_hp
	boss_current_hp = max_hp
	boss_name = name

	# 更新UI
	health_bar.max_value = boss_max_hp
	health_bar.value = boss_current_hp
	health_label.text = "100%"
	boss_name_label.text = boss_name

	# 显示血条
	visible = true

	# 打印调试信息
	print("=== Boss Health Bar Setup ===")
	print("Max HP: ", boss_max_hp)
	print("Boss Name: ", boss_name)
	print("Visible: ", visible)

# ============================================================
# 更新boss血量
# ============================================================
func update_boss_health(new_hp: int) -> void:
	boss_current_hp = clamp(new_hp, 0, boss_max_hp)

	# 更新血条值
	health_bar.value = boss_current_hp

	# 显示百分比
	var hp_percent = int((float(boss_current_hp) / float(boss_max_hp)) * 100)
	health_label.text = "%d%%" % hp_percent

	# 血量低时改变颜色（更鲜艳的红色）
	if boss_current_hp <= boss_max_hp * 0.3:
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style is StyleBoxFlat:
			fill_style.bg_color = Color(1.0, 0.0, 0.0)  # 更鲜艳的红色
			health_bar.add_theme_stylebox_override("fill", fill_style)

	# 打印调试信息
	print("=== Boss Health Updated ===")
	print("Current HP: ", boss_current_hp, "/", boss_max_hp, " (", hp_percent, "%)")

# ============================================================
# 隐藏血条
# ============================================================
func hide_health_bar() -> void:
	visible = false
	print("=== Boss Health Bar Hidden ===")

# ============================================================
# 显示血条
# ============================================================
func show_health_bar() -> void:
	visible = true
	print("=== Boss Health Bar Shown ===")
