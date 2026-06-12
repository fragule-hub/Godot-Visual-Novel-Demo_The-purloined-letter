# Konado 视觉小说 AI Skill 完整参考手册

> 本文档供 AI 会话使用，指导编写 `.ks` 剧本文件、控制 Konado 插件、管理 Clara 组合立绘系统。

---

## 一、项目概览（Project Overview）

| 项目 | 说明 |
|------|------|
| 引擎 | Godot 4.6+ |
| 核心插件 | Konado v2.4.0 "Cannoli" |
| 剧本格式 | `.ks`（Konado Script） |
| 编译管线 | `.ks` → Lexer → Parser → Analyzer → Emitter → `KND_Shot` |

### 两套立绘系统（Portrait Systems）

| 系统 | 角色 | 类名 | 说明 |
|------|------|------|------|
| 简单立绘（Simple） | Eve | `SimplePortraitActor` | 单张 PNG + 状态切换，每个状态 = 一张完整图片 |
| 组合立绘（Composite） | Clara | `CompositePortraitActor` | 16 层图层动态组合，通过 `ClaraPortraitDB` 管理 |

### 核心管理器（Core Managers）

| 类名 | 文件路径 | 职责 |
|------|----------|------|
| `KND_DialogueManager` | `addons/konado/scripts/dialogue/knd_dialogue_manager.gd` | 对话流程调度核心 |
| `KND_ActingInterface` | `addons/konado/scripts/act/knd_acting_interface.gd` | 背景 + 角色管理基础类 |
| `PortraitActingInterface` | `scripts/portrait/portrait_acting_interface.gd` | 统一立绘管理器（继承 ActingInterface） |
| `InlineCommandProcessor` | `scripts/dialogue/inline_command_processor.gd` | 内联命令解析执行 |
| `KND_DialogueBox` | `addons/konado/scripts/dialoguebox/knd_dialogue_box.gd` | 对话框 UI |
| `KND_AudioInterface` | `addons/konado/scripts/audio/knd_audio_interface.gd` | 音频控制 |
| `KND_ChoiceInterface` | `addons/konado/scripts/dialogue/knd_choice_interface.gd` | 选项界面 |

---

## 二、KS 语法完整参考（KS Syntax Reference）

### 2.1 基础规则（Basic Rules）

- **注释**：`#` 开头的行被忽略
- **空行**：自动跳过
- **每行一条指令**
- **字符串**：用双引号 `"` 包裹，支持 `\"` 转义
- **缩进**：4 个空格 或 1 个制表符 = 1 级缩进（用于 `branch`/`if` 块内部）

---

### 2.2 对话（Dialogue）

```
"角色名" "对话内容" [voice_id]
```

**说明**：第一段字符串为角色名，第二段为对话内容。可选第三段为配音 ID。

**示例**：
```ks
"我" "你好，世界！"
"Clara" "这是带配音的台词" voice_001
"Eve" "我叫 Eve，请多指教。"
```

**变量内联**：对话文本中可用 `%var`（持久变量）或 `$var`（临时变量）插入变量值。
```ks
set %player_name 小明
"Clara" "你好，%player_name！"
```

---

### 2.3 背景切换（Background）

```
background <资源名> [转场特效]
```

**说明**：切换当前背景图。资源名对应 `KND_BackgroundList` 中定义的 `background_name`。

**可用转场特效（Transition Effects）**：
| 特效名 | 说明 |
|--------|------|
| （不填） | 无特效直接切换 |
| `erase` | 擦除效果（1秒） |
| `blinds` | 百叶窗效果（1秒） |
| `wave` | 波浪效果（1秒） |
| `alpha_fade` | Alpha 淡入淡出（1秒） |
| `vortex_swap` | 极坐标漩涡（1秒） |
| `windmill` | 风车效果（1秒） |
| `cyber_glitch` | 电子故障效果（1秒） |

**示例**：
```ks
background test_room
background park alpha_fade
background night_scene cyber_glitch
```

---

### 2.4 角色控制（Actor）

#### 显示角色（show）

```
actor show <角色名> <状态> [at <位置>]
```

**说明**：在指定位置显示角色。位置为水平分块编号（`horizontal_division` 默认 5 块，1=最左，5=最右）。

**简单角色状态（Eve）**：`neutral`, `smile`, `angry`, `shy`, `surprise`, `laugh`, `cry`

**组合角色状态（Clara）**：`preset:<预设名>` 或 `key=value|key=value|...`（详见第四章）

**示例**：
```ks
actor show Eve neutral at 2
actor show Clara at 3
actor show Clara preset:dir_left|face=smile at 4
```

#### 切换角色状态（change）

