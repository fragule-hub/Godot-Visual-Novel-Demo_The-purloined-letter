extends Resource
class_name ClaraPortraitDB

@export var canvas_size: Vector2i = Vector2i(1000, 2000)
@export var display_scale: float = 1.42
## 画布底部锚定在视口的哪个比例位置（0.0=顶部, 1.0=底部）
@export_range(0.0, 1.0) var anchor_y_ratio: float = 0.9
@export var default_direction: String = "center"
@export var directions: Array[String] = ["center", "left", "right"]
@export var fallback_texture: Texture2D
## 组件化渲染顺序
@export var slot_order: Array[String] = [
	"hair_back",
	"body",
	"outer",
	"face",
	"hair_side",
	"ear",
	"hair_front",
	"hair_top"
]
@export var default_state: Dictionary = {
	"dir": "center",
	"body": "base",
	"outer": "none",
	"hair_back": "base",
	"hair_side": "none",
	"ear": "base",
	"face": "neutral",
	"hair_front": "base",
	"hair_top": "base"
}
## ── 3重预设系统 ──
## 方向预设：只设 dir（KS语法: preset:dir_left）
@export var direction_presets: Dictionary = {
	"dir_center": {"dir": "center"},
	"dir_left":   {"dir": "left", "hair_side": "base"},
	"dir_right":  {"dir": "right", "hair_side": "base"},
}
## 身体预设：只设 outer
@export var body_presets: Dictionary = {
	"body_casual":      {"outer": "none"},
	"body_coat":        {"outer": "coat_01"},
}
## 表情：统一通过 face=xxx 调用，不使用 preset 别名
@export var face_presets: Dictionary = {}
@export var layer_paths: Dictionary = {
	"center": {
		"body": {"base": "res://assets/立绘/clara/layers/center/body/base.png"},
		"hair_back": {"base": "res://assets/立绘/clara/layers/center/hair_back/base.png"},
		"ear": {"base": "res://assets/立绘/clara/layers/center/ear/base.png"},
		"outer": {"coat_01": "res://assets/立绘/clara/layers/center/outer/coat_01.png"},
		"face": {
			"angry": "res://assets/立绘/clara/layers/center/face/angry.png",
			"blush": "res://assets/立绘/clara/layers/center/face/blush.png",
			"confident": "res://assets/立绘/clara/layers/center/face/confident.png",
			"confused": "res://assets/立绘/clara/layers/center/face/confused.png",
			"crying": "res://assets/立绘/clara/layers/center/face/crying.png",
			"disgusted": "res://assets/立绘/clara/layers/center/face/disgusted.png",
			"embarrassed": "res://assets/立绘/clara/layers/center/face/embarrassed.png",
			"exhausted": "res://assets/立绘/clara/layers/center/face/exhausted.png",
			"fright": "res://assets/立绘/clara/layers/center/face/fright.png",
			"furious": "res://assets/立绘/clara/layers/center/face/furious.png",
			"happy": "res://assets/立绘/clara/layers/center/face/happy.png",
			"kiss": "res://assets/立绘/clara/layers/center/face/kiss.png",
			"mock": "res://assets/立绘/clara/layers/center/face/mock.png",
			"nauseating": "res://assets/立绘/clara/layers/center/face/nauseating.png",
			"neutral": "res://assets/立绘/clara/layers/center/face/neutral.png",
			"psychotic": "res://assets/立绘/clara/layers/center/face/psychotic.png",
			"sad": "res://assets/立绘/clara/layers/center/face/sad.png",
			"scared": "res://assets/立绘/clara/layers/center/face/scared.png",
			"serious": "res://assets/立绘/clara/layers/center/face/serious.png",
			"sleepy": "res://assets/立绘/clara/layers/center/face/sleepy.png",
			"smirk": "res://assets/立绘/clara/layers/center/face/smirk.png",
			"sobbing": "res://assets/立绘/clara/layers/center/face/sobbing.png",
			"soulless": "res://assets/立绘/clara/layers/center/face/soulless.png",
			"stoic": "res://assets/立绘/clara/layers/center/face/stoic.png",
			"surprised": "res://assets/立绘/clara/layers/center/face/surprised.png",
			"terror": "res://assets/立绘/clara/layers/center/face/terror.png",
			"tired": "res://assets/立绘/clara/layers/center/face/tired.png",
			"unease": "res://assets/立绘/clara/layers/center/face/unease.png"
		},
		"hair_front": {"base": "res://assets/立绘/clara/layers/center/hair_front/base.png"},
		"hair_top": {"base": "res://assets/立绘/clara/layers/center/hair_top/base.png"}
	},
	"left": {
		"body": {"base": "res://assets/立绘/clara/layers/left/body/base.png"},
		"hair_back": {"base": "res://assets/立绘/clara/layers/left/hair_back/base.png"},
		"hair_side": {"base": "res://assets/立绘/clara/layers/left/hair_side/base.png"},
		"ear": {"base": "res://assets/立绘/clara/layers/left/ear/base.png"},
		"outer": {"coat_01": "res://assets/立绘/clara/layers/left/outer/coat_01.png"},
		"face": {
			"angry": "res://assets/立绘/clara/layers/left/face/angry.png",
			"blush": "res://assets/立绘/clara/layers/left/face/blush.png",
			"confident": "res://assets/立绘/clara/layers/left/face/confident.png",
			"confused": "res://assets/立绘/clara/layers/left/face/confused.png",
			"crying": "res://assets/立绘/clara/layers/left/face/crying.png",
			"disgusted": "res://assets/立绘/clara/layers/left/face/disgusted.png",
			"embarrassed": "res://assets/立绘/clara/layers/left/face/embarrassed.png",
			"exhausted": "res://assets/立绘/clara/layers/left/face/exhausted.png",
			"fright": "res://assets/立绘/clara/layers/left/face/fright.png",
			"furious": "res://assets/立绘/clara/layers/left/face/furious.png",
			"happy": "res://assets/立绘/clara/layers/left/face/happy.png",
			"kiss": "res://assets/立绘/clara/layers/left/face/kiss.png",
			"mock": "res://assets/立绘/clara/layers/left/face/mock.png",
			"nauseating": "res://assets/立绘/clara/layers/left/face/nauseating.png",
			"neutral": "res://assets/立绘/clara/layers/left/face/neutral.png",
			"psychotic": "res://assets/立绘/clara/layers/left/face/psychotic.png",
			"sad": "res://assets/立绘/clara/layers/left/face/sad.png",
			"scared": "res://assets/立绘/clara/layers/left/face/scared.png",
			"serious": "res://assets/立绘/clara/layers/left/face/serious.png",
			"sleepy": "res://assets/立绘/clara/layers/left/face/sleepy.png",
			"smirk": "res://assets/立绘/clara/layers/left/face/smirk.png",
			"sobbing": "res://assets/立绘/clara/layers/left/face/sobbing.png",
			"soulless": "res://assets/立绘/clara/layers/left/face/soulless.png",
			"stoic": "res://assets/立绘/clara/layers/left/face/stoic.png",
			"surprised": "res://assets/立绘/clara/layers/left/face/surprised.png",
			"terror": "res://assets/立绘/clara/layers/left/face/terror.png",
			"tired": "res://assets/立绘/clara/layers/left/face/tired.png",
			"unease": "res://assets/立绘/clara/layers/left/face/unease.png"
		},
		"hair_front": {"base": "res://assets/立绘/clara/layers/left/hair_front/base.png"},
		"hair_top": {"base": "res://assets/立绘/clara/layers/left/hair_top/base.png"}
	},
	"right": {
		"body": {"base": "res://assets/立绘/clara/layers/right/body/base.png"},
		"hair_back": {"base": "res://assets/立绘/clara/layers/right/hair_back/base.png"},
		"hair_side": {"base": "res://assets/立绘/clara/layers/right/hair_side/base.png"},
		"ear": {"base": "res://assets/立绘/clara/layers/right/ear/base.png"},
		"outer": {"coat_01": "res://assets/立绘/clara/layers/right/outer/coat_01.png"},
		"face": {
			"angry": "res://assets/立绘/clara/layers/right/face/angry.png",
			"blush": "res://assets/立绘/clara/layers/right/face/blush.png",
			"confident": "res://assets/立绘/clara/layers/right/face/confident.png",
			"confused": "res://assets/立绘/clara/layers/right/face/confused.png",
			"crying": "res://assets/立绘/clara/layers/right/face/crying.png",
			"disgusted": "res://assets/立绘/clara/layers/right/face/disgusted.png",
			"embarrassed": "res://assets/立绘/clara/layers/right/face/embarrassed.png",
			"exhausted": "res://assets/立绘/clara/layers/right/face/exhausted.png",
			"fright": "res://assets/立绘/clara/layers/right/face/fright.png",
			"furious": "res://assets/立绘/clara/layers/right/face/furious.png",
			"happy": "res://assets/立绘/clara/layers/right/face/happy.png",
			"kiss": "res://assets/立绘/clara/layers/right/face/kiss.png",
			"mock": "res://assets/立绘/clara/layers/right/face/mock.png",
			"nauseating": "res://assets/立绘/clara/layers/right/face/nauseating.png",
			"neutral": "res://assets/立绘/clara/layers/right/face/neutral.png",
			"psychotic": "res://assets/立绘/clara/layers/right/face/psychotic.png",
			"sad": "res://assets/立绘/clara/layers/right/face/sad.png",
			"scared": "res://assets/立绘/clara/layers/right/face/scared.png",
			"serious": "res://assets/立绘/clara/layers/right/face/serious.png",
			"sleepy": "res://assets/立绘/clara/layers/right/face/sleepy.png",
			"smirk": "res://assets/立绘/clara/layers/right/face/smirk.png",
			"sobbing": "res://assets/立绘/clara/layers/right/face/sobbing.png",
			"soulless": "res://assets/立绘/clara/layers/right/face/soulless.png",
			"stoic": "res://assets/立绘/clara/layers/right/face/stoic.png",
			"surprised": "res://assets/立绘/clara/layers/right/face/surprised.png",
			"terror": "res://assets/立绘/clara/layers/right/face/terror.png",
			"tired": "res://assets/立绘/clara/layers/right/face/tired.png",
			"unease": "res://assets/立绘/clara/layers/right/face/unease.png"
		},
		"hair_front": {"base": "res://assets/立绘/clara/layers/right/hair_front/base.png"},
		"hair_top": {"base": "res://assets/立绘/clara/layers/right/hair_top/base.png"}
	}
}
@export var conflict_rules: Array[Dictionary] = [
	{"when": {"dir": "left"}, "set": {"hair_side": "base"}},
	{"when": {"dir": "right"}, "set": {"hair_side": "base"}},
	{"when": {"dir": "center"}, "set": {"hair_side": "none"}},
]


