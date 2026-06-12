# Clara 立绘系统 — 问题与修复记录

> 记录 Clara 组合立绘系统重建过程中遇到的所有问题及解决方案。
> 更新于 2026-06-12

---

## 1. Premultiplied Alpha 描边

**现象**：导出的面部 PNG 在表情与肤色过渡处存在黑色描边。

**根因**：PSD 使用 Premultiplied Alpha 存储边缘像素，Python 未正确处理。

| 方法 | Alpha 处理 | 结果 |
|------|-----------|------|
| `layer.topil()` | 返回原始通道值，无预乘转换 | 暗边描边 |
| `layer.composite()` 无 composite extra | 退化为基础渲染 | 暗边描边 |
| `psd.composite(force=True)` | 完整管线，正确处理预乘 | **无描边** |

**修复**：安装 `psd-tools[composite]`，使用 `psd.composite(force=True)`。

---

## 2. 表情层叠加（Face Overlap）

**现象**：每个表情 PNG 出现所有子层叠加——sobbing 同时显示 teeth+closed+open 三种 mouth，以及 closed+open+tears 三种 eyes。

**根因**：
1. `export_single_layer()` / `export_composite()` 导出后调用 `set_all_visible(root_children)`
2. `set_all_visible` **递归**遍历所有子层（包括 expression 内部），全部设为 visible
3. `export_face_variants()` 中 `hide_all_children()` 只隐藏根的**直接**子层，不重置 expression 内部
4. 结果：每个表情渲染时，所有 mouth/eye/tear 子层叠加

**修复**：
1. 在任何 `set_all_visible` 调用**之前**，用 `save_expression_defaults()` 保存所有表情子层的 PSD 原始可见性
2. 渲染每个表情前，先将**所有** 28 个 expression 组及内部子层设为不可见
3. 用 `restore_expression_defaults()` 恢复当前表情的 PSD 默认可见性
4. 渲染后重新隐藏当前表情内部子层，为下一个表情建立干净基线

---

## 3. PSD 层名问题

**现象**：脚本使用空格分隔的层名（如 "back hair"），但 PSD 实际使用下划线（"back_hair"）。

**其他命名差异**：
- CENTER: `shoes`，LEFT/RIGHT: `sneakers`
- CENTER: `expresssions`（3 个 s），LEFT/RIGHT: `expressions`
- LEFT/RIGHT: `surprise`，标准化为 `surprised`
- CENTER: `scared` 后跟 null 字节 `\x00`

**修复**：创建 `_clean()` 函数处理层名：`name.rstrip('\x00').strip().lower()`。注意 `rstrip('\x00')` 必须在 `strip()` 之前，否则 null 字节不会被移除。

---

## 4. `psd[0]` 返回错误层

**现象**：`psd[0]` 返回 PixelLayer（background），不是角色 Group。

**修复**：遍历 `psd` 查找第一个 `is_group()` 的子层作为角色根组。

---

## 5. LEFT 表情完全透明

**现象**：LEFT 的 face/neutral.png 完全透明。

**根因**：`hide_all_children()` 隐藏了 `expressions` 父组。psd-tools 尊重父组可见性——父组隐藏时子层不渲染。

**修复**：`hide_all_children()` 之后添加 `expressions_group.visible = True`。

---

## 6. `hair_under` 冗余

**现象**：`hair_back` 和 `hair_under` 图像完全一致。

**根因**：PSD 中只有一个 `back_hair` 层，两个 slot 都从同一源导出，完全重复。

**修复**：从 slot 系统中完全移除 `hair_under`（Clara 无独立 under 层）。

---

## 7. `hair_side` 永远不渲染

**现象**：LEFT 方向的侧发不显示，Godot 报 missing texture 警告。

**根因**：`default_state` 中 `hair_side: "none"`，且没有任何预设会将其改为 `"base"`。ClaraStateCodec 解析 `preset:dir_left|face=neutral` 时，`dir_left` 预设只设置 `dir`，`face=neutral` 作为显式键跳过了 `_apply_face_preset`，`hair_side` 始终为 `"none"`。