```
actor change <角色名> <新状态>
```

**示例**：
```ks
actor change Eve angry
actor change Clara preset:dir_left|face=smile
actor change Clara dir=center|outer=coat_01|vest=school_vest
```

#### 角色退场（exit）

```
actor exit <角色名>
```

**示例**：
```ks
actor exit Eve
actor exit Clara
```

#### 移动角色（move）

```
actor move <角色名> <位置>
```

**示例**：
```ks
actor move Eve 4
```

---

### 2.5 音频控制（Audio）

#### 播放（play）

```
play bgm <资源名>     # 播放背景音乐（BGM）
play sfx <资源名>     # 播放音效（Sound Effect）
```

资源名对应 `KND_BgmList` 或 `KND_SoundEffectList` 中定义的名称。

**示例**：
```ks
play bgm title
play bgm easygoing
play sfx door_open
```

#### 停止（stop）

```
stop bgm     # 停止背景音乐
```

#### 可用 BGM 资源名（Available BGM Resource Names）

| 资源名 | 原始文件名 | 情境描述 |
|--------|-----------|----------|
| `title` | 标题音乐 | 标题画面 |
| `easygoing` | 优哉游哉(loop) | 放学后轻松散步，无多余的人打扰 |
| `pink_blood` | 粉色血液 | 从轻缓到激动，约会、两情相悦 |
| `anecdote` | 轶事性知识 | 一段尘封的故事娓娓道来、悲伤 |
| `circulation` | Circulation(loop) | 夜间漫步、思考将来 |
| `rest` | Rest time | 安静的酒吧 |
| `battle` | Start the battle | 乱入、突入 |
| `waiting` | Waiting | 被打断、搞笑 |

> 标注 `(loop)` 的曲目适合循环播放。在 `.ks` 中使用：`play bgm easygoing`

---

### 2.6 选项与分支（Choice & Branch）

#### 选项（choice）

```
choice "选项文本" -> <分支名>
```

连续的 `choice` 行自动合并为一个选项组。玩家选择后跳转到对应分支。

**示例**：
```ks
choice "去公园" -> go_park
choice "回家休息" -> go_home
choice "去商店" -> go_shop
```

#### 分支（branch）

```
branch <分支名>
    <缩进的指令...>
    <缩进的指令...>
```

**说明**：分支内部的指令需要缩进一级（4空格或1Tab）。

**示例**：
```ks
branch go_park
    background park
    "我" "来到公园了。"
    jump_branch after_choice

branch go_home
    background room
    "我" "还是回家吧。"
    jump_branch after_choice

branch go_shop
    background shop
    "我" "去商店看看。"
    jump_branch after_choice
```

> **注意**：`branch` 目前标记为 Deprecated，推荐使用 `choice` + `jump_branch` 或 `if/else` 替代。

---

### 2.7 条件分支（If/Else）

```
if %变量名 运算符 值:
    <指令...>
else:
    <指令...>
endif
```

**运算符**：`==`、`!=`、`>`、`<`、`>=`、`<=`

**示例**：
```ks
set %affection 5

if %affection >= 10:
    "Clara" "你对我真好！"
else:
    "Clara" "还不够哦。"
endif
```

> **注意**：`else:` 和 `endif` 后的冒号可选。if/else 内的指令**不需要缩进**（与 branch 不同）。

---

### 2.8 变量操作（Variables）

#### 设置变量（set）

```
set %变量名 值       # 持久变量（%前缀，跨镜头保存，存档持久化）
set $变量名 值       # 临时变量（$前缀，仅当前脚本有效，镜头重置时清除）
```

#### 算术运算（add/sub/mul/div）

```
add %变量名 值       # %变量 += 值
sub %变量名 值       # %变量 -= 值
mul %变量名 值       # %变量 *= 值
div %变量名 值       # %变量 /= 值
```

**等号可选**：`set %var = 5` 和 `set %var 5` 等价。

**示例**：
```ks
set %affection 0
add %affection 5
sub %affection 2
mul %score 2
div %hp 3
set $temp_msg "临时消息"
```

#### 变量内联引用

在对话文本中直接使用 `%var` 或 `$var`，运行时自动替换为变量值：
```ks
set %player_name 小明
set %affection 10
"Clara" "你好，%player_name。你的好感度是 %affection。"
```

---

### 2.9 跳转（Jump）

#### 跨镜头跳转（jump）

```
jump <shot文件路径>
```

**说明**：加载并跳转到另一个 `.ks` 文件（编译后的 `KND_Shot` 资源）。

**示例**：
```ks
jump res://story/chapter2.ks
```

#### 分支内跳转（jump_branch）

