extends Node
class_name KND_SaveSystem

## KND_SaveSystem

## 调试日志开关
const DEBUG_LOG := false
##
## 基于快照原理的存档系统核心类，负责创建、存储和恢复游戏状态的快照
## 支持对话系统的存档/读档功能，与现有对话管理系统无缝集成

## 存档完成
signal save_completed(save_id: int, success: bool)

## 读档完成
signal load_completed(save_id: int, success: bool)

## 存档目录
const SAVE_DIR = "user://konado_saves/"

## 存档文件扩展名
const SAVE_EXT = ".kns"

## 最大存档数量
@export var max_save_slots: int = 20

## 自动存档间隔（秒）
@export var auto_save_interval: float = 30.0

## 是否启用自动存档
@export var enable_auto_save: bool = true

## 存档策略配置
@export var save_strategy: Dictionary = {
	"include_dialogue_state": true,
	"include_variables": true,
	"include_audio_state": true,
	"include_actor_state": true,
	"include_background_state": true
}

## 对话管理器引用
var dialogue_manager: KND_DialogueManager

## 自动存档计时器
var auto_save_timer: Timer

func _ready() -> void:
	# 确保存档目录存在
	_dir_check()
	
	# 初始化自动存档计时器
	if enable_auto_save:
		auto_save_timer = Timer.new()
		auto_save_timer.wait_time = auto_save_interval
		auto_save_timer.autostart = true
		auto_save_timer.timeout.connect(_auto_save)
		add_child(auto_save_timer)

## 检查并创建存档目录
func _dir_check() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

## 设置对话管理器
func set_dialogue_manager(manager: KND_DialogueManager) -> void:
	dialogue_manager = manager

## 创建存档
func save_game(save_id: int, save_name: String = "") -> bool:
	if save_id < 0 or save_id >= max_save_slots:
		printerr("存档ID超出范围")
		return false
	
	if not dialogue_manager:
		printerr("对话管理器未设置")
		return false
	
	# 创建存档数据
	var save_data = KND_SaveData.new()
	
	# 填充存档数据
	if save_strategy["include_dialogue_state"]:
		save_data.dialogue_state = _capture_dialogue_state()
	
	if save_strategy["include_variables"]:
		if dialogue_manager.variable_store:
			save_data.variables = dialogue_manager.variable_store.to_dict()
		else:
			save_data.variables = {}
	
	if save_strategy["include_audio_state"]:
		save_data.audio_state = _capture_audio_state()
	
	if save_strategy["include_actor_state"]:
		save_data.actor_state = _capture_actor_state()
	
	if save_strategy["include_background_state"]:
		save_data.background_state = _capture_background_state()
	
	# 添加存档元数据
	save_data.save_time = Time.get_datetime_dict_from_system()
	save_data.version = "1.0"
	if not save_name.is_empty():
		save_data.save_name = save_name
	
	# 序列化为JSON
	var json = JSON.stringify(save_data.to_dict())
	if json == "":
		printerr("存档序列化失败")
		return false
	
	# 写入文件
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		printerr("无法打开存档文件进行写入")
		return false
	
	file.store_string(json)
	file.close()
	
	print("存档成功: " + OS.get_user_data_dir() + "/" + save_path.replace("user://", ""))
	save_completed.emit(save_id, true)
	return true

## 加载存档
func load_game(save_id: int) -> bool:
	if save_id < 0 or save_id >= max_save_slots:
		printerr("存档ID超出范围")
		return false
	
	if not dialogue_manager:
		printerr("对话管理器未设置")
		return false
	
	# 读取存档文件
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		printerr("无法打开存档文件进行读取")
		return false
	
	var json = file.get_as_text().strip_edges()
	file.close()
	
	# 反序列化为存档数据
	var parse_result = JSON.parse_string(json)
	if typeof(parse_result) != TYPE_DICTIONARY:
		printerr("存档解析失败")
		return false
	
	var save_data = KND_SaveData.new()
	save_data.from_dict(parse_result)
	
	# 恢复游戏状态
	if save_strategy["include_dialogue_state"] and save_data.dialogue_state:
		_restore_dialogue_state(save_data.dialogue_state)
	
	# 恢复背景状态
	if save_strategy["include_background_state"] and save_data.background_state:
		_restore_background_state(save_data.background_state)
	
	# 恢复演员状态
	if save_strategy["include_actor_state"] and save_data.actor_state:
		_restore_actor_state(save_data.actor_state)
	
	# 恢复音频状态
	if save_strategy["include_audio_state"] and save_data.audio_state:
		_restore_audio_state(save_data.audio_state)
	
	# 恢复游戏变量
	if save_strategy["include_variables"] and save_data.variables:
		if dialogue_manager.variable_store:
			dialogue_manager.variable_store.from_dict(save_data.variables)
		else:
			dialogue_manager.variable_store = KND_VariableStore.new()
			dialogue_manager.variable_store.from_dict(save_data.variables)
	
	# 读档恢复完成后的打字机处理
	if dialogue_manager._konado_dialogue_box:
		var box = dialogue_manager._konado_dialogue_box
		# _restore_dialogue_state 设文字触发了 update_dialogue_content，
		# 其异步 tween 会在演员恢复期间启动，读档后直接显示全文
		if box.typing_tween and box.typing_tween.is_valid():
			box.typing_tween.kill()
		box.dialogue_label.visible_ratio = 1.0
	
	print("读档成功: " + save_path)
	load_completed.emit(save_id, true)
	return true

