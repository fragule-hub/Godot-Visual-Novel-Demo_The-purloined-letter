extends PanelContainer
class_name SaveSlot

## 存档槽组件
##
## 使用容器布局，场景定义静态 UI，脚本只做数据绑定。
## 与 addon SaveComponent 保持相同接口。
##
## 空存档显示原始 Label（不可交互），有存档时替换为 LineEdit（可单击编辑）。

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

## LineEdit（懒创建，仅在有存档时加入场景树）
var _name_edit: LineEdit
var _name_signals_connected := false
## LabelSettings 缓存（用于 LineEdit 和空存档 Label 还原）
var _name_font_size: int
var _name_font_color: Color
var _name_font: Font

var save_name: String = "":
	set(value):
		save_name = value
		# 更新当前活跃的名称控件
		var ctl := _active_name_control()
		if ctl:
			ctl.text = value

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
	# 从 LabelSettings 读取字体配置（作为后续 LineEdit / 空存档 Label 的基准）
	if _name_label.label_settings:
		_name_font_size = _name_label.label_settings.font_size
		_name_font_color = _name_label.label_settings.font_color
		_name_font = _name_label.label_settings.font
	else:
		_name_font_size = _name_label.get_theme_font_size("font_size")
		_name_font_color = _name_label.get_theme_color("font_color")
	_name_edit = _create_name_edit()
	_time_label.text = save_time
	_auto_label.visible = auto_save
	_apply_empty_style()
	_apply_localization()
	_update_button_visibility()

	_save_btn.pressed.connect(_on_save_pressed)
	_load_btn.pressed.connect(_on_load_pressed)
	_del_btn.pressed.connect(_on_delete_pressed)


## 创建 LineEdit（不加入场景树，继承 NameLabel 的字体配置）
func _create_name_edit() -> LineEdit:
	var edit := LineEdit.new()
	edit.name = "NameEdit"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.flat = true
	edit.editable = false
	edit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	edit.add_theme_font_size_override("font_size", _name_font_size)
	edit.add_theme_color_override("font_color", _name_font_color)
	edit.add_theme_color_override("font_uneditable_color", _name_font_color)
	if _name_font:
		edit.add_theme_font_override("font", _name_font)
	return edit


## 将 NameLabel 替换为 LineEdit（有存档时调用）
func _swap_to_edit() -> void:
	if _name_label.get_parent():
		var parent := _name_label.get_parent()
		var idx := _name_label.get_index()
		parent.remove_child(_name_label)
		parent.add_child(_name_edit)
		parent.move_child(_name_edit, idx)
	_name_edit.text = save_name
	_name_edit.editable = false
	if not _name_signals_connected:
		_name_edit.gui_input.connect(_on_name_input)
		_name_edit.text_submitted.connect(_on_name_submitted)
		_name_edit.focus_exited.connect(_on_name_focus_exited)
		_name_signals_connected = true


## 将 LineEdit 替换回 NameLabel（空存档时调用）
func _swap_to_label() -> void:
	if _name_edit and _name_edit.get_parent():
		var parent := _name_edit.get_parent()
		var idx := _name_edit.get_index()
		parent.remove_child(_name_edit)
		parent.add_child(_name_label)
		parent.move_child(_name_label, idx)
	_name_label.text = save_name


## 初始化为空存档
func init_empty_save_slot() -> void:
	is_empty = true
	save_name = tr("save_empty")
	save_time = "--/--/-- --:--"
	auto_save = false
	_swap_to_label()
	_apply_empty_style()
	_update_button_visibility()


## 设置存档系统
func set_save_system(system: KND_SaveSystem) -> void:
	save_system = system


## 返回当前在场景树中的名称控件（Label 或 LineEdit）
func _active_name_control() -> Control:
	if _name_edit and _name_edit.is_inside_tree():
		return _name_edit
	if _name_label and _name_label.is_inside_tree():
		return _name_label
	return null


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

		var custom_name: String = info.get("save_name", "")
		save_name = custom_name if not custom_name.is_empty() else tr("save_slot_name") % (save_id + 1)
		auto_save = (save_id == 0)
		_apply_normal_style()
		_swap_to_edit()
		_update_button_visibility()
	else:
		init_empty_save_slot()


func _apply_normal_style() -> void:
	add_theme_stylebox_override("panel", STYLE_NORMAL)
	if _name_edit:
		_name_edit.add_theme_color_override("font_color", _name_font_color)
		_name_edit.add_theme_color_override("font_uneditable_color", _name_font_color)
	if _time_label:
		_time_label.modulate = Color.WHITE


func _apply_empty_style() -> void:
	add_theme_stylebox_override("panel", STYLE_EMPTY)
	if _name_label:
		_name_label.label_settings = null
		_apply_label_font_overrides(_name_label)
		_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	if _time_label:
		_time_label.modulate = Color(1, 1, 1, 0.5)


func _apply_label_font_overrides(label: Label) -> void:
	label.add_theme_font_size_override("font_size", _name_font_size)
	if _name_font:
		label.add_theme_font_override("font", _name_font)


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
		# 仅当名称为用户手动编辑的自定义名时才持久化，默认模板名不写入
		var is_custom := save_name != tr("save_empty") and save_name != tr("save_slot_name") % (save_id + 1)
		var name_to_save := save_name if is_custom else ""
		var success := save_system.save_game(save_id, name_to_save)
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


# ============================================================
# 名称编辑
# ============================================================

func _on_name_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_name_edit.editable = true
		_name_edit.grab_focus()
		_name_edit.select_all()


func _on_name_submitted(new_text: String) -> void:
	_commit_name(new_text)


func _on_name_focus_exited() -> void:
	if _name_edit.editable:
		_commit_name(_name_edit.text)


func _commit_name(new_text: String) -> void:
	new_text = new_text.strip_edges()
	_name_edit.editable = false
	_name_edit.text = save_name
	if new_text.is_empty() or is_empty or not save_system:
		return
	save_name = new_text
	save_system.update_save_name(save_id, new_text)