```
jump_branch <分支名>
```

**说明**：跳转到当前脚本内的指定分支标签。

**示例**：
```ks
jump_branch after_choice
```

---

### 2.10 信号、成就与结束

#### 自定义信号（signal）

```
signal <内容>
```

**说明**：发射 `KND_DialogueManager.custom_signal` 信号，供外部 GDScript 监听。

**示例**：
```ks
signal chapter1_complete
```

#### 成就系统（achievement）

```
achievement unlock <成就ID>           # 解锁成就
achievement increment <成就ID> <数值>  # 更新成就进度
achievement set_flag <成就ID> <true/false>  # 设置成就标志
```

#### 结束（end）

```
end
```

**说明**：标记剧本结束，触发 `KND_DialogueManager` 停止对话流程。

---

## 三、内联命令详解（Inline Commands）

内联命令嵌入对话文本中，在打字过程中按字符位置触发。标签语法：`{命令名:参数}`

### 3.1 命令列表

#### `{wait}` — 暂停打字

```
{wait:秒数}
```

**示例**：
```ks
"Clara" "说到一半...{wait:1.0}...停顿后继续。"
"Clara" "一{wait:0.3}个{wait:0.3}字{wait:0.3}一{wait:0.3}个{wait:0.3}字。"
```

#### `{change}` — 渐变切换立绘状态

```
{change:角色名,状态}
```

**说明**：在对话打字过程中触发立绘交叉溶解切换。状态格式与 `actor change` 一致。

**示例**：
```ks
"Clara" "本来很平静，但是{change:Clara,face=angry}突然生气了！"
"Clara" "让我换个表情...{change:Clara,preset:dir_left|face=smile}现在微笑了。"
```

#### `{speed}` — 改变打字速度

```
{speed:字符每秒}
```

**说明**：数值越大打字越快。

**示例**：
```ks
"Clara" "{speed:50}噼里啪啦说完一整段话！{speed:25}呼——恢复正常。"
```

#### `{bounce}` — 立绘跳动动画

```
{bounce:角色名[,次数,高度,时长]}
```

**参数说明**：
| 参数 | 默认值 | 范围 |
|------|--------|------|
| 次数 | 1 | 1-10 |
| 高度 | 25.0 | 5.0-200.0 |
| 时长 | 0.18 | 0.05-1.0 |

**示例**：
```ks
"Clara" "看我跳一下！{bounce:Clara}很简单对吧？"
"Clara" "连续跳三下！{bounce:Clara,3}厉害吧！"
"Clara" "大力跳！{bounce:Clara,1,60,0.3}跳得又高又慢。"
"Clara" "轻轻抖一下{bounce:Clara,2,10,0.1}细微的抖动。"
```

#### `{wait_pause}` — 省略号停顿

```
{wait_pause:秒数[,最大点数]}
```

**说明**：显示循环省略号动画（.→..→...），等待指定秒数后自然结束。最大点数范围 3-6。

**示例**：
```ks
"Clara" "我需要想一想{wait_pause:3.0,3}嗯，想好了。"
"Clara" "这是一个很长的停顿{wait_pause:5.0,6}终于结束了。"
```

### 3.2 组合使用范例

```ks
# 跳动 + 换表情
"Clara" "跳动加换表情：{bounce:Clara,2}{change:Clara,face=angry}跳完就生气！"

# 全组合测试
"Clara" "嗯...{wait:0.8}{change:Clara,preset:dir_left|face=smile}{speed:15}慢慢地、微笑着说...{wait:0.5}{change:Clara,face=angry}{speed:50}但是突然就生气了！{change:Clara,face=neutral}{speed:25}好，恢复正常。"

# 省略号停顿 + 换表情
"Clara" "我在思考{wait_pause:2.0,3}{change:Clara,face=angry}想完就生气！"
```

---

## 四、Clara 组合立绘系统详解（Clara Composite Portrait System）

### 4.1 系统架构

| 组件 | 文件路径 | 职责 |
|------|----------|------|
| `ClaraPortraitDB` | `resources/portrait/clara/clara_portrait_db.tres` | 层定义、预设、冲突规则、资源路径 |
| `ClaraStateCodec` | `scripts/portrait/clara/clara_state_codec.gd` | 解析状态字符串为完整状态字典 |
| `CompositePortraitActor` | `scripts/portrait/composite_portrait_actor.gd` | 运行时多层渲染 |
| `PortraitActorBase` | `scripts/portrait/portrait_actor_base.gd` | 立绘基类，交叉溶解、进场/退场动画 |

### 4.2 图层顺序（Layer Order，16层，从后到前）

