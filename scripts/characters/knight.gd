extends EnemyBase

# ============================================================
# Knight Boss - Two-Phase Boss Fight
# ============================================================

# Node references for dual sprite system
@onready var no_attack_sprite: AnimatedSprite2D = $NoAttack
@onready var attack_sprite: AnimatedSprite2D = $Attack
@onready var effects_sprite: AnimatedSprite2D = $effects

# Boss health bar reference
var boss_health_bar: Control = null

# ============================================================
# Boss Phase System
# ============================================================
var boss_phase: int = 1  # 1 = Phase 1, 2 = Phase 2 (HP ≤ 50%)
var phase_2_speed_multiplier: float = 1.3  # Phase 2 is 30% faster
var is_rolling: bool = false
var is_blocking: bool = false
var is_transitioning: bool = false  # 二阶段转换期间无敌
var roll_cooldown: float = 0.0
var block_cooldown: float = 0.0
var combo_count: int = 0  # Track combo in Phase 2
var boss_bgm_played: bool = false  # 标记是否已播放boss BGM（移到Knight类中，避免重复初始化）

# ============================================================
# KnightPatrolState - Combat-ready idle
# ============================================================
class KnightPatrolState extends State:
	var animation_started: bool = false

	func enter() -> void:
		enemy.is_rolling = false
		enemy.is_blocking = false
		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# 强制播放待机动画
		enemy.no_attack_sprite.stop()
		enemy.no_attack_sprite.play("idle")
		enemy.no_attack_sprite.frame = 0
		animation_started = true

	func update(_delta: float) -> void:
		if not enemy.player:
			return
		var dist: float = enemy._distance_to_player()
		if dist < enemy.DETECT_RANGE:
			enemy.transition_to("KnightChaseState")

	func physics_update(delta: float) -> void:
		enemy._apply_gravity(delta)
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)

	func exit() -> void:
		animation_started = false


# ============================================================
# KnightChaseState - Phase-dependent chasing behavior
# ============================================================
class KnightChaseState extends State:
	var decision_timer: float = 0.0
	var decision_interval: float = 0.1  # Check every 0.1 seconds
	var current_anim: String = ""

	func enter() -> void:
		enemy.is_rolling = false
		enemy.is_blocking = false
		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0
		decision_timer = 0.0
		current_anim = ""

		# 首次进入战斗状态时初始化boss血条（BGM由boss_battle.gd负责播放）
		if not enemy.boss_bgm_played:
			enemy.boss_bgm_played = true
			# 初始化boss血条
			_initialize_boss_health_bar()

	func _initialize_boss_health_bar() -> void:
		# 查找boss血条UI - 先尝试从当前场景的UI节点查找，再遍历场景树
		# 首先尝试从当前关卡场景的UI节点查找
		var current_scene = enemy.get_tree().current_scene
		if current_scene:
			enemy.boss_health_bar = current_scene.get_node_or_null("UI/BossHealthBar")

		# 如果找不到，遍历整个场景树查找
		if not enemy.boss_health_bar:
			enemy.boss_health_bar = _find_node_by_name(enemy.get_tree().root, "BossHealthBar")

		if not enemy.boss_health_bar:
			print("Warning: BossHealthBar not found in scene tree!")
			print("Current scene: ", current_scene.name if current_scene else "null")
			if current_scene:
				var ui_node = current_scene.get_node_or_null("UI")
				if ui_node:
					print("UI node found, children:")
					for i in range(ui_node.get_child_count()):
						print("  [", i, "] ", ui_node.get_child(i).name)
				else:
					print("UI node not found!")
			return

		if enemy.boss_health_bar.has_method("setup_boss_health"):
			enemy.boss_health_bar.setup_boss_health(enemy.MAX_HP, "KNIGHT BOSS")
			print("Boss health bar initialized successfully!")
		else:
			print("Warning: BossHealthBar has no setup_boss_health method!")

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

	func update(delta: float) -> void:
		if not enemy.player:
			enemy.transition_to("KnightPatrolState")
			return

		var dist: float = enemy._distance_to_player()

		# Out of range
		if dist > enemy.DETECT_RANGE * 1.2:
			enemy.transition_to("KnightPatrolState")
			return

		decision_timer += delta
		if decision_timer >= decision_interval:
			decision_timer = 0.0
			_make_decision(dist)

		# Face player
		enemy._face_player()
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# Check phase for animation and speed
		var current_speed = enemy.CHASE_SPEED
		if enemy.boss_phase == 2:
			current_speed *= enemy.phase_2_speed_multiplier

		# Chase movement
		if dist > enemy.ATTACK_RANGE * 0.8:
			enemy.velocity.x = enemy.facing_direction * current_speed
		elif dist < enemy.ATTACK_RANGE * 0.5:
			# Back up if too close
			enemy.velocity.x = -enemy.facing_direction * (current_speed * 0.4)
		else:
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)

		# Animation based on phase (只在动画改变时才播放)
		var target_anim: String
		if absf(enemy.velocity.x) > 10.0:
			target_anim = "move" if enemy.boss_phase == 1 else "run"
		else:
			target_anim = "idle"

		# 只在动画需要改变时才播放
		if target_anim != current_anim:
			current_anim = target_anim
			enemy.no_attack_sprite.stop()
			enemy.no_attack_sprite.play(current_anim)

	func _make_decision(dist: float) -> void:
		# 二阶段特有：中等距离跳跃攻击
		# 当距离在中等范围时，优先跳跃攻击（仅二阶段）
		if enemy.boss_phase == 2:
			var min_jump_dist = enemy.ATTACK_RANGE * 2.0
			var max_jump_dist = enemy.DETECT_RANGE * 0.75
			if dist > min_jump_dist and dist < max_jump_dist and enemy.attack_cooldown_timer <= 0.0:
				enemy.transition_to("KnightJumpState")
				return

		# Attack range check
		if dist < enemy.ATTACK_RANGE and enemy.attack_cooldown_timer <= 0.0:
			enemy.velocity.x = 0.0
			enemy.transition_to("KnightAttackState")
			return

		# Detect player attack and respond
		if _is_player_attacking() or _should_react_to_player():
			if enemy.boss_phase == 1:
				# Phase 1: Roll dodge
				if enemy.roll_cooldown <= 0.0 and dist < enemy.ATTACK_RANGE * 2.0:
					if randf() < 0.75:  # 75% chance to roll
						enemy.transition_to("KnightRollState")
						return
			else:
				# Phase 2: Shield block
				if enemy.block_cooldown <= 0.0 and dist < enemy.ATTACK_RANGE * 2.0:
					if randf() < 0.8:  # 80% chance to block
						enemy.transition_to("KnightBlockState")
						return

	func _is_player_attacking() -> bool:
		# Check if player is attacking (has is_attacking property)
		if enemy.player and enemy.player.has_method("get"):
			var is_attacking = enemy.player.get("is_attacking")
			if is_attacking != null and is_attacking == true:
				return true
		return false

	func _should_react_to_player() -> bool:
		# 如果玩家在攻击范围内，即使没有检测到is_attacking，也有一定概率反应
		if not enemy.player:
			return false
		var dist = enemy._distance_to_player()
		if dist < enemy.ATTACK_RANGE * 1.2:
			# 30%概率主动反应（预判）
			if randf() < 0.3:
				return true
		return false

	func physics_update(delta: float) -> void:
		enemy._apply_gravity(delta)