func get_direction_preset(preset_id: String) -> Dictionary:
	var val: Variant = direction_presets.get(preset_id, {})
	if val is Dictionary:
		return (val as Dictionary).duplicate(true)
	return {}


func get_body_preset(preset_id: String) -> Dictionary:
	var val: Variant = body_presets.get(preset_id, {})
	if val is Dictionary:
		return (val as Dictionary).duplicate(true)
	return {}


func get_face_preset(face_id: String) -> Dictionary:
	var face_value: Variant = face_presets.get(face_id, {})
	if face_value is Dictionary:
		var face_state: Dictionary = face_value
		return face_state.duplicate(true)
	return {}


func get_layer_path(direction: String, slot_name: String, option_name: String) -> String:
	if option_name.is_empty() or option_name == "none" or option_name == "default":
		return ""
	var direct_path: String = _get_layer_path_exact(direction, slot_name, option_name)
	if not direct_path.is_empty():
		return direct_path
	if direction != default_direction:
		direct_path = _get_layer_path_exact(default_direction, slot_name, option_name)
		if not direct_path.is_empty():
			return direct_path

	var default_option: String = str(default_state.get(slot_name, ""))
	if default_option.is_empty() or default_option == option_name or default_option == "none":
		return ""
	direct_path = _get_layer_path_exact(direction, slot_name, default_option)
	if not direct_path.is_empty():
		return direct_path
	if direction != default_direction:
		return _get_layer_path_exact(default_direction, slot_name, default_option)
	return ""