| 层号 | 插槽名（Slot） | 说明 |
|------|---------------|------|
| 1 | `hair_back` | 后发 |
| 2 | `body` | 身体 |
| 3 | `inner` | 内衣/衬衫 |
| 4 | `outer` | 外套 |
| 5 | `vest` | 背心 |
| 6 | `accessory` | 配饰（蝴蝶结、首饰等） |
| 7 | `hair_under` | 底层发 |
| 8 | `head` | 头部 |
| 9 | `hair_side` | 侧发 |
| 10 | `ear` | 耳朵 |
| 11 | `eyes` | **眼睛组件（28种表情各自的眼睛）** |
| 12 | `mouth` | **嘴型组件（28种表情各自的嘴型）** |
| 13 | `hair_front` | 前发 |
| 14 | `hair_top` | 顶发 |

> **组件化面部系统**：Clara 的表情由 `eyes`（眼睛）+ `mouth`（嘴型）两个独立组件合成，不再使用 `face_overlay`。每个表情的 eyes 和 mouth 从 PSD 源文件的 eyes/mouth 像素层提取。`brows` 和 `face_overlay` 已从 slot_order 中移除。

### 4.3 方向（Directions）

| 方向值 | 说明 |
|--------|------|
| `center` | 正面朝向（默认） |
| `left` | 面向左侧 |
| `right` | 面向右侧 |

每个方向有独立的图层资源目录：
```
res://assets/立绘/clara/layers/{direction}/{slot}/{option}.png
```

### 4.4 3重预设系统（Direction → Body → Face）

Clara 使用 **3 层独立预设叠加**，每层只负责自己的槽位，互不干扰。

#### 方向预设（direction_presets）

| 预设名 | 设置的 slot | 说明 |
|--------|------------|------|
| `preset:dir_center` | `dir=center` | 正向（**默认**） |
| `preset:dir_left` | `dir=left` | 面向左 |
| `preset:dir_right` | `dir=right` | 面向右 |

#### 身体预设（body_presets）

| 预设名 | inner | outer | vest | accessory | 说明 |
|--------|-------|-------|------|-----------|------|
| `preset:body_casual` | shirt_01 | none | none | none | 短袖常服（**默认**） |
| `preset:body_coat` | shirt_01 | coat_01 | none | none | 穿外套 |
| `preset:body_formal` | shirt_01 | none | school_vest | ribbon | 马甲 + 蝴蝶结 |
| `preset:body_coat_formal` | shirt_01 | coat_01 | school_vest | ribbon | 外套 + 马甲（冲突规则移除马甲） |

#### 表情预设（face_presets）

见 4.5 节，通过 `face=xxx` 展开为 `eyes` + `mouth`。

#### 组合方式

```
preset:dir_left|preset:body_coat|face=happy
```

3 层预设按固定优先级（方向 → 身体 → 表情 → 自定义覆盖）叠加：
1. 方向预设只设 `dir`
2. 身体预设只设 `inner`/`outer`/`vest`/`accessory`
3. 表情预设展开为 `eyes` + `mouth`
4. 任何 `key=value` 覆盖前面所有层

### 4.5 表情系统（Face Presets，共28种）

所有表情由 `eyes`（眼睛）+ `mouth`（嘴型）两个独立组件合成。face_presets 自动展开 `face` 键为对应的 `eyes` 和 `mouth` 选项。

**常用表情（18种）：**

| 表情名 | eyes | mouth | 眼睛状态 | 视觉描述 | 剧本使用场景 |
|--------|------|-------|----------|----------|-------------|
| `neutral` | neutral_open | neutral | 睁开 | 无表情，默认 | 一般对话、日常登场 |
| `smile` | happy_open | happy | 睁开 | 微笑（闭眼笑，别名 happy） | 友好、轻松 |
| `happy` | happy_open | happy | 睁开 | 开心笑（张嘴笑） | 大笑、非常高兴 |
| `angry` | angry_open | angry | 睁开 | 生气 | 一般愤怒、吐槽 |
| `furious` | furious_closed | furious | **闭眼** | 暴怒 | 极度愤怒 |
| `surprise` | surprised_open | surprised | 睁开 | 惊讶（张嘴） | 突然发现、震惊 |
| `sad` | sad_open | sad | 睁开 | 悲伤 | 难过、沮丧 |
| `confused` | confused_open | confused | 睁开 | 困惑 | 不理解、疑惑 |
| `serious` | serious_open | serious | 睁开 | 严肃 | 认真思考、庄重 |
| `confident` | confident_open | confident | 睁开 | 自信 | 自信满满、行动宣言 |
| `embarrassed` | embarrassed_open | embarrassed | 睁开 | 尴尬（含红晕） | 被揭穿、出丑 |
| `blush` | blush_open | blush | 睁开 | 脸红（含红晕） | 害羞、心动 |
| `smirk` | smirk_open | smirk | 睁开 | 奸笑 | 不怀好意、坏笑 |
| `mock` | mock_open | mock | 睁开 | 嘲弄 | 嘲讽、取笑 |
| `crying` | crying_open | crying | 睁开 | 哭泣（含泪） | 悲伤哭泣 |
| `exhausted` | exhausted_open | exhausted | 睁开 | 筋疲力尽（含阴影） | 累坏了 |
| `sleepy` | sleepy_open | sleepy | 睁开 | 困倦 | 想睡觉 |
| `scared` | scared_open | scared | 睁开 | 害怕 | 恐惧 |

