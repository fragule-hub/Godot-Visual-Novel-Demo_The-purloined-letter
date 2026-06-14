extends PanelContainer
class_name SaveSlot

## 存档槽组件
##
## 使用容器布局，场景定义静态 UI，脚本只做数据绑定。
## 与 addon SaveComponent 保持相同接口。

@onready var _name_label: Label = %NameLabel
@onready var _time_label: Label = %TimeLabel
@onready var _auto_label: Label = %AutoLabel
@onready var _save_btn: Button = %SaveBtn
@onready var _load_btn: Button = %LoadBtn
@onready var _del_btn: Button = %DelBtn

## 只读模式：隐藏保存按钮（标题界面纯读档场景）
@export var read_only: bool = false

const STYLE_NORMAL := preload("res://resources/theme/save_slot_bg.tres")
const STYLE_EMPTY := preload("res://resources/theme/save_slot_empty_bg.tres")

## 存档ID
var save_id: int = -1

var save_name: String = "空存档":
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
	_name_label.text = save_name
	_time_label.text = save_time
	_auto_label.visible = auto_save
	_apply_empty_style()
	_save_btn.visible = not read_only

	_save_btn.pressed.connect(_on_save_pressed)
	_load_btn.pressed.connect(_on_load_pressed)
	_del_btn.pressed.connect(_on_delete_pressed)


## 初始化为空存档
func init_empty_save_slot() -> void:
	save_name = "空存档"
	save_time = "--/--/-- --:--"
	auto_save = false
	_apply_empty_style()


## 设置存档系统
func set_save_system(system: KND_SaveSystem) -> void:
	save_system = system


## 更新存档信息
func update_save_info(info: Dictionary) -> void:
	if info and info.exists:
		var save_time_dict: Dictionary = info.get("save_time", {})
		if save_time_dict:
			var year = save_time_dict.get("year", "--")
			var month = str("%02d" % save_time_dict.get("month", 0))
			var day = str("%02d" % save_time_dict.get("day", 0))
			var hour = str("%02d" % save_time_dict.get("hour", 0))
			var minute = str("%02d" % save_time_dict.get("minute", 0))
			save_time = "%s/%s/%s %s:%s" % [year, month, day, hour, minute]
		else:
			save_time = "未知时间"

		save_name = "存档%02d" % (save_id + 1)
		auto_save = (save_id == 0)
		_apply_normal_style()
	else:
		init_empty_save_slot()


func _apply_normal_style() -> void:
	add_theme_stylebox_override("panel", STYLE_NORMAL)


func _apply_empty_style() -> void:
	add_theme_stylebox_override("panel", STYLE_EMPTY)


func _on_save_pressed() -> void:
	if save_system and save_id >= 0:
		var success := save_system.save_game(save_id)
		if success:
			update_save_info(save_system.get_save_info(save_id))


func _on_load_pressed() -> void:
	if save_system and save_id >= 0:
		save_system.load_game(save_id)


func _on_delete_pressed() -> void:
	if save_system and save_id >= 0:
		var success := save_system.delete_save(save_id)
		if success:
			init_empty_save_slot()
