extends Node
class_name BacklogRecorder
## 连接 dialogue_text_ready 信号，记录对话到 backlog panel

@export var backlog_panel: BacklogPanel

var _tag_regex: RegEx


func _ready() -> void:
	_tag_regex = RegEx.new()
	_tag_regex.compile("\\{\\w+:[^}]+\\}")


func start_line(content: String, character_id: String) -> void:
	if backlog_panel and not content.is_empty():
		var clean_text := _strip_tags(content)
		backlog_panel.add_entry(character_id, clean_text)


func _strip_tags(raw: String) -> String:
	return _tag_regex.sub(raw, "", true)
