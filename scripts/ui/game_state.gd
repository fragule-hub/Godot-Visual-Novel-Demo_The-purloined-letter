extends Node

## 跨场景游戏状态单例
## 用于在标题界面和游戏场景之间传递存档 ID，以及管理语言切换

## 语言变更信号
signal language_changed

## 待加载的存档 ID（-1 表示无待加载存档）
var pending_save_id: int = -1

## 语言映射：显示名称 → locale 代码
const LANG_MAP: Dictionary = {
	"中文": "zh",
	"English": "en",
	"日本語": "ja",
}


func _ready() -> void:
	_apply_saved_language()


## 应用语言设置（从 KND_Settings 读取并切换 TranslationServer locale）
func _apply_saved_language() -> void:
	var mgr := get_node_or_null("/root/KND_Settings")
	if mgr:
		var lang = mgr.get_setting("display", "language")
		if lang:
			apply_language(lang)
		else:
			# 首次启动：根据系统地区自动选择语言
			_auto_detect_language(mgr)


## 首次启动时根据系统地区自动选择语言
func _auto_detect_language(mgr: Node) -> void:
	var sys_locale := OS.get_locale()  # 如 "zh_CN", "ja_JP", "en_US"
	var lang_prefix := sys_locale.substr(0, 2)
	var display_name: String
	match lang_prefix:
		"zh": display_name = "中文"
		"ja": display_name = "日本語"
		_:    display_name = "English"
	mgr.set_setting("display", "language", display_name)
	apply_language(display_name)


## 根据显示名称切换语言（唯一入口，自带去重和持久化）
func apply_language(display_name: String) -> void:
	var locale: String = LANG_MAP.get(display_name, "zh")
	if locale == TranslationServer.get_locale():
		return  # 去重：locale 未变时跳过
	TranslationServer.set_locale(locale)
	# 持久化到 KND_Settings
	var mgr := get_node_or_null("/root/KND_Settings")
	if mgr:
		mgr.set_setting("display", "language", display_name)
	language_changed.emit()