**备选表情（11种）：**

| 表情名 | eyes | mouth | 眼睛状态 | 视觉描述 |
|--------|------|-------|----------|----------|
| `fright` | fright_open | fright | 睁开 | 惊恐（含汗滴） |
| `terror` | terror_open | terror | 睁开 | 恐惧（更强烈） |
| `sobbing` | sobbing_open | sobbing | 睁开 | 啜泣（含泪） |
| `unease` | unease_open | unease | 睁开 | 不安 |
| `tired` | tired_open | tired | 睁开 | 疲惫 |
| `disgusted` | disgusted_open | disgusted | 睁开 | 厌恶 |
| `nauseating` | nauseating_open | nauseating | 睁开 | 恶心（含汗滴） |
| `kiss` | kiss_open | kiss | 睁开 | 亲吻（嘟嘴） |
| `soulless` | soulless_open | soulless | 睁开 | 无神 |
| `psychotic` | psychotic_open | psychotic | 睁开 | 疯狂 |
| `stoic` | stoic_open | stoic | 睁开 | 冷静/淡然 |

> 系统通过 `face` 键自动展开为 `eyes` 和 `mouth` 子层。组件文件位于：
> - Eyes: `assets/立绘/clara/layers/{direction}/eyes/{expr}_{open|closed}.png`
> - Mouth: `assets/立绘/clara/layers/{direction}/mouth/{expr}.png`
> 
> ⚠ **注意**：不同方向的 PSD 可能有不同的眼睛状态（如 center 的 furious 是 closed，left 的 blush 是 closed）。face_presets 以 center 为参考。当目标方向没有对应文件时，自动回退到 center。

### 4.6 状态字符串语法（State String Syntax）

状态字符串用于 `actor show`/`actor change` 和内联 `{change}` 标签中。

#### 3重预设模式
```
preset:dir_xxx|preset:body_xxx|face=xxx
```
每层 preset 只设置对应槽位，各层互不干扰。未指定的层使用默认值（center + casual + neutral）。

**示例**：
```ks
preset:dir_left|preset:body_coat|face=happy
preset:dir_left|face=angry
preset:body_formal|face=confident
```

#### 键值模式
```
key=value|key=value|...
```
**可用键名**：`dir`, `body`, `inner`, `outer`, `vest`, `hair_back`, `hair_under`, `head`, `hair_side`, `ear`, `eyes`, `mouth`, `hair_front`, `hair_top`, `face`, `accessory`

**示例**：
```ks
dir=left|face=smile
face=angry|accessory=ribbon
```

#### 混合模式
```ks
preset:dir_left|preset:body_coat|face=happy|mouth=smirk
face=angry|outer=coat_01
```

### 4.7 服装冲突规则（Conflict Rules）

当 `outer`（外套）和 `vest`（背心）同时设置为非 `none` 值时，`ClaraPortraitDB.apply_constraints()` 会根据 `conflict_rules` 自动处理冲突。当前规则下外套优先级高于背心。

**示例**：
```ks
# 冲突测试：同时设置外套和背心，系统自动隐藏背心
actor change Clara dir=center|outer=coat_01|vest=school_vest
```

### 4.8 可选值参考（Available Options）