## 删除存档
func delete_save(save_id: int) -> bool:
	if save_id < 0 or save_id >= max_save_slots:
		printerr("存档ID超出范围")
		return false
	
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	if not FileAccess.file_exists(save_path):
		return true  # 文件不存在，视为删除成功
	
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path)) == OK

## 获取存档信息
func get_save_info(save_id: int) -> Dictionary:
	if save_id < 0 or save_id >= max_save_slots:
		return {"exists": false}
	
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	if not FileAccess.file_exists(save_path):
		return {"exists": false}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {"exists": false}
	
	var json = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json)
	if typeof(parse_result) != TYPE_DICTIONARY:
		return {"exists": false}
	
	return {
		"save_time": parse_result.get("save_time", {}),
		"version": parse_result.get("version", ""),
		"save_name": parse_result.get("save_name", ""),
		"exists": true
	}

## 获取所有存档信息
func get_all_save_info() -> Array[Dictionary]:
	var save_infos: Array[Dictionary] = []
	for i in range(max_save_slots):
		save_infos.append(get_save_info(i))
	return save_infos


## 单独更新存档名称（不触发完整存档流程）
func update_save_name(save_id: int, new_name: String) -> bool:
	if save_id < 0 or save_id >= max_save_slots:
		return false
	var save_path := SAVE_DIR + str(save_id) + SAVE_EXT
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false
	var json := file.get_as_text()
	file.close()
	var data := JSON.parse_string(json)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	data["save_name"] = new_name
	var out := FileAccess.open(save_path, FileAccess.WRITE)
	if not out:
		return false
	out.store_string(JSON.stringify(data))
	out.close()
	return true

## 自动存档
func _auto_save() -> void:
	save_game(0)  # 自动存档到0号槽位

## 捕获对话状态
func _capture_dialogue_state() -> Dictionary:
	var state = {}
	var pre := dialogue_manager._pre_break_save
	var use_pre := not pre.is_empty()

	# 保存章节 ID（语言无关）
	if not dialogue_manager._current_chapter_id.is_empty():
		state["chapter_id"] = dialogue_manager._current_chapter_id

	# node_id：有转场快照时用快照的（跳过 scene_break），否则用当前的
	state["current_node_id"] = pre["node_id"] if use_pre else dialogue_manager.cur_node_id

	# 保存对话状态
	state["dialogue_state"] = dialogue_manager.dialogueState

	return state

