"""
Clara PSD Export Script

从 3 个 PSD 源文件导出组合立绘所需的 PNG 层。
使用 psd-tools[composite] 的 force=True 合成，正确处理 Premultiplied Alpha。

PSD 实际层名（带下划线，非空格）:
  CENTER: back_hair, body, socks, shoes, pants, necklace, tank_top, right_arm,
          jacket, band, watch, bangs, head, earring, front_hair, expresssions, ahoge
  LEFT:   back_hair, body, socks, sneakers, watch, shorts, tank_top, arm,
          necklace, jacket, band, hair, ear, front_hair, expressions, ahoge
  RIGHT:  back_hair, body, socks, sneakers, shorts, tank_top, right hand,
          head, left_arm, watch, necklace, jacket, bang, left_ear, ear rings,
          front_hair, expressions, ahoge
"""
import sys
from pathlib import Path

try:
    from psd_tools import PSDImage
except ImportError:
    print("ERROR: psd-tools not installed. Run: pip install 'psd-tools[composite]'")
    sys.exit(1)

# ── 项目路径 ─────────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).resolve().parent.parent
PSD_DIR = PROJECT_ROOT / "assets" / "立绘" / "clara"
OUTPUT_BASE = PSD_DIR / "layers"

PSD_FILES = {
    "center": PSD_DIR / "clara-original-center-normal_1000x2000px.psd",
    "left":   PSD_DIR / "clara-original-left-normal_1000x2000px.psd",
    "right":  PSD_DIR / "clara-original-right-normal_1000x2000px.psd",
}

# body 合并层名（小写下划线形式，匹配实际 PSD 层名）
BODY_LAYER_NAMES = {
    "body", "socks", "shoes", "sneakers", "pants", "shorts",
    "tank_top", "right_arm", "left_arm", "arm", "right hand",
    "necklace", "band", "watch",
}

# 表情名标准化（LEFT/RIGHT 的 "surprise" → "surprised"，"scared " → "scared"）
NAME_NORMALIZE = {"surprise": "surprised"}

# 全部 28 个标准表情名
EXPRESSION_NAMES = {
    "neutral", "happy", "angry", "sad", "surprised", "confused",
    "serious", "confident", "embarrassed", "blush", "smirk", "mock",
    "furious", "scared", "fright", "terror", "crying", "sobbing",
    "unease", "tired", "exhausted", "sleepy", "disgusted", "nauseating",
    "kiss", "soulless", "psychotic", "stoic",
}

# ── 工具函数 ─────────────────────────────────────────────────

def _clean(name: str) -> str:
    """清理 PSD 层名：去除尾部 null 字符和空白"""
    return name.rstrip('\x00').strip().lower()


def find_child(root, name: str):
    """在直接子层中查找（忽略大小写，strip 空格/null）"""
    target = _clean(name)
    for layer in root:
        if _clean(layer.name) == target:
            return layer
    return None


def find_child_any(root, *names):
    """查找匹配任一名称的直接子层"""
    targets = {_clean(n) for n in names}
    for layer in root:
        if _clean(layer.name) in targets:
            return layer
    return None


def find_children_by_keyword(root, keyword: str):
    """查找名称中包含关键词的所有直接子层"""
    kw = keyword.lower()
    return [layer for layer in root if kw in _clean(layer.name)]


def find_expressions_group(root):
    """查找表情组（容错：expressions / expresssions）"""
    for layer in root:
        name = _clean(layer.name)
        if name in ("expressions", "expresssions") and layer.is_group():
            return layer
    return None


def set_all_visible(root, visible: bool = True):
    """递归设置所有层可见性"""
    for layer in root:
        layer.visible = visible
        if layer.is_group():
            set_all_visible(layer, visible)


def hide_all_children(root):
    """隐藏所有直接子层"""
    for layer in root:
        layer.visible = False


def render_visible(psd):
    """合成当前可见状态的全画布图像"""
    return psd.composite(force=True)


