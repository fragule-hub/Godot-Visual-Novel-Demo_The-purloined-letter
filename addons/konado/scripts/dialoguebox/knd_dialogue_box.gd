extends Control
class_name KND_DialogueBox

## 打字机模式枚举
enum TypewriterMode {
	TRADITIONAL = 0,  ## 传统模式
	FADE_IN_TYPEWRITER = 1  ## 淡入打字机模式
}

## Konado对话框模板
## 可以自定义设置画面显示内容、位置、尺寸

## 点击对话框
signal on_dialogue_click 
signal on_button_pressed
signal on_character_name_click

## 打字完成
signal typing_completed

## 滚轮滚动到顶部（用于外部打开回顾面板）
signal scroll_up_at_top

## 对话框显示动画完成
signal on_dialogue_show_completed

## 对话框隐藏动画完成
signal on_dialogue_hide_completed

## 角色对象
@export_group("名字")
@export var character_name: String = "" :
	set(value):
		character_name = value
		update_dialogue()
			
@export var name_size: int = 32              ## 名字字体大小
@export var name_bg: Texture2D              ## 名字标签背景
@export var name_color: Color = Color.WHITE ## 名字颜色

## 对话内容
@export_group("对话文本设置")
@export var dialogue_text: String= "":
	set(value):
		dialogue_text = value
		_reset_scroll_state()
		update_dialogue_content()

@export var dialogue_font_size: int = 24     ## 对话文本字体大小（新增）
## 打字间隔（单字符）
@export var typing_interval: float = 0.4:
	set(value):
		typing_interval = value
		update_dialogue_content()
		
@export_group("打字音效配置")
@export var enable_typing_effect_audio: bool = true
@export var typing_effect_audio: AudioStream
@export var audio_trigger_chance: float = 0.8  ## 音效触发概率(0-1)，1=每次必播，0=不播
@export var min_audio_interval: float = 0.02   ## 音效最小播放间隔（秒），适配滴滴声快速节奏
@export var max_audio_interval: float = 0.08   ## 音效最大播放间隔（秒）
@export var audio_volumn: float = 0.6         ## 音效音量(0-1)

# 打字机音效音量管理（跟随 KND_Settings 的 master_volume × sfx_volume）
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0

@export_group("对话框设置")
@export var dialogue_margins: int = 100     ## 对话框左右边距
@export var dialogue_margin_bottom: int = 100  ## 对话框底部边距
@export var dialogue_bg: StyleBox          ## 对话框背景
@export var dialogue_color: Color = Color.WHITE ## 对话文字颜色
@export var dialogue_height: int = 200  ## 对话文本框高度

@export_group("按钮")
@export var button_show: bool = false
@export var button_text: String = ""
@export var button_texture: Texture2D

# 动画相关变量
@export_group("过渡动画设置")
@export var fade_duration: float = 0.5      ## 显示/隐藏过渡动画时长
@export var fade_trans_type: Tween.TransitionType = Tween.TRANS_SINE  ## 过渡动画曲线类型
@export var fade_ease_type: Tween.EaseType = Tween.EASE_IN_OUT        ## 过渡动画缓动类型

@export_group("打字机设置")
@export var typewriter_mode: TypewriterMode = TypewriterMode.TRADITIONAL  ## 打字机模式

# 动态音频播放器
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
# 音效状态变量 - 记录上一次播放时间、当前随机间隔
var last_audio_play_time: float = 0.0
var current_random_interval: float = 0.0
var _audio_accumulator: float = 0.0

# 透明度过渡动画Tween
var fade_tween: Tween = null

## 加载节点
@onready var character_name_label: Label = %character_name_label
@onready var dialogue_label: RichTextLabel = %dialogue_label
@onready var progress_bar: TextureProgressBar = %ProgressBar
@onready var dialogue_container: MarginContainer = %dialogue_container
@onready var dialogue_box_bg: Panel = %dialogue_box_bg

# TypewriterText 组件
@export var typewriter_text: KND_TypewriterText

var typing_tween: Tween = null

# 省略号停顿
var _ellipsis_label: Label = null

# ── 滚动会话防误触 ──
var _scroll_session_active: bool = false
var _last_scroll_time_ms: int = 0
var _needs_scroll_top_reset: bool = false
const SCROLL_SESSION_TIMEOUT_MS: int = 150

# ── 打字滚动缓存（避免每帧重复计算） ──
var _last_visible_ratio: float = -1.0
var _overflowing_cached: bool = false
var _overflow_cache_dirty: bool = true

