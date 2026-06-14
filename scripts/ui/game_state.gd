extends Node

## 跨场景游戏状态单例
## 用于在标题界面和游戏场景之间传递存档 ID

## 待加载的存档 ID（-1 表示无待加载存档）
var pending_save_id: int = -1
