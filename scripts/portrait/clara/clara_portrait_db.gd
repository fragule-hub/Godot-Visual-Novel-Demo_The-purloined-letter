extends Resource
class_name ClaraPortraitDB

@export var preset_library: Resource
@export var canvas_size: Vector2i = Vector2i(1000, 2000)
@export var display_scale: float = 1.42
## 画布底部锚定在视口的哪个比例位置（0.0=顶部, 1.0=底部）
@export_range(0.0, 1.0) var anchor_y_ratio: float = 0.9
@export var default_direction: String = "center"
@export var directions: Array[String] = ["center", "left", "right"]
@export var fallback_texture: Texture2D
@export var slot_order: Array[String] = [
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
@export var default_state: Dictionary = {
	"dir": "center",
	"body": "base",
	"inner": "shirt_01",
	"outer": "none",
	"vest": "none",
	"hair_back": "base",
	"hair_under": "base",
	"head": "base",
	"hair_side": "base",
	"ear": "base",
	"hair_front": "base",
	"hair_top": "base",
	"face": "neutral",
	"eyes": "none",
	"brows": "none",
	"mouth": "none",
	"face_overlay": "neutral",
	"accessory": "none"
}
@export var slot_options: Dictionary = {
	"body": ["base"],
	"hair_back": ["base"],
	"hair_under": ["none", "base"],
	"head": ["none", "base"],
	"hair_side": ["none", "base"],
	"ear": ["none", "base"],
	"inner": ["shirt_01"],
	"outer": ["none", "coat_01"],
	"vest": ["none", "school_vest"],
	"eyes": ["none"],
	"brows": ["none"],
	"mouth": ["none"],
	"face_overlay": ["none", "neutral", "smile", "angry"],
	"hair_front": ["base"],
	"hair_top": ["none", "base"],
	"accessory": ["none", "ribbon", "jewelry"]
}
@export var presets: Dictionary = {
	"intro_default": {
		"dir": "center",
		"body": "base",
		"inner": "shirt_01",
		"outer": "none",
		"vest": "none",
		"hair_back": "base",
		"hair_under": "base",
		"head": "base",
		"hair_side": "base",
		"ear": "base",
		"hair_front": "base",
		"hair_top": "base",
		"face": "neutral",
		"accessory": "none"
	},
	"left_smile": {
		"dir": "left",
		"body": "base",
		"inner": "shirt_01",
		"outer": "none",
		"vest": "none",
		"hair_back": "base",
		"hair_under": "base",
		"head": "base",
		"hair_side": "base",
		"ear": "base",
		"hair_front": "base",
		"hair_top": "base",
		"face": "smile",
		"accessory": "none"
	},
	"coat_smile": {
		"dir": "center",
		"body": "base",
		"inner": "shirt_01",
		"outer": "coat_01",
		"vest": "none",
		"hair_back": "base",
		"hair_under": "base",
		"head": "base",
		"hair_side": "base",
		"ear": "base",
		"hair_front": "base",
		"hair_top": "base",
		"face": "smile",
		"accessory": "none"
	},
	"right_coat_smile": {
		"dir": "right",
		"body": "base",
		"inner": "shirt_01",
		"outer": "coat_01",
		"vest": "none",
		"hair_back": "base",
		"hair_under": "base",
		"head": "base",
		"hair_side": "base",
		"ear": "base",
		"hair_front": "base",
		"hair_top": "base",
		"face": "smile",
		"accessory": "none"
	},
	"vest_angry": {
		"dir": "center",
		"body": "base",
		"inner": "shirt_01",
		"outer": "none",
		"vest": "school_vest",
		"hair_back": "base",
		"hair_under": "base",
		"head": "base",
		"hair_side": "base",
		"ear": "base",
		"hair_front": "base",
		"hair_top": "base",
		"face": "angry",
		"accessory": "ribbon"
	}
}
@export var face_presets: Dictionary = {
	"neutral": {
		"eyes": "none",
		"brows": "none",
		"mouth": "none",
		"face_overlay": "neutral"
	},
	"smile": {
		"eyes": "none",
		"brows": "none",
		"mouth": "none",
		"face_overlay": "smile"
	},
	"angry": {
		"eyes": "none",
		"brows": "none",
		"mouth": "none",
		"face_overlay": "angry"
	}
}
@export var layer_paths: Dictionary = {
	"center": {
		"body": {"base": "res://assets/立绘/clara/layers/center/body/base.png"},
		"hair_back": {"base": "res://assets/立绘/clara/layers/center/hair_back/base.png"},
		"hair_under": {"base": "res://assets/立绘/clara/layers/center/hair_under/base.png"},
		"head": {"base": "res://assets/立绘/clara/layers/center/head/base.png"},
		"hair_side": {"base": "res://assets/立绘/clara/layers/center/hair_side/base.png"},
		"ear": {"base": "res://assets/立绘/clara/layers/center/ear/base.png"},
		"inner": {"shirt_01": "res://assets/立绘/clara/layers/center/inner/shirt_01.png"},
		"outer": {"coat_01": "res://assets/立绘/clara/layers/center/outer/coat_01.png"},
		"vest": {"school_vest": "res://assets/立绘/clara/layers/center/vest/school_vest.png"},
		"face_overlay": {
			"neutral": "res://assets/立绘/clara/layers/center/face_overlay/neutral.png",
			"smile": "res://assets/立绘/clara/layers/center/face_overlay/smile.png",
			"angry": "res://assets/立绘/clara/layers/center/face_overlay/angry.png"
		},
		"hair_front": {"base": "res://assets/立绘/clara/layers/center/hair_front/base.png"},
		"hair_top": {"base": "res://assets/立绘/clara/layers/center/hair_top/base.png"},
		"accessory": {
			"ribbon": "res://assets/立绘/clara/layers/center/accessory/ribbon.png",
			"jewelry": "res://assets/立绘/clara/layers/center/accessory/jewelry.png"
		}
	},
	"left": {
		"body": {"base": "res://assets/立绘/clara/layers/left/body/base.png"},
		"hair_back": {"base": "res://assets/立绘/clara/layers/left/hair_back/base.png"},
		"hair_under": {"base": "res://assets/立绘/clara/layers/left/hair_under/base.png"},
		"head": {"base": "res://assets/立绘/clara/layers/left/head/base.png"},
		"hair_side": {"base": "res://assets/立绘/clara/layers/left/hair_side/base.png"},
		"ear": {"base": "res://assets/立绘/clara/layers/left/ear/base.png"},
		"inner": {"shirt_01": "res://assets/立绘/clara/layers/left/inner/shirt_01.png"},
		"outer": {"coat_01": "res://assets/立绘/clara/layers/left/outer/coat_01.png"},
		"vest": {"school_vest": "res://assets/立绘/clara/layers/left/vest/school_vest.png"},
		"face_overlay": {
			"neutral": "res://assets/立绘/clara/layers/left/face_overlay/neutral.png",
			"smile": "res://assets/立绘/clara/layers/left/face_overlay/smile.png",
			"angry": "res://assets/立绘/clara/layers/left/face_overlay/angry.png"
		},
		"hair_front": {"base": "res://assets/立绘/clara/layers/left/hair_front/base.png"},
		"hair_top": {"base": "res://assets/立绘/clara/layers/left/hair_top/base.png"},
		"accessory": {
			"ribbon": "res://assets/立绘/clara/layers/left/accessory/ribbon.png",
			"jewelry": "res://assets/立绘/clara/layers/left/accessory/jewelry.png"
		}
	},
	"right": {
		"body": {"base": "res://assets/立绘/clara/layers/right/body/base.png"},
		"hair_back": {"base": "res://assets/立绘/clara/layers/right/hair_back/base.png"},
		"hair_under": {"base": "res://assets/立绘/clara/layers/right/hair_under/base.png"},
		"head": {"base": "res://assets/立绘/clara/layers/right/head/base.png"},
		"hair_side": {"base": "res://assets/立绘/clara/layers/right/hair_side/base.png"},
		"ear": {"base": "res://assets/立绘/clara/layers/right/ear/base.png"},
		"inner": {"shirt_01": "res://assets/立绘/clara/layers/right/inner/shirt_01.png"},
		"outer": {"coat_01": "res://assets/立绘/clara/layers/right/outer/coat_01.png"},
		"vest": {"school_vest": "res://assets/立绘/clara/layers/right/vest/school_vest.png"},
		"face_overlay": {
			"neutral": "res://assets/立绘/clara/layers/right/face_overlay/neutral.png",
			"smile": "res://assets/立绘/clara/layers/right/face_overlay/smile.png",
			"angry": "res://assets/立绘/clara/layers/right/face_overlay/angry.png"
		},
		"hair_front": {"base": "res://assets/立绘/clara/layers/right/hair_front/base.png"},
		"hair_top": {"base": "res://assets/立绘/clara/layers/right/hair_top/base.png"},
		"accessory": {
			"ribbon": "res://assets/立绘/clara/layers/right/accessory/ribbon.png",
			"jewelry": "res://assets/立绘/clara/layers/right/accessory/jewelry.png"
		}
	}
}
@export var conflict_rules: Array[Dictionary] = []


func get_preset(preset_id: String) -> Dictionary:
	if preset_library:
		var library_preset_value: Variant = preset_library.call("get_preset", preset_id)
		if library_preset_value is Dictionary:
			var library_preset: Dictionary = library_preset_value
			if not library_preset.is_empty():
				return library_preset
	var preset_value: Variant = presets.get(preset_id, {})
	if preset_value is Dictionary:
		var preset_state: Dictionary = preset_value
		return preset_state.duplicate(true)
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


func get_slot_options(slot_name: String) -> Array[String]:
	var options: Array[String] = []
	var options_value: Variant = slot_options.get(slot_name, [])
	if options_value is Array:
		for option_value in options_value:
			options.append(str(option_value))
	return options


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
