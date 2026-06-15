extends Node
class_name KND_AudioInterface

## 音频接口类

## Bgm播放成功
signal finish_playbgm
## 语音播放成功
signal finish_playvoice
## 音效播放成功
signal finish_playsoundeffect

## 语音播放完成
signal voice_finish_playing

## BGM淡出完成
signal bgm_fade_finished

## BGM播放器
@export var bgm_player: AudioStreamPlayer
## 对话播放器
@export var voice_player: AudioStreamPlayer
## 音效播放器
@export var sound_effect_player: AudioStreamPlayer

## 设置桥接器引用
@export var _settings_bridge: KND_SettingsBridge

## 缓存的音量值
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0


func _ready() -> void:
	if _settings_bridge:
		_update_volume_from_settings()
	# 转发 BgmManager 淡出完成信号
	if BgmManager.has_signal("bgm_fade_finished"):
		BgmManager.bgm_fade_finished.connect(func(): bgm_fade_finished.emit())


## 从设置更新音量（仅 voice / sfx，BGM 由 BgmManager autoload 自行管理）
func _update_volume_from_settings() -> void:
	if _settings_bridge == null:
		return
	
	_master_volume = _settings_bridge.get_master_volume()
	_sfx_volume = _settings_bridge.get_sfx_volume()
	
	# bgm_player 音量由 BgmManager autoload 管理
	# voice_volume 已从设置中移除，语音仅受主音量控制
	if voice_player:
		voice_player.volume_db = linear_to_db(_master_volume)
	if sound_effect_player:
		sound_effect_player.volume_db = linear_to_db(_master_volume * _sfx_volume)

## 设置变更处理
func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	if category == "audio":
		_update_volume_from_settings()

## 将线性音量转换为分贝
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)


## 播放BGM的方法（委托 BgmManager autoload，跨场景持久化）
func play_bgm(audio: AudioStream, audio_id: String) -> void:
	BgmManager.play_stream(audio)
	finish_playbgm.emit()
		
	
## 停止播放BGM的方法（委托 BgmManager autoload）
func stop_bgm() -> void:
	BgmManager.stop()

## 带淡出的停止BGM
func fade_out_bgm(duration: float = 1.0) -> void:
	BgmManager.stop(duration)


## 播放语音的方法
func play_voice(audio: AudioStream) -> void:
	if not voice_player:
		push_error("没找到voice_player")
		finish_playvoice.emit()
		return
	if voice_player.is_playing():
		voice_player.stop()
	voice_player.stream=audio
	voice_player.play()
	finish_playvoice.emit()
	await voice_player.finished
	voice_finish_playing.emit()

## 停止播放语音的方法
func stop_voice() -> void:
	if not voice_player:
		push_error("没找到voice_player")
		return
	voice_player.stop()

## 播放音效的方法
func play_sound_effect(audio: AudioStream) -> void:
	if not sound_effect_player:
		push_error("没找到sound_effect_player")
		finish_playsoundeffect.emit()
		return
	sound_effect_player.stop()
	sound_effect_player.stream = audio
	sound_effect_player.play()
	finish_playsoundeffect.emit()
