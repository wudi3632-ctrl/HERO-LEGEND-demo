extends Control

# ============================================================
# 死亡界面（独立场景，类似主菜单）
# ============================================================

var player_sprite: AnimatedSprite2D
var continue_button: Button
var exit_button: Button

# 复活动画状态: 0=无, 1=播放die_reverse, 2=播放idle等待
var _revive_phase: int = 0
var _revive_timer: float = 0.0

var _rebirth_sfx: AudioStream = preload("res://assets/audio/ui/rebirth.ogg")


func _ready() -> void:
	_build_ui()
	_setup_player_sprite()
	_show_death_pose()
	# 播放死亡BGM（替换关卡BGM，播放一次后停止）
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.bgm_player:
		audio_manager.bgm_player.stop()
		audio_manager.bgm_player.stream = load("res://assets/audio/ui/Loser.wav")
		audio_manager.bgm_player.volume_db = linear_to_db(audio_manager.bgm_volume)
		audio_manager.bgm_player.play()
		audio_manager.current_bgm = ""  # 防止_on_bgm_finished循环播放


func _process(delta: float) -> void:
	if _revive_phase == 1:
		if not player_sprite.is_playing():
			player_sprite.play("idle")
			_revive_phase = 2
			_revive_timer = 0.0
	elif _revive_phase == 2:
		_revive_timer += delta
		if _revive_timer >= 1.5:
			_revive_phase = 0
			# 立即停止当前BGM（无淡出，避免与新场景BGM冲突）
			var audio_manager = get_node_or_null("/root/AudioManager")
			if audio_manager:
				audio_manager.stop_bgm(0)
			# 重新开始当前关卡（场景会播放自己的BGM）
			var game_manager = get_node_or_null("/root/GameManager")
			if game_manager and game_manager.has_method("restart_current_level"):
				game_manager.restart_current_level()


func _build_ui() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	var center_x = vp_size.x / 2.0
	var center_y = vp_size.y / 2.0
	var pixel_font = load("res://assets/fonts/PressStart2P-Regular.ttf")

	# 深色背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# === 光束效果 ===
	var player_pos = Vector2(center_x, center_y - 30)

	# 从上方射下的锥形光束（上窄下宽，以玩家x为中心）
	var beam = Polygon2D.new()
	var beam_top_half_w = 15.0
	var beam_bot_half_w = 55.0
	beam.position = Vector2(player_pos.x, 0.0)
	beam.polygon = PackedVector2Array([
		Vector2(-beam_top_half_w, player_pos.y - 600.0),
		Vector2(beam_top_half_w, player_pos.y - 600.0),
		Vector2(beam_bot_half_w, player_pos.y + 35.0),
		Vector2(-beam_bot_half_w, player_pos.y + 35.0),
	])
	beam.vertex_colors = PackedColorArray([
		Color(1, 1, 1, 0.3),
		Color(1, 1, 1, 0.3),
		Color(1, 1, 1, 0.5),
		Color(1, 1, 1, 0.5),
	])
	add_child(beam)

	# 玩家脚下白色圆形光晕
	var circle = Polygon2D.new()
	var circle_pts = PackedVector2Array()
	var circle_radius = 55.0
	for i in range(64):
		var angle = i * 2.0 * PI / 64.0
		circle_pts.append(Vector2(cos(angle) * circle_radius, sin(angle) * circle_radius * 0.3))
	circle.polygon = circle_pts
	circle.color = Color(1, 1, 1, 1.0)
	circle.position = player_pos + Vector2(0, 35)
	add_child(circle)

	# "YOU ARE DIE" 标签
	var title = Label.new()
	title.text = "YOU ARE DIE"
	title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.position = Vector2(center_x - 280, center_y - 140)
	title.size = Vector2(560, 50)
	add_child(title)

	# 玩家精灵
	player_sprite = AnimatedSprite2D.new()
	player_sprite.position = Vector2(center_x, center_y - 30)
	player_sprite.scale = Vector2(4, 4)
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(player_sprite)

	# 按钮（主题从根节点.tscn继承）
	var btn_w = 180
	var btn_h = 45
	var btn_gap = 30
	var btn_y = center_y + 90

	continue_button = Button.new()
	continue_button.text = "CONTINUE"
	continue_button.add_theme_font_size_override("font_size", 11)
	continue_button.position = Vector2(center_x - btn_w - btn_gap / 2.0, btn_y)
	continue_button.size = Vector2(btn_w, btn_h)
	continue_button.pressed.connect(_on_continue)
	add_child(continue_button)

	exit_button = Button.new()
	exit_button.text = "EXIT"
	exit_button.add_theme_font_size_override("font_size", 11)
	exit_button.position = Vector2(center_x + btn_gap / 2.0, btn_y)
	exit_button.size = Vector2(btn_w, btn_h)
	exit_button.pressed.connect(_on_exit)
	add_child(exit_button)


func _setup_player_sprite() -> void:
	var sprite_sheet = load("res://assets/character/hero/SPRITE_SHEET.png")
	var frames = SpriteFrames.new()

	# die动画：10帧（y=192行）
	frames.add_animation("die")
	frames.set_animation_speed("die", 12.0)
	frames.set_animation_loop("die", false)
	for i in range(10):
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * 32.0, 192.0, 32.0, 32.0)
		frames.add_frame("die", atlas)

	# die_reverse：倒放的die动画
	frames.add_animation("die_reverse")
	frames.set_animation_speed("die_reverse", 12.0)
	frames.set_animation_loop("die_reverse", false)
	for i in range(9, -1, -1):
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * 32.0, 192.0, 32.0, 32.0)
		frames.add_frame("die_reverse", atlas)

	# idle动画：6帧（y=0行）
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_loop("idle", true)
	for i in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * 32.0, 0.0, 32.0, 32.0)
		frames.add_frame("idle", atlas)

	player_sprite.sprite_frames = frames


func _show_death_pose() -> void:
	player_sprite.play("die")
	var frame_count = player_sprite.sprite_frames.get_frame_count("die")
	player_sprite.pause()
	player_sprite.frame = frame_count - 1


func _on_continue() -> void:
	continue_button.disabled = true
	exit_button.disabled = true
	_revive_phase = 1
	player_sprite.play("die_reverse")
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(_rebirth_sfx)


func _on_exit() -> void:
	continue_button.disabled = true
	exit_button.disabled = true
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_bgm("warm_fantasy_rpg_menu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
