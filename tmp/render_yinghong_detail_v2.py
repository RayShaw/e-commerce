from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path('/Users/rayleighshaw/www/e-commerce')
OUT = ROOT / '商品介绍/英德红茶-英红九号-浓香型-礼盒铁罐装-双罐500g-第二版详情页'
BASE = OUT / '底图'
SRC = ROOT / '素材/英德红茶-英红九号-浓香型-礼盒铁罐装-双罐500g'

W, H = 750, 1100
FONT = '/System/Library/Fonts/STHeiti Light.ttc'

COLORS = {
    'paper': '#F3EBDD',
    'paper2': '#E8DCC9',
    'brown': '#604238',
    'charcoal': '#292826',
    'red': '#733D39',
    'teal': '#23565B',
    'gold': '#B58A50',
    'white': '#FFFDF8',
}


def font(size):
    return ImageFont.truetype(FONT, size)


def cover(img, size=(W, H), focus=(0.5, 0.5)):
    img = img.convert('RGB')
    sw, sh = size
    scale = max(sw / img.width, sh / img.height)
    nw, nh = round(img.width * scale), round(img.height * scale)
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = max(0, min(nw - sw, round((nw - sw) * focus[0])))
    top = max(0, min(nh - sh, round((nh - sh) * focus[1])))
    return img.crop((left, top, left + sw, top + sh))