| 插槽 | 可选值 |
|------|--------|
| `body` | `base` |
| `hair_back` | `base` |
| `hair_under` | `none`, `base` |
| `head` | `none`, `base` |
| `hair_side` | `none`, `base` |
| `ear` | `none`, `base` |
| `inner` | `shirt_01` |
| `outer` | `none`, `coat_01` |
| `vest` | `none`, `school_vest` |
| `eyes` | `none`, `angry_open`, `blush_open`, `confident_open`, `confused_open`, `crying_open`, `disgusted_open`, `embarrassed_open`, `exhausted_open`, `fright_open`, `furious_closed`, `happy_open`, `kiss_open`, `mock_open`, `nauseating_open`, `neutral_open`, `psychotic_open`, `sad_open`, `scared_open`, `serious_open`, `sleepy_open`, `smirk_open`, `sobbing_open`, `soulless_open`, `stoic_open`, `surprised_open`, `terror_open`, `tired_open`, `unease_open` |
| `mouth` | `none`, `angry`, `blush`, `confident`, `confused`, `crying`, `disgusted`, `embarrassed`, `exhausted`, `fright`, `furious`, `happy`, `kiss`, `mock`, `nauseating`, `neutral`, `psychotic`, `sad`, `scared`, `serious`, `sleepy`, `smirk`, `sobbing`, `soulless`, `stoic`, `surprised`, `terror`, `tired`, `unease` |
| `hair_front` | `base` |
| `hair_top` | `none`, `base` |
| `accessory` | `none`, `ribbon`, `jewelry` |

---

## 五、简单立绘系统（Simple Portrait — Eve）

### 5.1 架构

- 类：`SimplePortraitActor`（`scripts/portrait/simple_portrait_actor.gd`）
- 每个状态 = 一张完整 PNG 图片
- 状态在 `KND_CharacterList` 资源中预定义（`resources/konado/test_character_list.tres`）

### 5.2 Eve 可用状态

| 状态名 | 图片文件 |
|--------|----------|
| `neutral` | `res://assets/立绘/eve/Eve_Neutral.png` |
| `smile` | `res://assets/立绘/eve/Eve_Smile.png` |
| `angry` | `res://assets/立绘/eve/Eve_Angry.png` |
| `shy` | `res://assets/立绘/eve/Eve_Shy.png` |
| `surprise` | `res://assets/立绘/eve/Eve_Surprise.png` |
| `laugh` | `res://assets/立绘/eve/Eve_Laugh.png` |
| `cry` | `res://assets/立绘/eve/Eve_Cry.png` |

### 5.3 使用方式

```ks
actor show Eve neutral at 2       # 显示 Eve，正面中性表情，位置2
actor change Eve smile             # 切换到微笑
actor change Eve angry             # 切换到生气
actor exit Eve                     # Eve 退场
```

### 5.4 布局配置（PortraitActorLayoutDB）

在 `resources/portrait/project_actor_layout.tres` 中配置：

| 角色 | actor_type | viewport_size | scale | content_offset |
|------|------------|---------------|-------|----------------|
| Clara | composite | (1000, 2000) | 1.2 | (0, 1250) |
| Eve | simple | (1070, 1800) | 0.55 | (0, 0) |

---

## 六、资源系统（Resource System）

所有资源均以 `.tres` 格式存储在 `resources/` 目录下，在 `KND_DialogueManager` 的导出属性中引用。

| 资源类型 | 类名 | 当前资源文件 | 用途 |
|----------|------|-------------|------|
| 角色列表 | `KND_CharacterList` | `resources/konado/test_character_list.tres` | 定义简单角色及其状态图片 |
| 背景列表 | `KND_BackgroundList` | `resources/konado/test_background_list.tres` | 定义背景图片资源 |
| BGM 列表 | `KND_BgmList` | `resources/konado/test_bgm_list.tres` | 定义背景音乐资源 |
| 音效列表 | `KND_SoundEffectList` | `resources/konado/test_soundeffect_list.tres` | 定义音效资源 |
| 配音列表 | `DialogVoiceList` | `resources/konado/test_voice_list.tres` | 定义配音资源 |
| 对话镜头 | `KND_Shot` | `resources/konado/test_dialogue_shot.tres` | 编译后的剧本数据 |
| 演员布局 | `PortraitActorLayoutDB` | `resources/portrait/project_actor_layout.tres` | 各角色的渲染布局参数 |
| Clara 立绘库 | `ClaraPortraitDB` | `resources/portrait/clara/clara_portrait_db.tres` | Clara 图层定义、预设、资源路径 |

### 资源名匹配规则

`.ks` 剧本中使用的资源名（如 `background test_room` 中的 `test_room`）必须与对应资源列表中定义的名称**精确匹配**（区分大小写）。

---

## 七、剧本编写范例模板（Script Templates）

### 7.1 开场场景

```ks
# 第一章：相遇
background classroom alpha_fade

actor show Clara face=neutral at 3

"Clara" "你好，我是 Clara。"
"Clara" "欢迎来到这个世界。"

actor show Eve neutral at 1

"Eve" "我叫 Eve，请多指教。"
"Clara" "让我们一起冒险吧！"
```

### 7.2 角色表情切换

