extends Control
class_name BacklogPanel

## 回顾面板内容（由 KND_OverlayPanel 包裹）

@onready var close_btn: Button = %CloseBtn
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var log_container: VBoxContainer = %LogContainer

const MAX_ENTRIES := 500
const SCROLL_SESSION_TIMEOUT_MS := 150

const ENTRY_STYLE_ODD  := preload("res://resources/theme/backlog_entry_odd.tres")
const ENTRY_STYLE_EVEN := preload("res://resources/theme/backlog_entry_even.tres")
const ENTRY_NAME_SETTINGS := preload("res://resources/theme/backlog_entry_name.tres")

var _last_wheel_time_msec: int = 0
var _session_started_at_bottom: bool = false

## 由外部（test_dialogue_screen）设置
var _overlay: KND_OverlayPanel


func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	if _overlay:
		_overlay.close()


## overlay 打开时回调
func on_overlay_opened() -> void:
	_last_wheel_time_msec = 0
	_session_started_at_bottom = false
	if not scroll_container.gui_input.is_connected(_on_scroll_gui_input):
		scroll_container.gui_input.connect(_on_scroll_gui_input)
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll_to_bottom()


## overlay 关闭时回调
func on_overlay_closed() -> void:
	if scroll_container.gui_input.is_connected(_on_scroll_gui_input):
		scroll_container.gui_input.disconnect(_on_scroll_gui_input)


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
		if _overlay:
			_overlay.close()
		scroll_container.accept_event()


func _is_at_bottom() -> bool:
	var v_scroll := scroll_container.get_v_scroll_bar()
	return scroll_container.scroll_vertical >= int(v_scroll.max_value - v_scroll.page)


func _scroll_to_bottom() -> void:
	var v_scroll := scroll_container.get_v_scroll_bar()
	scroll_container.scroll_vertical = int(v_scroll.max_value - v_scroll.page)


func add_entry(character_id: String, text: String) -> void:
	# 条目背景 Panel（样式从资源加载，交替颜色）
	var bg := PanelContainer.new()
	var is_even := log_container.get_child_count() % 2 == 0
	bg.add_theme_stylebox_override("panel",
		ENTRY_STYLE_EVEN if is_even else ENTRY_STYLE_ODD)

	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 12)

	# 角色名（样式从 LabelSettings 资源加载）
	var name_label := Label.new()
	name_label.text = character_id + ": " if character_id else "??? : "
	name_label.label_settings = ENTRY_NAME_SETTINGS
	name_label.custom_minimum_size.x = 120
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# 对话文本
	var text_label := RichTextLabel.new()
	text_label.text = text
	text_label.bbcode_enabled = false
	text_label.fit_content = true
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.scroll_active = false

	entry.add_child(name_label)
	entry.add_child(text_label)
	bg.add_child(entry)
	log_container.add_child(bg)

	# 超过上限则删除最早的
	if log_container.get_child_count() > MAX_ENTRIES:
		var oldest := log_container.get_child(0)
		log_container.remove_child(oldest)
		oldest.queue_free()