# ============================================================
# KnightAttackState - Phase-dependent attack patterns
# ============================================================
class KnightAttackState extends State:
	var damage_dealt: bool = false
	var has_hit_frame_2: bool = false
	var has_hit_frame_5: bool = false
	var current_attack: int = 1  # 1 or 2
	var sound_played_frame_2: bool = false
	var sound_played_frame_5: bool = false

	func enter() -> void:
		enemy.is_rolling = false
		enemy.is_blocking = false
		enemy.velocity.x = 0.0
		enemy._face_player()
		enemy.no_attack_sprite.visible = false
		enemy.attack_sprite.visible = true

		# Reset damage flags
		enemy.has_dealt_damage = false
		damage_dealt = false
		has_hit_frame_2 = false
		has_hit_frame_5 = false
		sound_played_frame_2 = false
		sound_played_frame_5 = false

		# Determine attack based on phase and combo
		if enemy.boss_phase == 1:
			# Phase 1: Only attack_1
			current_attack = 1
			enemy.combo_count = 0
		else:
			# Phase 2: Combo attack_1 -> attack_2
			enemy.combo_count += 1
			if enemy.combo_count == 1:
				current_attack = 1
			else:
				current_attack = 2
				enemy.combo_count = 0  # Reset for next combo

		# Play appropriate animation
		var anim_name = "attack_1" if current_attack == 1 else "attack_2"
		enemy.attack_sprite.flip_h = enemy.facing_direction < 0

		# 强制播放攻击动画
		enemy.attack_sprite.stop()
		enemy.attack_sprite.play(anim_name)
		enemy.attack_sprite.frame = 0

		# Connect animation_finished
		if not enemy.attack_sprite.animation_finished.is_connected(_on_attack_finished):
			enemy.attack_sprite.animation_finished.connect(_on_attack_finished)

	func update(_delta: float) -> void:
		var frame = enemy.attack_sprite.frame

		# attack_1 (0-9帧): 第5帧造成伤害
		if current_attack == 1 and not damage_dealt:
			if frame == 5:
				_play_attack_sound()  # 在伤害帧播放音效
				enemy.deal_damage_to_player()
				damage_dealt = true

		# attack_2 (0-11帧): 第2帧和第5帧造成伤害
		elif current_attack == 2:
			# 第2帧第一次伤害
			if frame == 2 and not has_hit_frame_2:
				if not sound_played_frame_2:
					_play_attack_sound()  # 第一次伤害音效
					sound_played_frame_2 = true
				enemy.deal_damage_to_player()
				enemy.has_dealt_damage = false
				has_hit_frame_2 = true
			# 第5帧第二次伤害
			elif frame == 5 and not has_hit_frame_5:
				if not sound_played_frame_5:
					_play_attack_sound()  # 第二次伤害音效
					sound_played_frame_5 = true
				enemy.deal_damage_to_player()
				has_hit_frame_5 = true
				damage_dealt = true

	func _play_attack_sound() -> void:
		var attack_sounds = [
			"res://assets/audio/enemy/sword_1.wav",
			"res://assets/audio/enemy/sword_2.wav"
		]
		var random_sound = attack_sounds[randi() % attack_sounds.size()]
		# Check if AudioManager exists (autoload scripts may not be available in headless mode)
		var audio_manager = enemy.get_tree().root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx(load(random_sound))

	func physics_update(delta: float) -> void:
		# 攻击时不移动，只应用重力
		enemy.velocity.y += enemy.GRAVITY * delta
		enemy.velocity.x = 0.0  # 确保攻击时不移动
		enemy.move_and_slide()

	func exit() -> void:
		if enemy.attack_sprite.animation_finished.is_connected(_on_attack_finished):
			enemy.attack_sprite.animation_finished.disconnect(_on_attack_finished)

	func _on_attack_finished() -> void:
		if not is_instance_valid(enemy):
			return

		# Phase 2: Combo follow-up (attack_1 -> attack_2)
		if enemy.boss_phase == 2 and current_attack == 1:
			# 80% chance to follow up with attack_2
			if randf() < 0.8:
				enemy.transition_to("KnightAttackState")
				return
			else:
				enemy.combo_count = 0  # Reset combo

		# End attack sequence
		enemy.attack_cooldown_timer = enemy.ATTACK_COOLDOWN
		enemy.transition_to("KnightChaseState")


