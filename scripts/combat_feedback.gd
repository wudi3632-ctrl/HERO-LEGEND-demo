extends Node
# ============================================================
# CombatFeedback — 全局战斗反馈（顿帧 + 屏幕抖动）
# ============================================================

signal hit_stop_started
signal hit_stop_ended

# 顿帧参数（使用真实毫秒计时，避免 time_scale=0 时 delta=0 无法恢复）
var hit_stop_end_msec: int = 0
var is_hit_stopped: bool = false

# 屏幕抖动参数（同样使用真实毫秒计时）
var shake_intensity: float = 3.0
var shake_end_msec: int = 0
var shake_duration: float = 0.2
var is_shaking: bool = false
var _original_offset: Vector2 = Vector2.ZERO
var _camera: Camera2D = null

# 延迟震动：顿帧结束后再触发震动，确保击退和震动同时开始
var _pending_shake_intensity: float = 0.0
var _pending_shake_duration: float = 0.0
var _has_pending_shake: bool = false

# 持续震动参数
var continuous_shake_active: bool = false
var continuous_shake_end_msec: int = 0
var continuous_shake_intensity: float = 0.0
var continuous_shake_frequency: float = 8.0


func _ready() -> void:
	call_deferred("_find_camera")


func _find_camera() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player: Node2D = players[0] as Node2D
		if player and player.has_node("Camera2D"):
			_camera = player.get_node("Camera2D") as Camera2D
			_original_offset = _camera.offset


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()

	# 处理顿帧（真实时间，不受 time_scale 影响）
	if is_hit_stopped and now >= hit_stop_end_msec:
		is_hit_stopped = false
		Engine.time_scale = 1.0
		hit_stop_ended.emit()
		# 顿帧结束后触发延迟震动，确保击退和震动同步
		if _has_pending_shake:
			_has_pending_shake = false
			trigger_screen_shake(_pending_shake_intensity, _pending_shake_duration)
	# 安全兜底：超过 1 秒强制恢复，防止灰屏卡死
	elif is_hit_stopped and (hit_stop_end_msec == 0 or now - hit_stop_end_msec > 1000):
		is_hit_stopped = false
		Engine.time_scale = 1.0
		hit_stop_ended.emit()
		_has_pending_shake = false

	# 处理持续震动（真实时间，不受 time_scale 影响）
	if continuous_shake_active and _camera:
		if now >= continuous_shake_end_msec:
			continuous_shake_active = false
			_camera.offset = _original_offset
		else:
			var time_left = (continuous_shake_end_msec - now) / 1000.0
			var shake_amount = continuous_shake_intensity * sin(time_left * continuous_shake_frequency * TAU)
			_camera.offset = _original_offset + Vector2(shake_amount, shake_amount * 0.5)

	# 处理普通屏幕抖动（真实时间）
	if is_shaking and _camera:
		if now >= shake_end_msec:
			is_shaking = false
			_camera.offset = _original_offset
		else:
			var progress: float = float(shake_end_msec - now) / (shake_duration * 1000.0)
			var current_intensity: float = shake_intensity * progress
			var shake_offset: Vector2 = Vector2(
				randf_range(-current_intensity, current_intensity),
				randf_range(-current_intensity, current_intensity)
			)
			_camera.offset = _original_offset + shake_offset


# ---------- 公开接口 ----------

## 触发顿帧 + 延迟震动：顿帧结束后自动触发震动
func trigger_hit_stop(duration: float = 0.08, shake_intensity: float = 0.0, shake_duration: float = 0.0) -> void:
	if is_hit_stopped:
		return
	is_hit_stopped = true
	# 使用极小的 time_scale 而非 0.0，避免 move_and_slide 产生 NaN 法线
	Engine.time_scale = 0.001
	hit_stop_end_msec = Time.get_ticks_msec() + int(duration * 1000.0)
	# 记录待触发的震动参数
	if shake_intensity > 0.0:
		_pending_shake_intensity = shake_intensity
		_pending_shake_duration = shake_duration
		_has_pending_shake = true
	hit_stop_started.emit()

## 直接触发屏幕抖动（不带顿帧时使用）
func trigger_screen_shake(intensity: float = 3.0, duration: float = 0.2) -> void:
	if not _camera:
		_find_camera()
	if not _camera:
		return
	shake_intensity = intensity
	shake_duration = duration
	shake_end_msec = Time.get_ticks_msec() + int(duration * 1000.0)
	is_shaking = true

## 启动持续震动（用于boss转换等长时间震动）
func start_continuous_shake(intensity: float = 5.0, frequency: float = 8.0, duration: float = 5.0) -> void:
	if not _camera:
		_find_camera()
	if not _camera:
		return
	continuous_shake_intensity = intensity
	continuous_shake_frequency = frequency
	continuous_shake_end_msec = Time.get_ticks_msec() + int(duration * 1000.0)
	continuous_shake_active = true

## 停止持续震动
func stop_continuous_shake() -> void:
	continuous_shake_active = false
	if _camera:
		_camera.offset = _original_offset
