extends Resource
class_name PortraitActorLayoutDB

## 统一角色布局配置：每个角色 { slot_y_offset, scale }
@export var actor_layouts: Dictionary = {
	"Eve": { "slot_y_offset": 0.0, "scale": 0.9 },
	"Clara": { "slot_y_offset": 0.0, "scale": 1.1 },
}

## 旧接口兼容（已被 actor_layouts 取代，保留用于向后兼容）
@export var slot_y_offsets: Dictionary = {}


func get_layout(actor_id: String) -> Dictionary:
	if actor_layouts.has(actor_id):
		return actor_layouts[actor_id]
	return {}


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


func get_scale(actor_id: String) -> float:
	var layout := get_layout(actor_id)
	if layout.has("scale"):
		return float(layout["scale"])
	return 1.0
