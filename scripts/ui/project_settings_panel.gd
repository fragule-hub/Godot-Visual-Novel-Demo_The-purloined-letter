extends Control
class_name ProjectSettingsPanel

## 独立设置面板
##
## 场景提供静态 UI 结构和主题。
## 脚本只负责从 KND_Settings 构建 TabContainer 标签页。

const SETTINGS_THEME := preload("res://resources/theme/settings_theme.tres")

## JSON display_name → CSV 翻译键 映射
const TR_CAT_MAP: Dictionary = {
	"音频": "cat_audio",
	"文本播放": "cat_text",
	"画面": "cat_display",
}
## JSON item label → CSV 翻译键 映射（不含语言选项）
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

@onready var _tab_container: TabContainer = %TabContainer
@onready var _reset_btn: Button = %ResetBtn
@onready var _close_btn: Button = %CloseBtn
@onready var _return_btn: Button = %ReturnBtn
@onready var _title_label: Label = %Label

var _confirm_dialog: ConfirmationDialog
var _overlay: KND_OverlayPanel  ## 由外部设置
## 是否显示"返回主界面"按钮（标题界面打开时隐藏，对话场景打开时显示）
var show_return_btn: bool = true
## 标签页重建代数（防止 await 期间的信号触发导致重复重建）
var _rebuild_generation: int = 0


func _ready() -> void:
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.dialog_text = tr("confirm_reset")
	_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	add_child(_confirm_dialog)

	_reset_btn.pressed.connect(_on_reset_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_return_btn.pressed.connect(_on_return_pressed)
	_return_btn.visible = show_return_btn

	_apply_localization()
	_build_tabs()

	# 订阅语言变更
	var mgr := get_node_or_null("/root/KND_Settings")
	if mgr and mgr.has_signal("setting_changed"):
		mgr.setting_changed.connect(_on_setting_changed)


func _build_tabs() -> void:
	var mgr := _get_mgr()
	if not mgr:
		return
	for cat: KND_SettingCategory in mgr.get_categories():
		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var cat_key: String = TR_CAT_MAP.get(cat.display_name, cat.display_name)
		margin.name = tr(cat_key)
		margin.theme = SETTINGS_THEME
		for side in ["margin_top", "margin_left", "margin_bottom", "margin_right"]:
			margin.add_theme_constant_override(side, 20)

		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(scroll)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(vbox)

		for item: KND_SettingItem in cat.items:
			if "debug" in item.platforms:
				continue
			var row := KND_SettingsUIFactory.create_control(cat.id, item, _on_value_changed)
			# 翻译行标签（create_control 是 addon 静态方法，无法直接使用映射）
			var label_node := row.get_child(0) as Label
			if label_node:
				var lbl_key: String = TR_OPT_MAP.get(item.label, item.label)
				label_node.text = tr(lbl_key)
			_upgrade_toggle(row)
			vbox.add_child(row)

		_tab_container.add_child(margin)


## 将 addon 工厂创建的 CheckBox 替换为更大的 CheckButton，并放大 OptionButton
func _upgrade_toggle(row: HBoxContainer) -> void:
	for child in row.get_children():
		if child is CheckBox:
			var toggle := CheckButton.new()
			toggle.button_pressed = child.button_pressed
			toggle.custom_minimum_size = Vector2(120, 40)
			# 重连信号：找到原有的 toggled 回调并转移到新控件
			for conn in child.get_signal_connection_list("toggled"):
				toggle.toggled.connect(conn["callable"])
			row.remove_child(child)
			child.queue_free()
			row.add_child(toggle)
			break
		elif child is OptionButton:
			child.custom_minimum_size = Vector2(180, 40)
			break


func _on_value_changed(cat_id: String, key: String, value: Variant) -> void:
	var mgr := _get_mgr()
	if mgr:
		mgr.set_setting(cat_id, key, value)


func _on_reset_pressed() -> void:
	var idx := _tab_container.current_tab
	var cats: Array = _get_mgr().get_categories() if _get_mgr() else []
	if idx >= 0 and idx < cats.size():
		_confirm_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	var idx := _tab_container.current_tab
	var cats: Array = _get_mgr().get_categories() if _get_mgr() else []
	if idx >= 0 and idx < cats.size():
		var mgr := _get_mgr()
		if mgr:
			mgr.reset_category(cats[idx].id)
			for child in _tab_container.get_children():
				child.queue_free()
			await get_tree().process_frame
			_build_tabs()


func _on_close_pressed() -> void:
	if _overlay:
		_overlay.close()


func _on_return_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/title_screen.tscn", SceneTransition.Effect.SLIDE)


func _get_mgr() -> Node:
	return get_tree().root.get_node_or_null("KND_Settings")


func _apply_localization() -> void:
	_title_label.text = tr("settings_title")
	_reset_btn.text = tr("btn_reset")
	_close_btn.text = tr("btn_close")
	_return_btn.text = tr("btn_return")
	_confirm_dialog.dialog_text = tr("confirm_reset")


func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	if category == "display" and key == "language":
		GameState.apply_language(value)
		_apply_localization()
		# 代数递增：await 期间再次触发时，旧代数的重建会被跳过
		_rebuild_generation += 1
		var gen := _rebuild_generation
		for child in _tab_container.get_children():
			child.queue_free()
		await get_tree().process_frame
		if gen != _rebuild_generation:
			return
		_build_tabs()
