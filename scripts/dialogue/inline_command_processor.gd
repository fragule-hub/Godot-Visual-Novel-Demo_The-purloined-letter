extends Node
class_name InlineCommandProcessor

## 内联命令处理器
## 解析对话文本中的 {tag:value} 标签，在打字过程中按位置触发命令
## 支持命令：change（切换立绘）、wait（暂停）、speed（变速）、wait_pause（省略号停顿）

var _dialogue_manager: KND_DialogueManager
var _dialogue_box: KND_DialogueBox
var _acting_interface: KND_ActingInterface
var _typewriter: KND_TypewriterText

var _commands: Array[Dictionary] = []
var _next_cmd_index: int = 0
var _paused: bool = false
var _total_chars: int = 0
var _default_typing_interval: float = 0.0
var _suppress_typing_completed: bool = false
var _in_typing_handler: bool = false
var _skipped: bool = false
var _taking_over: bool = false  # 接管 manager tween 期间阻止信号泄漏

# 传统模式 tween 管理
var _active_tween: Tween = null

# 省略号停顿
var _ellipsis_active: bool = false
var _ellipsis_wait_done: bool = false
var _ellipsis_max_dots: int = 3
var _ellipsis_current: int = 1
var _ellipsis_cycle_timer: Timer = null
var _ellipsis_cmd_pos: int = 0


func _init(dm: KND_DialogueManager, db: KND_DialogueBox, ai: KND_ActingInterface) -> void:
	_dialogue_manager = dm
	_dialogue_box = db
	_acting_interface = ai
	if db.typewriter_text:
		_typewriter = db.typewriter_text


## 入口：每行对话开始时调用
func start_line(content: String, chara_id: String) -> void:
	var parsed := _parse_tags(content)
	_commands = parsed.commands
	_next_cmd_index = 0
	_paused = false
	_skipped = false
	_suppress_typing_completed = false
	_default_typing_interval = _dialogue_manager._typing_interval
	_total_chars = parsed.text.length()
	# 有命令时覆盖干净文本并接管 tween；无命令时透传给 manager
	if _commands.size() > 0:
		_dialogue_box.set_deferred("dialogue_text", parsed.text)
		_dialogue_box.set_deferred("character_name", chara_id)
	_connect_typing_monitor.call_deferred()