def save_png(img, path: Path):
    """保存为 PNG"""
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(path), "PNG")
    print(f"  -> {path.relative_to(PROJECT_ROOT)}")


# ── 导出函数 ─────────────────────────────────────────────────

def export_single_layer(psd, root_children, layer, output_path: Path):
    """导出单个 PSD 层为全画布 PNG"""
    hide_all_children(root_children)
    layer.visible = True
    img = render_visible(psd)
    save_png(img, output_path)
    set_all_visible(root_children)


def export_composite(psd, root_children, layers: list, output_path: Path):
    """合并多个层为单个全画布 PNG"""
    hide_all_children(root_children)
    for layer in layers:
        layer.visible = True
    img = render_visible(psd)
    save_png(img, output_path)
    set_all_visible(root_children)


def save_expression_defaults(expressions_group) -> dict:
    """保存 PSD 中所有表情子层的原始可见性状态（在任何 set_all_visible 调用前）"""
    defaults = {}
    for expr_group in expressions_group:
        raw_name = _clean(expr_group.name)
        expr_name = NAME_NORMALIZE.get(raw_name, raw_name)
        layer_vis = {}
        _collect_visibility(expr_group, "", layer_vis)
        defaults[expr_name] = layer_vis
    return defaults


def _collect_visibility(layer, prefix: str, result: dict):
    """递归收集层可见性到 result dict"""
    key = prefix + layer.name
    result[key] = layer.visible
    if layer.is_group():
        for child in layer:
            _collect_visibility(child, key + "/", result)


def restore_expression_defaults(expr_group, defaults: dict):
    """恢复一个表情组内所有子层到 PSD 默认可见性"""
    _apply_visibility(expr_group, "", defaults)


def _apply_visibility(layer, prefix: str, defaults: dict):
    """递归恢复层可见性"""
    key = prefix + layer.name
    if key in defaults:
        layer.visible = defaults[key]
    if layer.is_group():
        for child in layer:
            _apply_visibility(child, key + "/", defaults)


def export_face_variants(psd, root_children, expressions_group, head_layer,
                         output_dir: Path, has_head: bool, expr_defaults: dict):
    """
    导出 28 个表情为 face PNG。
    每次渲染前：
    1. 隐藏所有根子层（包括 expressions 组）
    2. 显示 expressions 父组
    3. 隐藏所有 28 个表情组的内部子层（避免其他表情叠加）
    4. 恢复当前表情的 PSD 默认子层可见性
    5. 显示当前表情
    """
    # 先隐藏所有根子层
    hide_all_children(root_children)
    expressions_group.visible = True  # 父组必须可见

    # 隐藏所有 28 个表情组的内部子层（为每次渲染建立干净基线）
    for expr_group in expressions_group:
        expr_group.visible = False
        for sub in expr_group:
            sub.visible = False
            if sub.is_group():
                for child in sub:
                    child.visible = False

    for expr_group in expressions_group:
        raw_name = _clean(expr_group.name)
        expr_name = NAME_NORMALIZE.get(raw_name, raw_name)
        if expr_name not in EXPRESSION_NAMES:
            print(f"    Skipping unknown expression: '{raw_name}'")
            continue

        # 恢复该表情的 PSD 默认可见性
        if expr_name in expr_defaults:
            restore_expression_defaults(expr_group, expr_defaults[expr_name])

        # 显示此表情
        expr_group.visible = True
        if has_head and head_layer:
            head_layer.visible = True

        img = render_visible(psd)
        save_png(img, output_dir / f"{expr_name}.png")

        # 隐藏当前表情，准备下一个
        expr_group.visible = False
        # 重新隐藏内部子层（被 restore 改过）
        for sub in expr_group:
            sub.visible = False
            if sub.is_group():
                for child in sub:
                    child.visible = False
        if head_layer:
            head_layer.visible = False

    set_all_visible(root_children)


# ── 主流程 ─────────────────────────────────────────────────

