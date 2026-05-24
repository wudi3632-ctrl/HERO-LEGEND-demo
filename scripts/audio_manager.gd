extends Node

# BGM 音频播放器
# 管理背景音乐的淡入淡出和切换

signal bgm_changed(track_name: String)

var bgm_player: AudioStreamPlayer
var current_bgm: String = ""
var bgm_volume: float = 0.7
var is_fading: bool = false
var _current_fade_tween: Tween = null

# SFX 系统
var sfx_volume: float = 0.7
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 8

# UI 按钮音效
var _ui_hover_sfx: AudioStream = preload("res://assets/audio/ui/switch14.ogg")
var _ui_click_sfx: AudioStream = preload("res://assets/audio/ui/select_008.ogg")

# 文件名映射表 (代码名称 -> 实际文件名)
var bgm_file_map: Dictionary = {
	"warm_fantasy_rpg_menu": "Warm Fantasy RPG Menu Theme",
	"pixel_adventure_action": "Pixel Adventure Action BGM",
	"boss_entrance": "Boss Entrance Cinematic Theme",
	"boss_phase_2": "High-Energy Action Combat Loop"
}

func _ready():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)
	# 自动为所有按钮连接hover/click音效
	get_tree().node_added.connect(_on_node_added)
	# 扫描已在树中的按钮（解决首次加载主菜单时按钮无音效的问题）
	call_deferred("_connect_existing_buttons")
	# 初始化SFX播放器池
	for i in _sfx_pool_size:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_%d" % i
		sfx_player.bus = "Master"
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)

# 播放 BGM
func play_bgm(track_name: String, fade_duration: float = 1.0):
	print("=== AudioManager.play_bgm() ===")
	print("  track_name: ", track_name)
	print("  current_bgm: ", current_bgm)
	print("  bgm_player.playing: ", bgm_player.playing)
	print("  is_fading: ", is_fading)

	# 只在完全相同且稳定的情况下才跳过（不在淡入淡出期间）
	if current_bgm == track_name and bgm_player.playing and not is_fading:
		# BGM已经在播放，不需要重新播放
		print("  Skipping: BGM already playing")
		return

	# 如果正在淡入淡出，先停止当前的tween
	if is_fading or _current_fade_tween != null:
		# 强制停止当前的淡入淡出
		_kill_fade_tween()
		is_fading = false
		print("  Killed previous fade transition")

	var stream = load_bgm(track_name)
	if stream == null:
		push_error("Failed to load BGM: " + track_name)
		return

	print("  BGM loaded successfully, playing with fade_duration: ", fade_duration)
	if fade_duration > 0:
		_fade_transition(stream, track_name, fade_duration)
	else:
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_player.play()
		current_bgm = track_name
		bgm_changed.emit(track_name)

# 加载 BGM 文件
func load_bgm(track_name: String) -> AudioStream:
	var actual_filename = bgm_file_map.get(track_name, track_name)
	var extensions = [".mp3", ".ogg", ".wav"]

	var paths_to_try: Array[String] = [
		"res://assets/audio/bgm/%s" % actual_filename,
		"res://assets/audio/bgm/%s" % actual_filename.to_lower(),
		"res://assets/audio/bgm/%s" % track_name.replace("_", " ").capitalize(),
	]

	for base_path in paths_to_try:
		for ext in extensions:
			var path: String = base_path + ext
			if ResourceLoader.exists(path):
				return _load_audio_file(path)

	push_warning("未找到BGM文件: %s" % track_name)
	return null

# 加载音频文件
func _load_audio_file(path: String) -> AudioStream:
	if path.ends_with(".mp3"):
		var stream = load(path) as AudioStreamMP3
		if stream:
			stream.loop = true
		return stream
	elif path.ends_with(".ogg"):
		var stream = load(path) as AudioStreamOggVorbis
		if stream:
			stream.loop = true
		return stream
	elif path.ends_with(".wav"):
		var stream = load(path) as AudioStreamWAV
		if stream:
			stream.loop = false
		return stream
	return null