# ── 打字 Tween 代数（防止 await 期间重复赋值导致 Tween 竞争） ──
var _typing_generation: int = 0


func _ready() -> void:
	self.modulate.a = 0.0
	apply_dialogue_text_theme_settings()
	update_dialogue_box_height()
	
	if enable_typing_effect_audio:
		# 将音频播放器添加为子节点，自动完成初始化
		add_child(audio_player)
		audio_player.name = "TypingAudioPlayer"
		# 绑定滴滴音效资源
		audio_player.stream = typing_effect_audio
		# 音量跟随设置系统（master × sfx × audio_volumn）
		_load_typing_audio_volume()
		var mgr := get_node_or_null("/root/KND_Settings")
		if mgr and mgr.has_signal("setting_changed"):
			mgr.setting_changed.connect(_on_typing_audio_setting_changed)
		audio_player.autoplay = false
		# 初始化随机间隔
		current_random_interval = randf_range(min_audio_interval, max_audio_interval)
	
	# 根据打字机模式处理 TypewriterText 组件
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		create_typewriter_text()
	else:
		# 如果 TypewriterText 组件存在，则隐藏它并显示传统的 dialogue_label
		if typewriter_text != null:
			typewriter_text.hide()
		dialogue_label.show()

## 应用对话文本的主题设置
func apply_dialogue_text_theme_settings() -> void:
	if not is_inside_tree():
		return
	dialogue_label.add_theme_font_size_override("normal_font_size", dialogue_font_size)
	
	# 如果使用 TypewriterText 模式，也应用主题设置
	if typewriter_text != null:
		typewriter_text.font_size = dialogue_font_size
		typewriter_text.font_color = dialogue_color

## 创建 TypewriterText 组件
func create_typewriter_text() -> void:
	# 连接信号
	typewriter_text.typewriter_finished.connect(func():
		typing_completed.emit()
	)
	
	# 隐藏默认的 dialogue_label
	dialogue_label.hide()
	
## 隐藏对话框（带透明度过渡动画）
func hide_dialogue_box() -> void:
	# 停止原有过渡动画，避免动画冲突
	if fade_tween != null and fade_tween.is_running():
		fade_tween.kill()
	
	# 创建新的透明度过渡动画
	fade_tween = get_tree().create_tween()
	fade_tween.set_trans(fade_trans_type)
	fade_tween.set_ease(fade_ease_type)
	
	# 同时过渡三个节点的 modulate:a 从当前值到 0
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	if character_name_label:
		fade_tween.tween_property(character_name_label, "modulate:a", 0.0, fade_duration)
	if dialogue_label:
		fade_tween.tween_property(dialogue_label, "modulate:a", 0.0, fade_duration)
	if typewriter_text:
		fade_tween.tween_property(typewriter_text, "modulate:a", 0.0, fade_duration)
	
	# 动画结束后隐藏所有节点并重置透明度
	fade_tween.finished.connect(func():
		self.hide()
		self.modulate.a = 1.0
		
		character_name_label.hide()
		character_name_label.modulate.a = 1.0
		
		dialogue_label.hide()
		dialogue_label.modulate.a = 1.0
		
		# 发射对话框隐藏完成信号
		on_dialogue_hide_completed.emit()
	)
	
## 显示对话框（带透明度过渡动画）
func show_dialogue_box() -> void:
	# 先显示节点并重置透明度
	self.show()
	self.modulate.a = 0.0
	
	# 停止原有过渡动画，避免动画冲突
	if fade_tween != null and fade_tween.is_running():
		fade_tween.kill()
	
	# 创建新的透明度过渡动画
	fade_tween = get_tree().create_tween()
	# 设置动画曲线和缓动类型
	fade_tween.set_trans(fade_trans_type)
	fade_tween.set_ease(fade_ease_type)
	# 过渡modulate的alpha值从0到1
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	# 动画结束后发射显示完成信号
	fade_tween.finished.connect(func():
		on_dialogue_show_completed.emit()
	)
	
func update_dialogue():
	if not is_inside_tree():
		return
	_reset_scroll_state()
	update_character_name()
	update_dialogue_content()
	
func update_character_name() -> void:
	if not is_inside_tree():
		return
	character_name_label.text = character_name
	character_name_label.label_settings.font_size = name_size
	character_name_label.label_settings.font_color = name_color
	