def export_direction(direction: str, psd_path: Path):
    """导出一个方向的所有 slot"""
    print(f"\n{'='*60}")
    print(f"Exporting: {direction.upper()}  ({psd_path.name})")
    print(f"{'='*60}")

    psd = PSDImage.open(str(psd_path))
    # 找到角色 Group（跳过 background 等非 Group 层）
    root = None
    for layer in psd:
        if layer.is_group():
            root = layer
        else:
            layer.visible = False  # 隐藏 background
    if root is None:
        print(f"  ERROR: No character group found in {psd_path.name}")
        return
    root.visible = True
    children = list(root)

    out = OUTPUT_BASE / direction
    out.mkdir(parents=True, exist_ok=True)

    # ── 保存 expression 默认可见性（必须在任何 set_all_visible 调用前）──
    expressions = find_expressions_group(root)
    expr_defaults = {}
    if expressions:
        expr_defaults = save_expression_defaults(expressions)
        print(f"  Saved expression defaults: {len(expr_defaults)} expressions")

    # ─ hair_back ─
    back_hair = find_child_any(root, "back_hair", "back hair")
    if back_hair:
        export_single_layer(psd, children, back_hair, out / "hair_back" / "base.png")
    else:
        print("  WARNING: back_hair not found")

    # ─ hair_side ─
    # LEFT: "hair" 层, RIGHT: "bang" 层（实际为侧发）, CENTER: 无独立层
    hair_side = None
    if direction == "left":
        hair_side = find_child(root, "hair")
    elif direction == "right":
        hair_side = find_child(root, "bang")
    if hair_side:
        export_single_layer(psd, children, hair_side, out / "hair_side" / "base.png")

    # ─ hair_front ─
    front_hair = find_child_any(root, "front_hair", "front hair")
    if front_hair:
        export_single_layer(psd, children, front_hair, out / "hair_front" / "base.png")
    else:
        print("  WARNING: front_hair not found")

    # ─ hair_top (ahoge) ─
    ahoge = find_child(root, "ahoge")
    if ahoge:
        export_single_layer(psd, children, ahoge, out / "hair_top" / "base.png")
    else:
        print("  WARNING: ahoge not found")

    # ─ ear ─
    ear_layers = find_children_by_keyword(root, "ear")
    if ear_layers:
        export_composite(psd, children, ear_layers, out / "ear" / "base.png")
    else:
        print("  WARNING: ear layers not found")

    # ─ body (composite) ─
    body_layers = []
    for layer in children:
        if _clean(layer.name) in BODY_LAYER_NAMES:
            body_layers.append(layer)
    if body_layers:
        print(f"  Body: compositing {len(body_layers)} layers: "
              f"{[_clean(l.name) for l in body_layers]}")
        export_composite(psd, children, body_layers, out / "body" / "base.png")
    else:
        print("  WARNING: no body layers found")

    # ─ outer (jacket) ─
    jacket = find_child_any(root, "jacket")
    if jacket:
        export_single_layer(psd, children, jacket, out / "outer" / "coat_01.png")
    else:
        print("  WARNING: jacket not found")

    # ─ face (expressions) ─ 使用已保存的默认值，避免被之前的 set_all_visible 污染
    if expressions:
        head = find_child(root, "head")
        has_head = head is not None
        print(f"  Face: {len(list(expressions))} expressions, "
              f"{'with head' if has_head else 'no head (LEFT)'}")
        export_face_variants(psd, children, expressions, head,
                             out / "face", has_head, expr_defaults)
    else:
        print("  WARNING: expressions group not found")

    print(f"  Done: {direction}")


def main():
    print("Clara PSD Export")
    print(f"PSD dir:    {PSD_DIR}")
    print(f"Output dir: {OUTPUT_BASE}")

    for direction, psd_path in PSD_FILES.items():
        if not psd_path.exists():
            print(f"\nWARNING: PSD not found: {psd_path}")
            continue
        export_direction(direction, psd_path)

    print(f"\n{'='*60}")
    print("Export complete!")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
