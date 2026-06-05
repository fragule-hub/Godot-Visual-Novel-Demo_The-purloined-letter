@tool
extends KND_Actor
class_name ClaraCompositeActor

const CLARA_STATE_CODEC_SCRIPT: Script = preload("res://scripts/portrait/clara/clara_state_codec.gd")
const RENDER_SLOT_ORDER: Array[String] = [
	"hair_back",
	"body",
	"inner",
	"outer",
	"vest",
	"accessory",
	"hair_under",
	"head",
	"hair_side",
	"ear",
	"eyes",
	"brows",
	"mouth",
	"hair_front",
	"face_overlay",
	"hair_top"
]

@export var portrait_db: Resource

## 外部覆盖缩放值，>0 时优先于 portrait_db.display_scale
@export var override_scale: float = -1.0

var current_state: Dictionary = {}
var _layer_nodes: Dictionary = {}
var _texture_cache: Dictionary = {}
var _missing_texture_warnings: Dictionary = {}
var _state_codec: RefCounted

@onready var _layer_stack: Control = $Slot/LayerStack


func _ready() -> void:
	if portrait_db == null:
		portrait_db = load("res://resources/portrait/clara/clara_portrait_db.tres")
	_collect_layer_nodes()
	# 强制 Slot 填满父节点（防止 anchors_preset 与 anchor_right 时序竞争）
	slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_layer_render_order()
	_apply_layout()
	if current_state.is_empty():
		apply_state("preset:intro_default")
	if not resized.is_connected(_on_root_resized):
		resized.connect(_on_root_resized)
	# 延迟到布局系统更新后再计算位置，避免 slot.size 尚未生效
	_on_resized.call_deferred()


func apply_state(state_text: String) -> void:
	if portrait_db == null:
		push_error("ClaraPortraitDB is missing")
		return
	if _state_codec == null:
		_state_codec = CLARA_STATE_CODEC_SCRIPT.new()
	var previous_state: Dictionary = current_state.duplicate(true)
	var resolved_value: Variant = _state_codec.call("resolve_state", state_text, portrait_db)
	if resolved_value is Dictionary:
		current_state = resolved_value
	else:
		current_state = {}
	_apply_changed_layers(previous_state)
	visible = true


func get_current_state() -> Dictionary:
	return current_state.duplicate(true)


func set_character_texture(texture: Texture) -> void:
	if texture and portrait_db and portrait_db.get("fallback_texture") == null:
		portrait_db.set("fallback_texture", texture as Texture2D)


func set_highlight(highlight: bool) -> void:
	if not _layer_stack:
		return
	if highlight:
		_layer_stack.modulate = Color(1.0, 1.0, 1.0, _layer_stack.modulate.a)
	else:
		_layer_stack.modulate = Color(0.35, 0.35, 0.35, _layer_stack.modulate.a)


func enter_actor(play_anim: bool = true) -> void:
	modulate.a = 0.0
	visible = true
	if not play_anim:
		modulate.a = 1.0
		actor_entered.emit()
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, animation_time)
	tween.finished.connect(func() -> void: actor_entered.emit())


func exit_actor(play_anim: bool = true) -> void:
	if not play_anim:
		queue_free()
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_time)
	tween.finished.connect(func() -> void: queue_free())


func _on_resized() -> void:
	if slot == null:
		return
	var effective_w: float = size.x
	if effective_w <= 0.0 and is_inside_tree():
		effective_w = get_viewport_rect().size.x
	if effective_w <= 0.0:
		return
	var safe_division: int = maxi(h_division, 2)
	var target_x: float = -effective_w / float(safe_division) * float(safe_division - h_character_position) + effective_w / 2.0
	if use_tween and is_inside_tree():
		var tween: Tween = slot.create_tween()
		tween.tween_property(slot, "position:x", target_x, animation_time)
		tween.finished.connect(func() -> void: actor_moved.emit())
	else:
		slot.position.x = target_x
		actor_moved.emit()


func _on_root_resized() -> void:
	_apply_layout()
	_on_resized()


func _collect_layer_nodes() -> void:
	_layer_nodes = {
		"body": $Slot/LayerStack/Body,
		"hair_back": $Slot/LayerStack/HairBack,
		"hair_under": $Slot/LayerStack/HairUnder,
		"head": $Slot/LayerStack/Head,
		"hair_side": $Slot/LayerStack/HairSide,
		"ear": $Slot/LayerStack/Ear,
		"inner": $Slot/LayerStack/Inner,
		"outer": $Slot/LayerStack/Outer,
		"vest": $Slot/LayerStack/Vest,
		"eyes": $Slot/LayerStack/Eyes,
		"brows": $Slot/LayerStack/Brows,
		"mouth": $Slot/LayerStack/Mouth,
		"face_overlay": $Slot/LayerStack/FaceOverlay,
		"hair_front": $Slot/LayerStack/HairFront,
		"hair_top": $Slot/LayerStack/HairTop,
		"accessory": $Slot/LayerStack/Accessory
	}


