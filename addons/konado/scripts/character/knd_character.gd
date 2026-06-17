extends KND_Data
class_name KND_Character

## 角色姓名（内部 ID，如 "Clara"）
@export var chara_name: String

## 多语言显示名映射（locale → 显示名），用于 highlight_actor 反查
## 示例：{"zh": "克拉拉", "en": "Clara", "ja": "クララ"}
@export var display_names: Dictionary = {}

## 角色状态图集
@export var chara_status: Array[KND_CharacterStatus]
