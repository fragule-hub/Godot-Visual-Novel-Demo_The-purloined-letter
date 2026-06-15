extends Control

@export var dialogue_manager: KND_DialogueManager

var _inline_processor: InlineCommandProcessor
var _backlog_overlay: KND_OverlayPanel
var _backlog_panel: BacklogPanel
var _save_overlay: KND_OverlayPanel
var _game_started := false


func _ready() -> void:
	if not dialogue_manager:
		return

	# 禁用自动启动，等待 SceneTransition 过渡完成后再开始对话
	dialogue_manager.autostart = false

	dialogue_manager.custom_signal.connect(func(c): print("Konado signal: ", c))
	dialogue_manager.shot_end.connect(_on_shot_end)

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
		review_btn.text = tr("btn_review")

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
		save_btn.text = tr("btn_save_load")

	# 连接「返回」按钮
	var return_btn := get_node_or_null(
		"KonadoDialogueLeftProject/KonadoUI/ColorRect/HBoxContainer/Return")
	if return_btn is Button:
		return_btn.pressed.connect(_on_return_to_title)
		return_btn.text = tr("btn_return_title")

	# ── 设置面板信号 ──
	if dialogue_manager._settings_bridge:
		var bridge = dialogue_manager._settings_bridge
		bridge.settings_panel_opened.connect(_on_panel_opened)
		bridge.settings_panel_closed.connect(_on_panel_closed)

	# ── 语言变更订阅 ──
	var settings_mgr := get_node_or_null("/root/KND_Settings")
	if settings_mgr and settings_mgr.has_signal("setting_changed"):
		settings_mgr.setting_changed.connect(_on_setting_changed)

	# ── 底部按钮本地化 ──
	_apply_ui_localization()

	# ── 等待过渡完成后再启动游戏 ──
	if SceneTransition.is_transitioning():
		SceneTransition.transition_finished.connect(_start_game)
		# 防御：过渡异常时最多等 3 秒
		get_tree().create_timer(3.0).timeout.connect(func():
			if not _game_started:
				_start_game()
		)
	else:
		_start_game()


func _start_game() -> void:
	if _game_started:
		return
	_game_started = true

	# 从标题界面加载存档（同步加载，先恢复状态再开始对话）
	if GameState.pending_save_id >= 0:
		var save_id: int = GameState.pending_save_id
		GameState.pending_save_id = -1
		dialogue_manager.save_system.load_game(save_id)

	dialogue_manager.start_dialogue()


func _input(event: InputEvent) -> void:
	if _is_any_panel_open():
		return
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


func _on_return_to_title() -> void:
	SceneTransition.change_scene("res://scenes/ui/title_screen.tscn", SceneTransition.Effect.FADE)


func _on_shot_end() -> void:
	BgmManager.stop(1.0)
	get_tree().create_timer(1.0).timeout.connect(func():
		SceneTransition.change_scene("res://scenes/ui/title_screen.tscn", SceneTransition.Effect.FADE)
	)


func _apply_ui_localization() -> void:
	var base := "KonadoDialogueLeftProject/KonadoUI/ColorRect/HBoxContainer/"
	var auto_btn := get_node_or_null(base + "AutoPlay")
	if auto_btn is Button:
		# 固定最小宽度，防止文字切换时按钮宽度跳变
		auto_btn.custom_minimum_size.x = 95
		dialogue_manager._update_auto_play_button()
	var achievement_btn := get_node_or_null(base + "Achievement")
	if achievement_btn is Button:
		achievement_btn.text = tr("btn_achievement")
	var settings_btn := get_node_or_null(base + "Settings")
	if settings_btn is Button:
		settings_btn.text = tr("btn_dialogue_settings")
	# Review / Save / Return 按钮也在底部栏，一并刷新
	var review_btn := get_node_or_null(base + "Review")
	if review_btn is Button:
		review_btn.text = tr("btn_review")
	var save_btn := get_node_or_null(base + "Save")
	if save_btn is Button:
		save_btn.text = tr("btn_save_load")
	var return_btn := get_node_or_null(base + "Return")
	if return_btn is Button:
		return_btn.text = tr("btn_return_title")


func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	if category == "display" and key == "language":
		GameState.apply_language(value)
		_apply_ui_localization()
		# 刷新回顾面板标题
		if _backlog_panel:
			_backlog_panel._title_label.text = tr("backlog_title")