```ks
actor show Clara face=neutral at 3

"Clara" "今天天气真好。"
actor change Clara preset:dir_left|face=smile
"Clara" "心情也不错呢。"
actor change Clara preset:body_formal|face=angry
"Clara" "但是！你迟到了！"
actor change Clara face=neutral
"Clara" "算了，原谅你了。"
```

### 7.3 Clara 服装切换

```ks
actor show Clara face=neutral at 3
"Clara" "这是我的校服。"

# 换上外套
actor change Clara preset:body_coat|face=smile
"Clara" "加件外套。"

# 换上背心+蝴蝶结
actor change Clara preset:body_formal|face=angry
"Clara" "或者换成背心加蝴蝶结。"

# 手动指定任意组合
actor change Clara dir=right|outer=coat_01|face=smile|accessory=jewelry
"Clara" "右侧外套微笑加首饰。"

actor exit Clara
```

### 7.4 选项分支

```ks
background crossroad
"我" "前面有三条路，走哪条？"

choice "左边的森林" -> forest
choice "中间的大路" -> road
choice "右边的海边" -> beach

branch forest
    background forest
    "我" "走进了神秘的森林..."
    jump_branch after_choice

branch road
    background road
    "我" "沿着大路前进。"
    jump_branch after_choice

branch beach
    background beach
    "我" "来到了美丽的海边！"
    jump_branch after_choice

branch after_choice
    "我" "继续前进吧。"
```

### 7.5 条件分支

```ks
set %affection 0

"Clara" "你觉得我怎么样？"
choice "很喜欢" -> like
choice "一般般" -> normal

branch like
    add %affection 10
    "Clara" "真的吗？太开心了！"
    jump_branch check_affection

branch normal
    add %affection 2
    "Clara" "这样啊...没关系。"
    jump_branch check_affection

branch check_affection
    if %affection >= 10:
        "Clara" "你对我真好！好感度：%affection"
    else:
        "Clara" "还需要努力哦。好感度：%affection"
    endif
```

### 7.6 Clara + Eve 双人场景

```ks
background schoolyard

actor show Clara face=neutral at 3
"Clara" "Eve，你也来了？"

actor show Eve neutral at 1
"Eve" "嗯，今天天气不错。"

actor change Clara preset:dir_left|face=smile
"Clara" "一起去散步吧。"

# Eve 换表情
actor change Eve smile
"Eve" "好主意！"

# Clara 退场，留下 Eve
actor exit Clara
"Eve" "她先走了，我们也走吧。"

actor exit Eve
```

### 7.7 带内联命令的丰富对话

```ks
actor show Clara face=neutral at 3

# 等待 + 换表情
"Clara" "让我想想...{wait:1.5}{change:Clara,preset:dir_left|face=smile}想起来了！"

# 跳动 + 生气
"Clara" "你说什么？！{bounce:Clara,2}{change:Clara,face=angry}太气人了！"

# 变速对话
"Clara" "{speed:60}快点快点快点快点！{speed:20}...呼，慢下来了。"

# 省略号停顿
"Clara" "其实我...{wait_pause:3.0,3}嗯，没什么。"

# 综合：停顿后换表情再变速
"Clara" "等一下...{wait:0.8}{change:Clara,preset:dir_left|face=smile}{speed:15}慢慢地、微笑着说...{wait:0.5}{change:Clara,face=angry}{speed:50}但是突然就生气了！{change:Clara,face=neutral}{speed:25}好，恢复正常。"

actor exit Clara
```

### 7.8 场景过渡 + 音频

```ks
play bgm morning_theme
background classroom alpha_fade

actor show Clara face=neutral at 3
"Clara" "新的一天开始了。"

play sfx bell_ring
"Clara" "上课铃响了。"

background corridor
"Clara" "下课后去走廊走走。"

stop bgm
play bgm after_school
background schoolyard wave
"Clara" "放学了！"

actor exit Clara
stop bgm
end
```

---

## 八、常见错误与注意事项（Common Pitfalls）

### 8.1 Clara 与 Eve 的区别

- **Eve**：在 `KND_CharacterList` 中定义了 `chara_status` 数组（每项含 `status_name` + `status_texture`），使用 `SimplePortraitActor` 渲染。
- **Clara**：在 `KND_CharacterList` 中**只有名字**，没有 `chara_status`。她使用 `CompositePortraitActor` + `ClaraPortraitDB` 管理图层，状态通过 `preset:xxx` 或 `key=value` 格式指定。面部表情由 `eyes` + `mouth` 组件合成，通过 `face=xxx` 展开。

### 8.2 资源名精确匹配

`.ks` 中的资源名（`background`、`play bgm`、`play sfx`）必须与对应 `.tres` 资源列表中的名称**完全一致**（区分大小写）。

### 8.3 缩进规则

