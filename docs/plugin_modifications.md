# Konado 插件修改记录

本文件记录所有对 `addons/konado/` 的直接修改，便于插件升级时重新应用。

---

## 2026-06-05: 新增 `dialogue_text_ready` 信号

**文件:** `addons/konado/scripts/dialogue/knd_dialogue_manager.gd`

**改动:**

1. 信号声明区域新增（line ~26）:
   ```gdscript
   signal dialogue_text_ready(content: String, character_id: String)
   ```

2. ORDINARY_DIALOG 分支中，`_konado_dialogue_box.dialogue_text = content` 之前新增:
   ```gdscript
   dialogue_text_ready.emit(content, chara_id)
   ```

**原因:** 项目层内联命令系统需要在对话文本写入 dialogue_box 之前拦截并处理 `{tag:value}` 标签。

**影响:** 不连接此信号时行为完全不变，零副作用。

**对应功能:** `InlineCommandProcessor`（中途切换立绘 / 修改速度 / 插入延迟）

---

## 2026-06-06: 修复存档恢复对组合立绘角色的支持

**文件:** `addons/konado/scripts/save_system/knd_save_system.gd`

**改动:**

`_restore_actor_state` 方法中，移除 `if state_tex:` 守卫条件，改为始终调用 `create_new_character`，并在 `state_tex` 为 null 时输出警告。

**原因:** 原实现通过 `chara_status` 纹理查找来决定是否创建角色。标准 KND_Actor 的状态名（如 `"neutral"`）能在 `chara_status` 中找到对应纹理，但 Clara 的组合立绘系统使用文本状态（如 `"preset:intro_default"`），不存在于 `chara_status` 中，导致 `state_tex = null` → 跳过创建 → 立绘丢失。Clara 的 `create_new_character` 不使用 `tex` 参数，仅通过 `state` 文本调用 `apply_state` 恢复。

**影响:** 标准角色行为不变（纹理正常找到）；组合立绘角色（Clara）现在能正确从存档恢复。

---

## 2026-06-06: 修复 delete_character 未找到角色时信号丢失

**文件:** `addons/konado/scripts/act/knd_acting_interface.gd`

**改动:**

`delete_character` 方法末尾新增：当遍历 `actor_dict` 未找到匹配角色时，仍发射 `character_deleted` 信号。

**原因:** 原实现中，如果 `actor_dict` 中不存在目标角色，函数直接返回且不发射 `character_deleted`。而对话管理器的 `_exit_actor` 通过 `_auto_process_next` 回调等待此信号，信号缺失导致对话流程永久阻塞。读档后如果 Clara 未被正确恢复到 `actor_dict`，后续 `actor exit Clara` 会触发此问题。

**影响:** 未找到角色时仍会输出警告日志并发射信号，对话流程不会阻塞。

---

## 2026-06-06: 新增省略号停顿覆盖层

**文件:** `addons/konado/scripts/dialoguebox/knd_dialogue_box.gd`

**改动:**

新增字段（line ~100）:
```gdscript
var _ellipsis_label: Label = null
var _ellipsis_original_text: String = ""
var _ellipsis_original_ratio: float = 1.0
```

新增方法：
- `show_ellipsis(dots: String)` — 动态创建 `_ellipsis_label`（Label 节点），定位到 `dialogue_label` 最后可见字符右侧，显示省略号文本
- `update_ellipsis(dots: String)` — 更新省略号文本（位置不变）
- `hide_ellipsis()` — 隐藏并清空省略号标签
- `_update_ellipsis_position()` — 使用 `dialogue_label.get_character_bounds()` 计算位置；API 不可用时回退到 dialogue_label 右下角

**原因:** `{wait_pause:X,N}` 内联命令需要在长停顿期间显示循环省略号动画，给玩家视觉反馈表明游戏并未卡死。

**影响:** `show/update/hide_ellipsis` 方法仅由 `InlineCommandProcessor` 在处理 `{wait_pause}` 标签时调用，不涉及时正常对话流程不受影响，零副作用。

---

## 2026-06-10: 新增 play_bounce() 和 fade_apply_state()

**文件:** `addons/konado/template/character/konado_actor.gd`

**改动:**

新增两个方法（在 `set_character_texture()` 之后）：

1. `play_bounce(count: int = 1, height: float = 25.0, duration: float = 0.18)` — 立绘跳动动画。通过 tween 交替动画 `slot.position.y` 实现弹跳效果。支持可配置的跳动次数、高度和时长。

2. `fade_apply_state(state_text: String) -> void` — 带淡入淡出的状态切换基类方法。基类实现为空（pass），供子类（如 ClaraCompositeActor / ViewportActorBase）覆盖实现交叉溶解效果。

**原因:** ICP（InlineCommandProcessor）内联命令系统需要在打字过程中通过 `{bounce:角色名}` 和 `{change:角色名,state}` 标签触发立绘动画和状态切换。

**影响:** 无 ICP 命令调用时行为完全不变，零副作用。
