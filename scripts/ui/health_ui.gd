extends Node2D

# ============================================================
# 血量UI管理脚本
# ============================================================
# 显示玩家生命值，每颗心包含3个AnimatedSprite2D节点
# 动画状态：
# - "Full heart": 满血（一帧）
# - "Empty heart": 空血（一帧）
# - "Lose heart": 受伤过渡动画（5帧）

# ============================================================
# 节点引用
# ============================================================
@onready var heart_1: AnimatedSprite2D = $AnimatedSprite2D
@onready var heart_2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var heart_3: AnimatedSprite2D = $AnimatedSprite2D3

# ============================================================
# 血量管理
# ============================================================
var max_health: int = 3
var current_health: int = 3
var hearts: Array[AnimatedSprite2D] = []

# ============================================================
# 信号定义
# ============================================================
signal health_depleted()

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
	# 将所有心节点添加到数组
	hearts = [heart_1, heart_2, heart_3]

	# 设置纹理过滤为最近邻（像素风格）
	for heart in hearts:
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.play("Full heart")

	# 连接动画完成信号
	for i in range(hearts.size()):
		if not hearts[i].animation_finished.is_connected(_on_heart_animation_finished):
			hearts[i].animation_finished.connect(_on_heart_animation_finished.bind(i))

# ============================================================
# 设置初始血量
# ============================================================
func set_health(health: int) -> void:
	current_health = clamp(health, 0, max_health)
	_update_hearts_display()

# ============================================================
# 响应玩家血量变化信号
# ============================================================
func on_player_health_changed(new_health: int, _max_health: int) -> void:
	if new_health >= current_health:
		current_health = new_health
		_update_hearts_display()
		return
	var hearts_to_lose_start = new_health
	for i in range(hearts_to_lose_start, current_health):
		if i >= 0 and i < hearts.size():
			hearts[i].play("Lose heart")
	current_health = new_health

# ============================================================
# 受到伤害
# ============================================================
func take_damage(amount: int = 1) -> void:
	if current_health <= 0:
		return

	var damage_amount = min(amount, current_health)
	var hearts_to_lose = current_health - damage_amount

	# 播放受伤动画（从满血到空血的过渡）
	for i in range(hearts_to_lose, current_health):
		if i >= 0 and i < hearts.size():
			hearts[i].play("Lose heart")

	current_health = hearts_to_lose

# ============================================================
# 恢复血量
# ============================================================
func heal(amount: int = 1) -> void:
	if current_health >= max_health:
		return

	current_health = min(current_health + amount, max_health)
	_update_hearts_display()

# ============================================================
# 更新心形显示（不播放动画）
# ============================================================
func _update_hearts_display() -> void:
	for i in range(hearts.size()):
		if i < current_health:
			hearts[i].play("Full heart")
		else:
			hearts[i].play("Empty heart")

# ============================================================
# 动画完成回调
# ============================================================
func _on_heart_animation_finished(heart_index: int) -> void:
	# 检查是否是受伤动画完成
	if hearts[heart_index].animation == "Lose heart":
		# 动画播放完成后，设置为空血状态
		if heart_index >= current_health:
			hearts[heart_index].play("Empty heart")

	# 检查是否血量耗尽
	if current_health <= 0:
		health_depleted.emit()

# ============================================================
# 重置血量
# ============================================================
func reset_health() -> void:
	current_health = max_health
	_update_hearts_display()