# 淡入淡出过渡
func _fade_transition(new_stream: AudioStream, new_track: String, duration: float):
	is_fading = true

	# 先杀死任何现有的tween
	_kill_fade_tween()

	var tween = create_tween()
	_current_fade_tween = tween
	tween.set_parallel(false)

	# 淡出
	if bgm_player.playing:
		tween.parallel().tween_property(bgm_player, "volume_db", -60, duration * 0.5)
		tween.tween_callback(_stop_current_bgm)

	# 淡入
	bgm_player.stream = new_stream
	bgm_player.volume_db = -60
	bgm_player.play()
	current_bgm = new_track

	tween.parallel().tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume), duration * 0.5)
	tween.tween_callback(_on_fade_complete)

	bgm_changed.emit(new_track)

func _on_fade_complete():
	is_fading = false
	_current_fade_tween = null

func _stop_current_bgm():
	bgm_player.stop()

func _on_bgm_finished():
	# 循环播放（如果流不支持loop属性），current_bgm为空时不循环（如死亡界面Loser.wav）
	if current_bgm != "" and bgm_player.stream != null:
		bgm_player.play()

# 停止 BGM
func stop_bgm(fade_duration: float = 0.5):
	print("=== AudioManager.stop_bgm() ===")
	print("  fade_duration: ", fade_duration)

	# 立即更新状态，避免与新播放请求冲突
	current_bgm = ""
	is_fading = false

	# 杀死任何现有的淡入淡出tween
	_kill_fade_tween()

	if fade_duration > 0:
		var tween = create_tween()
		_current_fade_tween = tween
		tween.tween_property(bgm_player, "volume_db", -60, fade_duration)
		tween.tween_callback(_on_stop_fade_complete)
	else:
		_stop_current_bgm()

func _on_stop_fade_complete():
	_stop_current_bgm()
	_current_fade_tween = null

# 杀死当前正在运行的淡入淡出tween
func _kill_fade_tween():
	if _current_fade_tween != null and _current_fade_tween.is_valid():
		_current_fade_tween.kill()
		_current_fade_tween = null
		print("  Killed existing fade tween")

# 暂停 BGM
func pause_bgm():
	bgm_player.stream_paused = true

# 恢复 BGM
func resume_bgm():
	bgm_player.stream_paused = false

# 设置BGM音量 (0.0 - 1.0)
func set_volume(volume: float):
	bgm_volume = clamp(volume, 0.0, 1.0)
	if bgm_player.stream != null:
		bgm_player.volume_db = linear_to_db(bgm_volume)

# 播放SFX音效（从对象池中获取空闲播放器）
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume)
			player.play()
			return
	# 池满时复用第一个
	var player = _sfx_pool[0]
	player.stop()
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.play()

# 设置SFX音量 (0.0 - 1.0)
func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)

# 获取当前BGM名称
func get_current_bgm() -> String:
	return current_bgm


# ============================================================
# UI 按钮音效（自动连接）
# ============================================================
func _on_node_added(node: Node) -> void:
	if node is Button:
		_connect_button_sfx(node)

# 为单个按钮连接音效（防止重复连接）
func _connect_button_sfx(btn: Button) -> void:
	if btn.has_meta("_sfx_connected"):
		return
	btn.set_meta("_sfx_connected", true)
	btn.mouse_entered.connect(play_sfx.bind(_ui_hover_sfx))
	btn.pressed.connect(play_sfx.bind(_ui_click_sfx))

# 扫描场景树中已有的按钮并连接音效
func _connect_existing_buttons() -> void:
	var buttons = get_tree().get_nodes_in_group("Button") if get_tree().has_group("Button") else []
	# get_nodes_in_group 对内置类型不可靠，用递归遍历
	_scan_buttons(get_tree().root)

func _scan_buttons(node: Node) -> void:
	if node is Button:
		_connect_button_sfx(node)
	for child in node.get_children():
		_scan_buttons(child)