**修复**：
1. `default_state` 中 `hair_side` 保持 `"none"`（CENTER/RIGHT 无独立层）
2. `direction_presets` 中 `dir_left` 和 `dir_right` 增加 `"hair_side": "base"`
3. 切换方向时自动启用侧发，CENTER 不触发

---

## 8. `.tres` 缓存旧值

**现象**：修改 GDScript `default_state` 默认值后，Godot 仍使用旧值。

**根因**：Godot 缓存 `.tres` 资源的属性值。`.tres` 中未显式声明的属性使用首次加载时的 GDScript 默认值，后续修改不会自动同步。

**修复**：在 `.tres` 中显式声明 `slot_order`、`default_state`、`direction_presets`，确保 Godot 使用最新值。

---

## 9. `ear` 被 `face` 覆盖

**现象**：RIGHT 方向的 ear 不显示。

**根因**：slot 顺序中 `ear` 在 `face` 之前渲染。CENTER/RIGHT 的 `face` 包含 head 层，head 的不透明像素覆盖了 ear。

**修复**：将 `ear` 从 `face` 之前移到 `face` 之后。

---

## 10. RIGHT `bang` 层误分类

**现象**：RIGHT 的侧发（`bang` 层）被合入 body，而非作为独立 hair_side 导出。

**根因**：`bang` 被加入 `BODY_LAYER_NAMES`。实际上 RIGHT PSD 中无 `band`（手环）层，`bang` 是侧发（对应 LEFT 的 `hair` 层）。

**修复**：
1. 从 `BODY_LAYER_NAMES` 移除 `bang`
2. RIGHT hair_side 导出 `bang` 层
3. 更新 `direction_presets` 中 `dir_right` 增加 `hair_side: "base"`

---

## 11. `hair_side` 被 `face` head 覆盖

**现象**：RIGHT 的 hair_side（bang）导出正确但仍不显示。

**根因**：slot 顺序中 `hair_side` 在 `face` 之前。RIGHT 的 `face` 包含 head（bbox 434,184-659,458），完全覆盖 `hair_side`（bbox 555,267-643,416），重叠 88x149 像素。

**修复**：将 `hair_side` 从 `face` 之前移到 `face` 之后。

---

## 最终 Slot 渲染顺序

```
hair_back → body → outer → face → hair_side → ear → hair_front → hair_top
```

| 顺序 | Slot | 说明 |
|------|------|------|
| 1 | hair_back | 后发（最底层） |
| 2 | body | 完整身体合并 |
| 3 | outer | 外套（可 toggle） |
| 4 | face | 头部 + 表情（CENTER/RIGHT 含 head） |
| 5 | hair_side | 侧发（仅 LEFT/RIGHT，覆盖在 head 上） |
| 6 | ear | 耳朵/耳环（覆盖在 head 上） |
| 7 | hair_front | 前发刘海 |
| 8 | hair_top | 呆毛（最顶层） |

## 方向差异汇总

| 项目 | CENTER | LEFT | RIGHT |
|------|--------|------|-------|
| head 层 | 独立 `head` | 无（合入 body） | 独立 `head` |
| hair_side | 无 | `hair` 层 | `bang` 层 |
| ear | `earring` | `ear` | `left_ear` + `ear rings` |
| shoes | `shoes` | `sneakers` | `sneakers` |
| 表情组名 | `expresssions`(3s) | `expressions` | `expressions` |
| 表情 surprise | `surprised` | `surprise` | `surprise` |

## 关键文件

| 文件 | 作用 |
|------|------|
| `tools/export_clara_psd.py` | PSD → PNG 导出脚本 |
| `scripts/portrait/clara/clara_portrait_db.gd` | Slot/预设/路径定义 |
| `resources/portrait/clara/clara_portrait_db.tres` | 运行时资源配置 |
| `scripts/portrait/clara/clara_state_codec.gd` | KS 命令 → 状态解析 |
| `scripts/portrait/composite_portrait_actor.gd` | 组合立绘渲染器 |
| `scripts/portrait/portrait_acting_interface.gd` | KS Actor → 立绘调度 |
