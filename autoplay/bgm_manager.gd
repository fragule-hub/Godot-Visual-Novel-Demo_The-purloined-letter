extends Node

## BGM 管理器（autoload 单例）
## 跨场景持久化 BGM 播放，不随 change_scene_to_file 中断。
## 直接订阅 KND_Settings.setting_changed 实时响应音量变化。

## BGM 淡出完成信号
signal bgm_fade_finished

var _player: AudioStreamPlayer
var _fade_tween: Tween
var _current_path: String = ""

## 缓存音量（从 KND_Settings 读取）
var _master_volume: float = 1.0
var _music_volume: float = 0.8


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "BgmPlayer"
	add_child(_player)

	# BGM 循环播放
	_player.finished.connect(func() -> void:
		_player.play()
	)

	# 订阅音量变化
	var mgr := get_node_or_null("/root/KND_Settings")
	if mgr and mgr.has_signal("setting_changed"):
		mgr.setting_changed.connect(_on_setting_changed)

	# 启动时加载音量
	_load_volume_from_settings()


## 从文件路径播放 BGM（标题界面等使用）
func play(path: String) -> void:
	if path.is_empty():
		return
	_current_path = path
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("BgmManager: 无法加载音频: %s" % path)
		return
	_play_stream_internal(stream)


## 播放已加载的 AudioStream（KND_AudioInterface 委托）
func play_stream(stream: AudioStream) -> void:
	if stream == null:
		return
	_current_path = ""  # 非路径加载，无 path
	_play_stream_internal(stream)


## 停止 BGM（可选淡出）
func stop(fade_duration: float = 0.3) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if fade_duration > 0.0 and _player.playing:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", -80.0, fade_duration)
		_fade_tween.finished.connect(func():
			_player.stop()
			bgm_fade_finished.emit()
		)
	else:
		_player.stop()
		bgm_fade_finished.emit()
	_current_path = ""


## 淡入淡出切换曲目
func fade_to(path: String, duration: float = 0.5) -> void:
	if path.is_empty():
		return
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("BgmManager: 无法加载音频: %s" % path)
		return

	# 先淡出当前
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	if _player.playing:
		var fade_out := create_tween()
		fade_out.tween_property(_player, "volume_db", -80.0, duration * 0.4)
		fade_out.finished.connect(func() -> void:
			_player.stop()
			_current_path = path
			_player.stream = stream
			_player.play()
			# 淡入
			var fade_in := create_tween()
			fade_in.tween_property(_player, "volume_db", _calc_target_db(), duration * 0.6)
		)
	else:
		_current_path = path
		_player.stream = stream
		_player.play()
		# 淡入
		var fade_in := create_tween()
		fade_in.tween_property(_player, "volume_db", _calc_target_db(), duration * 0.6)


## 停止（无淡出，立即）
func stop_immediate() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_player.stop()
	_current_path = ""


# ============================================================
# 内部
# ============================================================

func _play_stream_internal(stream: AudioStream) -> void:
	_player.stop()
	_player.stream = stream
	_player.play()
	_player.volume_db = _calc_target_db()


## 是否正在播放
func is_playing() -> bool:
	return _player.playing


## 获取当前音频流（用于存档）
func get_current_stream() -> AudioStream:
	return _player.stream


func _calc_target_db() -> float:
	var linear := _master_volume * _music_volume
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)


func _on_setting_changed(category: String, key: String, _value: Variant) -> void:
	if category != "audio":
		return
	if key == "master_volume" or key == "music_volume":
		_load_volume_from_settings()
		if _player.playing:
			_player.volume_db = _calc_target_db()


func _load_volume_from_settings() -> void:
	var mgr := get_node_or_null("/root/KND_Settings")
	if mgr == null:
		return
	var master_val: Variant = mgr.get_setting("audio", "master_volume")
	_master_volume = float(master_val) if master_val != null else 1.0
	var music_val: Variant = mgr.get_setting("audio", "music_volume")
	_music_volume = float(music_val) if music_val != null else 0.8
