#!/usr/bin/env python3
"""对照检查中英日三语 KS 剧本的匹配度"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

import re
import os

BASE = r"E:\AAAGAMEDEMO\视觉小说\new-novel-demo\story"

CHAPTERS = {
    "chapter1": "第一章",
    "chapter2": "第二章",
    "chapter3": "第三章",
    "chapter4": "第四章",
}

# KS 命令关键字的正则
CMD_RE = re.compile(
    r'^\s*(?:(?:#\s*)?scene_break|background|play\s+bgm|actor\s+(?:show|change|exit|move)'
    r'|choice\s+|branch\s+|jump_branch\s+|jump_id\s+|end)\b|'
    r'^#|^$'
)

DIALOGUE_RE = re.compile(r'^"([^"]*)"\s*"([^"]*)"')

def extract_commands(lines):
    """提取指令行（非对话行）"""
    cmds = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('#'):
            cmds.append(('comment', stripped))
        elif CMD_RE.match(stripped) and not DIALOGUE_RE.match(stripped):
            cmds.append(('cmd', stripped))
        elif stripped == '':
            cmds.append(('blank', ''))
        elif DIALOGUE_RE.match(stripped):
            cmds.append(('dialogue', stripped))
        else:
            cmds.append(('other', stripped))
    return cmds

def extract_dialogues(lines):
    """提取纯对话行"""
    result = []
    for line in lines:
        m = DIALOGUE_RE.match(line.strip())
        if m:
            result.append((m.group(1), m.group(2)))
    return result

def check_chapter(ch_name, zh_path, en_path, ja_path):
    """检查单个章节的三语匹配"""
    issues = []
    with open(zh_path, 'r', encoding='utf-8') as f:
        zh = f.readlines()
    with open(en_path, 'r', encoding='utf-8') as f:
        en = f.readlines()
    with open(ja_path, 'r', encoding='utf-8') as f:
        ja = f.readlines()

    zh_stripped = [l.rstrip('\n\r') for l in zh]
    en_stripped = [l.rstrip('\n\r') for l in en]
    ja_stripped = [l.rstrip('\n\r') for l in ja]

    # 1. 提取所有对话
    zh_dial = extract_dialogues(zh)
    en_dial = extract_dialogues(en)
    ja_dial = extract_dialogues(ja)

    # 1a. 对话行数比较
    if len(zh_dial) != len(en_dial):
        issues.append(f"[对话行数] ZH={len(zh_dial)}, EN={len(en_dial)} — 数量不匹配(差{abs(len(zh_dial)-len(en_dial))})")
    if len(zh_dial) != len(ja_dial):
        issues.append(f"[对话行数] ZH={len(zh_dial)}, JA={len(ja_dial)} — 数量不匹配(差{abs(len(zh_dial)-len(ja_dial))})")

    # 2. 提取所有命令标签（非对话）
    zh_cmds = extract_commands(zh_stripped)
    en_cmds = extract_commands(en_stripped)
    ja_cmds = extract_commands(ja_stripped)

    # 逐一对比对话
    for i, ((zh_speaker, zh_text), (en_speaker, en_text), (ja_speaker, ja_text)) in enumerate(zip(zh_dial, en_dial, ja_dial)):
        idx = i + 1
        # 说话人已本地化，仅当格式异常时报告
        # 跳过正常的本地化差异 (如 克拉拉/Clara/クララ, 我/Me/私, 伊芙/Eve/イヴ)

        # 检查内联命令 (如 {bounce:...}, {change:...}, {wait:...}, {speed:...})
        zh_inlines = set(re.findall(r'\{[^}]+\}', zh_text))
        en_inlines = set(re.findall(r'\{[^}]+\}', en_text))
        ja_inlines = set(re.findall(r'\{[^}]+\}', ja_text))

        if zh_inlines != en_inlines:
            missing_en = zh_inlines - en_inlines
            extra_en = en_inlines - zh_inlines
            if missing_en:
                issues.append(f"[内联命令缺失-EN] 第{idx}条对话: {missing_en}")
            if extra_en:
                issues.append(f"[内联命令多余-EN] 第{idx}条对话: {extra_en}")

        if zh_inlines != ja_inlines:
            missing_ja = zh_inlines - ja_inlines
            extra_ja = ja_inlines - zh_inlines
            if missing_ja:
                issues.append(f"[内联命令缺失-JA] 第{idx}条对话: {missing_ja}")
            if extra_ja:
                issues.append(f"[内联命令多余-JA] 第{idx}条对话: {extra_ja}")

    # 3. 检查关键命令 (branch, choice, jump_id, actor, bgm, scene_break)
    zh_branches = [l for l in zh_stripped if re.match(r'^\s*branch\s+', l)]
    en_branches = [l for l in en_stripped if re.match(r'^\s*branch\s+', l)]
    ja_branches = [l for l in ja_stripped if re.match(r'^\s*branch\s+', l)]
    if len(zh_branches) != len(en_branches):
        issues.append(f"[branch数量] ZH={len(zh_branches)}, EN={len(en_branches)}")
    if len(zh_branches) != len(ja_branches):
        issues.append(f"[branch数量] ZH={len(zh_branches)}, JA={len(ja_branches)}")

    zh_choices = [l for l in zh_stripped if re.match(r'^\s*choice\s+', l)]
    en_choices = [l for l in en_stripped if re.match(r'^\s*choice\s+', l)]
    ja_choices = [l for l in ja_stripped if re.match(r'^\s*choice\s+', l)]
    if len(zh_choices) != len(en_choices):
        issues.append(f"[choice数量] ZH={len(zh_choices)}, EN={len(en_choices)}")
    if len(zh_choices) != len(ja_choices):
        issues.append(f"[choice数量] ZH={len(zh_choices)}, JA={len(ja_choices)}")

    zh_jumps = [l for l in zh_stripped if re.match(r'^\s*jump_(?:branch|id)\s+', l)]
    en_jumps = [l for l in en_stripped if re.match(r'^\s*jump_(?:branch|id)\s+', l)]
    ja_jumps = [l for l in ja_stripped if re.match(r'^\s*jump_(?:branch|id)\s+', l)]
    if len(zh_jumps) != len(en_jumps):
        issues.append(f"[jump数量] ZH={len(zh_jumps)}, EN={len(en_jumps)}")
    if len(zh_jumps) != len(ja_jumps):
        issues.append(f"[jump数量] ZH={len(zh_jumps)}, JA={len(ja_jumps)}")

    # 4. 检查总行数差异
    issues.append(f"[总行数] ZH={len(zh_stripped)}, EN={len(en_stripped)}, JA={len(ja_stripped)}")

    # 5. 检查结尾是否一致
    zh_last = zh_stripped[-1].strip() if zh_stripped else ''
    en_last = en_stripped[-1].strip() if en_stripped else ''
    ja_last = ja_stripped[-1].strip() if ja_stripped else ''
    if zh_last != en_last or zh_last != ja_last:
        issues.append(f"[结尾不一致] ZH='{zh_last}', EN='{en_last}', JA='{ja_last}'")

    return issues

def main():
    all_ok = True
    for ch_id, ch_label in CHAPTERS.items():
        zh_path = os.path.join(BASE, f"{ch_id}.ks")
        en_path = os.path.join(BASE, "en", f"{ch_id}.ks")
        ja_path = os.path.join(BASE, "ja", f"{ch_id}.ks")

        print(f"\n{'='*60}")
        print(f"  {ch_label} ({ch_id})")
        print(f"{'='*60}")
        issues = check_chapter(ch_id, zh_path, en_path, ja_path)

        if not issues or (len(issues) == 1 and issues[0].startswith('[总行数]')):
            print(f"  ✅ 通过 — 三语匹配无问题")
            if issues:
                print(f"     {issues[0]}")
        else:
            all_ok = False
            for iss in issues:
                print(f"  ❌ {iss}")

    if all_ok:
        print(f"\n{'='*60}")
        print(f"  🎉 全部通过：中英日三语剧本完全匹配！")
        print(f"{'='*60}")
    else:
        print(f"\n{'='*60}")
        print(f"  ⚠️  发现问题，需要修复")
        print(f"{'='*60}")

if __name__ == '__main__':
    main()
