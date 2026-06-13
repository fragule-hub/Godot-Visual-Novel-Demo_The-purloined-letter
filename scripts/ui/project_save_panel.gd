extends Control
class_name ProjectSavePanel

## 独立存档面板
##
## 场景提供静态 UI 结构和主题。
## 脚本负责创建 SaveSlot 存档槽和管理数据刷新。

@onready var _slot_container: VBoxContainer = %SlotContainer
@onready var _close_btn: Button = %CloseBtn

@export var save_slot_scene: PackedScene = preload("res://scenes/ui/save_slot.tscn")
@export var save_slot_count: int = 20

var save_system: KND_SaveSystem
var _overlay: KND_OverlayPanel
var _save_slots: Array[SaveSlot] = []


func _ready() -> void:
	_close_btn.pressed.connect(_on_close_pressed)
	_create_slots()


func _create_slots() -> void:
	for i in save_slot_count:
		var slot: SaveSlot = save_slot_scene.instantiate()
		if slot:
			_slot_container.add_child(slot)
			slot.save_id = i
			slot.init_empty_save_slot()
			_save_slots.append(slot)


## overlay 打开时刷新存档数据
func on_overlay_opened() -> void:
	_update_all()


func _update_all() -> void:
	if not save_system:
		return
	var infos := save_system.get_all_save_info()
	for i in mini(_save_slots.size(), infos.size()):
		_save_slots[i].set_save_system(save_system)
		_save_slots[i].update_save_info(infos[i])


func _on_close_pressed() -> void:
	if _overlay:
		_overlay.close()
