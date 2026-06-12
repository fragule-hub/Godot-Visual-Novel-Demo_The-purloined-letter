extends KND_ActingInterface
class_name PortraitActingInterface

## 统一立绘表演管理器
## 根据 PortraitActorLayoutDB 中角色类型自动选择 Actor 场景（SimplePortrait / CompositePortrait）

const CLARA_ID: String = "Clara"

@export var simple_actor_scene: PackedScene = preload("res://scenes/portrait/simple_portrait.tscn")
@export var composite_actor_scene: PackedScene = preload("res://scenes/portrait/composite_portrait.tscn")
@export var actor_layout_db: Resource = preload("res://resources/portrait/project_actor_layout.tres")


# ============================================================
# 创建角色
# ============================================================

func create_new_character(chara_id: String, h_division: int, pos_h: int, state: String, tex: Texture) -> void:
	# 检查重复
	if actor_dict.has(chara_id):
		delete_character(chara_id)

	# 记录到字典
	var chara_dict: Dictionary = {
		"id": chara_id,
		"h_division": h_division,
		"pos": pos_h,
		"state": state,
	}
	actor_dict[chara_id] = chara_dict

	# 获取布局配置
	var layout_config := _get_layout_config(chara_id)

	# 根据角色类型选择 Actor 场景
	var actor_node: PortraitActorBase
	if layout_config.get("actor_type", "simple") == "composite":
		actor_node = composite_actor_scene.instantiate() as PortraitActorBase
	else:
		actor_node = simple_actor_scene.instantiate() as PortraitActorBase

	if actor_node == null:
		push_error("PortraitActingInterface: 无法实例化 Actor: %s" % chara_id)
		character_created.emit()
		return

	actor_node.name = chara_id
	actor_node.use_tween = false

	# 注入布局配置（在 add_child 之前，确保 _ready() 能读取）
	actor_node.layout_config = layout_config

	_chara_controler.add_child(actor_node)
	actor_node.h_division = h_division
	actor_node.h_character_position = pos_h
	actor_nodes[chara_id] = actor_node

	# 应用初始纹理/状态
	if layout_config.get("actor_type", "simple") == "composite":
		actor_node.call("apply_state", state)
	else:
		actor_node.set_character_texture(tex)

	actor_node.use_tween = true

	# 连接信号
	actor_node.actor_entered.connect(
		func() -> void:
			character_created.emit()
			print("新建了演员：" + chara_id + " 演员状态：" + state)
	)
	actor_node.actor_moved.connect(_on_character_moved)

	# 进场动画
	actor_node.enter_actor(true)


# ============================================================
# 切换状态
# ============================================================

func change_actor_state(actor_id: String, state_id: String, state_tex: Texture) -> void:
	var actor_node: PortraitActorBase = get_chara_node(actor_id) as PortraitActorBase
	if actor_node == null:
		push_error("切换角色状态失败：角色 '%s' 未找到" % actor_id)
		character_state_changed.emit()
		return

	actor_dict[actor_id]["state"] = state_id

	# 复合立绘（Clara）：通过 fade_apply_state 切换
	if actor_node is CompositePortraitActor:
		actor_node.fade_apply_state(state_id)
	# 简单立绘：通过 fade_set_character_texture 交叉溶解
	elif actor_node is SimplePortraitActor and state_tex != null:
		actor_node.fade_set_character_texture(state_tex)
	else:
		actor_node.set_character_texture(state_tex)

	character_state_changed.emit()
	print("切换 " + actor_id + " 到 " + state_id + " 状态")


# ============================================================
# 布局工具
# ============================================================

## 从 LayoutDB 读取角色布局配置
func _get_layout_config(chara_id: String) -> Dictionary:
	if actor_layout_db != null and actor_layout_db.has_method("get_layout"):
		var config_value: Variant = actor_layout_db.call("get_layout", chara_id)
		if config_value is Dictionary:
			return config_value
	# 默认配置
	return {
		"actor_type": "simple",
		"viewport_size": Vector2.ZERO,
		"scale": 1.0,
		"content_offset": Vector2.ZERO,
		"container_fit": "fill_height",
	}
