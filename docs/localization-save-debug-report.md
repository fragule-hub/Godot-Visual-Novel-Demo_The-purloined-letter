# 本地化系统与存读档系统交叉问题排查报告

## 概述

2026-06-28 排查并修复了视觉小说项目中英文模式下章节切换卡死、读档回退中文、读档回到第一章开头的问题。

## 问题现象

| # | 现象 | 触发条件 |
|---|------|----------|
| 1 | 英文下第一章结束后卡死在转场动画（黑屏后无新内容） | 语言设为 English，播放至 Chapter 1 末尾 |
| 2 | 存档后读档，回到第一章开头 | 在 Chapter 1→2 切换卡死后存档，再读档 |
| 3 | 读档后对话框文字变为中文 | 同问题 2，读档后显示中文内容 |

## 排查过程

### 第一轮：代码审查

审查了本地化系统、存读档系统、章节切换逻辑的完整链路。

**涉及文件：**
- `addons/konado/scripts/dialogue/knd_dialogue_manager.gd` — 对话管理器、章节切换
- `addons/konado/scripts/save_system/knd_save_system.gd` — 存读档
- `story/chapter_map.json` — 章节语言路径映射

**发现的关键线索：**
- `_execute_jump_transition` 中先设 `_current_chapter_id = "chapter2"`，后调用 `set_shot(res)` → 而 `set_shot` 会把 `_current_chapter_id` 清空为 `""`
- 读档回退逻辑直接使用中文的 `start_dialogue_shot` 兜底

### 第二轮：日志分析

添加调试日志后运行游戏，获得以下关键日志：

```
set_shot: 之后 _current_chapter_id=
切换状态到: 1 → 当前状态：播放状态
切换背景为: test_room 过渡效果: 4
背景过渡动画完成
切换状态到: 2 → PAUSED
触发自动下一个信号
PAUSED→OFF: next_id 为空 (cur_node_id=ks_node_1)
切换状态到: 0 → OFF
```

确认章节切换代码和读档回退代码中存在 `_current_chapter_id` 被错误清空的 bug，以及章节 2 剧本编译缓存过时导致节点不完整的问题。

## 根因分析

### 根因 1：`_current_chapter_id` 被 `set_shot` 错误清空

**位置：** `knd_dialogue_manager.gd` — `_execute_jump_transition()` 和 `_restore_dialogue_state()`

**问题：** 
- `_execute_jump_transition` 中先设 `_current_chapter_id = chapter_id`（如 "chapter2"）
- 后调用 `set_shot(res)` → 内部会将 `_current_chapter_id` 清空为 `""`
- 导致存档时 `_capture_dialogue_state()` 不保存 chapter_id
- 读档时没有 chapter_id → 无法按语言查找到对应剧本 → 回退到中文 `start_dialogue_shot`

**影响链路：**
```
章节切换 → _current_chapter_id 被清空 → 存档丢失 chapter_id → 读档回退中文
```

### 根因 2：剧本导入缓存过时

**位置：** `.godot/imported/chapter2.ks-*.res`

**问题：**
- English chapter2.ks 的编译缓存文件在剧本只有一句 `background test_room fade` 占位时生成
- 后续增补了完整剧本内容（约 16.6KB），但缓存没有自动重新生成
- 运行游戏时 `ResourceLoader.load()` 加载的是过时缓存，KND_Shot 中只有 1 个节点
- 导致章节 2 第一条指令（背景切换）完成后，`next_id` 为空，系统进入 OFF 状态

**诊断依据：**
- 源文件大小：英文 16.6KB / 中文 14.7KB / 日文 19.2KB
- 缓存文件大小：三份均仅 ~715 bytes（明显与源文件不匹配）

### 根因 3：信号连接未正确断开

**位置：** `knd_dialogue_manager.gd` — `_auto_process_next()`

**问题：**
- 连接时用 `_auto_process_next.bind(s)`（带参数的 BoundCallable）
- 断开时用 `_auto_process_next`（不带参数的裸 Callable）
- 两者永远不匹配，`disconnect()` 永不执行 → 信号连接跨章节累积
- 在章节切换后，累积的信号回调可能导致状态混乱

## 修复方案

### 修复 1：调换 `_current_chapter_id` 赋值顺序

**修改文件：** `knd_dialogue_manager.gd`

`_execute_jump_transition` 中：

```gdscript
# 修改前（错误顺序）
_current_chapter_id = chapter2    // 先设
set_shot(res)                      // 后被清空

# 修改后（正确顺序）
set_shot(res)                      // 先设（内部清空 _current_chapter_id）
_current_chapter_id = chapter2    // 后恢复
```

同样的修复也应用于 `_restore_dialogue_state`（`knd_save_system.gd`）。

### 修复 2：优化读档回退链

**修改文件：** `knd_save_system.gd`

当 `chapter_id` 丢失或编译失败时，不再直接回退到中文 `start_dialogue_shot`，改为：
1. 先尝试按当前语言加载起始章节（`chapter1`）
2. 仅当所有尝试都失败时，才兜底到 `start_dialogue_shot`

### 修复 3：修复信号断开逻辑

**修改文件：** `knd_dialogue_manager.gd`

`_auto_process_next` 中用 BoundCallable 匹配和断开连接：

```gdscript
# 修改前
if s.is_connected(_auto_process_next):     // 裸 Callable，永不匹配
    s.disconnect(_auto_process_next)

# 修改后
var bound := _auto_process_next.bind(s)
if s.is_connected(bound):                  // BoundCallable，正确匹配
    s.disconnect(bound)
```

### 修复 4：清除过时的导入缓存

**操作：** 删除了 `story/en/chapter2.ks` 对应的 `.res` 和 `.md5` 缓存文件，touch 源文件触发编辑器重新导入。

## 验证方式

1. 将语言设为 English，播放至 Chapter 1 末尾
2. 观察是否能正常切换到 Chapter 2（背景和对话正常显示）
3. 在 Chapter 2 中进行存档 → 退出游戏 → 读档
4. 验证读档后内容为英文、章节位置正确

## 相关文件

| 文件 | 修改类型 | 说明 |
|------|----------|------|
| `addons/konado/scripts/dialogue/knd_dialogue_manager.gd` | 逻辑修复 | `set_shot` 和 `_current_chapter_id` 的赋值顺序、信号断开 |
| `addons/konado/scripts/save_system/knd_save_system.gd` | 逻辑修复 | `set_shot` 和 chapter_id 的顺序、读档回退链优化 |
| `.godot/imported/chapter2.ks-bb6e2318bda662b2814a3da4ceb140ed.res` | 删除 | 过时的英文 chapter2 编译缓存 |
| `story/chapter_map.json` | 未修改 | 确认配置正确 |
