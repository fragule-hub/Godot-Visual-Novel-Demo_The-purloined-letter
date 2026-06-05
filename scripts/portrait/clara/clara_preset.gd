extends Resource
class_name ClaraPresetLibrary

@export var presets: Dictionary = {
	"intro_default": {
		"dir": "center",
		"body": "base",
		"inner": "shirt_01",
		"outer": "none",
		"vest": "none",
		"hair_back": "base",
		"hair_front": "base",
		"face": "neutral",
		"accessory": "none"
	},
	"coat_smile": {
		"dir": "center",
		"body": "base",
		"inner": "shirt_01",
		"outer": "coat_01",
		"vest": "none",
		"hair_back": "base",
		"hair_front": "base",
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
		"hair_front": "base",
		"face": "angry",
		"accessory": "ribbon"
	}
}


func get_preset(preset_id: String) -> Dictionary:
	var preset_value: Variant = presets.get(preset_id, {})
	if preset_value is Dictionary:
		var preset_state: Dictionary = preset_value
		return preset_state.duplicate(true)
	return {}