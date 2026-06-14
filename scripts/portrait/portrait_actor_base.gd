@tool
extends KND_Actor
class_name PortraitActorBase

## 统一立绘基类
## TextureRect 显示 SubViewport 纹理 — scale/position 直接控制，不经过容器。
## 交叉溶解用双 TextureRect alpha 渐变。

var _vp: SubViewport
var _texture_rect: TextureRect
var _overlay_rect: TextureRect

var _old_vp: SubViewport
var _transition_tween: Tween
var _pending_free_vps: Array[SubViewport] = []

var layout_config: Dictionary = {}


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	modulate.a = 1.0
	visible = false
	_setup_actor()
	_apply_layout()
	_render_frame_to_viewport(_vp)
	super._ready()


func _setup_actor() -> void:
	if _vp != null:
		return
	if not slot:
		push_warning("PortraitActorBase: slot is null")
		return

	# VP — 不可见的渲染画布
	_vp = SubViewport.new()
	_vp.name = "SubViewport"
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_vp)

	# TextureRect — 显示 VP 纹理
	_texture_rect = TextureRect.new()
	_texture_rect.name = "TextureRect"
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_texture_rect.texture = _vp.get_texture()
	slot.add_child(_texture_rect)


# ============================================================
# 布局
# ============================================================

func _calc_vp_size() -> Vector2:
	var vp_size: Vector2 = layout_config.get("viewport_size", Vector2.ZERO)
	if vp_size != Vector2.ZERO and vp_size.x > 0 and vp_size.y > 0:
		return vp_size
	return Vector2(1080, 1920)


func _apply_layout() -> void:
	if _vp == null or _texture_rect == null:
		return

	# VP 渲染分辨率
	var vp_size: Vector2 = _calc_vp_size()
	_vp.size = vp_size

	# TextureRect = VP 尺寸，1:1 显示
	_texture_rect.size = vp_size

	# scale 直接用配置值
	var actor_scale: float = layout_config.get("scale", 1.0)
	_texture_rect.scale = Vector2(actor_scale, actor_scale)

	# 底部居中于 Slot，叠加 content_offset 偏移
	var slot_w: float = maxf(slot.size.x, 1.0)
	var slot_h: float = maxf(slot.size.y, 1.0)
	var visual_w: float = vp_size.x * actor_scale
	var visual_h: float = vp_size.y * actor_scale
	var offset: Vector2 = layout_config.get("content_offset", Vector2.ZERO)
	_texture_rect.position = Vector2(
		(slot_w - visual_w) / 2.0 + offset.x,
		slot_h - visual_h + offset.y
	)

	# position_zero: 强制 TextureRect 归零（标题界面等不需要自动偏移的场景）
	if layout_config.get("position_zero", false):
		_texture_rect.position = Vector2.ZERO


# ============================================================
# 子类虚方法
# ============================================================

func _render_frame_to_viewport(_vp_target: SubViewport) -> void:
	pass


func apply_state(_state_text: String) -> void:
	pass


# ============================================================
# 交叉溶解（双 TextureRect alpha 渐变）
# ============================================================

