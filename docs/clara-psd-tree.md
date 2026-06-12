# Clara PSD Tree Structure

> 从 PSD 文件直接读取的实际层名（使用下划线命名）
> 更新于 2026-06-12


## CENTER
Size: 1000x2000
Root Group: "clara_original_center_normal"  children=17
  [Pixel] "back_hair"        → hair_back
  [Pixel] "body"             → body (base)
  [Pixel] "socks"            → body
  [Pixel] "shoes"            → body
  [Pixel] "pants"            → body
  [Pixel] "necklace"         → body
  [Pixel] "tank_top"         → body
  [Pixel] "right_arm"        → body
  [Pixel] "jacket"           → outer
  [Pixel] "band"             → body
  [Pixel] "watch"            → body
  [Pixel] "bangs"            → (前发刘海，未单独导出)
  [Pixel] "head"             → face (与表情合并)
  [Pixel] "earring"          → ear
  [Pixel] "front_hair"       → hair_front
  [Group] "expresssions"     → face (28 表情子组)
  [Pixel] "ahoge"            → hair_top

### Expressions (28):
kiss, soulless, psychotic, mock, smirk, embarrassed, blush, exhausted, sleepy, tired,
nauseating, disgusted, terror, fright, scared, furious, angry, sobbing, crying, unease,
sad, confused, serious, stoic, confident, surprised, happy, neutral


## LEFT
Size: 1000x2000
Root Group: "clara_left_original_normal"  children=16
  [Pixel] "back_hair"        → hair_back
  [Pixel] "body"             → body (base，含头部)
  [Pixel] "socks"            → body
  [Pixel] "sneakers"         → body
  [Pixel] "watch"            → body
  [Pixel] "shorts"           → body
  [Pixel] "tank_top"         → body
  [Pixel] "arm"              → body
  [Pixel] "necklace"         → body
  [Pixel] "jacket"           → outer
  [Pixel] "band"             → body
  [Pixel] "hair"             → hair_side
  [Pixel] "ear"              → ear
  [Pixel] "front_hair"       → hair_front
  [Group] "expressions"      → face (28 表情子组，无 head)
  [Pixel] "ahoge"            → hair_top

### Expressions (28):
kiss, soulless, psychotic, mock, smirk, embarrassed, blush, exhausted, sleepy, tired,
nauseating, disgusted, terror, fright, scared, furious, angry, sobbing, crying, unease,
sad, confused, serious, stoic, confident, surprise(→surprised), happy, neutral


## RIGHT
Size: 1000x2000
Root Group: "clara original right normal"  children=18
  [Pixel] "back_hair"        → hair_back
  [Pixel] "body"             → body (base)
  [Pixel] "socks"            → body
  [Pixel] "sneakers"         → body
  [Pixel] "shorts"           → body
  [Pixel] "tank_top"         → body
  [Pixel] "right hand"       → body
  [Pixel] "head"             → face (与表情合并)
  [Pixel] "left_arm"         → body
  [Pixel] "watch"            → body
  [Pixel] "necklace"         → body
  [Pixel] "jacket"           → outer
  [Pixel] "bang"             → body (band 同物)
  [Pixel] "left_ear"         → ear
  [Pixel] "ear rings"        → ear
  [Pixel] "front_hair"       → hair_front
  [Group] "expressions"      → face (28 表情子组)
  [Pixel] "ahoge"            → hair_top

### Expressions (28):
kiss, soulless, psychotic, mock, smirk, embarrassed, blush, exhausted, sleepy, tired,
nauseating, disgusted, terror, fright, scared, furious, angry, sobbing, crying, unease,
sad, confused, serious, stoic, confident, surprise(→surprised), happy, neutral


## 关键差异

| 项目 | CENTER | LEFT | RIGHT |
|------|--------|------|-------|
| head 层 | 独立 `head` | 无（在 body 中） | 独立 `head` |
| hair_side | 无 | `hair` | 无 |
| ear | `earring` | `ear` | `left_ear` + `ear rings` |
| 表情组名 | `expresssions`(3s) | `expressions` | `expressions` |
| 表情 surprise | `surprised` | `surprise` | `surprise` |
| shoes 命名 | `shoes` | `sneakers` | `sneakers` |
