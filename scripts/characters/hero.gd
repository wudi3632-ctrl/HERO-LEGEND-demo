extends CharacterBody2D

# ============================================================
# 节点引用
# ============================================================
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var camera_2d: Camera2D = $Camera2D

# ============================================================
# 角色参数
# ============================================================
var GRAVITY: float = ProjectSettings.get("physics/2d/default_gravity")
@export var MOVE_SPEED: float = 100.0
@export var JUMP_VELOCITY: float = -300.0
@export var DASH_SPEED: float = 200.0
@export var DASH_DURATION: float = 0.15
@export var DASH_COOLDOWN: float = 1.5
@export var DOUBLE_JUMP_MULTIPLIER: float = 0.85
@export var JUMP_CUT_MULTIPLIER: float = 0.4
@export var ACCELERATION: float = 600.0
@export var DECELERATION: float = 800.0
@export var ATTACK_DAMAGE_KNOCKBACK: float = 200.0

# ============================================================
# 运行时变量
# ============================================================
var can_double_jump: bool = true
var dash_cooldown_timer: float = 0.0
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var state_before_dash: String = ""
var is_hurt: bool = false
var is_attacking: bool = false
var hurt_knockback: Vector2 = Vector2.ZERO
var attack_target_enemy: CharacterBody2D = null
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 0.6
var is_dead: bool = false

# ============================================================
# 血量管理
# ============================================================
var max_health: int = 3
var current_health: int = 3

# ============================================================
# 信号定义
# ============================================================
signal player_health_changed(current_health: int, max_health: int)
signal player_died()

# ============================================================
# 状态机
# ============================================================
var current_state: State

# ---------- State 基类 ----------
class State:
	var hero: CharacterBody2D

	func _init(hero_node: CharacterBody2D) -> void:
		hero = hero_node

	func enter() -> void:
		pass

	func exit() -> void:
		pass

	func update(_delta: float) -> void:
		pass

	func physics_update(_delta: float) -> void:
		pass


# ---------- IdleState ----------
class IdleState extends State:
	func enter() -> void:
		hero.can_double_jump = true

	func update(_delta: float) -> void:
		if is_zero_approx(hero.velocity.x):
			hero.animated_sprite_2d.play("idle")
		if Input.is_action_just_pressed("jump"):
			hero.transition_to("JumpState")
		if Input.is_action_just_pressed("flash") and hero.dash_cooldown_timer <= 0.0:
			hero.transition_to("DashState")
		if Input.is_action_just_pressed("attack-1"):
			hero.transition_to("AttackState1")
		var direction := Input.get_axis("move_left", "move_right")
		if not is_zero_approx(direction):
			hero.transition_to("MoveState")

	func physics_update(delta: float) -> void:
		hero.velocity.y += hero.GRAVITY * delta
		# 惯性减速缓冲
		hero.velocity.x = move_toward(hero.velocity.x, 0.0, hero.DECELERATION * delta)
		if not is_zero_approx(hero.velocity.x):
			hero.animated_sprite_2d.play("stop")
			hero.animated_sprite_2d.flip_h = hero.velocity.x < 0
		hero.move_and_slide()
		if not hero.is_on_floor():
			hero.transition_to("FallState")


# ---------- MoveState ----------
class MoveState extends State:
	func enter() -> void:
		hero.can_double_jump = true

	func update(_delta: float) -> void:
		var direction := Input.get_axis("move_left", "move_right")
		if is_zero_approx(direction):
			hero.transition_to("IdleState")
			return
		if Input.is_action_just_pressed("jump"):
			hero.transition_to("JumpState")
			return
		if Input.is_action_just_pressed("flash") and hero.dash_cooldown_timer <= 0.0:
			hero.transition_to("DashState")
			return
		if Input.is_action_just_pressed("attack-1"):
			hero.transition_to("AttackState1")
			return
		hero.animated_sprite_2d.play("move")
		hero.animated_sprite_2d.flip_h = direction < 0

	func physics_update(delta: float) -> void:
		hero.velocity.y += hero.GRAVITY * delta
		var direction := Input.get_axis("move_left", "move_right")
		var target_speed: float = direction * hero.MOVE_SPEED
		hero.velocity.x = move_toward(hero.velocity.x, target_speed, hero.ACCELERATION * delta)
		hero.move_and_slide()
		if not hero.is_on_floor():
			hero.transition_to("FallState")