func _apply_layer_render_order() -> void:
	if _layer_stack == null:
		return
	var target_index: int = 0
	for slot_name in RENDER_SLOT_ORDER:
		var layer_node: Node = _layer_nodes.get(slot_name) as Node
		if layer_node != null and layer_node.get_parent() == _layer_stack:
			_layer_stack.move_child(layer_node, target_index)
			target_index += 1


## 简化布局：完整显示画布，仅控制缩放和锚定位置
func _apply_layout() -> void:
	if portrait_db == null or _layer_stack == null:
		return

	# 确定有效缩放值
	var effective_scale: float = override_scale if override_scale > 0.0 else 1.42
	if portrait_db.has_method("get_display_scale") and override_scale <= 0.0:
		effective_scale = portrait_db.call("get_display_scale")

	# 读取画布尺寸
	var canvas_size: Vector2 = Vector2(1000, 2000)
	if portrait_db.get("canvas_size"):
		canvas_size = Vector2(portrait_db.get("canvas_size"))

	# 读取锚定比例
	var anchor_y: float = 0.9
	if portrait_db.get("anchor_y_ratio") != null:
		anchor_y = float(portrait_db.get("anchor_y_ratio"))

	# 计算 LayerStack 大小和位置
	var layer_size: Vector2 = canvas_size * effective_scale
	var viewport_h: float = size.y
	if viewport_h <= 0.0 and get_parent() is Control:
		viewport_h = (get_parent() as Control).size.y

	_layer_stack.custom_minimum_size = layer_size
	_layer_stack.size = layer_size
	_layer_stack.position = Vector2.ZERO
	_layer_stack.position.y = viewport_h * anchor_y - layer_size.y

	# 设置各层纹理 Rect 尺寸
	for node_value in _layer_nodes.values():
		var layer_rect: TextureRect = node_value as TextureRect
		if layer_rect:
			layer_rect.position = Vector2.ZERO
			layer_rect.custom_minimum_size = layer_size
			layer_rect.size = layer_size


func _apply_changed_layers(previous_state: Dictionary) -> void:
	var slot_order_value: Variant = portrait_db.get("slot_order")
	if not slot_order_value is Array:
		push_warning("Clara: portrait_db missing slot_order")
		return
	var previous_direction: String = str(previous_state.get("dir", ""))
	var current_direction: String = str(current_state.get("dir", ""))
	var updated_slots: Array[String] = []
	for slot_name_value in slot_order_value:
		var slot_name: String = str(slot_name_value)
		var should_update: bool = previous_state.is_empty() or previous_direction != current_direction or previous_state.get(slot_name) != current_state.get(slot_name)
		if should_update:
			updated_slots.append(slot_name)
			_set_slot_texture(slot_name, current_state)


func _set_slot_texture(slot_name: String, state: Dictionary) -> void:
	var layer_rect: TextureRect = _layer_nodes.get(slot_name) as TextureRect
	if layer_rect == null:
		push_warning("Clara: layer '%s' not found" % slot_name)
		return
	var default_direction: String = str(portrait_db.get("default_direction"))
	if default_direction.is_empty():
		default_direction = "center"
	var direction: String = str(state.get("dir", default_direction))
	var option_name: String = str(state.get(slot_name, "none"))
	var texture_path: String = str(portrait_db.call("get_layer_path", direction, slot_name, option_name))
	if texture_path.is_empty():
		layer_rect.visible = false
		layer_rect.texture = null
		return
	var texture: Texture2D = _load_layer_texture(texture_path)
	if texture == null:
		if not _missing_texture_warnings.has(texture_path):
			_missing_texture_warnings[texture_path] = true
			push_warning("Clara layer missing: %s/%s/%s -> %s" % [direction, slot_name, option_name, texture_path])
		layer_rect.visible = false
		layer_rect.texture = null
		return
	layer_rect.texture = texture
	layer_rect.visible = true


func _load_layer_texture(texture_path: String) -> Texture2D:
	var cached_value: Variant = _texture_cache.get(texture_path)
	if cached_value is Texture2D:
		return cached_value
	var texture: Texture2D = load(texture_path) as Texture2D
	if texture != null:
		_texture_cache[texture_path] = texture
	return texture