func update_dialogue_box_height() -> void:
	# 更改边距
	dialogue_container.add_theme_constant_override("margin_left", dialogue_margins)
	dialogue_container.add_theme_constant_override("margin_right",dialogue_margins)
	dialogue_container.add_theme_constant_override("margin_bottom",dialogue_margin_bottom)
	# 如果用户选择了背景
	if dialogue_bg:
		dialogue_box_bg.add_theme_stylebox_override("panel",dialogue_bg)
	# 更改文本高度
	dialogue_label.custom_minimum_size.y = dialogue_height
	
	# 如果使用 TypewriterText 模式，也设置其高度
	if typewriter_text != null:
		typewriter_text.size = Vector2(dialogue_container.size.x, dialogue_height)
	
	
func update_dialogue_content() -> void:
	if not is_inside_tree():
		return
	# 清空文本：停止打字动画并清空标签
	if dialogue_text.is_empty():
		if typing_tween != null and typing_tween.is_valid():
			typing_tween.kill()
			typing_tween = null
		dialogue_label.text = ""
		dialogue_label.visible_ratio = 1.0
		_reset_scroll_state()
		return
	
	# 每次更新对话内容时，重新应用主题设置（确保字体大小/颜色生效）
	apply_dialogue_text_theme_settings()
	
	update_dialogue_box_height()
	
	# 重置音效状态 - 重新打字时从头计算间隔
	last_audio_play_time = 0.0
	current_random_interval = randf_range(min_audio_interval, max_audio_interval)
	
	# 根据打字机模式选择不同的更新方式
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		# 淡入打字机模式
		if typewriter_text == null:
			create_typewriter_text()
		else:
			typewriter_text.set_bbcode(dialogue_text, true)
	else:
		# 传统模式
		_typing_generation += 1
		var gen := _typing_generation
		dialogue_label.visible_ratio = 0
		dialogue_label.text = dialogue_text
		await get_tree().process_frame
		if gen != _typing_generation:
			return  # 已被更新覆盖，放弃旧 tween

		# 停止原有打字动画
		if typing_tween != null and typing_tween.is_running():
			typing_tween.kill()

		# 创建新的打字动画
		typing_tween = get_tree().create_tween()
		typing_tween.finished.connect(func():
			typing_completed.emit())
		# 优化：按**字符数**计算总时长
		var total_typing_time = dialogue_text.length() * typing_interval
		typing_tween.tween_property(dialogue_label, "visible_ratio", 1.0, total_typing_time).set_trans(Tween.TRANS_LINEAR)

## 跳过打字机动画
func skip_typing_anim() -> void:
	# 根据打字机模式选择不同的跳过方式
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		# 淡入打字机模式
		if typewriter_text != null and typewriter_text.is_playing():
			typewriter_text.skip()
			
			if enable_typing_effect_audio and audio_player.is_playing():
				audio_player.stop()
			# 重置音效状态
			last_audio_play_time = 0.0
			current_random_interval = randf_range(min_audio_interval, max_audio_interval)
			typing_completed.emit()
	else:
		# 传统模式
		if typing_tween != null and typing_tween.is_running():
			# 停止打字动画
			typing_tween.kill()
			# 直接显示完整文本
			dialogue_label.visible_ratio = 1.0
			
			if enable_typing_effect_audio and audio_player.is_playing():
				audio_player.stop()
			# 重置音效状态
			last_audio_play_time = 0.0
			current_random_interval = randf_range(min_audio_interval, max_audio_interval)
			typing_completed.emit()


## 当前是否正在打字
func _is_currently_typing() -> bool:
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		return typewriter_text != null and typewriter_text.is_playing() and not dialogue_text.is_empty()
	return typing_tween and typing_tween.is_running() and not dialogue_text.is_empty()