func fade_apply_state(state_text: String) -> void:
	if _vp == null or _texture_rect == null:
		apply_state(state_text)
		return

	# 1. 终止进行中的交叉溶解，并同步纹理指针（否则 tween kill 后 _texture_rect.texture 永久停滞）
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
		_texture_rect.texture = _vp.get_texture()
		_texture_rect.modulate.a = 1.0

	# 2. 清理残留 overlay
	_cleanup_crossfade()

	# 3. 旧 VP 延迟释放，限制 pending 数量防止快速点击积累
	if _old_vp:
		_pending_free_vps.append(_old_vp)
		_old_vp = null
		while _pending_free_vps.size() > 2:
			_pending_free_vps.pop_front().queue_free()

	# 4. 恢复 _texture_rect 不透明度（已在步1处理，此处防御重复）
	if _texture_rect.modulate.a < 1.0:
		_texture_rect.modulate.a = 1.0

	# 5. 冻结当前 VP
	_old_vp = _vp

	# 6. 创建新 VP 并渲染目标状态
	var new_vp := SubViewport.new()
	new_vp.transparent_bg = true
	new_vp.size = _old_vp.size
	new_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(new_vp)

	_vp = new_vp
	apply_state(state_text)
	_render_frame_to_viewport(_vp)

	# 7. 覆盖层（alpha=0 不可见；首帧纹理未渲染时不会产生白块）
	_overlay_rect = TextureRect.new()
	_overlay_rect.name = "OverlayRect"
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_overlay_rect.texture = _vp.get_texture()
	_overlay_rect.size = _texture_rect.size
	_overlay_rect.position = _texture_rect.position
	_overlay_rect.scale = _texture_rect.scale
	_overlay_rect.modulate.a = 0.0
	slot.add_child(_overlay_rect)

	# 8. 并行 alpha 渐变
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(_texture_rect, "modulate:a", 0.0, animation_time)
	_transition_tween.tween_property(_overlay_rect, "modulate:a", 1.0, animation_time)
	_transition_tween.finished.connect(_on_crossfade_finished)


func _cleanup_crossfade() -> void:
	if _overlay_rect:
		_overlay_rect.modulate.a = 0.0
		_overlay_rect.queue_free()
		_overlay_rect = null


func _on_crossfade_finished() -> void:
	_texture_rect.texture = _vp.get_texture()
	_texture_rect.modulate.a = 1.0
	# 释放旧 VP：此时 _texture_rect 已切换至新纹理，旧 VP 安全销毁
	if _old_vp:
		_old_vp.queue_free()
		_old_vp = null
	for vp in _pending_free_vps:
		vp.queue_free()
	_pending_free_vps.clear()
	_cleanup_crossfade()


func _exit_tree() -> void:
	# 确保 Actor 销毁时释放所有 pending VP
	if _old_vp:
		_old_vp.queue_free()
		_old_vp = null
	for vp in _pending_free_vps:
		vp.queue_free()
	_pending_free_vps.clear()


# ============================================================
# 进场 / 退场 / 高亮
# ============================================================

func enter_actor(play_anim: bool = true) -> void:
	modulate.a = 0.0
	visible = true
	if not play_anim:
		modulate.a = 1.0
		actor_entered.emit()
		return
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, animation_time)
	tw.finished.connect(func() -> void: actor_entered.emit())


func exit_actor(play_anim: bool = true) -> void:
	if not play_anim:
		queue_free()
		return
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, animation_time)
	tw.finished.connect(func() -> void: queue_free())


func set_highlight(highlight: bool) -> void:
	if _texture_rect == null:
		return
	if highlight:
		_texture_rect.modulate = Color(1.0, 1.0, 1.0, _texture_rect.modulate.a)
	else:
		_texture_rect.modulate = Color(0.35, 0.35, 0.35, _texture_rect.modulate.a)


# ============================================================
# 位置同步
# ============================================================

func _on_resized() -> void:
	if slot == null:
		return

	# position_zero 模式下跳过自动位置计算（由 _apply_layout 手动定位）
	if layout_config.get("position_zero", false):
		return

	var safe_division: int = maxi(h_division, 2)
	var effective_w: float = size.x
	if effective_w <= 0.0 and is_inside_tree():
		effective_w = get_viewport_rect().size.x
	if effective_w <= 0.0:
		return

	var target_x: float = (
		effective_w / float(safe_division + 1) * float(h_character_position)
		- effective_w / 2.0
	)

	if use_tween and is_inside_tree():
		var tw: Tween = slot.create_tween()
		tw.tween_property(slot, "position:x", target_x, animation_time)
		tw.finished.connect(func() -> void: actor_moved.emit())
	else:
		slot.position.x = target_x
		actor_moved.emit()


func set_character_texture(_texture: Texture) -> void:
	pass