# ============================================================
# KnightRollState - Phase 1 defensive roll with invincibility
# ============================================================
class KnightRollState extends State:
	var roll_timer: float = 0.0
	var roll_duration: float = 0.6
	var roll_direction: int = 0
	var animation_started: bool = false

	func enter() -> void:
		enemy.is_rolling = true
		enemy.is_blocking = false
		roll_timer = 0.0
		animation_started = false

		# Roll direction: toward player (朝向玩家翻滚)
		if enemy.player:
			var dir_to_player = enemy._direction_to_player()
			roll_direction = 1 if dir_to_player > 0 else -1
		else:
			roll_direction = enemy.facing_direction

		# 确保精灵可见性
		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true

		# 翻滚方向：朝向玩家翻滚
		# boss始终面朝玩家，翻滚时保持sprite朝向与移动方向一致
		# 玩家在右边(dir_to_player > 0) → boss面向右(flip_h=false) → 向右翻滚
		# 玩家在左边(dir_to_player < 0) → boss面向左(flip_h=true) → 向左翻滚
		if enemy.player:
			var dir_to_player = enemy._direction_to_player()
			enemy.no_attack_sprite.flip_h = (dir_to_player > 0)
		else:
			enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# 强制停止当前动画并播放翻滚
		enemy.no_attack_sprite.stop()
		enemy.no_attack_sprite.play("roll")
		enemy.no_attack_sprite.frame = 0
		animation_started = true

		# 翻滚时完全禁用碰撞，可以直接穿过玩家
		enemy.collision_layer = 0  # 不与任何物体碰撞
		enemy.collision_mask = 1   # 只检测地面

		# Initial roll velocity with more horizontal speed
		var roll_speed = enemy.CHASE_SPEED * 2.0
		enemy.velocity = Vector2(roll_direction * roll_speed, -80.0)

	func update(delta: float) -> void:
		roll_timer += delta

		# 确保动画持续播放
		if animation_started and enemy.no_attack_sprite.animation != "roll":
			enemy.no_attack_sprite.play("roll")

		if roll_timer >= roll_duration:
			enemy.transition_to("KnightChaseState")
			return

	func physics_update(delta: float) -> void:
		# 持续保持翻滚移动速度
		enemy.velocity.y += enemy.GRAVITY * delta

		# 保持水平翻滚速度，逐渐减速
		var roll_speed = enemy.CHASE_SPEED * 1.8
		var speed_factor = 1.0 - (roll_timer / roll_duration) * 0.5  # 从100%减速到50%
		enemy.velocity.x = roll_direction * roll_speed * speed_factor

		enemy.move_and_slide()

	func exit() -> void:
		enemy.is_rolling = false
		enemy.roll_cooldown = 2.0  # 2 seconds cooldown
		# 恢复碰撞检测
		enemy.collision_layer = 3  # 敌人层
		enemy.collision_mask = 1   # 地面