func get_defined_layer_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for direction_key in layer_paths.keys():
		var direction_value: Variant = layer_paths.get(direction_key, {})
		if not direction_value is Dictionary:
			continue
		var direction_map: Dictionary = direction_value
		for slot_key in direction_map.keys():
			var slot_value: Variant = direction_map.get(slot_key, {})
			if not slot_value is Dictionary:
				continue
			var slot_map: Dictionary = slot_value
			for option_key in slot_map.keys():
				var layer_path: String = str(slot_map.get(option_key, ""))
				if not layer_path.is_empty():
					paths.append(layer_path)
	return paths


func apply_constraints(state: Dictionary) -> Dictionary:
	var normalized_state: Dictionary = state.duplicate(true)
	for rule in conflict_rules:
		var when_value: Variant = rule.get("when", {})
		var set_value: Variant = rule.get("set", {})
		if not when_value is Dictionary or not set_value is Dictionary:
			continue
		var when_state: Dictionary = when_value
		if _state_matches(normalized_state, when_state):
			var set_state: Dictionary = set_value
			for key in set_state.keys():
				normalized_state[key] = set_state[key]
	return normalized_state


func get_display_scale() -> float:
	if display_scale <= 0.0:
		return 1.42
	return display_scale


func _get_layer_path_exact(direction: String, slot_name: String, option_name: String) -> String:
	var direction_value: Variant = layer_paths.get(direction, {})
	if not direction_value is Dictionary:
		return ""
	var direction_map: Dictionary = direction_value
	var slot_value: Variant = direction_map.get(slot_name, {})
	if not slot_value is Dictionary:
		return ""
	var slot_map: Dictionary = slot_value
	return str(slot_map.get(option_name, ""))


func _state_matches(state: Dictionary, expected: Dictionary) -> bool:
	for key in expected.keys():
		if not state.has(key) or state[key] != expected[key]:
			return false
	return true