## 解析 {tag:value} 标签，返回干净文本和命令列表
func _parse_tags(raw_text: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("\\{(\\w+):([^}]+)\\}")

	var commands: Array[Dictionary] = []
	var clean_text := ""
	var last_end := 0

	for m in regex.search_all(raw_text):
		# 标签前的普通文本
		clean_text += raw_text.substr(last_end, m.get_start() - last_end)
		commands.append({
			"type": m.get_string(1),
			"pos": clean_text.length(),
			"params": m.get_string(2),
		})
		last_end = m.get_end()

	clean_text += raw_text.substr(last_end)
	return {"text": clean_text, "commands": commands}


## 连接打字进度监听
func _connect_typing_monitor() -> void:
	# 连接 dialogue_box.typing_completed（拦截信号）
	if not _dialogue_box.typing_completed.is_connected(_on_typing_completed):
		_dialogue_box.typing_completed.connect(_on_typing_completed)

	if _is_fade_in_mode():
		if _typewriter and not _typewriter.character_revealed.is_connected(_on_character_revealed):
			_typewriter.character_revealed.connect(_on_character_revealed)
		if _commands.size() > 0:
			_suppress_typing_completed = true
	else:
		# 传统模式：先设 suppress 再接管，避免 kill tween 时信号泄漏到 manager
		if _commands.size() > 0:
			_suppress_typing_completed = true
		await get_tree().process_frame
		print("[ICP] _connect_typing_monitor: frame elapsed, typing_tween valid=%s, visible_ratio=%.3f" % [
			_dialogue_box.typing_tween != null and _dialogue_box.typing_tween.is_valid(),
			_dialogue_box.dialogue_label.visible_ratio
		])
		_takeover_traditional_tween()


## 传统模式：接管 dialogue_box 的 tween
func _takeover_traditional_tween() -> void:
	if _commands.is_empty():
		return  # 无命令时透传 manager 的 tween，不做任何干预
	var db_tween := _dialogue_box.typing_tween
	print("[ICP] _takeover: db_tween valid=%s, visible_ratio=%.3f" % [db_tween != null and db_tween.is_valid(), _dialogue_box.dialogue_label.visible_ratio])
	if db_tween and db_tween.is_valid():
		_taking_over = true
		_dialogue_box.typing_tween.kill()  # _taking_over 阻止 finished 信号泄漏到 manager
		_taking_over = false
		print("[ICP]   killed manager tween")
		var label := _dialogue_box.dialogue_label
		var current_ratio := label.visible_ratio
		var remaining_chars := _total_chars - int(current_ratio * float(_total_chars))
		var remaining_time := remaining_chars * _default_typing_interval
		_active_tween = get_tree().create_tween()
		_active_tween.finished.connect(_on_typing_completed)
		_active_tween.tween_property(label, "visible_ratio", 1.0, remaining_time) \
			.set_trans(Tween.TRANS_LINEAR)
		_dialogue_box.typing_tween = _active_tween
		print("[ICP]   created _active_tween from ratio %.3f, remaining=%d, time=%.2f" % [current_ratio, remaining_chars, remaining_time])
	else:
		print("[ICP]   NO manager tween found — this is the race condition!")
		var label := _dialogue_box.dialogue_label
		var remaining_chars := _total_chars - int(label.visible_ratio * float(_total_chars))
		var remaining_time := remaining_chars * _default_typing_interval
		_active_tween = get_tree().create_tween()
		_active_tween.finished.connect(_on_typing_completed)
		_active_tween.tween_property(label, "visible_ratio", 1.0, remaining_time) \
			.set_trans(Tween.TRANS_LINEAR)
		_dialogue_box.typing_tween = _active_tween
		print("[ICP]   created _active_tween (else branch), remaining=%d, time=%.2f" % [remaining_chars, remaining_time])
	# manager tween 已被 kill，_active_tween 是唯一活跃 tween，重置 suppress
	_suppress_typing_completed = false


# ============================================================
# 打字进度监听
# ============================================================

## FADE_IN 模式：character_revealed 信号回调
func _on_character_revealed(index: int) -> void:
	_check_commands_at(index)


## 传统模式：_process 轮询 visible_ratio
func _process(_delta: float) -> void:
	if _paused:
		return
	if _commands.is_empty() or _next_cmd_index >= _commands.size():
		return
	if _is_fade_in_mode():
		return
	var label := _dialogue_box.dialogue_label
	var char_index := int(label.visible_ratio * float(_total_chars))
	_check_commands_at(char_index)


## 检查并执行当前位置的命令
func _check_commands_at(current_pos: int) -> void:
	while _next_cmd_index < _commands.size():
		var cmd: Dictionary = _commands[_next_cmd_index]
		if cmd.pos > current_pos:
			break
		print("[ICP] exec cmd[%d] '%s' pos=%d at char=%d" % [_next_cmd_index, cmd.type, cmd.pos, current_pos])
		_execute_command(cmd)
		_next_cmd_index += 1


# ============================================================
# 命令执行
# ============================================================

func _execute_command(cmd: Dictionary) -> void:
	match cmd.type:
		"change":
			_execute_change(cmd.params)
		"wait":
			_execute_wait(cmd.params.to_float())
		"speed":
			_execute_speed(cmd.params.to_float())
		"wait_pause":
			var parts: PackedStringArray = cmd.params.split(",", false)
			var seconds: float = parts[0].strip_edges().to_float()
			var max_dots: int = 3
			if parts.size() > 1:
				max_dots = clampi(parts[1].strip_edges().to_int(), 3, 6)
			_execute_wait_pause(seconds, max_dots, cmd.pos)
		_:
			push_warning("InlineCommandProcessor: 未知标签类型 '%s'" % cmd.type)


## 切换立绘状态
func _execute_change(params: String) -> void:
	var comma_idx := params.find(",")
	if comma_idx < 0:
		push_warning("change 标签格式错误，需要 {change:角色名,state}")
		return
	var actor_name := params.substr(0, comma_idx).strip_edges()
	var state := params.substr(comma_idx + 1).strip_edges()

	var actor_node := _acting_interface.get_chara_node(actor_name)
	if actor_node == null:
		push_warning("change 标签：角色 '%s' 未找到" % actor_name)
		return
	if actor_node.has_method("apply_state"):
		actor_node.call("apply_state", state)
	else:
		push_warning("change 标签：角色 '%s' 不支持 apply_state" % actor_name)


## 暂停打字
func _execute_wait(seconds: float) -> void:
	_paused = true
	if _is_fade_in_mode():
		_typewriter._playing = false
	else:
		_save_and_kill_tween()
	get_tree().create_timer(seconds).timeout.connect(_on_wait_finished)


## 变速
func _execute_speed(new_cps: float) -> void:
	if _is_fade_in_mode():
		_typewriter.chars_per_second = new_cps
	else:
		_restart_traditional_tween(1.0 / new_cps)


## 等待结束，恢复打字
func _on_wait_finished() -> void:
	if _skipped:
		return
	_paused = false
	if _is_fade_in_mode():
		_typewriter._playing = true
	else:
		_resume_traditional()


## 省略号停顿
func _execute_wait_pause(seconds: float, max_dots: int, cmd_pos: int) -> void:
	_paused = true
	_ellipsis_active = true
	_ellipsis_wait_done = false
	_ellipsis_max_dots = max_dots
	_ellipsis_current = 1
	_ellipsis_cmd_pos = cmd_pos
	print("[ICP] _execute_wait_pause: seconds=%.1f max_dots=%d visible_ratio=%.3f" % [seconds, max_dots, _dialogue_box.dialogue_label.visible_ratio])
	if _is_fade_in_mode():
		_typewriter._playing = false
	else:
		_save_and_kill_tween()
	_dialogue_box.show_ellipsis(".".repeat(_ellipsis_current))
	# 最小等待计时器
	get_tree().create_timer(seconds).timeout.connect(_on_ellipsis_wait_done)
	# 循环计时器
	_ellipsis_cycle_timer = Timer.new()
	_ellipsis_cycle_timer.wait_time = 0.4
	_ellipsis_cycle_timer.timeout.connect(_cycle_ellipsis)
	add_child(_ellipsis_cycle_timer)
	_ellipsis_cycle_timer.start()


## 省略号最小等待时间到
func _on_ellipsis_wait_done() -> void:
	_ellipsis_wait_done = true


## 省略号循环
func _cycle_ellipsis() -> void:
	_ellipsis_current += 1
	if _ellipsis_current > _ellipsis_max_dots:
		_ellipsis_current = 1
	_dialogue_box.update_ellipsis(".".repeat(_ellipsis_current))
	# 等待时间到 + 循环回到起点 → 自然结束
	if _ellipsis_wait_done and _ellipsis_current == 1:
		_end_ellipsis_pause()


## 省略号停顿结束
func _end_ellipsis_pause() -> void:
	if _ellipsis_cycle_timer:
		_ellipsis_cycle_timer.stop()
		_ellipsis_cycle_timer.queue_free()
		_ellipsis_cycle_timer = null
	_ellipsis_active = false
	_dialogue_box.hide_ellipsis()
	# 将省略号插入文本，使其成为对话内容的一部分
	if not _is_fade_in_mode():
		var label := _dialogue_box.dialogue_label
		var pos := _ellipsis_cmd_pos
		var dots := ".".repeat(_ellipsis_max_dots)
		label.text = label.text.substr(0, pos) + dots + label.text.substr(pos)
		_total_chars = label.text.length()
		var shown_chars := pos + dots.length()
		label.visible_ratio = float(shown_chars) / float(_total_chars)
		# 后续命令位置因插入省略号而偏移
		for i in range(_next_cmd_index, _commands.size()):
			_commands[i].pos += dots.length()
	_paused = false
	if _is_fade_in_mode():
		_typewriter._playing = true
	else:
		_resume_traditional()


## 暂停传统模式：保存进度，销毁 tween
func _save_and_kill_tween() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_dialogue_box.typing_tween = null


## 恢复传统模式：从保存位置重建 tween
func _resume_traditional() -> void:
	var label := _dialogue_box.dialogue_label
	var remaining_chars := _total_chars - int(label.visible_ratio * float(_total_chars))
	var remaining_time := remaining_chars * _default_typing_interval
	print("[ICP] _resume_traditional: ratio=%.3f remaining=%d time=%.3f active_tween_valid=%s" % [
		label.visible_ratio, remaining_chars, remaining_time,
		_active_tween != null and _active_tween.is_valid()
	])
	# 先杀掉可能残留的旧 tween（如 speed tween 仍在跑）
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	# 重置 suppress：原始 manager tween 已在 takeover 时被杀，后续完成不应被抑制
	_suppress_typing_completed = false
	if remaining_chars <= 0:
		print("[ICP]   already at end → emit immediately (deferred)")
		_dialogue_box.typing_completed.emit.call_deferred()
		return
	_active_tween = get_tree().create_tween()
	_active_tween.finished.connect(_on_typing_completed)
	_active_tween.tween_property(label, "visible_ratio", 1.0, remaining_time) \
		.set_trans(Tween.TRANS_LINEAR)
	_dialogue_box.typing_tween = _active_tween


## 变速（传统模式）：从当前位置用新速度重建 tween
func _restart_traditional_tween(interval: float) -> void:
	var label := _dialogue_box.dialogue_label
	print("[ICP] _restart_tween: interval=%.3f, visible_ratio=%.3f, total_chars=%d" % [interval, label.visible_ratio, _total_chars])
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	var remaining_chars := _total_chars - int(label.visible_ratio * float(_total_chars))
	var remaining_time := remaining_chars * interval
	_active_tween = get_tree().create_tween()
	_active_tween.finished.connect(_on_typing_completed)
	_active_tween.tween_property(label, "visible_ratio", 1.0, remaining_time) \
		.set_trans(Tween.TRANS_LINEAR)
	_dialogue_box.typing_tween = _active_tween
	print("[ICP]   new tween: remaining=%d, time=%.3f" % [remaining_chars, remaining_time])


# ============================================================
# 工具方法
# ============================================================

func _is_fade_in_mode() -> bool:
	return _dialogue_box.typewriter_mode == KND_DialogueBox.TypewriterMode.FADE_IN_TYPEWRITER


## 打字完成回调（拦截 dialogue_box.typing_completed）
## 发射 dialogue_box.typing_completed 以触发 dialogue_manager 的 isfinishtyping
func _on_typing_completed() -> void:
	print("[ICP] _on_typing_completed: suppress=%s, paused=%s, in_handler=%s, taking_over=%s, cmd_idx=%d/%d" % [
		_suppress_typing_completed, _paused, _in_typing_handler, _taking_over, _next_cmd_index, _commands.size()
	])
	if _in_typing_handler:
		return
	if _taking_over:
		return  # 接管 manager tween 期间，阻止 finished 信号泄漏到 manager
	_in_typing_handler = true
	if _suppress_typing_completed:
		_suppress_typing_completed = false
		if _paused:
			# 等待期间 tween 结束 — 由 speed 命令创建的 tween 跑完了，忽略
			# 玩家跳过由 skip_anim() 处理，不经过此路径
			print("[ICP]   suppress + paused (tween finished mid-wait) → ignore")
		else:
			# suppress=true, paused=false → manager tween finished during takeover, ignore
			print("[ICP]   suppress consumed (manager tween) → NOT emitting")
	elif _paused:
		# 有命令暂停中（wait/wait_pause），tween 不应在此时触发完成
		print("[ICP]   paused without suppress (speed tween finished mid-wait) → NOT emitting")
	elif _next_cmd_index >= _commands.size():
		# 所有命令已执行，打字真正完成
		print("[ICP]   all commands done → emit typing_completed")
		_dialogue_box.typing_completed.emit()
	else:
		# 还有命令未执行（理论上不应到达这里）
		print("[ICP]   commands remaining (%d/%d) → NOT emitting" % [_next_cmd_index, _commands.size()])
	_in_typing_handler = false


## 跳过动画（由 test_dialogue_screen 调用，替代 dialogue_box.skip_typing_anim）
func skip_anim() -> void:
	_skipped = true
	_suppress_typing_completed = true
	_in_typing_handler = true
	# 省略号停顿期间跳过
	if _ellipsis_active:
		if _ellipsis_cycle_timer:
			_ellipsis_cycle_timer.stop()
			_ellipsis_cycle_timer.queue_free()
			_ellipsis_cycle_timer = null
		_ellipsis_active = false
		_dialogue_box.hide_ellipsis()
		# 将省略号插入文本
		if not _is_fade_in_mode():
			var label := _dialogue_box.dialogue_label
			var pos := _ellipsis_cmd_pos
			var dots := ".".repeat(_ellipsis_max_dots)
			label.text = label.text.substr(0, pos) + dots + label.text.substr(pos)
			_total_chars = label.text.length()
	if _is_fade_in_mode():
		_typewriter.skip()
	else:
		if _active_tween and _active_tween.is_valid():
			_active_tween.kill()
		_dialogue_box.dialogue_label.visible_ratio = 1.0
	_in_typing_handler = false
	_suppress_typing_completed = false
	# 通知 dialogue_manager 流程继续
	_dialogue_box.typing_completed.emit()
