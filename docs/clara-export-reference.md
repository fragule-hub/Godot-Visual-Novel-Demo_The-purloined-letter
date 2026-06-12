# Clara 立绘导出文档

## 总览

从 3 个 PSD 源文件（center / left / right）导出组件层，供 Godot 运行时组合立绘。
表情使用 PSD 中各表情组的默认子层可见设置，不做额外 mouth/eyes 覆盖。

## PSD 源文件

| 文件 | 方向 |
|------|------|
| `clara-original-center-normal_1000x2000px.psd` | CENTER |
| `clara-original-left-normal_1000x2000px.psd` | LEFT |
| `clara-original-right-normal_1000x2000px.psd` | RIGHT |

## Slot 渲染顺序

```
hair_back → body → outer → face → hair_side → ear → hair_front → hair_top
```

| Slot | PSD 源 | 说明 |
|------|--------|------|
| hair_back | back_hair | 后发 |
| body | body + 身体子层（袜、鞋、裤、背心、手臂、项链、手表、band） | 完整身体合并 |
| outer | jacket | 外套，可 toggle |
| hair_side | hair（仅 LEFT） | 侧发，仅 LEFT 方向有独立层 |
| face | head+表情(CENTER/RIGHT) 或 纯表情(LEFT) | 面部预设（28 表情） |
| ear | earring / ear / left_ear+ear_rings | 耳朵/耳环 |
| hair_front | front_hair | 前发 |
| hair_top | ahoge | 呆毛 |

## 方向差异

| 差异点 | CENTER | LEFT | RIGHT |
|--------|--------|------|-------|
| head 层 | 独立 `head` 层 | 无（合并到 body） | 独立 `head` 层 |
| hair_side | 无 | `hair` 层 | 无 |
| ear | `earring` | `ear` | `left_ear` + `ear rings` |
| body 合并层 | body+socks+shoes+pants+necklace+tank_top+right_arm+band+watch | body+socks+sneakers+watch+shorts+tank_top+arm+necklace+band | body+socks+sneakers+shorts+tank_top+right_hand+left_arm+watch+necklace+bang |
| 表情名 | `surprised` | `surprise`→`surprised` | `surprise`→`surprised` |

## 表情配置

28 个表情预设，对应 `layers/{dir}/face/{expr}.png`。
使用 PSD 中各表情组的默认可见子层（eyes + mouth + modifiers），不做额外覆盖。

表情列表：
neutral, happy, angry, sad, surprised, confused, serious, confident, embarrassed, blush, smirk, mock, furious, scared, fright, terror, crying, sobbing, unease, tired, exhausted, sleepy, disgusted, nauseating, kiss, soulless, psychotic, stoic

## 导出流程

1. `psd.composite(force=True)` — 使用完整合成管线，正确处理 Premultiplied Alpha（避免描边）
2. 按 slot 临时设置层可见性，渲染全画布 PNG
3. body slot：合并所有身体相关子层为单个 PNG
4. face slot：逐一显示表情组，保留组内默认子层可见性
5. 命名标准化：`surprise` → `surprised`

## 所需依赖

```bash
pip install 'psd-tools[composite]'
```

## 运行

```bash
python tools/export_clara_psd.py
```
