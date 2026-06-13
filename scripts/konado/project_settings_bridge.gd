extends KND_SettingsBridge
class_name ProjectSettingsBridge

## 项目级设置桥接器
##
## 继承 addon 的 KND_SettingsBridge，使用独立的 ProjectSettingsPanel。

var _settings_overlay: KND_OverlayPanel = null


func show_settings_panel() -> void:
	if _settings_overlay:
		_settings_overlay.queue_free()
		_settings_overlay = null

	_settings_overlay = KND_OverlayPanel.new()
	add_child(_settings_overlay)

	var panel: ProjectSettingsPanel = preload(
		"res://scenes/ui/project_settings_panel.tscn").instantiate()
	panel._overlay = _settings_overlay
	_settings_overlay.content = panel

	_settings_overlay.opened.connect(func(): settings_panel_opened.emit())
	_settings_overlay.closed.connect(func(): settings_panel_closed.emit())
	_settings_overlay.open()


func close_settings_panel() -> void:
	if _settings_overlay:
		_settings_overlay.close()
