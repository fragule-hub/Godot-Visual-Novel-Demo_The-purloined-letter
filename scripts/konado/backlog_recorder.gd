extends Node
class_name BacklogRecorder
## 连接 dialogue_text_ready 信号，记录对话到 backlog panel

@export var backlog_panel: BacklogPanel


func start_line(content: String, character_id: String) -> void:
	if backlog_panel and not content.is_empty():
		backlog_panel.add_entry(character_id, content)