def contain(img, size, bg):
    img = img.convert('RGB')
    scale = min(size[0] / img.width, size[1] / img.height)
    img = img.resize((round(img.width * scale), round(img.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new('RGB', size, bg)
    canvas.paste(img, ((size[0] - img.width) // 2, (size[1] - img.height) // 2))
    return canvas


def gradient_overlay(img, top_alpha=0, bottom_alpha=150, color=(20, 15, 12)):
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    px = overlay.load()
    for y in range(img.height):
        a = int(top_alpha + (bottom_alpha - top_alpha) * y / max(1, img.height - 1))
        for x in range(img.width):
            px[x, y] = (*color, a)
    return Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')


def round_rect(draw, box, fill, radius=20, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, size, fill, anchor='la', spacing=8, stroke=0, stroke_fill=None):
    draw.multiline_text(xy, value, font=font(size), fill=fill, anchor=anchor,
                        spacing=spacing, stroke_width=stroke, stroke_fill=stroke_fill)


def feather(draw, x, y, length=140, color=None):
    color = color or COLORS['teal']
    draw.arc((x, y, x + length, y + length // 2), 190, 350, fill=color, width=3)
    for i in range(5):
        px = x + 30 + i * 20
        py = y + 34 - i * 3
        draw.line((px, py, px + 18, py - 18), fill=color, width=2)
        draw.line((px + 3, py + 3, px + 25, py + 13), fill=color, width=2)


def save(img, name):
    img.save(OUT / name, quality=94, subsampling=0)


def page1():
    src = Image.open(BASE / '01-首屏底图.png')
    canvas = Image.new('RGB', (W, H), COLORS['paper'])
    photo = cover(src, (W, 750), focus=(0.5, 0.5))
    canvas.paste(photo, (0, 350))
    draw = ImageDraw.Draw(canvas)
    text(draw, (58, 66), '英德红茶 · 英红九号', 26, COLORS['teal'])
    text(draw, (58, 118), '浓香型双罐茶礼', 57, COLORS['brown'])
    text(draw, (60, 203), '两罐配一只礼袋，送人方便，\n留在家里慢慢喝也合适。', 27, '#54463D', spacing=11)
    draw.line((58, 302, 692, 302), fill=COLORS['gold'], width=2)
    text(draw, (58, 320), '浓香型   双罐装   配礼袋   500g', 22, COLORS['red'])
    feather(draw, 560, 62, 130)
    save(canvas, '01-首屏双罐茶礼.jpg')


def page2():
    src = Image.open(BASE / '02-包装组合底图.png')
    canvas = Image.new('RGB', (W, H), COLORS['paper'])
    photo = cover(src, (750, 730), focus=(0.50, 0.52))
    canvas.paste(photo, (0, 220))
    draw = ImageDraw.Draw(canvas)
    text(draw, (54, 48), '一袋两罐，包装组合看清楚', 43, COLORS['brown'])
    text(draw, (55, 116), '礼袋、双罐，实物组合直接看', 25, '#6D5A4D')
    feather(draw, 584, 112, 105)
    round_rect(draw, (38, 925, 712, 1068), COLORS['white'], radius=22)
    text(draw, (78, 967), '双罐分装', 27, COLORS['teal'])
    text(draw, (283, 967), '礼袋随附', 27, COLORS['teal'])
    text(draw, (488, 967), '日常取用', 27, COLORS['teal'])
    text(draw, (78, 1017), '一罐常喝', 20, '#6E625A')
    text(draw, (283, 1017), '摆放整齐', 20, '#6E625A')
    text(draw, (488, 1017), '开合顺手', 20, '#6E625A')
    save(canvas, '02-礼盒双罐实物.jpg')


def page3():
    img = cover(Image.open(BASE / '03-干茶底图.png'), (W, H), focus=(0.5, 0.5))
    draw = ImageDraw.Draw(img)
    text(draw, (54, 70), '干茶近一点看', 50, COLORS['white'])
    text(draw, (56, 142), '卷曲茶条，深浅自然', 27, '#D8C9B6')
    draw.line((55, 194, 244, 194), fill=COLORS['gold'], width=3)
    panel = Image.new('RGBA', (W, 270), (25, 22, 20, 205))
    img.paste(panel, (0, 830), panel)
    draw = ImageDraw.Draw(img)
    text(draw, (55, 878), '深褐与乌褐交错，\n能看见较浅的金黄色茶条。', 29, COLORS['white'], spacing=12)
    text(draw, (55, 1004), '粗细、长短和碎整有自然差异', 21, '#D7C8B8')
    text(draw, (615, 1036), '干茶参考素材制作', 15, '#B8AA9B', anchor='ma')
    save(img, '03-干茶条索细节.jpg')


def page4():
    img = cover(Image.open(BASE / '04-冲泡底图.png'), (W, H), focus=(0.5, 0.5))
    draw = ImageDraw.Draw(img)
    round_rect(draw, (42, 45, 708, 264), (243, 235, 221, 235), radius=18)
    text(draw, (76, 77), '浓香型，浓淡自己掌握', 43, COLORS['brown'])
    text(draw, (77, 143), '投茶量、水温和浸泡时间不同，\n一杯茶的浓淡也会跟着变化。', 25, '#5D5149', spacing=10)
    text(draw, (75, 234), '冲泡场景示意', 16, COLORS['teal'])
    feather(draw, 550, 190, 95)
    save(img, '04-浓香型冲泡场景.jpg')


def page5():
    img = cover(Image.open(BASE / '04-冲泡底图.png'), (W, H), focus=(0.5, 0.48)).filter(ImageFilter.GaussianBlur(0.25))
    shade = Image.new('RGBA', (W, H), (20, 15, 12, 90))
    img = Image.alpha_composite(img.convert('RGBA'), shade).convert('RGB')
    draw = ImageDraw.Draw(img)
    text(draw, (54, 62), '先少放一点，泡到喜欢的浓度', 42, COLORS['white'], stroke=1, stroke_fill='#3A2B24')
    text(draw, (56, 126), '这组参数适合第一次试泡', 24, '#EFE3D1')
    cards = [
        ('01', '约5克', '先从少量开始'),
        ('02', '约90℃', '水温不用滚沸'),
        ('03', '及时出汤', '偏浓就泡快些'),
    ]
    y = 720
    for n, big, small in cards:
        round_rect(draw, (52, y, 698, y + 94), (246, 238, 225, 235), radius=18)
        text(draw, (82, y + 47), n, 18, COLORS['gold'], anchor='lm')
        text(draw, (148, y + 46), big, 30, COLORS['brown'], anchor='lm')
        text(draw, (650, y + 47), small, 21, '#675B52', anchor='rm')
        y += 108
    text(draw, (375, 1067), '茶具容量不同，请按个人口味调整', 17, '#EFE3D1', anchor='ma')
    save(img, '05-简单冲泡建议.jpg')


def page6():
    img = cover(Image.open(BASE / '05-礼赠底图.png'), (W, H), focus=(0.5, 0.5))
    draw = ImageDraw.Draw(img)
    round_rect(draw, (42, 44, 708, 248), (244, 235, 220, 238), radius=18)
    text(draw, (75, 75), '送出去体面，留下来实用', 43, COLORS['brown'])
    text(draw, (76, 142), '拜访亲友，礼袋拎上就走。\n平时自饮，一罐常喝，一罐收好。', 25, '#5D5149', spacing=10)
    text(draw, (75, 225), '礼赠场景示意', 16, COLORS['teal'])
    feather(draw, 552, 180, 92)
    save(img, '06-送礼与自饮场景.jpg')


def page7():
    src = Image.open(BASE / '02-包装组合底图.png')
    canvas = Image.new('RGB', (W, H), COLORS['paper'])
    photo = cover(src, (W, 490), focus=(0.51, 0.48))
    canvas.paste(photo, (0, 0))
    draw = ImageDraw.Draw(canvas)
    text(draw, (54, 530), '下单前，把规格看清楚', 43, COLORS['brown'])
    draw.line((55, 592, 695, 592), fill=COLORS['gold'], width=2)
    rows = [
        ('商品名称', '英德红茶 · 英红九号'),
        ('口味类型', '浓香型'),
        ('计划净含量', '250g/罐 × 2罐，共500g'),
        ('包装形式', '双铁罐装，配礼袋'),
        ('储存建议', '密封、避光、防潮、防异味'),
    ]
    y = 628
    for label, value in rows:
        text(draw, (56, y), label, 21, COLORS['teal'])
        text(draw, (225, y), value, 24, '#4C423B')
        draw.line((55, y + 48, 695, y + 48), fill='#D6C8B5', width=1)
        y += 76
    round_rect(draw, (54, 1014, 696, 1070), COLORS['brown'], radius=12)
    text(draw, (375, 1042), '生产日期与保质期以实际包装标识为准', 19, COLORS['white'], anchor='mm')
    save(canvas, '07-包装与规格.jpg')


def page8():
    img = cover(Image.open(BASE / '01-首屏底图.png'), (W, H), focus=(0.5, 0.50))
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle((0, 0, W, 360), fill=(243, 235, 221, 242))
    od.rectangle((0, 920, W, H), fill=(35, 31, 27, 205))
    img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    draw = ImageDraw.Draw(img)
    text(draw, (55, 70), '双罐配礼袋，喝茶送礼都好安排', 41, COLORS['brown'])
    text(draw, (56, 139), '想送人，双罐礼袋已经配好。\n想自饮，先按自己的口味泡一杯。', 26, '#594B42', spacing=11)
    feather(draw, 555, 214, 100)
    text(draw, (375, 975), '英德红茶 · 英红九号', 27, '#F1E5D2', anchor='ma')
    text(draw, (375, 1029), '浓香型  |  双罐装  |  配礼袋  |  500g', 20, COLORS['white'], anchor='ma')
    text(draw, (375, 1070), '茶叶为农产品，不同批次会有细微差异', 16, '#D3C5B4', anchor='ma')
    save(img, '08-收尾购买提醒.jpg')


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for fn in (page1, page2, page3, page4, page5, page6, page7, page8):
        fn()
