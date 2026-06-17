extends Button
class_name LangToggleBtn

## 标题界面语言切换按钮
## 竖排显示两行：大写语言名 + 小写 LANGUAGE
## 点击循环切换：中文 → English → 日本語

const LANG_CYCLE: Array[String] = ["中文", "English", "日本語"]
const LANG_UPPER: Dictionary = {
	"中文":    "中文",
	"English": "ENGLISH",
	"日本語":  "日本語",
}

@onready var _name_label: Label = %LangNameLabel
@onready var _sub_label: Label = %LangSubLabel

var _lang_index: int = 0


func _ready() -> void:
	_sync_index_from_locale()
	_update_display()
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	_lang_index = (_lang_index + 1) % LANG_CYCLE.size()
	var display_name: String = LANG_CYCLE[_lang_index]
	GameState.apply_language(display_name)
	_update_display()


func _update_display() -> void:
	var display_name: String = LANG_CYCLE[_lang_index]
	_name_label.text = LANG_UPPER.get(display_name, display_name)
	_sub_label.text = "LANGUAGE"


## 从当前 locale 重新推算 _lang_index（外部语言变更后调用）
func _sync_index_from_locale() -> void:
	var locale := TranslationServer.get_locale()
	for i in LANG_CYCLE.size():
		if GameState.LANG_MAP.get(LANG_CYCLE[i], "zh") == locale:
			_lang_index = i
			break