# ============================================================
# KnightBlockState - Phase 2 shield block with attack capability
# ============================================================
class KnightBlockState extends State:
	var block_timer: float = 0.0
	var max_block_duration: float = 5.0  # 格挡持续5秒
	var knockback_velocity: Vector2 = Vector2.ZERO
	var is_being_knocked_back: bool = false
	var animation_started: bool = false
	var current_anim: String = ""

	func enter() -> void:
		enemy.is_blocking = true
		enemy.is_rolling = false
		block_timer = 0.0
		is_being_knocked_back = false
		knockback_velocity = Vector2.ZERO
		animation_started = false
		current_anim = ""

		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# 强制停止当前动画并播放格挡动画
		enemy.no_attack_sprite.stop()
		enemy.no_attack_sprite.play("shield raise")
		enemy.no_attack_sprite.frame = 0
		current_anim = "shield raise"
		animation_started = true

	func update(delta: float) -> void:
		block_timer += delta

		# 始终面朝玩家，防止背身被偷袭
		if enemy.player:
			enemy._face_player()
			enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# 处理击退缓停效果
		if is_being_knocked_back:
			# 应用更强的惯性缓停效果
			knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, delta * 5.0)
			enemy.velocity = knockback_velocity
			if knockback_velocity.length() < 3.0:
				is_being_knocked_back = false
				enemy.velocity = Vector2.ZERO
		else:
			# 没有被击退时，可以移动
			if enemy.player:
				var dist = enemy._distance_to_player()
				var current_speed = enemy.CHASE_SPEED * 0.6  # 格挡时移动速度较慢

				# 根据距离决定移动
				if dist > enemy.ATTACK_RANGE * 1.2:
					# 距离较远时接近玩家
					enemy.velocity.x = enemy.facing_direction * current_speed
				elif dist < enemy.ATTACK_RANGE * 0.6:
					# 距离太近时后退
					enemy.velocity.x = -enemy.facing_direction * (current_speed * 0.5)
				else:
					# 距离合适时停止移动
					enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)

			# 根据是否移动来切换动画
			var target_anim: String
			if absf(enemy.velocity.x) > 10.0:
				target_anim = "shield raise move"
			else:
				target_anim = "shield raise"

			# 只在动画需要改变时才播放
			if target_anim != current_anim:
				current_anim = target_anim
				enemy.no_attack_sprite.stop()
				enemy.no_attack_sprite.play(current_anim)

		# Exit conditions
		if block_timer >= max_block_duration:
			enemy.transition_to("KnightChaseState")
			return

		# Exit if player is far
		if not enemy.player or enemy._distance_to_player() > enemy.ATTACK_RANGE * 2.5:
			enemy.transition_to("KnightChaseState")
			return

	func _on_blocked_attack() -> void:
		# 当格挡成功时调用
		is_being_knocked_back = true
		var knockback_dir = -enemy.facing_direction
		knockback_velocity = Vector2(knockback_dir * 80.0, -40.0)

		# 播放格挡音效
		_play_block_sound()

		# 播放格挡动画
		enemy.no_attack_sprite.play("shield raise")
		current_anim = "shield raise"

		# 播放火花特效
		_play_block_spark_effect()

	func _play_block_sound() -> void:
		var block_sounds = [
			"res://assets/audio/ui/block-sound-1.ogg",
			"res://assets/audio/ui/block-sound-3.ogg"
		]
		var random_sound = block_sounds[randi() % block_sounds.size()]
		# Check if AudioManager exists (autoload scripts may not be available in headless mode)
		var audio_manager = enemy.get_tree().root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx(load(random_sound))

	func _play_block_spark_effect() -> void:
		# 播放格挡火花特效
		if not enemy.effects_sprite:
			return

		# 确保特效可见
		enemy.effects_sprite.visible = true

		# 根据Boss朝向调整特效位置（Boss身前）
		# Boss面向右(flip_h=false)时，特效在右侧
		# Boss面向左(flip_h=true)时，特效在左侧
		var spark_offset = Vector2(8, 0)  # 在Boss前方8像素处

		# 添加随机位置扰动（±4像素），让每次格挡的火花位置略有不同
		var random_jitter = Vector2(
			randf_range(-4.0, 4.0),  # x轴随机偏移
			randf_range(-4.0, 4.0)   # y轴随机偏移
		)

		if enemy.no_attack_sprite.flip_h:
			# 面向左，特效在左侧
			enemy.effects_sprite.position = Vector2(-4, -1) + Vector2(-spark_offset.x, spark_offset.y) + random_jitter
			enemy.effects_sprite.flip_h = false
		else:
			# 面向右，特效在右侧
			enemy.effects_sprite.position = Vector2(-4, -1) + spark_offset + random_jitter
			enemy.effects_sprite.flip_h = false

		# 播放default动画（火花特效）
		enemy.effects_sprite.play("default")

		# 动画播放完成后隐藏特效
		if not enemy.effects_sprite.animation_finished.is_connected(_on_spark_animation_finished):
			enemy.effects_sprite.animation_finished.connect(_on_spark_animation_finished)

	func _on_spark_animation_finished() -> void:
		# 特效动画完成后停止并隐藏
		if enemy.effects_sprite and is_instance_valid(enemy.effects_sprite):
			enemy.effects_sprite.stop()
			enemy.effects_sprite.visible = false

	func physics_update(delta: float) -> void:
		if not is_being_knocked_back:
			# 格挡时可以移动，应用重力
			enemy.velocity.y += enemy.GRAVITY * delta
			enemy.move_and_slide()
		else:
			# 击退时应用重力
			knockback_velocity.y += enemy.GRAVITY * delta
			enemy.move_and_slide()

	func exit() -> void:
		enemy.is_blocking = false
		enemy.block_cooldown = 2.0  # 2 seconds cooldown


