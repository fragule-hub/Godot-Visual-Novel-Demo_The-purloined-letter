extends Control

@export var dialogue_manager: KND_DialogueManager

var _inline_processor: InlineCommandProcessor
var _backlog_overlay: KND_OverlayPanel
var _backlog_panel: BacklogPanel
var _save_overlay: KND_OverlayPanel


func _ready() -> void:
	if not dialogue_manager:
		return

	dialogue_manager.custom_signal.connect(func(c): print("Konado signal: ", c))
	dialogue_manager.shot_end.connect(func(): print("Dialogue finished"))

	# 内联命令处理器
	_inline_processor = InlineCommandProcessor.new(
		dialogue_manager,
		dialogue_manager._konado_dialogue_box,
		dialogue_manager._acting_interface
	)
	add_child(_inline_processor)
	dialogue_manager.dialogue_text_ready.connect(_inline_processor.start_line)

	# ── 回顾面板 ──
	_backlog_overlay = KND_OverlayPanel.new()
	_backlog_overlay.fade_duration = 0.25
	add_child(_backlog_overlay)

	_backlog_panel = preload("res://scenes/konado/backlog_panel.tscn").instantiate()
	_backlog_panel._overlay = _backlog_overlay
	_backlog_overlay.content = _backlog_panel
	_backlog_overlay.opened.connect(_backlog_panel.on_overlay_opened)
	_backlog_overlay.closed.connect(_backlog_panel.on_overlay_closed)
	_backlog_overlay.opened.connect(_on_panel_opened)
	_backlog_overlay.closed.connect(_on_panel_closed)

	var recorder := BacklogRecorder.new()
	recorder.backlog_panel = _backlog_panel
	add_child(recorder)
	dialogue_manager.dialogue_text_ready.connect(recorder.start_line)

	# 连接「回顾」按钮
	var review_btn := get_node_or_null(
		"KonadoDialogueLeftProject/KonadoUI/ColorRect/HBoxContainer/Review")
	if review_btn is Button:
		review_btn.pressed.connect(_backlog_overlay.open)

	# ── 存档面板 ──
	_save_overlay = KND_OverlayPanel.new()
	add_child(_save_overlay)

	var save_panel: ProjectSavePanel = preload(
		"res://scenes/ui/project_save_panel.tscn").instantiate()
	save_panel.save_system = dialogue_manager.save_system
	save_panel._overlay = _save_overlay
	_save_overlay.content = save_panel
	_save_overlay.opened.connect(save_panel.on_overlay_opened)
	_save_overlay.opened.connect(_on_panel_opened)
	_save_overlay.closed.connect(_on_panel_closed)

	# 连接「存档」按钮
	var save_btn := get_node_or_null(
		"KonadoDialogueLeftProject/KonadoUI/ColorRect/HBoxContainer/Save")
	if save_btn is Button:
		save_btn.pressed.connect(_save_overlay.open)

	# ── 设置面板信号 ──
	if dialogue_manager._settings_bridge:
		var bridge = dialogue_manager._settings_bridge
		bridge.settings_panel_opened.connect(_on_panel_opened)
		bridge.settings_panel_closed.connect(_on_panel_closed)


func _input(event: InputEvent) -> void:
	if _is_any_panel_open():
		return
	# 滚轮上滑 → 打开回顾，消费事件防止触发对话推进
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_backlog_overlay.open()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _is_any_panel_open():
		if event.is_action_pressed("ui_cancel"):
			var top := _get_top_panel()
			if top:
				top.close()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event.is_action_pressed("backlog"):
		_backlog_overlay.open()


# ============================================================
# 面板状态管理
# ============================================================

## 返回当前可见的最顶层 overlay（Esc 关闭优先级：设置 > 存档 > 回顾）
func _get_top_panel() -> KND_OverlayPanel:
	if dialogue_manager and dialogue_manager._settings_bridge:
		var bridge = dialogue_manager._settings_bridge
		if bridge._settings_overlay and bridge._settings_overlay.visible:
			return bridge._settings_overlay
	if _save_overlay and _save_overlay.visible:
		return _save_overlay
	if _backlog_overlay and _backlog_overlay.visible:
		return _backlog_overlay
	return null


func _is_any_panel_open() -> bool:
	return _get_top_panel() != null


func _on_panel_opened() -> void:
	dialogue_manager.notify_panel_opened()
	dialogue_manager._konado_dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_manager._konado_dialogue_box.set_process_input(false)
	dialogue_manager._konado_dialogue_box.set_process_unhandled_input(false)


func _on_panel_closed() -> void:
	dialogue_manager.notify_panel_closed()
	dialogue_manager._konado_dialogue_box.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_manager._konado_dialogue_box.set_process_input(true)
	dialogue_manager._konado_dialogue_box.set_process_unhandled_input(true)
