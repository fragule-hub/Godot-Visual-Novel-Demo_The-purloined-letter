# 迁移测试剧本
# 测试 Clara 组合立绘系统（面部预设 + 3重预设 + 内联命令）
# h_division=3: at 1=左, at 2=中, at 3=右

background test_room fade


# ================================================================
# ⚡ 快速测试区：双人场景 + 交叉溶解 / 内联命令（放在开头方便测试）
# ================================================================

# --- 双人场景：左+右 ---
actor show Clara preset:dir_left|preset:body_casual|face=neutral at 1
actor show Eve neutral at 3

"Clara" "双人测试——左右站位。"
"Eve" "没问题，我已就位。"

actor exit Clara
actor exit Eve

# --- 双人场景：左+中 ---
actor show Clara preset:dir_left|preset:body_casual|face=neutral at 1
actor show Eve neutral at 2

"Clara" "一左一中的布局。"
"Eve" "收到。"

actor exit Clara
actor exit Eve

# --- 双人场景：中+右 ---
actor show Eve neutral at 2
actor show Clara preset:dir_right|preset:body_casual|face=neutral at 3

"Eve" "这次我在中间。"
"Clara" "我在右侧。"

actor exit Clara
actor exit Eve

# ================================================================
# 内联命令 + 快速切换测试
# ================================================================
actor show Clara preset:dir_center|preset:body_casual|face=neutral at 2

# --- 内联 change 交叉溶解 ---
"Clara" "内联表情切换：{change:Clara,face=happy}开心！{change:Clara,face=angry}生气了！{change:Clara,face=surprised}惊讶！{change:Clara,face=neutral}恢复。"

"Clara" "内联换装：{change:Clara,preset:body_coat}穿上外套了。{change:Clara,preset:body_casual}换回来了。"

"Clara" "内联全组合：{change:Clara,preset:dir_left|preset:body_coat|face=surprised}左向外套惊讶！"

actor change Clara preset:dir_center|preset:body_casual|face=neutral

# --- 快速连续切换 ---
"Clara" "快速连续切换测试："

actor change Clara face=happy
"Clara" "happy。"
actor change Clara face=angry
"Clara" "angry。"
actor change Clara face=surprised
"Clara" "surprised。"
actor change Clara face=sad
"Clara" "sad。"
actor change Clara face=neutral
"Clara" "快速切换测试完毕。"

# --- bounce + change 组合 ---
"Clara" "跳动加换表情：{bounce:Clara,2}{change:Clara,face=angry}跳完就生气！"

# --- Eve 简单立绘快速切换 ---
actor show Eve neutral at 2
"Eve" "Eve 快速切换："
actor change Eve angry
"Eve" "angry。"
actor change Eve smile
"Eve" "smile。"
actor change Eve shy
"Eve" "shy。"
actor exit Eve

actor change Clara preset:dir_center|preset:body_casual|face=neutral
"Clara" "快速测试区完成。接下来是完整表情遍历。"
actor exit Clara


# ================================================================
# 完整测试区（以下为原测试内容）
# ================================================================

# ================================================================
# 左向表情测试
# ================================================================
actor show Clara preset:dir_left|face=neutral at 1

"Clara" "左向表情测试开始。这是 neutral。"

actor change Clara preset:dir_left|face=happy
"Clara" "左向 happy。{bounce:Clara,1}"

actor change Clara preset:dir_left|face=angry
"Clara" "左向 angry。"

actor change Clara preset:dir_left|face=sad
"Clara" "左向 sad。"

actor change Clara preset:dir_left|face=surprised
"Clara" "左向 surprised。"

actor change Clara preset:dir_left|face=confused
"Clara" "左向 confused。"

actor change Clara preset:dir_left|face=serious
"Clara" "左向 serious。"

actor change Clara preset:dir_left|face=smirk
"Clara" "左向 smirk。"

actor change Clara preset:dir_left|face=blush
"Clara" "左向 blush。"

actor change Clara preset:dir_left|face=embarrassed
"Clara" "左向 embarrassed。"

actor change Clara preset:dir_left|face=furious
"Clara" "左向 furious！{bounce:Clara,2}"

actor change Clara preset:dir_left|face=crying
"Clara" "左向 crying……"

actor change Clara preset:dir_left|face=kiss
"Clara" "左向 kiss。"

actor change Clara preset:dir_left|face=psychotic
"Clara" "左向 psychotic。"

actor change Clara preset:dir_left|face=neutral
"Clara" "左向 14 种表情测试完毕。"


# ================================================================
# 右向表情测试
# ================================================================
actor change Clara preset:dir_right|face=neutral

"Clara" "右向表情测试开始。这是 neutral。"

