extends Control

## 标题界面脚本
## 负责 Clara 立绘初始化、菜单按钮交互、存档/设置面板集成

const CompositePortraitScene: PackedScene = preload("res://scenes/portrait/composite_portrait.tscn")
const ClaraPortraitDBRes: Resource = preload("res://resources/portrait/clara/clara_portrait_db.tres")
const SavePanelScene: PackedScene = preload("res://scenes/ui/project_save_panel.tscn")

# ── 节点引用（通过 Unique Name 获取） ──
@onready var _new_game_btn: Button = %NewGameBtn
@onready var _continue_btn: Button = %ContinueBtn
@onready var _settings_btn: Button = %SettingsBtn
@warning_ignore("unused_private_class_variable") @onready var _credits_btn: Button = %CreditsBtn
@onready var _quit_btn: Button = %QuitBtn
@onready var _clara_click_area: Control = %ClaraClickArea
@onready var _clara_placeholder: Control = %ClaraPlaceholder

# ── Clara 立绘 ──
var _clara_portrait: CompositePortraitActor
var _current_state_str: String = "dir=center|face=neutral"

# ── 随机维度 ──
var _directions: Array[String] = ["center", "left", "right"]
var _outers: Array[String] = ["none", "coat_01"]
var _all_expressions: Array[String] = [
	"neutral", "angry", "happy", "surprised", "sad", "confused",
	"serious", "confident", "embarrassed", "blush", "smirk", "mock",
	"furious", "scared", "fright", "terror", "crying", "sobbing",
	"unease", "tired", "exhausted", "sleepy", "disgusted", "nauseating",
	"kiss", "soulless", "psychotic", "stoic"
]

# ── 面板 ──
var _save_overlay: KND_OverlayPanel
@warning_ignore("unused_private_class_variable") var _credits_overlay: KND_OverlayPanel
var _save_system: KND_SaveSystem


func _ready() -> void:
	_init_clara()
	_init_save_system()
	_connect_buttons()
	_clara_click_area.gui_input.connect(_on_clara_input)
	_play_title_bgm()


# ============================================================
# Clara 初始化
# ============================================================

func _init_clara() -> void:
	_clara_portrait = CompositePortraitScene.instantiate() as CompositePortraitActor
	_clara_portrait.portrait_db = ClaraPortraitDBRes
	_clara_portrait.layout_config = {
		"viewport_size": Vector2(1000, 2000),
		"scale": 1.0,
		"position_zero": true,
	}
	_clara_placeholder.add_child(_clara_portrait)
	await get_tree().process_frame
	_clara_portrait.apply_state(_current_state_str)


# ============================================================
# 存档系统初始化（仅用于读取存档列表）
# ============================================================

func _init_save_system() -> void:
	_save_system = KND_SaveSystem.new()
	_save_system.enable_auto_save = false
	add_child(_save_system)


# ============================================================
# 按钮连接
# ============================================================

func _connect_buttons() -> void:
	_new_game_btn.pressed.connect(_on_new_game)
	_continue_btn.pressed.connect(_on_continue)
	_settings_btn.pressed.connect(_on_settings)
	_credits_btn.pressed.connect(_on_credits)
	_quit_btn.pressed.connect(_on_quit)


# ============================================================
# 按钮处理
# ============================================================

func _on_new_game() -> void:
	SceneTransition.change_scene("res://scenes/konado/test_dialogue_screen.tscn", SceneTransition.Effect.CURTAIN)


func _on_continue() -> void:
	if _save_overlay:
		_save_overlay.open()
		return

	_save_overlay = KND_OverlayPanel.new()
	_save_overlay.fade_duration = 0.25
	add_child(_save_overlay)

	var save_panel: ProjectSavePanel = SavePanelScene.instantiate()
	save_panel.save_system = _save_system
	save_panel._overlay = _save_overlay
	_save_overlay.content = save_panel
	_save_overlay.opened.connect(save_panel.on_overlay_opened)
	_save_overlay.open()

	# 覆盖存档槽的加载行为：设置 pending_save_id 后切换场景
	_override_save_slot_load_behavior(save_panel)

	# 标题界面纯读档模式：隐藏保存按钮
	for slot in save_panel._save_slots:
		if slot is SaveSlot:
			slot.read_only = true
			slot._save_btn.visible = false


