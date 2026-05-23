class_name EnemyBase
extends CharacterBody2D

# ============================================================
# 节点引用
# ============================================================
@onready var animated_sprite_2d: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# ============================================================
# 共享参数
# ============================================================
var GRAVITY: float = ProjectSettings.get("physics/2d/default_gravity")
@export var MAX_HP: int = 3
@export var DETECT_RANGE: float = 100.0
@export var PATROL_SPEED: float = 30.0
@export var CHASE_SPEED: float = 55.0
@export var ATTACK_RANGE: float = 30.0
@export var ATTACK_COOLDOWN: float = 0.8
@export var KNOCKBACK_FORCE: float = 150.0
@export var HURT_DURATION: float = 0.4

# ============================================================
# 运行时变量
# ============================================================
var current_state: State
var hp: int
var player: CharacterBody2D
var is_hurt: bool = false
var is_dead: bool = false
var facing_direction: int = -1  # -1=左, 1=右
var hurt_knockback: Vector2 = Vector2.ZERO
var attack_cooldown_timer: float = 0.0
var has_dealt_damage: bool = false

# ============================================================
# 状态机
# ============================================================
class State:
	var enemy: CharacterBody2D

	func _init(enemy_node: CharacterBody2D) -> void:
		enemy = enemy_node

	func enter() -> void:
		pass

	func exit() -> void:
		pass

	func update(_delta: float) -> void:
		pass

	func physics_update(_delta: float) -> void:
		pass


# ---------- PatrolState ----------
class PatrolState extends State:
	var patrol_timer: float = 0.0
	var is_walking: bool = true
	var walk_duration: float = 0.0
	var idle_duration: float = 0.0

	func enter() -> void:
		enemy.animated_sprite_2d.flip_h = enemy.facing_direction < 0
		# 随机决定本次移动和停留的时长
		walk_duration = randf_range(1.5, 3.0)
		idle_duration = randf_range(1.0, 2.5)
		patrol_timer = 0.0
		is_walking = true
		enemy.animated_sprite_2d.play("move")

	func update(_delta: float) -> void:
		patrol_timer += _delta
		if is_walking and patrol_timer >= walk_duration:
			# 移动结束，切换到停留
			is_walking = false
			patrol_timer = 0.0
			enemy.velocity.x = 0.0
			enemy.animated_sprite_2d.play("idle")
		elif not is_walking and patrol_timer >= idle_duration:
			# 停留结束，切换到移动（可能换方向）
			is_walking = true
			patrol_timer = 0.0
			walk_duration = randf_range(1.5, 3.0)
			if randf() < 0.4:
				enemy.facing_direction *= -1
				enemy.animated_sprite_2d.flip_h = enemy.facing_direction < 0
			enemy.animated_sprite_2d.play("move")
		# 检测玩家
		if enemy.player:
			var dist: float = enemy._distance_to_player()
			if dist < enemy.DETECT_RANGE:
				enemy.transition_to("ChaseState")

	func physics_update(delta: float) -> void:
		enemy.velocity.y += enemy.GRAVITY * delta
		if is_walking:
			enemy.velocity.x = enemy.facing_direction * enemy.PATROL_SPEED
			enemy.move_and_slide()
			# 碰墙转向
			if enemy.is_on_wall():
				enemy.facing_direction *= -1
				enemy.animated_sprite_2d.flip_h = enemy.facing_direction < 0
		else:
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)
			enemy.move_and_slide()


# ---------- HurtState ----------
class HurtState extends State:
	var hurt_timer: float = 0.0

	func enter() -> void:
		enemy.is_hurt = true
		enemy.velocity = enemy.hurt_knockback
		enemy.animated_sprite_2d.play("hurt")
		hurt_timer = enemy.HURT_DURATION

	func update(delta: float) -> void:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			enemy.is_hurt = false
			if enemy.hp <= 0:
				enemy.transition_to("DeathState")
			elif enemy.player and enemy._distance_to_player() < enemy.DETECT_RANGE:
				enemy.transition_to("ChaseState")
			else:
				enemy.transition_to("PatrolState")

	func physics_update(delta: float) -> void:
		enemy.velocity.y += enemy.GRAVITY * delta
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)
		enemy.move_and_slide()


# ---------- DeathState ----------
class DeathState extends State:
	var death_finished: bool = false

	func enter() -> void:
		enemy.is_dead = true
		enemy.velocity = Vector2.ZERO
		enemy.animated_sprite_2d.play("die")
		if enemy.collision_shape_2d:
			enemy.collision_shape_2d.set_deferred("disabled", true)
		enemy.animated_sprite_2d.animation_finished.connect(_on_death_anim_finished)

	func exit() -> void:
		if enemy.animated_sprite_2d.animation_finished.is_connected(_on_death_anim_finished):
			enemy.animated_sprite_2d.animation_finished.disconnect(_on_death_anim_finished)

	func update(_delta: float) -> void:
		pass

	func physics_update(_delta: float) -> void:
		pass

	func _on_death_anim_finished() -> void:
		if not death_finished:
			death_finished = true
			enemy.queue_free()