# ============================================================
# KnightJumpState - Jump toward player for attack
# ============================================================
class KnightJumpState extends State:
	var jump_height: float = 300.0  # 增加跳跃高度
	var jump_horizontal_speed: float = 200.0  # 大幅增加水平速度
	var jump_direction: int = 0
	var has_landed: bool = false
	var attack_after_landing: bool = false
	var was_on_floor: bool = false  # 用于检测刚落地
	var land_timer: float = 0.0
	var land_delay: float = 0.15  # 落地后延迟0.15秒再攻击

	func enter() -> void:
		enemy.is_rolling = false
		enemy.is_blocking = false
		has_landed = false
		attack_after_landing = true
		was_on_floor = enemy.is_on_floor()
		land_timer = 0.0

		# 确定跳跃方向（朝向玩家）
		if enemy.player:
			var dir_to_player = enemy._direction_to_player()
			jump_direction = 1 if dir_to_player > 0 else -1
		else:
			jump_direction = enemy.facing_direction

		# 确保精灵可见性
		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# 设置跳跃速度：水平朝着玩家，垂直向上
		enemy.velocity = Vector2(jump_direction * jump_horizontal_speed, -jump_height)

		# 立即播放jump动画
		enemy.no_attack_sprite.play("jump")

	func update(delta: float) -> void:
		# 持续根据垂直速度播放动画（未落地时）
		if not has_landed:
			if enemy.velocity.y < 0:
				# 上升阶段 - jump动画
				if enemy.no_attack_sprite.animation != "jump":
					enemy.no_attack_sprite.play("jump")
			elif enemy.velocity.y > 0:
				# 下降阶段 - fall动画
				if enemy.no_attack_sprite.animation != "fall":
					enemy.no_attack_sprite.play("fall")

		# 检测刚落地的瞬间（从空中变为地面）
		var is_now_on_floor = enemy.is_on_floor()

		if not was_on_floor and is_now_on_floor:
			# 刚落地，播放idle动画
			enemy.no_attack_sprite.play("idle")
			has_landed = true

		was_on_floor = is_now_on_floor

		# 落地后延迟一段时间再攻击
		if has_landed:
			land_timer += delta
			if land_timer >= land_delay:
				# 延迟结束，转换到攻击或追击状态
				if attack_after_landing and enemy.attack_cooldown_timer <= 0.0:
					enemy.transition_to("KnightAttackState")
				else:
					enemy.transition_to("KnightChaseState")
				return

	func physics_update(delta: float) -> void:
		# 应用重力
		enemy.velocity.y += enemy.GRAVITY * delta

		# 保持水平速度（确保持续朝着玩家方向移动）
		if not has_landed:
			enemy.velocity.x = jump_direction * jump_horizontal_speed
		else:
			# 落地后停止水平移动
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 500.0 * delta)

		enemy.move_and_slide()

	func exit() -> void:
		# 可以在这里添加落地特效
		pass


# ============================================================
# KnightHurtState - Override for phase transition
# ============================================================
class KnightHurtState extends HurtState:

	func enter() -> void:
		# Normal hurt behavior - ensure correct sprite is visible
		enemy.is_rolling = false
		enemy.is_blocking = false
		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# 强制播放受伤动画
		enemy.no_attack_sprite.stop()
		enemy.no_attack_sprite.play("hurt")
		enemy.no_attack_sprite.frame = 0

		# Set hurt velocity
		enemy.velocity = enemy.hurt_knockback

		hurt_timer = enemy.HURT_DURATION

		# Check for phase transition after taking damage
		_check_phase_transition()

	func update(delta: float) -> void:
		hurt_timer -= delta

		# 处理普通受伤的击退缓停
		if hurt_timer < enemy.HURT_DURATION * 0.5:
			# 后半段逐渐减速
			var slow_factor = hurt_timer / (enemy.HURT_DURATION * 0.5)
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, delta * 500.0)

		if hurt_timer <= 0.0:
			if enemy.hp <= 0:
				enemy.transition_to("DeathState")
			else:
				# 优先检查是否需要进入二阶段转换
				_check_phase_transition()
				# 如果没有进入转换，正常转换到追击或巡逻
				if not enemy.is_transitioning:
					if enemy.player and enemy._distance_to_player() < enemy.DETECT_RANGE:
						enemy.transition_to("KnightChaseState")
					else:
						enemy.transition_to("KnightPatrolState")

	func physics_update(delta: float) -> void:
		enemy.velocity.y += enemy.GRAVITY * delta
		enemy.move_and_slide()

	func _check_phase_transition() -> void:
		var hp_percent = float(enemy.hp) / float(enemy.MAX_HP)
		print("=== _check_phase_transition() called ===")
		print("HP: ", enemy.hp, " / ", enemy.MAX_HP, " (", hp_percent * 100, "%)")
		print("boss_phase: ", enemy.boss_phase)
		print("is_transitioning: ", enemy.is_transitioning)

		if hp_percent <= 0.5 and enemy.boss_phase == 1 and not enemy.is_transitioning:
			print("Triggering KnightPhaseTransitionState from KnightHurtState!")
			# Transition to Phase 2 with animation!
			enemy.transition_to("KnightPhaseTransitionState")
		else:
			print("Phase transition conditions not met")