# ---------- JumpState ----------
class JumpState extends State:
	func enter() -> void:
		hero.velocity.y = hero.JUMP_VELOCITY
		hero.can_double_jump = true
		hero.animated_sprite_2d.play("jump")

	func update(_delta: float) -> void:
		if Input.is_action_just_released("jump") and hero.velocity.y < hero.JUMP_VELOCITY * hero.JUMP_CUT_MULTIPLIER:
			hero.velocity.y = hero.JUMP_VELOCITY * hero.JUMP_CUT_MULTIPLIER
		if Input.is_action_just_pressed("jump") and hero.can_double_jump:
			hero.velocity.y = hero.JUMP_VELOCITY * hero.DOUBLE_JUMP_MULTIPLIER
			hero.can_double_jump = false
		elif hero.velocity.y >= 0:
			hero.transition_to("FallState")
		var direction := Input.get_axis("move_left", "move_right")
		if not is_zero_approx(direction):
			hero.animated_sprite_2d.flip_h = direction < 0
		if Input.is_action_just_pressed("flash") and hero.dash_cooldown_timer <= 0.0:
			hero.transition_to("DashState")
		if Input.is_action_just_pressed("attack-1"):
			hero.transition_to("AttackState1")

	func physics_update(delta: float) -> void:
		hero.velocity.y += hero.GRAVITY * delta
		var direction := Input.get_axis("move_left", "move_right")
		var target_speed: float = direction * hero.MOVE_SPEED
		hero.velocity.x = move_toward(hero.velocity.x, target_speed, hero.ACCELERATION * delta)
		hero.move_and_slide()
		if hero.is_on_floor():
			var dir := Input.get_axis("move_left", "move_right")
			if is_zero_approx(dir):
				hero.transition_to("IdleState")
			else:
				hero.transition_to("MoveState")


# ---------- FallState ----------
class FallState extends State:
	func enter() -> void:
		hero.animated_sprite_2d.play("fall")

	func update(_delta: float) -> void:
		if Input.is_action_just_pressed("jump") and hero.can_double_jump:
			hero.velocity.y = hero.JUMP_VELOCITY * hero.DOUBLE_JUMP_MULTIPLIER
			hero.can_double_jump = false
			hero.animated_sprite_2d.play("jump")
		elif hero.velocity.y >= 0 and hero.animated_sprite_2d.animation == "jump":
			hero.animated_sprite_2d.play("fall")
		var direction := Input.get_axis("move_left", "move_right")
		if not is_zero_approx(direction):
			hero.animated_sprite_2d.flip_h = direction < 0
		if Input.is_action_just_pressed("flash") and hero.dash_cooldown_timer <= 0.0:
			hero.transition_to("DashState")
		if Input.is_action_just_pressed("attack-1"):
			hero.transition_to("AttackState1")

	func physics_update(delta: float) -> void:
		hero.velocity.y += hero.GRAVITY * delta
		var direction := Input.get_axis("move_left", "move_right")
		var target_speed: float = direction * hero.MOVE_SPEED
		hero.velocity.x = move_toward(hero.velocity.x, target_speed, hero.ACCELERATION * delta)
		hero.move_and_slide()
		if hero.is_on_floor():
			var dir := Input.get_axis("move_left", "move_right")
			if is_zero_approx(dir):
				hero.transition_to("IdleState")
			else:
				hero.transition_to("MoveState")


# ---------- DashState ----------
class DashState extends State:
	func enter() -> void:
		hero.state_before_dash = "IdleState"
		if not hero.is_on_floor():
			hero.state_before_dash = "FallState"
		var direction := Input.get_axis("move_left", "move_right")
		if not is_zero_approx(direction):
			hero.dash_direction = Vector2(direction, 0.0)
		else:
			hero.dash_direction = Vector2(-1.0 if hero.animated_sprite_2d.flip_h else 1.0, 0.0)
		hero.dash_timer = hero.DASH_DURATION
		hero.dash_cooldown_timer = hero.DASH_COOLDOWN
		hero.velocity = hero.dash_direction * hero.DASH_SPEED
		hero.animated_sprite_2d.play("flash")
		AudioManager.play_sfx(hero._dash_sfx)

	func update(delta: float) -> void:
		hero.dash_timer -= delta
		hero.dash_cooldown_timer -= delta
		if hero.dash_timer <= 0.0:
			hero.transition_to(hero.state_before_dash)

	func physics_update(_delta: float) -> void:
		hero.velocity = hero.dash_direction * hero.DASH_SPEED
		hero.move_and_slide()


