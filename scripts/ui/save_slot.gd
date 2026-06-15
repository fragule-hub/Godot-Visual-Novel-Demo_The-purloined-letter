extends PanelContainer
class_name SaveSlot

## 存档槽组件
##
## 使用容器布局，场景定义静态 UI，脚本只做数据绑定。
## 与 addon SaveComponent 保持相同接口。

## 读档成功信号
signal save_loaded

@onready var _name_label: Label = %NameLabel
@onready var _time_label: Label = %TimeLabel
@onready var _auto_label: Label = %AutoLabel
@onready var _save_btn: Button = %SaveBtn
@onready var _load_btn: Button = %LoadBtn
@onready var _del_btn: Button = %DelBtn

## 只读模式：隐藏保存按钮（标题界面纯读档场景）
@export var read_only: bool = false:
	set(value):
		read_only = value
		if is_inside_tree():
			_update_button_visibility()

const STYLE_NORMAL := preload("res://resources/theme/save_slot_bg.tres")
const STYLE_EMPTY := preload("res://resources/theme/save_slot_empty_bg.tres")

## 存档ID
var save_id: int = -1

## 当前是否为空存档
var is_empty: bool = true

var save_name: String = "":
	set(value):
		save_name = value
		if _name_label:
			_name_label.text = value

var save_time: String = "--/--/-- --:--":
	set(value):
		save_time = value
		if _time_label:
			_time_label.text = value

var auto_save: bool = false:
	set(value):
		auto_save = value
		if _auto_label:
			_auto_label.visible = value

## 存档系统引用
var save_system: KND_SaveSystem


func _ready() -> void:
	_name_label.text = save_name if not save_name.is_empty() else tr("save_empty")
	_time_label.text = save_time
	_auto_label.visible = auto_save
	_apply_empty_style()
	_apply_localization()
	_update_button_visibility()

	_save_btn.pressed.connect(_on_save_pressed)
	_load_btn.pressed.connect(_on_load_pressed)
	_del_btn.pressed.connect(_on_delete_pressed)


## 初始化为空存档
func init_empty_save_slot() -> void:
	is_empty = true
	save_name = tr("save_empty")
	save_time = "--/--/-- --:--"
	auto_save = false
	_apply_empty_style()
	_update_button_visibility()


## 设置存档系统
func set_save_system(system: KND_SaveSystem) -> void:
	save_system = system


## 更新存档信息
func update_save_info(info: Dictionary) -> void:
	if info and info.exists:
		is_empty = false
		var save_time_dict: Dictionary = info.get("save_time", {})
		if save_time_dict:
			var year = save_time_dict.get("year", "--")
			var month = str("%02d" % save_time_dict.get("month", 0))
			var day = str("%02d" % save_time_dict.get("day", 0))
			var hour = str("%02d" % save_time_dict.get("hour", 0))
			var minute = str("%02d" % save_time_dict.get("minute", 0))
			save_time = "%s/%s/%s %s:%s" % [year, month, day, hour, minute]
		else:
			save_time = tr("save_unknown_time")

		save_name = tr("save_slot_name") % (save_id + 1)
		auto_save = (save_id == 0)
		_apply_normal_style()
		_update_button_visibility()
	else:
		init_empty_save_slot()


func _apply_normal_style() -> void:
	add_theme_stylebox_override("panel", STYLE_NORMAL)
	if _name_label:
		_name_label.modulate = Color.WHITE
	if _time_label:
		_time_label.modulate = Color.WHITE


func _apply_empty_style() -> void:
	add_theme_stylebox_override("panel", STYLE_EMPTY)
	if _name_label:
		_name_label.modulate = Color(1, 1, 1, 0.5)
	if _time_label:
		_time_label.modulate = Color(1, 1, 1, 0.5)


## 根据上下文（read_only + is_empty）更新按钮可见性
func _update_button_visibility() -> void:
	if is_empty:
		# 空存档：只在可写模式下显示 Save 按钮
		_save_btn.visible = not read_only
		_load_btn.visible = false
		_del_btn.visible = false
	else:
		# 有内容：根据 read_only 决定 Save 按钮
		_save_btn.visible = not read_only
		_load_btn.visible = true
		_del_btn.visible = true


func _on_save_pressed() -> void:
	if save_system and save_id >= 0:
		var success := save_system.save_game(save_id)
		if success:
			update_save_info(save_system.get_save_info(save_id))


func _on_load_pressed() -> void:
	if save_system and save_id >= 0:
		var success := save_system.load_game(save_id)
		if success:
			save_loaded.emit()


func _on_delete_pressed() -> void:
	if save_system and save_id >= 0:
		var success := save_system.delete_save(save_id)
		if success:
			init_empty_save_slot()


func _apply_localization() -> void:
	_auto_label.text = tr("save_auto")
	_save_btn.text = tr("save_btn")
	_load_btn.text = tr("load_btn")
	_del_btn.text = tr("delete_btn")
