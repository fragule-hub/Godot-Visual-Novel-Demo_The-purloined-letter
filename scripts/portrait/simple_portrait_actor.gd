@tool
extends PortraitActorBase
class_name SimplePortraitActor

## 单图立绘 Actor（Eve 等简单角色）
## 持有一个 TextureRect，支持直接设置纹理或通过 state_text 切换。
## 交叉溶解通过基类 fade_apply_state 统一管道实现。

var _current_texture: Texture2D
var _inner_rect: TextureRect


# ============================================================
# 内容渲染
# ============================================================

## 将当前纹理渲染到指定 Viewport
func _render_frame_to_viewport(vp: SubViewport) -> void:
	# 清空旧内容
	for child in vp.get_children():
		child.queue_free()

	if _current_texture == null:
		return

	var content_offset: Vector2 = layout_config.get("content_offset", Vector2.ZERO)
	var vp_size: Vector2 = vp.size

	var tex_rect := TextureRect.new()
	tex_rect.name = "TextureRect"
	tex_rect.texture = _current_texture
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	tex_rect.size = vp_size
	tex_rect.position = content_offset
	vp.add_child(tex_rect)
	_inner_rect = tex_rect


# ============================================================
# 状态接口
# ============================================================

## 应用状态：优先作为资源路径加载，否则静默忽略
func apply_state(state_text: String) -> void:
	if state_text.is_empty():
		return
	if state_text == "_texture_changed":
		return  # 由 fade_set_character_texture 处理
	# 尝试作为纹理资源路径加载
	if ResourceLoader.exists(state_text):
		var res := load(state_text)
		if res is Texture2D:
			_current_texture = res
		else:
			push_warning("SimplePortraitActor: state '%s' 不是纹理" % state_text)
	# 非过渡模式：直接刷新 VP
	if _vp != null and _old_vp == null:
		_render_frame_to_viewport(_vp)


## 兼容旧接口：直接设置纹理
func set_character_texture(texture: Texture) -> void:
	if texture == null:
		return
	_current_texture = texture as Texture2D
	# 如果 VP 已存在且不在过渡中，直接刷新
	if _vp != null and _old_vp == null:
		_render_frame_to_viewport(_vp)


## 带交叉溶解的设置纹理（通过基类统一管道）
func fade_set_character_texture(new_texture: Texture) -> void:
	if new_texture == null:
		return
	_current_texture = new_texture as Texture2D
	fade_apply_state("_texture_changed")


## 获取当前纹理
func get_character_texture() -> Texture2D:
	return _current_texture
