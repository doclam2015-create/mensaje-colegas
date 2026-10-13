# Genera el ícono de Mensaje Colegas: globo de chat verde con ‼️ rojo
import json, os
from PIL import Image, ImageDraw
N = 1024
img = Image.new('RGBA', (N, N)); px = img.load()
for y in range(N):
    for x in range(N):
        t = (x * 0.3 + y * 0.7) / N
        px[x, y] = (int(18 + 20*t), int(140 + 40*t), int(90 + 20*t), 255)
d = ImageDraw.Draw(img)
d.rounded_rectangle([170, 210, 854, 720], radius=150, fill=(255, 255, 255, 255))
d.polygon([(280, 680), (230, 860), (430, 700)], fill=(255, 255, 255, 255))
for cx in (440, 584):  # ‼
    d.rounded_rectangle([cx-38, 300, cx+38, 545], radius=34, fill=(220, 40, 50, 255))
    d.ellipse([cx-42, 580, cx+42, 664], fill=(220, 40, 50, 255))
base = 'MensajeColegas/Assets.xcassets'
dst = f'{base}/AppIcon.appiconset'; os.makedirs(dst, exist_ok=True)
img.save(f'{dst}/icon-1024.png')
json.dump({"images": [{"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": {"author": "xcode", "version": 1}}, open(f'{dst}/Contents.json', 'w'), indent=1)
json.dump({"info": {"author": "xcode", "version": 1}}, open(f'{base}/Contents.json', 'w'))
os.makedirs(f'{base}/AccentColor.colorset', exist_ok=True)
json.dump({"colors": [{"idiom": "universal", "color": {"color-space": "srgb", "components": {"red": "0.07", "green": "0.55", "blue": "0.35", "alpha": "1.0"}}}], "info": {"author": "xcode", "version": 1}}, open(f'{base}/AccentColor.colorset/Contents.json', 'w'))
img.resize((256, 256)).save('tools/icono-preview.png')