actor change Clara preset:dir_right|face=happy
"Clara" "右向 happy。"

actor change Clara preset:dir_right|face=angry
"Clara" "右向 angry。"

actor change Clara preset:dir_right|face=sad
"Clara" "右向 sad。"

actor change Clara preset:dir_right|face=surprised
"Clara" "右向 surprised。"

actor change Clara preset:dir_right|face=confused
"Clara" "右向 confused。"

actor change Clara preset:dir_right|face=smirk
"Clara" "右向 smirk。"

actor change Clara preset:dir_right|face=furious
"Clara" "右向 furious！"

actor change Clara preset:dir_right|face=scared
"Clara" "右向 scared……"

actor change Clara preset:dir_right|face=tired
"Clara" "右向 tired……"

actor change Clara preset:dir_right|face=exhausted
"Clara" "右向 exhausted……"

actor change Clara preset:dir_right|face=sleepy
"Clara" "右向 sleepy……"

actor change Clara preset:dir_right|face=stoic
"Clara" "右向 stoic。"

actor change Clara preset:dir_right|face=neutral
"Clara" "右向 13 种表情测试完毕。"


# ================================================================
# 正向表情测试（精简）
# ================================================================
actor change Clara preset:dir_center|face=neutral

"Clara" "正向表情测试（精简）。这是 neutral。"

actor change Clara face=happy
"Clara" "正向 happy。"

actor change Clara face=angry
"Clara" "正向 angry。"

actor change Clara face=surprised
"Clara" "正向 surprised。"

actor change Clara face=sad
"Clara" "正向 sad。"

actor change Clara face=confused
"Clara" "正向 confused。"

actor change Clara face=furious
"Clara" "正向 furious。"

actor change Clara face=crying
"Clara" "正向 crying。"

actor change Clara face=neutral
"Clara" "正向 8 种表情测试完毕。"

# ================================================================
# 3重预设 + 身体测试
# ================================================================
"Clara" "接下来测试身体预设。"

actor change Clara preset:dir_left|preset:body_coat|face=happy
"Clara" "左向 + 外套 + 开心。"

actor change Clara preset:dir_right|preset:body_coat|face=angry
"Clara" "右向 + 外套 + 生气。"

actor change Clara preset:dir_center|preset:body_coat|face=confident
"Clara" "正向 + 外套 + 自信。"

actor change Clara preset:body_coat|face=smirk
"Clara" "外套 + smirk。"

actor change Clara preset:dir_left|preset:body_coat|face=blush
"Clara" "左向外套 + blush。"

actor change Clara preset:dir_right|preset:body_coat|face=serious
"Clara" "右向外套 + serious。"

actor change Clara preset:dir_center|preset:body_casual|face=neutral
"Clara" "恢复默认：正面 + 常服 + neutral。"

# ================================================================
# 内联命令测试
# ================================================================
"Clara" "内联表情切换：{change:Clara,face=happy}开心！{change:Clara,face=angry}生气了！{change:Clara,face=neutral}恢复。"

"Clara" "内联换装：{change:Clara,preset:body_coat}穿上外套了。"

"Clara" "内联全组合：{change:Clara,preset:dir_left|preset:body_coat|face=surprised}左向外套惊讶！"

# --- bounce / speed / wait ---
"Clara" "看我跳一下！{bounce:Clara}"
"Clara" "连续跳三下！{bounce:Clara,3}"
"Clara" "大力跳！{bounce:Clara,1,60,0.3}"
"Clara" "跳动加换表情：{bounce:Clara,2}{change:Clara,face=angry}跳完就生气！"

"Clara" "变速测试：{speed:50}这段话说得很快！{speed:25}恢复正常速度。"
"Clara" "停顿测试：等一下...{wait:1.0}好了。"

actor change Clara preset:dir_center|preset:body_casual|face=neutral
"Clara" "3重预设 + 内联命令测试全部完成！"

actor exit Clara

# ================================================================
# Eve 单独测试
# ================================================================
actor show Eve neutral at 2

"Eve" "现在我来展示表情切换。"

actor change Eve angry
"Eve" "切换到 Angry 表情。"

actor change Eve smile
"Eve" "切换到 Smile 表情。"

actor change Eve shy
"Eve" "切换到 Shy 表情。Eve 测试完成。"

actor exit Eve

# ================================================================
# 双人场景（结尾汇总）
# ================================================================
actor show Clara preset:dir_center|preset:body_casual|face=neutral at 2
actor show Eve neutral at 3

"Clara" "Eve，最终双人测试。"
"Eve" "一切正常，收工。"

actor exit Clara
actor exit Eve

# ========== 结束 ==========
"I" "迁移测试完成。"
end