# ============================================================
# 共享方法
# ============================================================
func _find_player() -> CharacterBody2D:
	var p = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if p and p.get("is_dead") == true:
		return null
	return p

func _distance_to_player() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)

func _direction_to_player() -> float:
	if not player:
		return 0.0
	return player.global_position.x - global_position.x

func _update_facing(target_direction: float) -> void:
	# 死区：水平距离太小时不转向，防止玩家在上下方时抖动
	if absf(target_direction) < 3.0:
		return
	if target_direction < 0:
		facing_direction = -1
	elif target_direction > 0:
		facing_direction = 1
	animated_sprite_2d.flip_h = facing_direction < 0

func _face_player() -> void:
	_update_facing(_direction_to_player())

func instant_kill() -> void:
	if is_dead:
		return
	hp = 0
	transition_to("DeathState")

func take_damage(knockback_dir: int) -> void:
	if is_hurt or is_dead:
		return
	hp -= 1
	hurt_knockback = Vector2(knockback_dir * KNOCKBACK_FORCE, -80.0)
	transition_to("HurtState")

func deal_damage_to_player() -> void:
	if has_dealt_damage:
		return
	if not player:
		return
	# 玩家已死亡，不攻击
	if player.get("is_dead") == true:
		return
	# 水平距离判定（横版游戏用水平距离更精确）
	var h_dist: float = absf(global_position.x - player.global_position.x)
	var v_dist: float = absf(global_position.y - player.global_position.y)
	if h_dist > ATTACK_RANGE or v_dist > 20.0:
		return
	# 方向判定：只能攻击面朝方向的玩家
	var dir_to_player: float = _direction_to_player()
	var facing_right: bool = not animated_sprite_2d.flip_h
	if facing_right and dir_to_player < -5.0:
		return
	if not facing_right and dir_to_player > 5.0:
		return
	# 无敌帧判定：玩家无敌期间不造成伤害
	if player.has_method("is_invincible") and player.is_invincible():
		return
	if player.has_method("take_hurt"):
		player.take_hurt(facing_direction, KNOCKBACK_FORCE)
		# 敌人命中玩家反馈：顿帧结束后再触发震动
		var combat_feedback = get_tree().root.get_node_or_null("CombatFeedback")
		if combat_feedback and combat_feedback.has_method("trigger_hit_stop"):
			combat_feedback.trigger_hit_stop(0.05, 1.5, 0.12)
		# 播放攻击音效
		var sfx_list := _get_attack_sfx()
		if sfx_list.size() > 0:
			var audio_manager = get_tree().root.get_node_or_null("AudioManager")
			if audio_manager and audio_manager.has_method("play_sfx"):
				audio_manager.play_sfx(sfx_list[randi() % sfx_list.size()])
		has_dealt_damage = true

# 子类覆写此方法返回攻击音效列表
func _get_attack_sfx() -> Array[AudioStream]:
	return []

func _apply_gravity(delta: float) -> void:
	velocity.y += GRAVITY * delta
	move_and_slide()


# ============================================================
# 状态转换（子类覆写以注册各自的 State 映射）
# ============================================================
func transition_to(_target_state_name: String) -> void:
	pass


# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	physics_interpolation_mode = Node2D.PHYSICS_INTERPOLATION_MODE_OFF
	# 像素精灵：使用最近邻过滤，防止缩放/移动时模糊
	if animated_sprite_2d:
		animated_sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# 碰撞层分离：敌人在 layer 3，只检测 layer 1（地面墙壁），不与玩家/其他敌人碰撞
	# collision_layer = 3 表示敌人层
	# collision_mask = 1 表示只检测地面墙壁（不检测layer 2玩家，不检测layer 3其他敌人）
	collision_layer = 3
	collision_mask = 1
	hp = MAX_HP
	player = _find_player()
	attack_cooldown_timer = 0.0
	add_to_group("enemies")

func _process(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if not player or not is_instance_valid(player):
		player = _find_player()
	elif player.get("is_dead") == true:
		player = null
	current_state.update(delta)

func _physics_process(delta: float) -> void:
	var combat_feedback = get_tree().root.get_node_or_null("CombatFeedback")
	if combat_feedback != null and combat_feedback.is_hit_stopped == true:
		return
	# 边缘检测：射线检测前方脚下是否有地面
	if not is_dead and is_on_floor() and not is_zero_approx(velocity.x):
		var space_state = get_world_2d().direct_space_state
		var ahead_x: float = global_position.x + facing_direction * 14.0
		var ray_start := Vector2(ahead_x, global_position.y - 2.0)
		var ray_end := Vector2(ahead_x, global_position.y + 20.0)
		var query := PhysicsRayQueryParameters2D.create(ray_start, ray_end, collision_mask)
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			facing_direction *= -1
			animated_sprite_2d.flip_h = facing_direction < 0
			velocity.x = 0.0
			animated_sprite_2d.play("idle")
	current_state.physics_update(delta)