func _override_save_slot_load_behavior(save_panel: ProjectSavePanel) -> void:
	# 遍历存档槽，替换 load 按钮的信号连接
	for slot in save_panel._save_slots:
		if slot is SaveSlot:
			# 断开原有的 load 信号（连接到 KND_SaveSystem.load_game）
			if slot._load_btn.pressed.is_connected(slot._on_load_pressed):
				slot._load_btn.pressed.disconnect(slot._on_load_pressed)
			# 连接到新的加载逻辑
			slot._load_btn.pressed.connect(_on_save_slot_load.bind(slot.save_id))


func _on_save_slot_load(save_id: int) -> void:
	_save_overlay.close()
	GameState.pending_save_id = save_id
	await _save_overlay.closed
	SceneTransition.change_scene("res://scenes/konado/test_dialogue_screen.tscn", SceneTransition.Effect.IRIS)


func _on_settings() -> void:
	var settings_overlay := KND_OverlayPanel.new()
	settings_overlay.fade_duration = 0.25
	add_child(settings_overlay)

	var panel: ProjectSettingsPanel = preload(
		"res://scenes/ui/project_settings_panel.tscn").instantiate()
	panel.show_return_btn = false
	panel._overlay = settings_overlay
	settings_overlay.content = panel
	settings_overlay.open()


func _on_credits() -> void:
	if _credits_overlay:
		_credits_overlay.open()
		return

	_credits_overlay = KND_OverlayPanel.new()
	_credits_overlay.fade_duration = 0.25
	add_child(_credits_overlay)

	var panel = preload("res://scenes/ui/credits_panel.tscn").instantiate()
	panel._overlay = _credits_overlay
	_credits_overlay.content = panel
	_credits_overlay.open()


func _on_quit() -> void:
	get_tree().quit()


# ============================================================
# Clara 点击交互
# ============================================================

func _on_clara_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_randomize_clara_state()


func _randomize_clara_state() -> void:
	var cur_dir: String = _get_current_dir()
	var cur_outer: String = _get_current_outer()
	var cur_face: String = _get_current_face()

	var new_state_str := ""
	for _attempt in range(20):
		var new_dir: String = cur_dir if randf() < 0.5 else _pick_other_direction(cur_dir)
		var new_outer: String = _outers[randi() % _outers.size()]
		var new_face: String = _all_expressions[randi() % _all_expressions.size()]

		if new_dir != cur_dir or new_outer != cur_outer or new_face != cur_face:
			new_state_str = "dir=%s|outer=%s|face=%s" % [new_dir, new_outer, new_face]
			break

	if new_state_str.is_empty():
		new_state_str = "dir=%s|outer=%s|face=%s" % [
			cur_dir, cur_outer, _pick_expression_different(cur_face)]

	_current_state_str = new_state_str
	_clara_portrait.fade_apply_state(new_state_str)


func _pick_other_direction(exclude: String) -> String:
	var others: Array[String] = []
	for d in _directions:
		if d != exclude:
			others.append(d)
	if others.is_empty():
		return "center"
	return others[randi() % others.size()]


func _get_current_dir() -> String:
	return _parse_state_key("dir", "center")


func _get_current_outer() -> String:
	return _parse_state_key("outer", "none")


func _get_current_face() -> String:
	return _parse_state_key("face", "neutral")


## 从 _current_state_str 中解析指定 key 的值
func _parse_state_key(key: String, default_value: String) -> String:
	var parts: PackedStringArray = _current_state_str.split("|")
	for part in parts:
		var eq_pos: int = part.find("=")
		if eq_pos > 0 and part.substr(0, eq_pos).strip_edges() == key:
			return part.substr(eq_pos + 1).strip_edges()
	return default_value


func _pick_expression_different(current: String) -> String:
	var other: String = current
	for _attempt in range(10):
		other = _all_expressions[randi() % _all_expressions.size()]
		if other != current:
			break
	return other


## 播放标题界面背景音乐（委托 BgmManager autoload）
func _play_title_bgm() -> void:
	BgmManager.play("res://assets/music/乌鸦producer/标题音乐.wav")