## 恢复对话状态
func _restore_dialogue_state(state: Dictionary) -> void:
	var shot: KND_Shot = null

	# 使用 chapter_id 查表（按当前语言加载对应 .ks 文件）
	if state.has("chapter_id") and not state["chapter_id"].is_empty():
		var path := dialogue_manager.get_chapter_path(state["chapter_id"])
		if path:
			shot = dialogue_manager._ks_compiler.compile_file(path)

	if shot:
		dialogue_manager.set_shot(shot)
		# 先 set_shot 再设 chapter_id（set_shot 内部会清空 _current_chapter_id）
		if state.has("chapter_id") and not state["chapter_id"].is_empty():
			dialogue_manager._current_chapter_id = state["chapter_id"]

	# 回退方案：先尝试按当前语言加载起始章节，兜底到 start_dialogue_shot
	elif dialogue_manager._start_chapter_id:
		var fallback_path := dialogue_manager.get_chapter_path(dialogue_manager._start_chapter_id)
		if not fallback_path.is_empty():
			var fallback_shot := dialogue_manager._ks_compiler.compile_file(fallback_path)
			if fallback_shot:
				dialogue_manager.set_shot(fallback_shot)
				dialogue_manager._current_chapter_id = dialogue_manager._start_chapter_id
			elif dialogue_manager.start_dialogue_shot:
				dialogue_manager.set_shot(dialogue_manager.start_dialogue_shot)
		elif dialogue_manager.start_dialogue_shot:
			dialogue_manager.set_shot(dialogue_manager.start_dialogue_shot)
	elif dialogue_manager.start_dialogue_shot:
		dialogue_manager.set_shot(dialogue_manager.start_dialogue_shot)

	# 恢复对话节点ID
	if state.has("current_node_id"):
		var node_id: String = state["current_node_id"]
		if dialogue_manager.cur_dialogue_shot and dialogue_manager.cur_dialogue_shot.find_node(node_id) != null:
			dialogue_manager.cur_node_id = node_id
		elif dialogue_manager.cur_dialogue_shot:
			dialogue_manager.cur_node_id = dialogue_manager.cur_dialogue_shot.start_node_id
		else:
			dialogue_manager.cur_node_id = ""

	# 恢复对话状态
	if state.has("dialogue_state"):
		dialogue_manager._dialogue_goto_state(state["dialogue_state"])

	# 恢复对话框内容：从新编译的脚本读取当前语言的文本
	if dialogue_manager._konado_dialogue_box:
		var dialog = dialogue_manager._current_dialogue()
		if dialog and dialog.dialog_type == KND_Dialogue.Type.ORDINARY_DIALOG:
			var content := dialogue_manager._interpolate_variables(dialog.dialog_content)
			dialogue_manager._konado_dialogue_box.dialogue_text = content
			dialogue_manager._konado_dialogue_box.character_name = dialog.character_id

## 捕获音频状态
func _capture_audio_state() -> Dictionary:
	var state = {}

	if dialogue_manager and dialogue_manager._audio_interface:
		var audio_interface = dialogue_manager._audio_interface

		# 保存BGM状态（使用 BgmManager autoload，跨场景持久化）
		var bgm_stream: AudioStream = BgmManager.get_current_stream()
		if bgm_stream:
			state["bgm"] = {
				"stream_path": bgm_stream.resource_path,
				"is_playing": BgmManager.is_playing(),
				"volume_db": 0.0
			}

		# 保存语音状态
		if audio_interface.voice_player and audio_interface.voice_player.stream:
			state["voice"] = {
				"stream_path": audio_interface.voice_player.stream.resource_path,
				"is_playing": audio_interface.voice_player.is_playing(),
				"volume_db": audio_interface.voice_player.volume_db
			}

		# 保存音效状态
		if audio_interface.sound_effect_player and audio_interface.sound_effect_player.stream:
			state["sound_effect"] = {
				"stream_path": audio_interface.sound_effect_player.stream.resource_path,
				"is_playing": audio_interface.sound_effect_player.is_playing(),
				"volume_db": audio_interface.sound_effect_player.volume_db
			}

	return state

## 恢复音频状态
func _restore_audio_state(state: Dictionary) -> void:
	if not dialogue_manager or not dialogue_manager._audio_interface:
		return
	
	var audio_interface = dialogue_manager._audio_interface
	
	# 恢复BGM状态（使用 BgmManager autoload）
	if state.has("bgm"):
		var bgm_state = state["bgm"]
		if bgm_state.has("stream_path"):
			var bgm_stream = load(bgm_state["stream_path"])
			if bgm_stream:
				if bgm_state.has("is_playing") and bgm_state["is_playing"]:
					BgmManager.play_stream(bgm_stream)
				else:
					# BGM 未在播放，仅预加载 stream（不播放）
					pass
	
	# 恢复语音状态
	if state.has("voice"):
		var voice_state = state["voice"]
		if voice_state.has("stream_path"):
			var voice_stream = load(voice_state["stream_path"])
			if voice_stream:
				audio_interface.voice_player.stream = voice_stream
				if voice_state.has("volume_db"):
					audio_interface.voice_player.volume_db = voice_state["volume_db"]
				if voice_state.has("is_playing") and voice_state["is_playing"]:
					audio_interface.voice_player.play()
	
	# 恢复音效状态
	if state.has("sound_effect"):
		var se_state = state["sound_effect"]
		if se_state.has("stream_path"):
			var se_stream = load(se_state["stream_path"])
			if se_stream:
				audio_interface.sound_effect_player.stream = se_stream
				if se_state.has("volume_db"):
					audio_interface.sound_effect_player.volume_db = se_state["volume_db"]
				if se_state.has("is_playing") and se_state["is_playing"]:
					audio_interface.sound_effect_player.play()