# ============================================================
# KnightPhaseTransitionState - Phase 1 to Phase 2 transition
# ============================================================
class KnightPhaseTransitionState extends State:
	var transition_timer: float = 0.0
	var transition_duration: float = 5.0  # 持续5秒
	var animation_finished: bool = false
	var screen_shake_started: bool = false
	var shake_tween: Tween  # 用于缓入缓出震动
	var current_shake_intensity: float = 0.0  # 当前震动强度

	func enter() -> void:
		print("=== KnightPhaseTransitionState.enter() called ===")
		enemy.is_transitioning = true
		enemy.is_rolling = false
		enemy.is_blocking = false
		transition_timer = 0.0
		animation_finished = false
		screen_shake_started = false
		current_shake_intensity = 0.0

		# 停止移动
		enemy.velocity = Vector2.ZERO

		# 确保精灵可见性
		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		print("Attempting to play 'second_stage' animation...")
		print("Available animations: ", enemy.no_attack_sprite.sprite_frames.get_animation_names())

		# 强制播放二阶段转换动画
		enemy.no_attack_sprite.stop()
		enemy.no_attack_sprite.play("second_stage")
		enemy.no_attack_sprite.frame = 0

		print("Animation started: ", enemy.no_attack_sprite.animation)

		# 播放战吼音效
		_play_roar_sound()

		# 播放二阶段BGM（在战吼动画开始时就开始播放）
		_play_phase_2_bgm()

		# 连接动画完成信号
		if not enemy.no_attack_sprite.animation_finished.is_connected(_on_animation_finished):
			enemy.no_attack_sprite.animation_finished.connect(_on_animation_finished)

	func update(delta: float) -> void:
		transition_timer += delta

		# 启动屏幕震动（从转换开始时就震动）
		if not screen_shake_started:
			_start_eased_screen_shake()
			screen_shake_started = true

		# 检查动画是否完成（通过帧数检查）
		if not animation_finished:
			var current_frame = enemy.no_attack_sprite.frame
			var total_frames = enemy.no_attack_sprite.sprite_frames.get_frame_count("second_stage")
			if current_frame >= total_frames - 1:
				animation_finished = true
				print("Animation finished via frame check, total frames: ", total_frames)
				# 动画完成后，保持在最后一帧
				enemy.no_attack_sprite.pause()

		# 5秒后才进入二阶段
		if transition_timer >= transition_duration:
			print("Transition complete, entering Phase 2")
			_stop_screen_shake()
			enemy.boss_phase = 2  # 正式进入二阶段
			enemy.transition_to("KnightChaseState")
			return

	func physics_update(delta: float) -> void:
		# 转换期间不移动，只应用重力
		enemy.velocity.y += enemy.GRAVITY * delta
		enemy.velocity.x = 0.0
		enemy.move_and_slide()

	func exit() -> void:
		print("=== KnightPhaseTransitionState.exit() called ===")
		_stop_screen_shake()
		enemy.is_transitioning = false
		if enemy.no_attack_sprite.animation_finished.is_connected(_on_animation_finished):
			enemy.no_attack_sprite.animation_finished.disconnect(_on_animation_finished)

	func _on_animation_finished() -> void:
		print("=== _on_animation_finished() called ===")
		animation_finished = true
		# 动画完成后，暂停在最后一帧
		enemy.no_attack_sprite.pause()

	func _play_phase_2_bgm() -> void:
		# AudioManager 是 autoload 单例，通过 /root/ 路径访问
		var audio_manager = enemy.get_node("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_bgm"):
			print("=== Playing Phase 2 BGM ===")
			# 不使用渐变，立即切换（避免渐变过程中出现的问题）
			audio_manager.play_bgm("boss_phase_2", 0)
		else:
			print("ERROR: AudioManager not found or has no play_bgm method")

	func _start_eased_screen_shake() -> void:
		# 使用Tween实现缓入缓出的震动效果
		shake_tween = enemy.create_tween()
		shake_tween.set_parallel(false)

		# 缓入：前1.5秒从0逐渐增加到4.0
		shake_tween.tween_method(_apply_shake_intensity, 0.0, 4.0, 1.5)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

		# 保持最大强度2秒
		shake_tween.tween_method(_apply_shake_intensity, 4.0, 4.0, 2.0)

		# 缓出：最后1.5秒从4.0逐渐减小到0
		shake_tween.tween_method(_apply_shake_intensity, 4.0, 0.0, 1.5)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

		print("Started eased screen shake (fade in: 1.5s, hold: 2s, fade out: 1.5s)")

	func _apply_shake_intensity(intensity: float) -> void:
		# 使用当前强度触发震动
		current_shake_intensity = intensity
		var combat_feedback = enemy.get_tree().root.get_node_or_null("CombatFeedback")
		if combat_feedback and combat_feedback.has_method("trigger_screen_shake"):
			# 使用较小的时间间隔来实现连续震动效果
			combat_feedback.trigger_screen_shake(intensity, 0.1)

	func _stop_screen_shake() -> void:
		if shake_tween and shake_tween.is_valid():
			shake_tween.kill()
			shake_tween = null
		current_shake_intensity = 0.0
		print("Stopped eased screen shake")

	func _play_roar_sound() -> void:
		print("=== _play_roar_sound() called ===")
		var audio_manager = enemy.get_tree().root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			# 直接播放战吼音效
			var roar_sound = load("res://assets/audio/enemy/roar.ogg")
			if roar_sound:
				audio_manager.play_sfx(roar_sound)
				print("Playing roar sound using AudioManager")
			else:
				print("Failed to load roar sound")
		else:
			print("AudioManager not found or has no play_sfx method")


# ============================================================
# Lifecycle & State Transitions
# ============================================================
func _ready() -> void:
	# Boss parameters
	MAX_HP = 30
	DETECT_RANGE = 160.0
	PATROL_SPEED = 20.0
	CHASE_SPEED = 60.0
	ATTACK_RANGE = 32.0
	ATTACK_COOLDOWN = 1.0
	KNOCKBACK_FORCE = 100.0
	HURT_DURATION = 0.35

	# Initialize phase - 从一阶段开始
	boss_phase = 1  # 从一阶段开始
	combo_count = 0

	# Call parent ready FIRST (this initializes @onready variables)
	super._ready()

	# Override sprite references AFTER parent ready
	animated_sprite_2d = no_attack_sprite

	# Start in patrol state
	current_state = KnightPatrolState.new(self)
	current_state.enter()

