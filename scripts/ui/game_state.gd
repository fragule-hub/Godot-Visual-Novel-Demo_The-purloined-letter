extends Node

## 跨场景游戏状态单例
## 用于在标题界面和游戏场景之间传递存档 ID，以及管理语言切换

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


## 根据显示名称切换语言
func apply_language(display_name: String) -> void:
	var locale: String = LANG_MAP.get(display_name, "zh")
	TranslationServer.set_locale(locale)
