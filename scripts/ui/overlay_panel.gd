extends CanvasLayer
class_name KND_OverlayPanel

## 通用面板覆盖层基类
##
## 提供统一的打开/关闭、淡入淡出、点击外部关闭功能。
## 使用组合模式：CanvasLayer 包裹 Control 内容面板。
## 背景（暗色遮罩）由 overlay 提供，content 只提供实际内容。

signal opened
signal closed

@export var content: Control:
	set(value):
		if content and content.get_parent() == _panel:
			_panel.remove_child(content)
		content = value
		if content and _panel:
			_panel.add_child(content)

@export var fade_duration: float = 0.0
@export var background_color: Color = Color(0, 0.04, 0.06, 0.55)
@export_group("Margins")
@export var margin_left: int = 240
@export var margin_top: int = 60
@export var margin_right: int = 240
@export var margin_bottom: int = 60

var _background: ColorRect
var _margin: MarginContainer
var _panel: PanelContainer
var _fade_tween: Tween


func _ready() -> void:
	# 暗色全屏背景
	_background = ColorRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.color = background_color
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	# MarginContainer 提供边距（CenterContainer 无主题常量，不支持 margin）
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_theme_constant_override("margin_left", margin_left)
	_margin.add_theme_constant_override("margin_top", margin_top)
	_margin.add_theme_constant_override("margin_right", margin_right)
	_margin.add_theme_constant_override("margin_bottom", margin_bottom)
	add_child(_margin)

	# PanelContainer 填满 MarginContainer（viewport 减去 margins）
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_margin.add_child(_panel)

	visible = false
	set_process_input(false)
	# content 由子类在 _ready() 中赋值（父类 _ready 先于子类执行）
	# setter 中 content 被自动添加到 _panel


func open() -> void:
	if not content:
		return
	content.visible = true
	visible = true
	set_process_input(true)
	if fade_duration > 0.0:
		_panel.modulate.a = 0.0
		_background.modulate.a = 0.0
		_fade(1.0)
	opened.emit()


func close() -> void:
	if fade_duration > 0.0:
		_fade(0.0)
		if _fade_tween:
			await _fade_tween.finished
	if content:
		content.visible = false
	visible = false
	set_process_input(false)
	closed.emit()


func _input(event: InputEvent) -> void:
	if not _panel:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var panel_rect: Rect2 = _panel.get_global_rect()
		if not panel_rect.has_point(event.position):
			close()
			get_viewport().set_input_as_handled()


func _fade(target_alpha: float) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_panel, "modulate:a", target_alpha, fade_duration)
	_fade_tween.tween_property(_background, "modulate:a", target_alpha, fade_duration)