func transition_to(target_state_name: String) -> void:
	if current_state:
		current_state.exit()

	match target_state_name:
		"KnightPatrolState", "PatrolState":
			current_state = KnightPatrolState.new(self)
		"KnightChaseState", "ChaseState":
			current_state = KnightChaseState.new(self)
		"KnightAttackState", "AttackState":
			current_state = KnightAttackState.new(self)
		"KnightBlockState", "BlockState":
			current_state = KnightBlockState.new(self)
		"KnightRollState", "RollState":
			current_state = KnightRollState.new(self)
		"KnightJumpState", "JumpState":
			current_state = KnightJumpState.new(self)
		"KnightPhaseTransitionState", "PhaseTransitionState":
			current_state = KnightPhaseTransitionState.new(self)
		"HurtState":
			current_state = KnightHurtState.new(self)
		"DeathState":
			current_state = KnightDeathState.new(self)  # 使用KnightDeathState

	current_state.enter()

func _process(delta: float) -> void:
	# Update cooldowns
	if roll_cooldown > 0.0:
		roll_cooldown -= delta
	if block_cooldown > 0.0:
		block_cooldown -= delta

	# Check phase transition - 在任何状态下都可能触发（通过HurtState已经处理）
	# 这里只处理非受伤状态下的转换
	if hp <= MAX_HP * 0.5 and boss_phase == 1 and not is_transitioning:
		print("=== _process() phase transition check ===")
		print("HP: ", hp, " / ", MAX_HP, " (50% = ", MAX_HP * 0.5, ")")
		print("boss_phase: ", boss_phase)
		print("is_transitioning: ", is_transitioning)
		print("current_state: ", current_state)
		if current_state:
			print("current_state is KnightHurtState: ", current_state is KnightHurtState)

		if current_state and not (current_state is KnightHurtState):
			# 如果不在受伤状态，立即触发转换
			print("Triggering KnightPhaseTransitionState from _process()")
			transition_to("KnightPhaseTransitionState")

	# Call parent process
	super._process(delta)

# Override take_damage to handle blocking and rolling invincibility
func take_damage(knockback_dir: int) -> void:
	# Check if transitioning to Phase 2 - 完全无敌
	if is_transitioning:
		# 转换期间完全无视攻击，不触发任何效果
		return

	# Check if rolling (Phase 1) - 无敌，不受伤害和击退，不触发任何打击效果
	if is_rolling:
		# 翻滚时完全无视攻击，直接返回，不触发任何音效或震动
		return

	# Check if blocking (Phase 2) - 无敌，只受击退，不扣血
	if is_blocking:
		# 打击顿帧效果（即使格挡也要有打击感）
		var combat_feedback = get_tree().root.get_node_or_null("CombatFeedback")
		if combat_feedback and combat_feedback.has_method("trigger_hit_stop"):
			combat_feedback.trigger_hit_stop(0.04, 1.2, 0.1)

		# 播放格挡音效
		var audio_manager = get_tree().root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			var block_sounds = [
				"res://assets/audio/ui/block-sound-1.ogg",
				"res://assets/audio/ui/block-sound-3.ogg"
			]
			var random_sound = block_sounds[randi() % block_sounds.size()]
			audio_manager.play_sfx(load(random_sound))

		# 设置击退速度，但不扣血，不转换状态
		velocity = Vector2(knockback_dir * KNOCKBACK_FORCE, -80.0)

		# 通知KnightBlockState开始处理击退
		if current_state and current_state is KnightBlockState:
			current_state._on_blocked_attack()
		return

	# Normal damage - call parent to reduce HP and enter hurt state
	super.take_damage(knockback_dir)

	# 更新boss血条
	_update_boss_health_bar()

# Override deal_damage_to_player for boss damage scaling
func deal_damage_to_player() -> void:
	if has_dealt_damage:
		return
	if not player:
		return
	if player.get("is_dead") == true:
		return

	var h_dist: float = absf(global_position.x - player.global_position.x)
	var v_dist: float = absf(global_position.y - player.global_position.y)
	if h_dist > ATTACK_RANGE or v_dist > 20.0:
		return

	var dir_to_player: float = _direction_to_player()
	var facing_right: bool = not no_attack_sprite.flip_h
	if facing_right and dir_to_player < -5.0:
		return
	if not facing_right and dir_to_player > 5.0:
		return

	if player.has_method("is_invincible") and player.is_invincible():
		return

	# Boss deals more damage in Phase 2
	var damage_multiplier = 1.0 if boss_phase == 1 else 1.3
	if player.has_method("take_hurt"):
		player.take_hurt(facing_direction, KNOCKBACK_FORCE * damage_multiplier)

		# 打击顿帧效果
		var combat_feedback = get_tree().root.get_node_or_null("CombatFeedback")
		if combat_feedback and combat_feedback.has_method("trigger_hit_stop"):
			combat_feedback.trigger_hit_stop(0.06, 1.8, 0.15)

		# 播放攻击音效
		var sfx_list := _get_attack_sfx()
		if sfx_list.size() > 0:
			var audio_manager = get_tree().root.get_node_or_null("AudioManager")
			if audio_manager and audio_manager.has_method("play_sfx"):
				audio_manager.play_sfx(sfx_list[randi() % sfx_list.size()])

		has_dealt_damage = true