func _process(delta: float) -> void:
	# 仅当打字动画运行、文本非空时，处理音效逻辑
	var is_typing := _is_currently_typing()

	# ── 打字期间自动滚动 ──
	if is_typing:
		var current_ratio := dialogue_label.visible_ratio
		if current_ratio != _last_visible_ratio:
			_overflow_cache_dirty = true
			_last_visible_ratio = current_ratio

		if _is_dialogue_overflowing():
			dialogue_label.scroll_active = true
			if _needs_scroll_top_reset:
				var v_scroll := dialogue_label.get_v_scroll_bar()
				if v_scroll:
					v_scroll.value = 0
				_needs_scroll_top_reset = false
			else:
				var v_scroll := dialogue_label.get_v_scroll_bar()
				if v_scroll:
					var content_h := float(dialogue_label.get_content_height())
					var label_h := float(dialogue_label.size.y)
					v_scroll.value = maxi(0, int(content_h * current_ratio - label_h))
		else:
			_needs_scroll_top_reset = false
	
	if not is_typing:
		_audio_accumulator = 0.0
		return

	_audio_accumulator += delta
	var time_since_last_play = _audio_accumulator - last_audio_play_time
	
	if enable_typing_effect_audio:
		var should_play = false
		if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
			# 淡入打字机模式：检查进度
			var progress = typewriter_text.get_progress()
			var total_chars = dialogue_text.length()
			should_play = progress < float(total_chars)
		else:
			# 传统模式：检查 visible_ratio
			should_play = dialogue_label.visible_ratio < 0.98
		
		if time_since_last_play > current_random_interval and randf() < audio_trigger_chance and should_play:
			# 防重叠
			audio_player.stop()
			audio_player.play()
			# 更新上一次播放时间
			last_audio_play_time = _audio_accumulator
			# 重新生成随机间隔（每次播放后更新，保证间隔不重复）
			current_random_interval = randf_range(min_audio_interval, max_audio_interval)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.is_pressed():
		return
	
	# ── 滚轮 → 走滚动会话逻辑 ──
	if event.button_index == MOUSE_BUTTON_WHEEL_UP or \
	   event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_handle_scroll_wheel(event)
		return
	
	# 非滚轮点击 → 推进对话
	on_dialogue_click.emit()
		
func _input(event: InputEvent) -> void:
	# 键盘：保留原有行为
	if event.is_action_pressed("ui_accept") || event.is_action_pressed("ui_select"):
		on_dialogue_click.emit()

	# 全局滚轮：仅当鼠标不在对话框区域内时处理（避免与 _gui_input 重复）
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or \
		   event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _is_dialogue_overflowing() and not get_global_rect().has_point(get_global_mouse_position()):
				_handle_scroll_wheel(event)


## 检测文字是否超出可见区域
func _is_dialogue_overflowing() -> bool:
	if not dialogue_label:
		return false
	if not _overflow_cache_dirty:
		return _overflowing_cached
	var content_h := dialogue_label.get_content_height()
	var visible_h := dialogue_label.size.y
	_overflowing_cached = content_h > visible_h + 4
	_overflow_cache_dirty = false
	return _overflowing_cached


## 重置滚动状态（新对话开始时调用）
func _reset_scroll_state() -> void:
	if not dialogue_label:
		return
	dialogue_label.scroll_active = false
	dialogue_label.scroll_following = false
	_scroll_session_active = false
	_last_scroll_time_ms = 0
	_needs_scroll_top_reset = true
	_overflow_cache_dirty = true
	_last_visible_ratio = -1.0


## 滚轮滚动会话处理（防误触 + 边界让位）
func _handle_scroll_wheel(event: InputEventMouseButton) -> void:
	# ── 打字中：下滚 = 跳过动画，上滚 = 打开回顾 ──
	if _is_currently_typing():
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			on_dialogue_click.emit()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_up_at_top.emit()
		accept_event()
		return

	if not _is_dialogue_overflowing():
		# 文字不溢出：上滚 = 打开回顾，下滚 = 推进对话
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_up_at_top.emit()
		else:
			on_dialogue_click.emit()
		return

	var now := Time.get_ticks_msec()
	var is_new_session := (now - _last_scroll_time_ms) > SCROLL_SESSION_TIMEOUT_MS
	_last_scroll_time_ms = now

	var v_scroll := dialogue_label.get_v_scroll_bar()
	if v_scroll == null:
		return

	var scrolling_up := event.button_index == MOUSE_BUTTON_WHEEL_UP
	var max_val := int(v_scroll.max_value)
	var at_top: bool = v_scroll.value <= 0
	var at_bottom: bool = v_scroll.value >= max_val - int(v_scroll.page)
	var at_boundary: bool = (scrolling_up and at_top) or (not scrolling_up and at_bottom)

	# ── 新会话且已在边界 → 让位给推进 / 回顾 ──
	if is_new_session and at_boundary:
		if scrolling_up and at_top:
			scroll_up_at_top.emit()
		else:
			on_dialogue_click.emit()
		_scroll_session_active = false
		return

	# ── 会话中滚动文字 ──
	_scroll_session_active = true
	var step := int(v_scroll.page * 0.3)
	if scrolling_up:
		v_scroll.value = maxi(0, v_scroll.value - step)
	else:
		v_scroll.value = mini(max_val - int(v_scroll.page), v_scroll.value + step)

func _on_button_pressed() -> void:
	on_button_pressed.emit()