- `branch` 块内的指令**需要缩进**（4空格或1Tab）
- `if/else/endif` 块内的指令**不需要缩进**（但支持缩进格式）
- 缩进级别错误会导致指令被跳过

### 8.4 变量前缀

| 前缀 | 类型 | 持久性 | 用途 |
|------|------|--------|------|
| `%` | 持久变量（Persistent） | 跨镜头、存档保存 | 好感度、剧情标志、玩家名称 |
| `$` | 临时变量（Temporary） | 当前镜头有效 | 临时计数、一次性标记 |

### 8.5 内联标签注意事项

- 标签不能嵌套：`{wait:{speed:50}}` 是**无效的**
- 标签在对话文本中按**字符位置**触发，标签本身不占可见字符位
- `{change}` 触发的是**交叉溶解**动画（带过渡），而 `actor change` 是**立即/渐变**切换
- `{bounce}` 需要角色已在场，否则静默警告

### 8.6 end 命令

忘记写 `end` 不会导致错误，但建议在剧本末尾显式添加，使意图清晰。

---

## 九、关键文件快速索引（Key Files Index）

### Konado 插件核心

| 文件路径 | 说明 |
|----------|------|
| `addons/konado/konado_plugin.gd` | 插件入口，版本注册 |
| `addons/konado/ks/ks_lexer.gd` | 词法分析器（Tokenizer） |
| `addons/konado/ks/ks_token.gd` | Token 类型定义 |
| `addons/konado/ks/ks_parser.gd` | 语法分析器（Parser → AST） |
| `addons/konado/ks/ks_ast.gd` | AST 节点定义 |
| `addons/konado/ks/ks_analyzer.gd` | 语义分析器 |
| `addons/konado/ks/ks_emitter.gd` | 代码生成器 |
| `addons/konado/ks/ks_compiler.gd` | 编译管线封装 |
| `addons/konado/ks/ks_interpreter.gd` | 编译入口（Compiler Facade） |

### 对话运行时

| 文件路径 | 说明 |
|----------|------|
| `addons/konado/scripts/dialogue/knd_dialogue_manager.gd` | 对话流程管理器（核心） |
| `addons/konado/scripts/dialogue/knd_dialogue.gd` | 对话节点数据结构 |
| `addons/konado/scripts/dialoguebox/knd_dialogue_box.gd` | 对话框 UI |
| `addons/konado/scripts/dialogue/knd_choice_interface.gd` | 选项界面 |
| `addons/konado/scripts/act/knd_acting_interface.gd` | 背景+角色管理基础类 |
| `addons/konado/scripts/audio/knd_audio_interface.gd` | 音频管理 |

### 立绘系统（项目层）

| 文件路径 | 说明 |
|----------|------|
| `scripts/portrait/portrait_acting_interface.gd` | 统一立绘管理器（继承 ActingInterface） |
| `scripts/portrait/portrait_actor_base.gd` | 立绘基类（交叉溶解、进场/退场） |
| `scripts/portrait/composite_portrait_actor.gd` | Clara 组合立绘 Actor |
| `scripts/portrait/simple_portrait_actor.gd` | Eve 简单立绘 Actor |
| `scripts/portrait/portrait_actor_layout_db.gd` | 演员布局配置 |
| `scripts/portrait/clara/clara_portrait_db.gd` | Clara 图层数据库 |
| `scripts/portrait/clara/clara_state_codec.gd` | Clara 状态解析器 |

### 内联命令

| 文件路径 | 说明 |
|----------|------|
| `scripts/dialogue/inline_command_processor.gd` | 内联命令解析与执行 |

### 资源文件

| 文件路径 | 说明 |
|----------|------|
| `resources/konado/test_character_list.tres` | 角色列表（Eve + Clara） |
| `resources/konado/test_background_list.tres` | 背景列表 |
| `resources/konado/test_bgm_list.tres` | BGM 列表 |
| `resources/konado/test_soundeffect_list.tres` | 音效列表 |
| `resources/konado/test_voice_list.tres` | 配音列表 |
| `resources/konado/test_dialogue_shot.tres` | 对话镜头（编译后） |
| `resources/portrait/project_actor_layout.tres` | 演员布局配置 |
| `resources/portrait/clara/clara_portrait_db.tres` | Clara 立绘数据库 |

### 测试剧本

| 文件路径 | 说明 |
|----------|------|
| `story/test_migration.ks` | 迁移测试（Eve 单图 + Clara 组合 + 内联命令） |
| `scenes/konado/test_dialogue_screen.tscn` | 测试场景 |
| `scripts/konado/test_dialogue_screen.gd` | 测试场景脚本 |
