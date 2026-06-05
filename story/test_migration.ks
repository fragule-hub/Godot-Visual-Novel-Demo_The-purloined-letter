# 迁移测试剧本
# 测试 Eve 单图立绘 + Clara 组合立绘系统 + 内联命令系统

# 切换背景
background test_room

# ================================================================
# 内联命令测试（{wait} / {change} / {speed}）
# ================================================================
actor show Clara preset:intro_default at 3

# --- 全组合测试（优先验证） ---
"Clara" "全组合测试：嗯...{wait:0.8}{change:Clara,preset:left_smile}{speed:15}慢慢地、微笑着说...{wait:0.5}{change:Clara,preset:angry}{speed:50}但是突然就生气了！{change:Clara,preset:intro_default}{speed:25}好，恢复正常。"

# --- 省略号停顿测试 ---
"Clara" "我需要想一想{wait_pause:3.0,3}嗯，想好了。"
"Clara" "这是一个很长的停顿{wait_pause:5.0,6}终于结束了。"
"Clara" "我在思考{wait_pause:2.0,3}{change:Clara,preset:angry}想完就生气！"

# --- wait 基础 ---
"Clara" "这是 {wait} 基础测试：说到一半...{wait:1.0}...停顿后继续。"
"Clara" "再来一次稍长的停顿：我需要想想...{wait:2.0}...嗯，好的。"
"Clara" "短停顿也可以：一{wait:0.3}个{wait:0.3}字{wait:0.3}一{wait:0.3}个{wait:0.3}字。"

# --- change 基础 ---
"Clara" "接下来测试中途换表情。我本来很平静，但是{change:Clara,preset:angry}突然生气了！"
"Clara" "让我换个表情...{change:Clara,preset:left_smile}现在微笑了。"
"Clara" "再换回来{change:Clara,preset:intro_default}恢复正常。"

# --- speed 基础 ---
"Clara" "现在测试变速。{speed:50}这段话说得很快，因为速度调到了50。{speed:20}然后慢下来，回到20的速度，你能感觉到区别吗？"
"Clara" "极速模式：{speed:80}噼里啪啦噼里啪啦说完一整段话根本不带停的！{speed:25}呼——恢复正常。"

# --- change + wait 组合 ---
"Clara" "组合测试一：停顿后换表情。我有话要说...{wait:1.0}{change:Clara,preset:angry}其实我很不满！"
"Clara" "组合测试二：换表情后停顿。{change:Clara,preset:left_smile}嗯...{wait:1.5}开心的事要慢慢说。"

# --- change + speed 组合 ---
"Clara" "组合测试三：换表情同时变速。{change:Clara,preset:angry}{speed:50}你到底听明白了没有！{change:Clara,preset:intro_default}{speed:25}好，我再说一遍。"

# --- wait + speed 组合 ---
"Clara" "组合测试四：停顿后变速。等一下...{wait:1.0}{speed:50}然后突然加速说完这句话！{speed:25}结束。"

# --- 无标签对照组 ---
"Clara" "这是一句没有任何内联标签的普通对话，应该和以前完全一样。"

# 恢复默认状态，准备后续测试
actor change Clara preset:intro_default

# ================================================================
# Eve + Clara 双人场景测试
# ================================================================
"Eve" "Clara，测试开始了。你是组合立绘系统，我是单图立绘系统。"

actor show Eve neutral at 2

"Clara" "没错。我有 16 层图层可以自由组合，你只需要一张 PNG。"
"Eve" "虽然简单，但切换表情也很方便。让我们各自展示一下吧。"
"Clara" "好，我先退出，你来单独测试。"

actor exit Clara

# ========== Eve 单独测试 ==========
"Eve" "现在我来展示表情切换。"

actor change Eve angry
"Eve" "切换到 Angry 表情。"

actor change Eve smile
"Eve" "切换到 Smile 表情。"

actor change Eve shy
"Eve" "切换到 Shy 表情。Eve 多表情切换测试完成。"

actor exit Eve

# ========== Clara 单独测试 ==========
actor show Clara preset:intro_default at 3
"Clara" "我是 Clara，使用组合立绘系统。当前是默认预设（正面、中性表情）。"

actor change Clara preset:left_smile
"Clara" "切换到左向微笑预设。方向图层已切换。"

actor change Clara preset:right_coat_smile
"Clara" "切换到右向外套微笑。外套层叠加在衬衫层之上。"

actor change Clara preset:vest_angry
"Clara" "切换到背心+愤怒预设。背心层可见，配饰为蝴蝶结。"

# 服装冲突测试
"我" "接下来测试服装冲突规则：同时设置外套和背心。"

actor change Clara dir=center|outer=coat_01|vest=school_vest
"Clara" "冲突规则应自动隐藏背心（外套优先）。如果看到外套但无背心，说明规则生效。"

actor exit Clara

# ========== 结束 ==========
"我" "迁移测试完成。Eve 单图系统、Clara 组合立绘系统、内联命令系统均正常工作。"

end