## 省略号停顿：显示
func show_ellipsis(dots: String) -> void:
	if _ellipsis_label == null:
		_ellipsis_label = Label.new()
		_ellipsis_label.name = "EllipsisLabel"
		_ellipsis_label.z_index = 10
		_ellipsis_label.add_theme_font_size_override("font_size", dialogue_font_size)
		_ellipsis_label.add_theme_color_override("font_color", dialogue_color)
		dialogue_label.add_child(_ellipsis_label)
	_ellipsis_label.text = dots
	_update_ellipsis_position()
	_ellipsis_label.visible = true
	print("[ELLIPSIS] show_ellipsis('%s') → pos=%s" % [dots, _ellipsis_label.position])

## 省略号停顿：更新文本
func update_ellipsis(dots: String) -> void:
	if _ellipsis_label:
		_ellipsis_label.text = dots

## 省略号停顿：隐藏
func hide_ellipsis() -> void:
	if _ellipsis_label:
		_ellipsis_label.visible = false
		_ellipsis_label.text = ""

## 定位省略号到当前文字末尾（dialogue_label 坐标系内）
func _update_ellipsis_position() -> void:
	if not _ellipsis_label or not dialogue_label:
		return
	var font: Font = dialogue_label.get_theme_font("normal_font")
	if font == null:
		font = dialogue_label.get_theme_default_font()
	var font_size: int = dialogue_label.get_theme_font_size("normal_font_size")
	if font_size <= 0:
		font_size = dialogue_font_size
	var line_spacing: int = dialogue_label.get_theme_constant("line_separation")
	var line_h: float = font.get_height(font_size) + line_spacing
	# 取单个 CJK 字符宽度用于计算每行字符数
	var char_w: float = font.get_string_size("啊", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if char_w <= 0.0:
		char_w = 1.0
	var label_w: float = dialogue_label.size.x
	var chars_per_line: int = maxi(1, int(label_w / char_w))
	# 获取可见字符数
	var vis_chars: int = dialogue_label.visible_characters
	var raw_vis_chars := vis_chars
	if vis_chars <= 0:
		vis_chars = int(dialogue_label.visible_ratio * dialogue_label.text.length())
	vis_chars = clampi(vis_chars, 1, dialogue_label.text.length())
	# 计算末行信息
	var lines_before: int = vis_chars / chars_per_line
	var chars_on_last: int = vis_chars - lines_before * chars_per_line
	var last_line_start: int = vis_chars - chars_on_last
	var last_line: String = dialogue_label.text.substr(last_line_start, chars_on_last)
	var last_line_w: float = font.get_string_size(last_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := Vector2(last_line_w, lines_before * line_h)
	_ellipsis_label.position = pos
	print("[ELLIPSIS] font='%s' size=%d char_w=%.1f line_h=%.1f label_w=%.0f" % [
		font.get_font_name(), font_size, char_w, line_h, label_w
	])
	print("[ELLIPSIS] vis_chars(raw=%d clamped=%d) ratio=%.3f text_len=%d" % [
		raw_vis_chars, vis_chars, dialogue_label.visible_ratio, dialogue_label.text.length()
	])
	print("[ELLIPSIS] chars_per_line=%d lines_before=%d chars_on_last=%d last_line_start=%d" % [
		chars_per_line, lines_before, chars_on_last, last_line_start
	])
	print("[ELLIPSIS] last_line='%s' w=%.1f → pos=%s" % [last_line, last_line_w, pos])

func _on_character_name_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		on_character_name_click.emit()


## 从 KND_Settings 加载 master/sfx 音量并更新打字机音效
func _load_typing_audio_volume() -> void:
	var mgr := get_node_or_null("/root/KND_Settings")
	if mgr:
		var mv: Variant = mgr.get_setting("audio", "master_volume")
		_master_volume = float(mv) if mv != null else 1.0
		var sv: Variant = mgr.get_setting("audio", "sfx_volume")
		_sfx_volume = float(sv) if sv != null else 1.0
	_apply_typing_audio_volume()


func _apply_typing_audio_volume() -> void:
	var linear := _master_volume * _sfx_volume * audio_volumn
	var db: float = -80.0 if linear <= 0.0 else 20.0 * log(linear) / log(10.0)
	audio_player.volume_db = db


func _on_typing_audio_setting_changed(category: String, key: String, _value: Variant) -> void:
	if category != "audio":
		return
	if key == "master_volume" or key == "sfx_volume":
		_load_typing_audio_volume()
