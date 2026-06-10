extends Resource
class_name PortraitActorLayoutDB

## 统一角色布局配置
## 每个角色包含：actor_type, viewport_size, scale, content_offset
@export var actor_layouts: Dictionary = {
	"Clara": {
		"actor_type": "composite",
		"viewport_size": Vector2(1000, 2000),
		"scale": 1.2,
		"content_offset": Vector2(0, -600),
	},
	"Eve": {
		"actor_type": "simple",
		"viewport_size": Vector2(0, 0),
		"scale": 0.9,
		"content_offset": Vector2(0, 0),
	},
}

## 旧接口兼容（已被 actor_layouts 取代，保留用于向后兼容）
@export var slot_y_offsets: Dictionary = {}


# ============================================================
# 公共接口
# ============================================================

## 获取完整布局配置
func get_layout(actor_id: String) -> Dictionary:
	var layout_value: Variant = actor_layouts.get(actor_id, {})
	if layout_value is Dictionary:
		return layout_value.duplicate(true)
	return {}


## 获取角色类型："simple" | "composite"
func get_actor_type(actor_id: String) -> String:
	var layout := get_layout(actor_id)
	return str(layout.get("actor_type", "simple"))


## 获取 Viewport 渲染尺寸
func get_viewport_size(actor_id: String) -> Vector2:
	var layout := get_layout(actor_id)
	var size_value: Variant = layout.get("viewport_size", Vector2.ZERO)
	if size_value is Vector2:
		return size_value
	if size_value is Vector2i:
		return Vector2(size_value)
	return Vector2.ZERO


## 获取缩放
func get_scale(actor_id: String) -> float:
	var layout := get_layout(actor_id)
	return float(layout.get("scale", 1.0))


## 获取内容偏移（在 VP 内）
func get_content_offset(actor_id: String) -> Vector2:
	var layout := get_layout(actor_id)
	var offset_value: Variant = layout.get("content_offset", Vector2.ZERO)
	if offset_value is Vector2:
		return offset_value
	if offset_value is Vector2i:
		return Vector2(offset_value)
	return Vector2.ZERO


# ============================================================
# 旧接口兼容
# ============================================================

func get_slot_y_offset(actor_id: String) -> float:
	var layout := get_layout(actor_id)
	if layout.has("slot_y_offset"):
		return float(layout["slot_y_offset"])
	# 回退到旧字段
	var offset_value: Variant = slot_y_offsets.get(actor_id, 0.0)
	if offset_value is float or offset_value is int:
		return float(offset_value)
	if offset_value is String and (offset_value as String).is_valid_float():
		return (offset_value as String).to_float()
	return 0.0
