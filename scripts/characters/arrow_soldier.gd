extends EnemyBase

var _attack_sfx: Array[AudioStream] = [
	preload("res://assets/audio/enemy/sword_1.wav"),
	preload("res://assets/audio/enemy/sword_2.wav"),
]


# ---------- ChaseState ----------
class ArrowSoldierChaseState extends State:
	func enter() -> void:
		enemy.has_dealt_damage = false

	func update(_delta: float) -> void:
		if not enemy.player:
			enemy.transition_to("ArrowSoldierPatrolState")
			return
		var dist: float = enemy._distance_to_player()
		if dist > enemy.DETECT_RANGE:
			enemy.transition_to("ArrowSoldierPatrolState")
			return
		if dist < enemy.ATTACK_RANGE and enemy.attack_cooldown_timer <= 0.0:
			enemy.velocity.x = 0.0
			enemy.transition_to("ArrowSoldierAttackState")
			return
		enemy._face_player()
		enemy.animated_sprite_2d.play("move")
		enemy.velocity.x = enemy.facing_direction * enemy.CHASE_SPEED

	func physics_update(delta: float) -> void:
		enemy._apply_gravity(delta)


# ---------- AttackState ----------
class ArrowSoldierAttackState extends State:
	func enter() -> void:
		enemy.has_dealt_damage = false
		enemy.velocity.x = 0.0
		enemy._face_player()
		enemy.animated_sprite_2d.play("attack")

	func update(_delta: float) -> void:
		if not enemy.has_dealt_damage and enemy.animated_sprite_2d.frame >= 3:
			enemy.deal_damage_to_player()

	func physics_update(delta: float) -> void:
		enemy._apply_gravity(delta)


# ============================================================
# 生命周期 & 状态转换
# ============================================================
func _ready() -> void:
	MAX_HP = 4
	DETECT_RANGE = 130.0
	PATROL_SPEED = 16.0
	CHASE_SPEED = 40.0
	ATTACK_RANGE = 32.0
	ATTACK_COOLDOWN = 1.2
	KNOCKBACK_FORCE = 120.0
	HURT_DURATION = 0.4
	super._ready()
	current_state = PatrolState.new(self)
	current_state.enter()

func transition_to(target_state_name: String) -> void:
	if current_state:
		current_state.exit()
	match target_state_name:
		"ArrowSoldierPatrolState":
			current_state = PatrolState.new(self)
		"ArrowSoldierChaseState":
			current_state = ArrowSoldierChaseState.new(self)
		"ArrowSoldierAttackState":
			current_state = ArrowSoldierAttackState.new(self)
		"HurtState":
			current_state = HurtState.new(self)
		"DeathState":
			current_state = DeathState.new(self)
		"PatrolState":
			current_state = PatrolState.new(self)
		"ChaseState":
			current_state = ArrowSoldierChaseState.new(self)
	current_state.enter()

func _process(delta: float) -> void:
	super._process(delta)
	if animated_sprite_2d.animation == "attack" and animated_sprite_2d.is_playing() and not animated_sprite_2d.is_connected("animation_finished", _on_attack_finished):
		animated_sprite_2d.animation_finished.connect(_on_attack_finished)

func _on_attack_finished() -> void:
	if is_instance_valid(self) and current_state is ArrowSoldierAttackState:
		attack_cooldown_timer = ATTACK_COOLDOWN
		transition_to("ArrowSoldierChaseState")

func _get_attack_sfx() -> Array[AudioStream]:
	return _attack_sfx
