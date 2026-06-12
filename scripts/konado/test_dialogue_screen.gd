extends Control

@export var dialogue_manager: KND_DialogueManager

var _inline_processor: InlineCommandProcessor
var _backlog_panel: BacklogPanel
var _backlog_open := false


func _ready() -> void:
	if dialogue_manager:
		dialogue_manager.custom_signal.connect(_on_custom_signal)
		dialogue_manager.shot_end.connect(_on_shot_end)
		# 内联命令处理器
		_inline_processor = InlineCommandProcessor.new(
			dialogue_manager,
			dialogue_manager._konado_dialogue_box,
			dialogue_manager._acting_interface
		)
		add_child(_inline_processor)
		dialogue_manager.dialogue_text_ready.connect(_inline_processor.start_line)

		# ── Backlog 系统 ──
		var backlog_scene: PackedScene = preload("res://scenes/konado/backlog_panel.tscn")
		_backlog_panel = backlog_scene.instantiate()
		add_child(_backlog_panel)

		var recorder := BacklogRecorder.new()
		recorder.backlog_panel = _backlog_panel
		add_child(recorder)
		dialogue_manager.dialogue_text_ready.connect(recorder.start_line)

		_backlog_panel.closed.connect(_on_backlog_closed)

		# 连接「回顾」按钮（位于 konado 子场景内）
		var review_btn := get_node_or_null(
			"KonadoDialogueLeftProject/KonadoUI/ColorRect/HBoxContainer/Review")
		if review_btn is Button:
			review_btn.pressed.connect(_on_review_pressed)


func _input(event: InputEvent) -> void:
	if _backlog_open:
		return
	# 滚轮上滑 → 打开回顾，消费事件防止触发对话推进
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_on_review_pressed()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _backlog_open:
			_backlog_panel.close()
		else:
			get_tree().quit()
	elif event.is_action_pressed("backlog"):
		if _backlog_open:
			_backlog_panel.close()
		else:
			_on_review_pressed()


func _on_review_pressed() -> void:
	if _backlog_panel and not _backlog_open:
		_backlog_panel.open()
		_backlog_open = true
		# 暂停对话框的点击输入
		if dialogue_manager and dialogue_manager._konado_dialogue_box:
			dialogue_manager._konado_dialogue_box.set_process_input(false)
			dialogue_manager._konado_dialogue_box.set_process_unhandled_input(false)


func _on_backlog_closed() -> void:
	_backlog_open = false
	# 恢复对话框的点击输入
	if dialogue_manager and dialogue_manager._konado_dialogue_box:
		dialogue_manager._konado_dialogue_box.set_process_input(true)
		dialogue_manager._konado_dialogue_box.set_process_unhandled_input(true)


func _on_custom_signal(content: String) -> void:
	print("Konado custom signal: " + content)


func _on_shot_end() -> void:
	print("Test dialogue finished")
