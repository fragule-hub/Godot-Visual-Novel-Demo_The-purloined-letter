extends Control
class_name BacklogPanel

signal closed

@onready var close_btn: Button = %CloseBtn
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var log_container: VBoxContainer = %LogContainer
@onready var content_area: VBoxContainer = $MarginContainer/VBoxContainer

const MAX_ENTRIES := 500
const FADE_DURATION := 0.25
const SCROLL_SESSION_TIMEOUT_MS := 150

var _fade_tween: Tween
var _last_wheel_time_msec: int = 0
var _session_started_at_bottom: bool = false


func _ready() -> void:
	modulate.a = 0.0
	visible = false
	close_btn.pressed.connect(close)
	set_process_input(false)
	set_process_unhandled_input(false)


func open() -> void:
	visible = true
	set_process_input(true)
	set_process_unhandled_input(true)
	if not scroll_container.gui_input.is_connected(_on_scroll_gui_input):
		scroll_container.gui_input.connect(_on_scroll_gui_input)
	_fade(1.0)
	_last_wheel_time_msec = 0
	_session_started_at_bottom = false
	# 等待布局稳定：RichTextLabel fit_content 需要多帧展开
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll_to_bottom()


func close() -> void:
	if scroll_container.gui_input.is_connected(_on_scroll_gui_input):
		scroll_container.gui_input.disconnect(_on_scroll_gui_input)
	_fade(0.0)
	if _fade_tween:
		await _fade_tween.finished
	set_process_input(false)
	set_process_unhandled_input(false)
	visible = false
	closed.emit()


func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton \
			or event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return

	var now := Time.get_ticks_msec()
	var is_new_session := (now - _last_wheel_time_msec) > SCROLL_SESSION_TIMEOUT_MS
	_last_wheel_time_msec = now

	var at_bottom := _is_at_bottom()
	if is_new_session:
		_session_started_at_bottom = at_bottom

	if _session_started_at_bottom:
		close()
		scroll_container.accept_event()


func _is_at_bottom() -> bool:
	var v_scroll := scroll_container.get_v_scroll_bar()
	return scroll_container.scroll_vertical >= int(v_scroll.max_value - v_scroll.page)


func _scroll_to_bottom() -> void:
	var v_scroll := scroll_container.get_v_scroll_bar()
	scroll_container.scroll_vertical = int(v_scroll.max_value - v_scroll.page)


func _fade(target_alpha: float) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_alpha, FADE_DURATION)


func add_entry(character_id: String, text: String) -> void:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 8)

	# 角色名
	var name_label := Label.new()
	name_label.text = character_id + ": " if character_id else "??? : "
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.custom_minimum_size.x = 160
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# 对话文本
	var text_label := RichTextLabel.new()
	text_label.text = text
	text_label.bbcode_enabled = false
	text_label.fit_content = true
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size", 28)
	text_label.scroll_active = false

	entry.add_child(name_label)
	entry.add_child(text_label)
	log_container.add_child(entry)

	# 超过上限则删除最早的
	if log_container.get_child_count() > MAX_ENTRIES:
		var oldest := log_container.get_child(0)
		log_container.remove_child(oldest)
		oldest.queue_free()


func _input(event: InputEvent) -> void:
	# 点击内容区域外部 → 关闭
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not content_area.get_global_rect().has_point(event.position):
			close()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("backlog"):
		close()
		get_viewport().set_input_as_handled()
