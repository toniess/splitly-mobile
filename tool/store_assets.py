# Доводит материалы для Google Play: скриншоты до 9:16, иконка 512, баннер 1024×500.
# Нужен Pillow; шрифт баннера — системный SF (macOS).
#   python3 tool/store_assets.py . "Делим счёт и считаем, кто кому должен" ru
#   python3 tool/store_assets.py . "Split the bill, see who owes whom" en
import sys, glob, os
from PIL import Image, ImageDraw, ImageFont
root = sys.argv[1]
BG = (15, 17, 21)

# Скриншоты: Play принимает телефонные снимки только в пропорции ровно 9:16.
# Современные телефоны вытянутее (19.5:9), поэтому расширяем снимок фоном по бокам.
for f in glob.glob(f'{root}/store/screenshots/*.png'):
    im = Image.open(f).convert('RGB')
    w, h = im.size
    nh = -(-max(h, w * 16 // 9) // 16) * 16   # кратно 16, чтобы 9:16 вышло точно
    nw = nh * 9 // 16
    if (nw, nh) != (w, h):
        canvas = Image.new('RGB', (nw, nh), BG)
        canvas.paste(im, ((nw - w) // 2, (nh - h) // 2))
        canvas.save(f)

icon = Image.open(f'{root}/assets/icon/icon.png').convert('RGB')
icon.resize((512, 512), Image.LANCZOS).save(f'{root}/store/icon-512.png')

# Баннер: иконка слева, название и подпись справа
fg = Image.new('RGB', (1024, 500), BG)
fg.paste(icon.resize((340, 340), Image.LANCZOS), (70, 80))
d = ImageDraw.Draw(fg)
font = lambda size: ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', size)
d.text((460, 170), 'Splitly', font=font(96), fill=(231, 233, 238))
size = 30
while d.textlength(sys.argv[2], font=font(size)) > 1024 - 464 - 50:
    size -= 1
d.text((464, 290), sys.argv[2], font=font(size), fill=(139, 147, 165))
fg.save(f'{root}/store/feature-graphic-{sys.argv[3]}.png')
