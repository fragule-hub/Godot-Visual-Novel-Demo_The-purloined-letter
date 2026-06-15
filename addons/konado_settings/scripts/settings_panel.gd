## 设置面板 - 用于显示和管理设置的界面
extends CanvasLayer

## JSON display_name → CSV 翻译键 映射
const TR_CAT_MAP: Dictionary = {
	"音频": "cat_audio",
	"文本播放": "cat_text",
	"画面": "cat_display",
}
## JSON item label → CSV 翻译键 映射
const TR_OPT_MAP: Dictionary = {
	"主音量": "opt_master_volume",
	"音乐音量": "opt_music_volume",
	"音效音量": "opt_sfx_volume",
	"文字速度": "opt_text_speed",
	"自动等待": "opt_auto_delay",
	"自动模式": "opt_auto_mode",
	"全屏": "opt_fullscreen",
	"语言": "opt_language",
}

## 标签容器，用于显示不同分类的设置
@export var _tab_container: TabContainer

## 恢复默认按钮
@export var btn_reset: Button

## 关闭按钮
@export var btn_close: Button

## 确认对话框，用于恢复默认设置的确认
var _confirm_dialog: ConfirmationDialog

## 当前标签页的分类ID
var _current_tab_cat_id: String = ""

## 节点就绪时调用
func _ready() -> void:
	# 设置按钮文本和信号连接
	btn_reset.text = TranslationServer.translate("btn_reset")
	btn_reset.pressed.connect(_on_reset_pressed)

	btn_close.text = TranslationServer.translate("btn_close")
	btn_close.pressed.connect(_on_close_pressed)

	# 创建确认对话框
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.dialog_text = TranslationServer.translate("confirm_reset")
	_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	add_child(_confirm_dialog)

	# 从注册的分类构建标签页
	_build_tabs()

	# 订阅语言变更以刷新 UI 文本
	var mgr := _get_mgr()
	if mgr and mgr.has_signal("setting_changed"):
		mgr.setting_changed.connect(_on_setting_changed)

## 构建设置标签页
func _build_tabs() -> void:
	var mgr := _get_mgr()
	if mgr == null:
		return
	for cat: KND_SettingCategory in mgr.get_categories():
		var margc: MarginContainer = MarginContainer.new()
		margc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var cat_key: String = TR_CAT_MAP.get(cat.display_name, cat.display_name)
		var cat_translated: String = TranslationServer.translate(cat_key)
		margc.name = cat_translated
		var margin_value = 20
		margc.add_theme_constant_override("margin_top", margin_value)
		margc.add_theme_constant_override("margin_left", margin_value)
		margc.add_theme_constant_override("margin_bottom", margin_value)
		margc.add_theme_constant_override("margin_right", margin_value)

		
		var scroll := ScrollContainer.new()
		scroll.name = cat_translated
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		margc.add_child(scroll)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(vbox)

		for item: KND_SettingItem in cat.items:
			var row: HBoxContainer = KND_SettingsUIFactory.create_control(cat.id, item, _on_value_changed)
			# 翻译行标签（覆盖 create_control 中 TranslationServer.translate 对中文原文的直出）
			var label_node := row.get_child(0) as Label
			if label_node:
				var lbl_key: String = TR_OPT_MAP.get(item.label, item.label)
				label_node.text = TranslationServer.translate(lbl_key)
			vbox.add_child(row)

		_tab_container.add_child(margc, true)

## 重建UI
func rebuild() -> void:
	for child in _tab_container.get_children():
		child.queue_free()
	# 等待一帧让节点被移除
	await get_tree().create_timer(0.1).timeout
	_build_tabs()


## 当设置值改变时调用
## @param cat_id: 分类ID
## @param key: 设置项的键
## @param value: 新的设置值
func _on_value_changed(cat_id: String, key: String, value: Variant) -> void:
	var mgr := _get_mgr()
	if mgr:
		mgr.set_setting(cat_id, key, value)

## 当点击恢复默认按钮时调用
func _on_reset_pressed() -> void:
	# 获取当前标签页的分类ID
	var idx := _tab_container.current_tab
	var cats: Array = _get_mgr().get_categories() if _get_mgr() else []
	if idx >= 0 and idx < cats.size():
		_current_tab_cat_id = cats[idx].id
		_confirm_dialog.popup_centered()

## 当确认恢复默认设置时调用
func _on_reset_confirmed() -> void:
	var mgr := _get_mgr()
	if mgr and _current_tab_cat_id != "":
		mgr.reset_category(_current_tab_cat_id)
		rebuild()

## 当点击关闭按钮时调用
func _on_close_pressed() -> void:
	hide()

## 语言变更时刷新 UI
func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	if category != "display" or key != "language":
		return
	btn_reset.text = TranslationServer.translate("btn_reset")
	btn_close.text = TranslationServer.translate("btn_close")
	_confirm_dialog.dialog_text = TranslationServer.translate("confirm_reset")
	for child in _tab_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	_build_tabs()

## 获取设置管理器实例
## @return: 设置管理器节点
func _get_mgr() -> Node:
	return get_tree().root.get_node_or_null("KND_Settings")
