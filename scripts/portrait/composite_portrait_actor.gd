@tool
extends PortraitActorBase
class_name CompositePortraitActor

## 组合立绘 Actor（Clara）
## 16 层动态组合，通过 ClaraPortraitDB + ClaraStateCodec 管理状态。
## 层结构由 portrait_db.slot_order 定义，动态创建，不依赖场景预置节点。

const CLARA_STATE_CODEC_SCRIPT: Script = preload("res://scripts/portrait/clara/clara_state_codec.gd")

@export var portrait_db: Resource

var _state_codec: RefCounted
var _current_state: Dictionary = {}
var _texture_cache: Dictionary = {}
var _missing_texture_warnings: Dictionary = {}


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	# 确保 portrait_db 已加载
	if portrait_db == null:
		portrait_db = load("res://resources/portrait/clara/clara_portrait_db.tres")
	# 初始化 state_codec
	_state_codec = CLARA_STATE_CODEC_SCRIPT.new()
	# 基类 _ready：创建 VP + 布局 + 初始渲染
	super._ready()


# ============================================================
# 内容渲染
# ============================================================

## 将所有可见层渲染到指定 SubViewport
func _render_frame_to_viewport(vp: SubViewport) -> void:
	# 清空旧内容
	for child in vp.get_children():
		child.queue_free()

	if portrait_db == null:
		return

	# 层尺寸 = VP 尺寸（VP 宽高比已匹配画布，渲染 1:1 无变形）
	var layer_size: Vector2 = vp.size

	# 读取层顺序
	var slot_order_value: Variant = portrait_db.get("slot_order")
	var slot_order: Array = []
	if slot_order_value is Array:
		slot_order = slot_order_value

	if slot_order.is_empty():
		push_warning("CompositePortraitActor: portrait_db 缺少 slot_order")
		return

	# 默认方向
	var default_direction: String = str(portrait_db.get("default_direction"))
	if default_direction.is_empty():
		default_direction = "center"
	var direction: String = str(_current_state.get("dir", default_direction))

	# 创建 LayerStack
	var layer_stack := Control.new()
	layer_stack.name = "LayerStack"
	layer_stack.position = Vector2.ZERO
	layer_stack.size = layer_size
	vp.add_child(layer_stack)

	# 按顺序创建每层 TextureRect
	for slot_name_value in slot_order:
		var slot_name: String = str(slot_name_value)
		var option_name: String = str(_current_state.get(slot_name, "none"))

		# 跳过隐藏层
		if option_name == "none" or option_name.is_empty():
			continue

		var texture_path: String = ""
		if portrait_db.has_method("get_layer_path"):
			texture_path = str(portrait_db.call("get_layer_path", direction, slot_name, option_name))

		if texture_path.is_empty():
			continue

		var texture: Texture2D = _load_layer_texture(texture_path)
		if texture == null:
			continue

		var tex_rect := TextureRect.new()
		tex_rect.name = slot_name.capitalize()
		tex_rect.texture = texture
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.size = layer_size
		tex_rect.position = Vector2.ZERO
		layer_stack.add_child(tex_rect)


# ============================================================
# 状态接口
# ============================================================

## 解析并应用状态字符串
func apply_state(state_text: String) -> void:
	if portrait_db == null:
		push_error("CompositePortraitActor: portrait_db is missing")
		return

	if _state_codec == null:
		_state_codec = CLARA_STATE_CODEC_SCRIPT.new()

	var resolved_value: Variant = _state_codec.call("resolve_state", state_text, portrait_db)
	if resolved_value is Dictionary:
		_current_state = resolved_value
	else:
		_current_state = {}

	# 非过渡模式：直接刷新当前 VP
	if _vp != null and (_old_vp == null):
		_render_frame_to_viewport(_vp)

	visible = true


## 获取当前状态快照
func get_current_state() -> Dictionary:
	return _current_state.duplicate(true)


# ============================================================
# 兼容接口
# ============================================================

func set_character_texture(texture: Texture) -> void:
	# 复合立绘不直接设置纹理，但设置 fallback
	if texture and portrait_db and portrait_db.get("fallback_texture") == null:
		portrait_db.set("fallback_texture", texture as Texture2D)


# ============================================================
# 布局
# ============================================================

func _calc_vp_size() -> Vector2:
	var config_vp: Vector2 = layout_config.get("viewport_size", Vector2.ZERO)
	if config_vp != Vector2.ZERO and config_vp.x > 0 and config_vp.y > 0:
		return config_vp

	var canvas_size: Vector2 = Vector2(1000, 2000)
	if portrait_db:
		var db_canvas: Variant = portrait_db.get("canvas_size")
		if db_canvas is Vector2i:
			canvas_size = Vector2(db_canvas)
		elif db_canvas is Vector2:
			canvas_size = db_canvas

	var scale_val: float = layout_config.get("scale", 1.0)
	if scale_val <= 0:
		scale_val = 1.0
	return canvas_size * scale_val


# ============================================================
# 纹理加载（带缓存）
# ============================================================

func _load_layer_texture(texture_path: String) -> Texture2D:
	var cached_value: Variant = _texture_cache.get(texture_path)
	if cached_value is Texture2D:
		return cached_value

	if not ResourceLoader.exists(texture_path):
		if not _missing_texture_warnings.has(texture_path):
			_missing_texture_warnings[texture_path] = true
			push_warning("CompositePortrait: layer texture not found: %s" % texture_path)
		return null

	var texture: Texture2D = load(texture_path) as Texture2D
	if texture != null:
		_texture_cache[texture_path] = texture
	return texture
