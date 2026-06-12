extends RefCounted
class_name ClaraStateCodec


func resolve_state(state_text: String, portrait_db: Resource) -> Dictionary:
	var resolved_state: Dictionary = {}
	var explicit_keys: Dictionary = {}
	
	if portrait_db:
		var default_state_value: Variant = portrait_db.get("default_state")
		if default_state_value is Dictionary:
			resolved_state = (default_state_value as Dictionary).duplicate(true)

	var trimmed_text: String = state_text.strip_edges()
	if not trimmed_text.is_empty():
		var segments: PackedStringArray = trimmed_text.split("|", false)
		for segment in segments:
			_apply_segment(segment.strip_edges(), portrait_db, resolved_state, explicit_keys)

	_apply_face_preset(portrait_db, resolved_state, explicit_keys)
	if portrait_db:
		var constrained_value: Variant = portrait_db.call("apply_constraints", resolved_state)
		if constrained_value is Dictionary:
			resolved_state = constrained_value
	return resolved_state


func _apply_segment(segment: String, portrait_db: Resource, state: Dictionary, explicit_keys: Dictionary) -> void:
	if segment.is_empty():
		return
	if segment.begins_with("preset:"):
		if portrait_db == null:
			return
		var preset_id: String = segment.substr("preset:".length()).strip_edges()
		# 按 direction → body → face 顺序查找并应用
		var preset_found: bool = false
		
		# ① 方向预设
		var dir_val: Variant = portrait_db.call("get_direction_preset", preset_id)
		if dir_val is Dictionary and not (dir_val as Dictionary).is_empty():
			_merge_preset(dir_val, state, explicit_keys)
			preset_found = true
		
		# ② 身体预设
		if not preset_found:
			var body_val: Variant = portrait_db.call("get_body_preset", preset_id)
			if body_val is Dictionary and not (body_val as Dictionary).is_empty():
				_merge_preset(body_val, state, explicit_keys)
				preset_found = true
		
		# ③ 表情预设
		if not preset_found:
			var face_val: Variant = portrait_db.call("get_face_preset", preset_id)
			if face_val is Dictionary and not (face_val as Dictionary).is_empty():
				_merge_preset(face_val, state, explicit_keys)
				preset_found = true
		
		if not preset_found:
			push_warning("ClaraStateCodec: preset '%s' 未在任何预设池中找到" % preset_id)
		return

	var separator_index: int = segment.find("=")
	if separator_index <= 0:
		return
	var key_name: String = segment.substr(0, separator_index).strip_edges()
	var value_name: String = segment.substr(separator_index + 1).strip_edges()
	if key_name.is_empty():
		return
	state[key_name] = value_name
	explicit_keys[key_name] = true


func _merge_preset(preset_state: Dictionary, state: Dictionary, explicit_keys: Dictionary) -> void:
	for key in preset_state.keys():
		state[key] = preset_state[key]
		explicit_keys[key] = true


func _apply_face_preset(portrait_db: Resource, state: Dictionary, explicit_keys: Dictionary) -> void:
	if portrait_db == null:
		return
	var face_id: String = str(state.get("face", "neutral"))
	var face_state_value: Variant = portrait_db.call("get_face_preset", face_id)
	if not face_state_value is Dictionary:
		return
	var face_state: Dictionary = face_state_value
	for key in face_state.keys():
		if not explicit_keys.has(key):
			state[key] = face_state[key]