## 捕获演员状态
func _capture_actor_state() -> Dictionary:
	var state = {}
	var pre := dialogue_manager._pre_break_save
	var use_pre := not pre.is_empty()

	if use_pre:
		state["actors"] = []
		for actor_id in pre["actors"].keys():
			var actor_data = pre["actors"][actor_id]
			state["actors"].append({
				"id": actor_id,
				"h_division": actor_data.get("h_division", 6),
				"pos_h": actor_data.get("pos", 0),
				"state": actor_data.get("state", ""),
				"c_scale": actor_data.get("c_scale", 1.0),
				"mirror": actor_data.get("mirror", false)
			})
	elif dialogue_manager and dialogue_manager._acting_interface:
		var acting_interface = dialogue_manager._acting_interface
		state["actors"] = []
		for actor_id in acting_interface.actor_dict.keys():
			var actor_data = acting_interface.actor_dict[actor_id]
			var actor_node = acting_interface.get_chara_node(actor_id)
			if actor_node:
				state["actors"].append({
					"id": actor_id,
					"h_division": actor_data.get("h_division", 6),
					"pos_h": actor_data.get("pos", 0),
					"state": actor_data.get("state", ""),
					"c_scale": actor_data.get("c_scale", 1.0),
					"mirror": actor_data.get("mirror", false)
				})

	return state

## 恢复演员状态
func _restore_actor_state(state: Dictionary) -> void:
	if not dialogue_manager or not dialogue_manager._acting_interface:
		return

	var acting_interface = dialogue_manager._acting_interface

	# 先删除所有现有演员
	acting_interface.delete_all_actor()

	# 等待一帧，确保所有旧的演员节点都已经被完全删除
	await get_tree().process_frame

	# 恢复演员状态
	if state.has("actors"):
		for actor_state in state["actors"]:
			var actor_id = actor_state.get("id", "")
			if actor_id:
				# 查找对应的角色数据
				var target_chara = null
				if dialogue_manager.chara_list:
					for chara in dialogue_manager.chara_list.characters:
						if chara.chara_name == actor_id:
							target_chara = chara
							break

				if target_chara:
					# 查找对应的状态纹理
					var state_name = actor_state.get("state", "")
					var state_tex = null
					for chara_state in target_chara.chara_status:
						if chara_state.status_name == state_name:
							state_tex = chara_state.status_texture
							break

					# 创建演员（组合立绘系统忽略 tex，通过 state 文本恢复）
					acting_interface.create_new_character(
						actor_id,
						actor_state.get("h_division", 6),
						actor_state.get("pos_h", 0),
						state_name,
						state_tex
					)

					# 等待一帧，确保演员节点能够正确创建
					await get_tree().process_frame
				else:
					push_warning("存档恢复：角色 '%s' 未在 chara_list 中找到" % actor_id)

## 捕获背景状态
func _capture_background_state() -> Dictionary:
	var state = {}
	var pre := dialogue_manager._pre_break_save
	var use_pre := not pre.is_empty()

	if use_pre:
		state["background_id"] = pre["background_id"]
		if pre["background_texture"]:
			state["background_texture_path"] = pre["background_texture"].resource_path
	elif dialogue_manager and dialogue_manager._acting_interface:
		var acting_interface = dialogue_manager._acting_interface
		state["background_id"] = acting_interface.background_id
		if acting_interface.current_texture:
			state["background_texture_path"] = acting_interface.current_texture.resource_path

	return state

## 恢复背景状态
func _restore_background_state(state: Dictionary) -> void:
	if not dialogue_manager or not dialogue_manager._acting_interface:
		return
	
	var acting_interface = dialogue_manager._acting_interface
	
	# 恢复背景状态
	if state.has("background_id") and state.has("background_texture_path"):
		var bg_id = state["background_id"]
		var bg_tex_path = state["background_texture_path"]
		
		# 确保bg_tex_path不为空
		if bg_tex_path and bg_tex_path != "":
			var bg_tex = load(bg_tex_path)
			
			if bg_tex:
				acting_interface.change_background_image(
					bg_tex,
					bg_id,
					KND_ActingInterface.BackgroundTransitionEffectsType.NONE_EFFECT
				)
			else:
				print("无法加载背景纹理: " + bg_tex_path)
