extends Control

@export var dialogue_manager: KND_DialogueManager

var _inline_processor: InlineCommandProcessor


func _ready() -> void:
	if dialogue_manager:
		dialogue_manager.custom_signal.connect(_on_custom_signal)
		dialogue_manager.shot_end.connect(_on_shot_end)
		# 内联命令处理器
		_inline_processor = InlineCommandProcessor.new(
			dialogue_manager,
			dialogue_manager._konado_dialogue_box,
			dialogue_manager._acting_interface
		)
		add_child(_inline_processor)
		dialogue_manager.dialogue_text_ready.connect(_inline_processor.start_line)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_custom_signal(content: String) -> void:
	print("Konado custom signal: " + content)


func _on_shot_end() -> void:
	print("Test dialogue finished")
