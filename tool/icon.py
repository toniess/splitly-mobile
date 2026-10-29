# Иконка Splitly: круг, разрезанный пополам с зазором, — «делим счёт».
#   python3 tool/icon.py assets/icon && dart run flutter_launcher_icons
import sys
from PIL import Image, ImageDraw

out = sys.argv[1]
S = 4096  # рисуем крупно и уменьшаем — сглаживание краёв
BG = (15, 17, 21, 255)
BLUE = (91, 140, 255, 255)
GREEN = (62, 207, 142, 255)

def motif(size, scale):
    """Две половины круга, сдвинутые друг от друга по диагонали."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = size * scale / 2
    c = size / 2
    gap = size * 0.035
    # левая-верхняя половина — синяя, правая-нижняя — зелёная; разрез по диагонали
    box = lambda dx, dy: [c - r + dx, c - r + dy, c + r + dx, c + r + dy]
    d.pieslice(box(-gap, -gap), 135, 315, fill=BLUE)
    d.pieslice(box(gap, gap), 315, 135, fill=GREEN)
    return img

# iOS и общий мастер: тёмный фон без прозрачности, iOS сам скруглит углы
full = Image.new('RGBA', (S, S), BG)
full.alpha_composite(motif(S, 0.58))
full.convert('RGB').resize((1024, 1024), Image.LANCZOS).save(f'{out}/icon.png')

# Android adaptive: только передний план, внутри безопасной зоны (66%)
fg = motif(S, 0.42)
fg.resize((1024, 1024), Image.LANCZOS).save(f'{out}/icon_foreground.png')
