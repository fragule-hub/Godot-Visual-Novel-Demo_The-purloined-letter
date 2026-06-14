extends CanvasLayer

## 场景切换过渡管理器（autoload）
## 提供 4 种场景切换特效：Fade / Curtain / Iris / Slide
## 使用 shader + Tween 驱动 progress 参数实现过渡动画
## 过渡完成后发射 transition_finished 信号，通知新场景可以开始

enum Effect { FADE, CURTAIN, IRIS, SLIDE }

signal transition_finished

const SHADERS := {
	Effect.FADE:    preload("res://resources/transition/fade.gdshader"),
	Effect.CURTAIN: preload("res://resources/transition/curtain.gdshader"),
	Effect.IRIS:    preload("res://resources/transition/iris.gdshader"),
	Effect.SLIDE:   preload("res://resources/transition/slide.gdshader"),
}

var _rect: ColorRect
var _tween: Tween
var _transitioning := false


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.name = "TransitionRect"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color.BLACK
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func is_transitioning() -> bool:
	return _transitioning


func change_scene(path: String, effect := Effect.FADE, duration := 0.5) -> void:
	if _transitioning:
		return
	_transitioning = true

	# 阻挡输入；恢复 modulate.a 使 shader 输出可见
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_rect.modulate.a = 1.0

	# 切换 shader，设置初始 progress = 0
	var shader: Shader = SHADERS.get(effect, SHADERS[Effect.FADE])
	if _rect.material == null or _rect.material.shader != shader:
		_rect.material = ShaderMaterial.new()
		_rect.material.shader = shader
	_rect.material.set_shader_parameter("progress", 0.0)

	# 淡出：progress 0 → 1
	_tween = create_tween()
	_tween.tween_property(_rect.material, "shader_parameter/progress", 1.0, duration)
	await _tween.finished
	_rect.material.set_shader_parameter("progress", 1.0)

	# 切换场景
	get_tree().change_scene_to_file(path)

	# 淡入：progress 1 → 0
	_tween = create_tween()
	_tween.tween_property(_rect.material, "shader_parameter/progress", 0.0, duration)
	await _tween.finished
	_rect.material.set_shader_parameter("progress", 0.0)

	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_transitioning = false
	transition_finished.emit()