# ---------- HurtState ----------
class HurtState extends State:
	var hurt_timer: float = 0.0

	func enter() -> void:
		hero.is_hurt = true
		hero.can_double_jump = false
		hero.velocity = hero.hurt_knockback
		hero.animated_sprite_2d.play("damage")
		hurt_timer = 0.4

	func update(delta: float) -> void:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			hero.is_hurt = false
			if hero.is_dead:
				# 播放死亡动画（信号在动画结束后由_process发射）
				hero.animated_sprite_2d.play("die")
				return
			if hero.is_on_floor():
				hero.transition_to("IdleState")
			else:
				hero.transition_to("FallState")

	func physics_update(delta: float) -> void:
		hero.velocity.y += hero.GRAVITY * delta
		hero.velocity.x = move_toward(hero.velocity.x, 0.0, 300.0 * delta)
		hero.move_and_slide()


# ---------- AttackState1 ----------
class AttackState1 extends State:
	func enter() -> void:
		hero.is_attacking = true
		hero.has_dealt_attack_damage = false
		hero.velocity.x = move_toward(hero.velocity.x, 0.0, 400.0)
		hero.animated_sprite_2d.play("attack-1")
		if not hero.animated_sprite_2d.is_connected("animation_finished", _on_attack1_finished):
			hero.animated_sprite_2d.animation_finished.connect(_on_attack1_finished)

	func exit() -> void:
		if hero.animated_sprite_2d.is_connected("animation_finished", _on_attack1_finished):
			hero.animated_sprite_2d.animation_finished.disconnect(_on_attack1_finished)

	func update(_delta: float) -> void:
		if hero.animated_sprite_2d.frame >= 2:
			hero._try_damage_nearby_enemies()

	func physics_update(delta: float) -> void:
		hero.velocity.y += hero.GRAVITY * delta
		hero.velocity.x = move_toward(hero.velocity.x, 0.0, 300.0 * delta)
		hero.move_and_slide()

	func _on_attack1_finished() -> void:
		if hero.current_state is AttackState1:
			var dir := Input.get_axis("move_left", "move_right")
			if hero.is_on_floor():
				if is_zero_approx(dir):
					hero.transition_to("IdleState")
				else:
					hero.transition_to("MoveState")
			else:
				hero.transition_to("FallState")


# ---------- AttackState2 ----------
class AttackState2 extends State:
	func enter() -> void:
		hero.is_attacking = true
		hero.has_dealt_attack_damage = false
		hero.velocity.x = move_toward(hero.velocity.x, 0.0, 400.0)
		hero.animated_sprite_2d.play("attack-2")
		if not hero.animated_sprite_2d.is_connected("animation_finished", _on_attack2_finished):
			hero.animated_sprite_2d.animation_finished.connect(_on_attack2_finished)

	func exit() -> void:
		if hero.animated_sprite_2d.is_connected("animation_finished", _on_attack2_finished):
			hero.animated_sprite_2d.animation_finished.disconnect(_on_attack2_finished)

	func update(_delta: float) -> void:
		if hero.animated_sprite_2d.frame >= 3:
			hero._try_damage_nearby_enemies()

	func physics_update(delta: float) -> void:
		hero.velocity.y += hero.GRAVITY * delta
		hero.velocity.x = move_toward(hero.velocity.x, 0.0, 300.0 * delta)
		hero.move_and_slide()

	func _on_attack2_finished() -> void:
		if hero.current_state is AttackState2:
			var dir := Input.get_axis("move_left", "move_right")
			if hero.is_on_floor():
				if is_zero_approx(dir):
					hero.transition_to("IdleState")
				else:
					hero.transition_to("MoveState")
			else:
				hero.transition_to("FallState")


# ============================================================
# 攻击检测：查找近距离敌人并造成伤害
# ============================================================
var has_dealt_attack_damage: bool = false
var _dash_sfx: AudioStream = preload("res://assets/audio/ui/jump.ogg")
var _hit_sounds: Array[AudioStream] = [
	preload("res://assets/audio/hero/hit_1.wav"),
	preload("res://assets/audio/hero/hit_2.wav"),
	preload("res://assets/audio/hero/hit_3.wav"),
]