func _get_attack_sfx() -> Array[AudioStream]:
	return []  # Add boss attack SFX here

# ============================================================
# Boss Health Bar Management
# ============================================================
func _update_boss_health_bar() -> void:
	if boss_health_bar and boss_health_bar.has_method("update_boss_health"):
		boss_health_bar.update_boss_health(hp)

func _hide_boss_health_bar() -> void:
	if boss_health_bar and boss_health_bar.has_method("hide_health_bar"):
		boss_health_bar.hide_health_bar()

	# 重置引用
	boss_health_bar = null


# ============================================================
# KnightDeathState - Override for dual sprite system
# ============================================================
class KnightDeathState extends DeathState:
	var wait_after_anim: float = 0.0
	var wait_duration: float = 2.0  # 死亡动画完成后等待2秒再消失
	var animation_ended: bool = false  # 标记动画是否结束

	func enter() -> void:
		enemy.is_dead = true
		enemy.velocity = Vector2.ZERO
		death_finished = false
		wait_after_anim = 0.0
		animation_ended = false

		# 隐藏boss血条
		if enemy.has_method("_hide_boss_health_bar"):
			enemy._hide_boss_health_bar()

		# 确保使用正确的精灵（no_attack_sprite）
		enemy.attack_sprite.visible = false
		enemy.no_attack_sprite.visible = true
		enemy.no_attack_sprite.flip_h = enemy.facing_direction < 0

		# 检查是否有die动画，如果没有则使用hurt动画
		var has_die_anim = enemy.no_attack_sprite.sprite_frames.has_animation("die")
		var death_anim = "die" if has_die_anim else "hurt"

		# 播放死亡动画
		enemy.no_attack_sprite.stop()
		enemy.no_attack_sprite.play(death_anim)

		if enemy.collision_shape_2d:
			enemy.collision_shape_2d.set_deferred("disabled", true)

		# 连接动画完成信号
		if not enemy.no_attack_sprite.animation_finished.is_connected(_on_death_anim_finished):
			enemy.no_attack_sprite.animation_finished.connect(_on_death_anim_finished)

		# Boss被击败，播放胜利音效并显示祝贺界面
		_show_victory_screen()

	func _show_victory_screen() -> void:
		print("=== Boss Defeated! Showing Victory Screen ===")

		# 播放胜利音效
		var audio_manager = enemy.get_node("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			var victory_sfx = load("res://assets/audio/ui/powerUp1.ogg")
			if victory_sfx:
				audio_manager.play_sfx(victory_sfx)

		# 停止BGM
		if audio_manager and audio_manager.has_method("stop_bgm"):
			audio_manager.stop_bgm(0)

		# 创建胜利界面（函数内部会添加到场景树）
		_create_victory_ui()

	func _create_victory_ui() -> Control:
		# 创建CanvasLayer确保UI固定在屏幕上（不受Camera2D影响）
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100  # 确保在最上层
		enemy.get_tree().root.add_child(canvas_layer)

		var root = Control.new()
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas_layer.add_child(root)

		# 半透明黑色背景
		var bg = ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0, 0, 0, 0.7)
		root.add_child(bg)

		# 加载像素字体
		var pixel_font = load("res://assets/fonts/PressStart2P-Regular.ttf")

		# "CONGRATULATION" 标签（使用锚点居中）
		var title = Label.new()
		title.text = "CONGRATULATION"
		title.add_theme_font_override("font", pixel_font)
		title.add_theme_font_size_override("font_size", 48)
		title.add_theme_color_override("font_color", Color(1, 0.84, 0))  # 金色
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# 使用锚点和边距居中（不依赖绝对位置）
		title.set_anchors_preset(Control.PRESET_CENTER)
		title.set_offset(SIDE_LEFT, -400)
		title.set_offset(SIDE_TOP, -50)
		title.set_offset(SIDE_RIGHT, 400)
		title.set_offset(SIDE_BOTTOM, 50)
		root.add_child(title)

		# 在enemy被释放前获取AudioManager和SceneTree引用
		var audio_manager = enemy.get_node("/root/AudioManager")
		var scene_tree = enemy.get_tree()

		# 4秒后返回主菜单
		var timer = root.create_tween()
		timer.tween_interval(4.0)
		timer.tween_callback(func():
			# 先清理CanvasLayer（避免残留）
			if is_instance_valid(canvas_layer):
				canvas_layer.queue_free()
			# 播放菜单BGM并切换到主菜单
			if audio_manager and audio_manager.has_method("play_bgm"):
				audio_manager.play_bgm("warm_fantasy_rpg_menu", 0)
			if scene_tree:
				scene_tree.change_scene_to_file("res://scenes/ui/main_menu.tscn")
		)

		return root

	func exit() -> void:
		if enemy.no_attack_sprite.animation_finished.is_connected(_on_death_anim_finished):
			enemy.no_attack_sprite.animation_finished.disconnect(_on_death_anim_finished)

	func update(delta: float) -> void:
		# 如果动画播放完成，开始等待
		if animation_ended and not death_finished:
			wait_after_anim += delta
			if wait_after_anim >= wait_duration:
				death_finished = true
				enemy.queue_free()

	func physics_update(_delta: float) -> void:
		pass

	func _on_death_anim_finished() -> void:
		if not animation_ended:
			animation_ended = true
			# 动画播放完成，等待一段时间后再消失
