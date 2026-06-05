extends KND_ActingInterface
class_name ClaraActingInterface

const CLARA_ID: String = "Clara"

@export var clara_actor_scene: PackedScene = preload("res://scenes/portrait/clara/clara_composite_actor.tscn")
@export var actor_layout_db: Resource = preload("res://resources/portrait/project_actor_layout.tres")


func create_new_character(chara_id: String, h_division: int, pos_h: int, state: String, tex: Texture) -> void:
	if chara_id != CLARA_ID:
		super.create_new_character(chara_id, h_division, pos_h, state, tex)
		_apply_project_actor_layout(chara_id)
		return

	if actor_dict.has(chara_id):
		delete_character(chara_id)

	var chara_dict: Dictionary = {
		"id": chara_id,
		"h_division": h_division,
		"pos": pos_h,
		"state": state
	}
	actor_dict[chara_id] = chara_dict

	var actor_node: KND_Actor = clara_actor_scene.instantiate() as KND_Actor
	if actor_node == null:
		push_error("Failed to instantiate ClaraCompositeActor")
		character_created.emit()
		return

	actor_node.name = chara_id
	actor_node.use_tween = false
	# 在 add_child 之前预设缩放，确保 _ready() → _apply_layout() 使用正确的值
	var actor_scale: float = _get_actor_scale(chara_id)
	if actor_scale > 0.0 and "override_scale" in actor_node:
		actor_node.set("override_scale", actor_scale)
	_chara_controler.add_child(actor_node)
	actor_node.h_division = h_division
	actor_node.h_character_position = pos_h
	actor_nodes[chara_id] = actor_node
	actor_node.call("apply_state", state)
	actor_node.use_tween = true
	actor_node.actor_entered.connect(
		func() -> void:
			character_created.emit()
			print("新建了演员：" + chara_id + " 演员状态：" + state)
	)
	actor_node.actor_moved.connect(_on_character_moved)
	_apply_project_actor_layout(chara_id)
	actor_node.enter_actor(true)


func _apply_project_actor_layout(chara_id: String) -> void:
	var actor_node: KND_Actor = actor_nodes.get(chara_id) as KND_Actor
	if actor_node == null:
		return

	var actor_slot: Control = actor_node.get("slot") as Control
	if actor_slot == null:
		actor_slot = actor_node.get_node_or_null("Slot") as Control
	if actor_slot == null:
		return

	# 应用缩放（override_scale 已在 create_new_character 中预设）
	var actor_scale: float = _get_actor_scale(chara_id)
	if actor_scale > 0.0:
		if not ("override_scale" in actor_node):
			actor_slot.scale = Vector2(actor_scale, actor_scale)
			# 底部对齐：补偿缩放导致的向上偏移
			var viewport_h: float = actor_node.size.y
			if viewport_h > 0.0:
				actor_slot.position.y = viewport_h * (1.0 - actor_scale)

	# 应用垂直偏移（在 scale 之后，覆盖缩放产生的 y 偏移）
	var slot_y_offset: float = _get_actor_slot_y_offset(chara_id)
	if not is_zero_approx(slot_y_offset):
		actor_slot.position.y = slot_y_offset


func _get_actor_slot_y_offset(chara_id: String) -> float:
	if actor_layout_db != null and actor_layout_db.has_method("get_slot_y_offset"):
		return float(actor_layout_db.call("get_slot_y_offset", chara_id))
	return 0.0


func _get_actor_scale(chara_id: String) -> float:
	if actor_layout_db != null and actor_layout_db.has_method("get_scale"):
		return float(actor_layout_db.call("get_scale", chara_id))
	return -1.0


func change_actor_state(actor_id: String, state_id: String, state_tex: Texture) -> void:
	if actor_id != CLARA_ID:
		super.change_actor_state(actor_id, state_id, state_tex)
		return

	var chara_node: Node = get_chara_node(actor_id)
	if chara_node == null:
		push_error("切换 Clara 状态失败：未找到角色节点")
		character_state_changed.emit()
		return

	actor_dict[actor_id]["state"] = state_id
	if chara_node.has_method("apply_state"):
		chara_node.call("apply_state", state_id)
	else:
		push_error("切换 Clara 状态失败：节点不是 ClaraCompositeActor")
	character_state_changed.emit()
	print("切换 Clara 到 " + state_id + " 状态")