func _try_damage_nearby_enemies() -> void:
	if has_dealt_attack_damage:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy_node in enemies:
		if not is_instance_valid(enemy_node) or not (enemy_node is CharacterBody2D):
			continue
		var enemy := enemy_node as CharacterBody2D
		if enemy == self:
			continue
		# 水平距离判定（横版游戏用水平距离更精确）
		var attack_reach: float = 25.0
		var h_dist: float = absf(global_position.x - enemy.global_position.x)
		var v_dist: float = absf(global_position.y - enemy.global_position.y)
		if h_dist >= attack_reach or v_dist > 20.0:
			continue
		# 方向判定：只攻击面朝方向的敌人
		var dir_to_enemy: float = enemy.global_position.x - global_position.x
		var facing_right: bool = not animated_sprite_2d.flip_h
		if facing_right and dir_to_enemy < -5.0:
			continue
		if not facing_right and dir_to_enemy > 5.0:
			continue
		var knockback_dir: int = -1 if enemy.global_position.x < global_position.x else 1
		if enemy.has_method("take_damage"):
			enemy.take_damage(knockback_dir)
		# 攻击命中反馈：顿帧结束后再触发震动
		CombatFeedback.trigger_hit_stop(0.06, 2.0, 0.15)
		AudioManager.play_sfx(_hit_sounds[randi() % _hit_sounds.size()])
		has_dealt_attack_damage = true
		return


# ============================================================
# 受伤接口
# ============================================================
func instant_kill() -> void:
	if is_dead:
		return
	is_dead = true
	current_health = 0
	player_health_changed.emit(0, max_health)
	transition_to("HurtState")

## 无敌状态查询（供敌人判定）
func is_invincible() -> bool:
	return invincible_timer > 0.0

func take_hurt(knockback_dir: int, knockback_force: float = 150.0) -> void:
	if is_hurt or invincible_timer > 0.0 or is_dead:
		return
	invincible_timer = INVINCIBLE_DURATION
	state_before_dash = "IdleState"
	if not is_on_floor():
		state_before_dash = "FallState"
	hurt_knockback = Vector2(knockback_dir * knockback_force, -80.0)

	# 扣减血量并发出信号
	current_health -= 1
	player_health_changed.emit(current_health, max_health)
	if current_health <= 0:
		is_dead = true

	transition_to("HurtState")


# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	physics_interpolation_mode = Node2D.PHYSICS_INTERPOLATION_MODE_OFF
	# 像素精灵：使用最近邻过滤，防止缩放/移动时模糊
	animated_sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# 碰撞层分离：玩家在 layer 2，只检测 layer 1（地面墙壁），不与敌人碰撞
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	current_state = IdleState.new(self)
	current_state.enter()

func _process(delta: float) -> void:
	if dash_cooldown_timer > 0.0 and current_state.get_script() != DashState:
		dash_cooldown_timer -= delta
	# 无敌帧倒计时 + 闪烁效果
	if invincible_timer > 0.0:
		invincible_timer -= delta
		if not is_hurt:
			visible = fmod(invincible_timer * 10.0, 1.0) > 0.5
	else:
		# 无敌结束后恢复可见（包括死亡动画期间，确保die动画能完整播放）
		visible = true
	# 死亡状态处理：等待die动画播放完毕后隐藏并发射信号
	if is_dead and not is_hurt:
		if animated_sprite_2d.animation == "die" and not animated_sprite_2d.is_playing():
			visible = false
			player_died.emit()
		return
	if not is_dead or is_hurt:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if CombatFeedback.is_hit_stopped:
		return
	if is_dead and not is_hurt:
		return
	current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	if current_state:
		current_state.exit()
	# 退出攻击状态时重置标记
	if current_state is AttackState1 or current_state is AttackState2:
		is_attacking = false
		has_dealt_attack_damage = false
	match target_state_name:
		"IdleState":
			current_state = IdleState.new(self)
		"MoveState":
			current_state = MoveState.new(self)
		"JumpState":
			current_state = JumpState.new(self)
		"FallState":
			current_state = FallState.new(self)
		"DashState":
			current_state = DashState.new(self)
		"HurtState":
			current_state = HurtState.new(self)
		"AttackState1":
			has_dealt_attack_damage = false
			current_state = AttackState1.new(self)
		"AttackState2":
			has_dealt_attack_damage = false
			current_state = AttackState2.new(self)
	current_state.enter()
