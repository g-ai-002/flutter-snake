#!/usr/bin/env python3
"""生成皮肤贴图（纯标准库，不依赖 Pillow）。

画布固定 16x16 RGBA，输出到 assets/images/sprites/<palette>/：
- snake_head.png / snake_body.png / snake_tail.png
- food_0.png ~ food_3.png（4 帧呼吸动画）

放在 assets/images 下是为了匹配 Flame Images 的默认前缀（assets/images/）。

刷新方式：python .build/generate_sprites.py
"""

import math
import os
import struct
import zlib

SIZE = 16
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_ROOT = os.path.join(ROOT, 'assets', 'images', 'sprites')

PALETTES = {
    'pixel': {
        'body': (95, 208, 104, 255),
        'body_dark': (44, 132, 62, 255),
        'body_light': (158, 238, 158, 255),
        'eye': (255, 255, 255, 255),
        'pupil': (24, 32, 24, 255),
        'food': (228, 87, 46, 255),
        'food_dark': (158, 44, 22, 255),
        'food_light': (255, 150, 108, 255),
        'leaf': (76, 175, 80, 255),
        'stem': (109, 76, 65, 255),
        'shine': (255, 255, 255, 220),
        'tongue': (230, 74, 74, 255),
    },
    'candy': {
        'body': (255, 139, 193, 255),
        'body_dark': (208, 78, 140, 255),
        'body_light': (255, 202, 229, 255),
        'eye': (255, 255, 255, 255),
        'pupil': (74, 20, 48, 255),
        'food': (94, 234, 212, 255),
        'food_dark': (30, 158, 142, 255),
        'food_light': (186, 255, 242, 255),
        'leaf': (255, 255, 255, 255),
        'stem': (255, 255, 255, 255),
        'shine': (255, 255, 255, 230),
        'tongue': (255, 255, 255, 255),
    },
}


def canvas():
    """返回 16x16 的 RGBA 像素矩阵（行优先）。"""
    return [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]


def put(px, x, y, color):
    if 0 <= x < SIZE and 0 <= y < SIZE:
        px[y][x] = color


def rounded_cells(left, top, right, bottom, radius):
    cells = set()
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            cx = min(max(x, left + radius), right - radius)
            cy = min(max(y, top + radius), bottom - radius)
            if (x - cx) ** 2 + (y - cy) ** 2 <= radius * radius + 0.5:
                cells.add((x, y))
    return cells


def draw_segment(pal, head=False, tail=False):
    px = canvas()
    if tail:
        left, top, right, bottom, radius = 2, 2, 13, 13, 5
    else:
        left, top, right, bottom, radius = 1, 1, 14, 14, 4

    for x, y in rounded_cells(left, top, right, bottom, radius):
        if x in (left, right) or y in (top, bottom):
            color = pal['body_dark']
        elif x <= left + 3 and y <= top + 3:
            color = pal['body_light']
        elif (x + y) % 7 == 0:
            color = pal['body_dark']
        else:
            color = pal['body']
        put(px, x, y, color)

    if head:
        # 眼睛（朝向右侧），瞳孔靠前。
        for x in (9, 10):
            for y in (3, 4, 10, 11):
                put(px, x, y, pal['eye'])
        put(px, 10, 4, pal['pupil'])
        put(px, 10, 11, pal['pupil'])
        # 吐信子。
        put(px, 14, 7, pal['tongue'])
        put(px, 15, 7, pal['tongue'])
        put(px, 14, 8, pal['tongue'])
    return px


def draw_food(pal, frame):
    px = canvas()
    radius = (4.6, 5.0, 5.2, 4.9)[frame]
    cx, cy = 7.5, 8.8
    for y in range(SIZE):
        for x in range(SIZE):
            dist = math.hypot(x - cx, y - cy)
            if dist > radius:
                continue
            if dist > radius - 0.9:
                color = pal['food_dark']
            elif (cx - x) + (cy - y) > 1.4:
                color = pal['food_light']
            else:
                color = pal['food']
            put(px, x, y, color)

    # 顶部果蒂与叶子。
    put(px, 7, 2, pal['stem'])
    put(px, 7, 3, pal['stem'])
    put(px, 8, 3, pal['stem'])
    for x, y in ((9, 3), (10, 3), (10, 4), (11, 4), (11, 5), (10, 5)):
        put(px, x, y, pal['leaf'])

    # 高光随帧轻微移动，形成闪动感。
    shine = ((4, 6), (4, 7), (5, 6), (5, 5))[frame]
    put(px, shine[0], shine[1], pal['shine'])
    put(px, shine[0] + 1, shine[1], pal['shine'])
    return px


def write_png(path, pixels):
    raw = b''.join(
        b'\x00' + b''.join(bytes(pixel) for pixel in row) for row in pixels
    )

    def chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return (
            struct.pack('>I', len(data))
            + tag
            + data
            + struct.pack('>I', crc)
        )

    header = struct.pack('>IIBBBBB', SIZE, SIZE, 8, 6, 0, 0, 0)
    png = (
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', header)
        + chunk(b'IDAT', zlib.compress(raw, 9))
        + chunk(b'IEND', b'')
    )
    with open(path, 'wb') as handle:
        handle.write(png)


def main():
    for name, palette in PALETTES.items():
        target = os.path.join(OUT_ROOT, name)
        os.makedirs(target, exist_ok=True)
        write_png(os.path.join(target, 'snake_head.png'), draw_segment(palette, head=True))
        write_png(os.path.join(target, 'snake_body.png'), draw_segment(palette))
        write_png(os.path.join(target, 'snake_tail.png'), draw_segment(palette, tail=True))
        for frame in range(4):
            write_png(
                os.path.join(target, f'food_{frame}.png'),
                draw_food(palette, frame),
            )
        print(f'generated {target}')


if __name__ == '__main__':
    main()
