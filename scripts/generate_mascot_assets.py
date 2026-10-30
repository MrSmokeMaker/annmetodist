import math
from PIL import Image, ImageDraw

def create_mascot_owl():
    size = 512
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)

    # Palette
    indigo_main = (79, 70, 229, 255)       # #4F46E5
    indigo_dark = (55, 48, 163, 255)       # #3730A3
    violet_light = (199, 210, 254, 255)    # #C7D2FE
    belly_cream = (245, 243, 255, 255)     # #F5F3FF
    beak_amber = (245, 158, 11, 255)       # #F59E0B
    beak_shadow = (217, 119, 6, 255)      # #D97706
    glasses_cyan = (6, 182, 212, 255)      # #06B6D4
    cap_dark = (30, 27, 75, 255)           # #1E1B4B
    tassel_gold = (251, 191, 36, 255)      # #FBBF24
    book_coral = (239, 68, 68, 255)        # #EF4444

    cx, cy = 256, 280

    # 1. Owl Ear Tufts
    draw.polygon([(cx - 120, cy - 80), (cx - 140, cy - 190), (cx - 60, cy - 130)], fill=indigo_dark)
    draw.polygon([(cx + 120, cy - 80), (cx + 140, cy - 190), (cx + 60, cy - 130)], fill=indigo_dark)
    draw.polygon([(cx - 110, cy - 85), (cx - 130, cy - 170), (cx - 70, cy - 125)], fill=violet_light)
    draw.polygon([(cx + 110, cy - 85), (cx + 130, cy - 170), (cx + 70, cy - 125)], fill=violet_light)

    # 2. Main Body & Head
    draw.ellipse([cx - 135, cy - 140, cx + 135, cy + 155], fill=indigo_main)

    # 3. Wings
    draw.ellipse([cx - 165, cy - 30, cx - 85, cy + 120], fill=indigo_dark)
    draw.ellipse([cx + 85, cy - 30, cx + 165, cy + 120], fill=indigo_dark)

    # 4. Belly
    draw.ellipse([cx - 90, cy - 10, cx + 90, cy + 140], fill=belly_cream)

    # Belly feather marks (cute crescents)
    for row in range(3):
        y_pos = cy + 25 + row * 30
        for x_offset in [-40, 0, 40] if row % 2 == 0 else [-20, 20]:
            draw.arc([cx + x_offset - 12, y_pos, cx + x_offset + 12, y_pos + 14], 0, 180, fill=indigo_dark, width=3)

    # 5. Feet
    for foot_x in [cx - 55, cx + 55]:
        for toe in [-15, 0, 15]:
            draw.ellipse([foot_x + toe - 9, cy + 140, foot_x + toe + 9, cy + 165], fill=beak_amber)

    # 6. Eye white disks
    draw.ellipse([cx - 95, cy - 85, cx - 10, cy], fill=(255, 255, 255, 255))
    draw.ellipse([cx + 10, cy - 85, cx + 95, cy], fill=(255, 255, 255, 255))

    # Pupils (deep midnight with shine)
    draw.ellipse([cx - 62, cy - 52, cx - 32, cy - 22], fill=cap_dark)
    draw.ellipse([cx + 32, cy - 52, cx + 62, cy - 22], fill=cap_dark)
    draw.ellipse([cx - 56, cy - 48, cx - 44, cy - 36], fill=(255, 255, 255, 255))
    draw.ellipse([cx + 38, cy - 48, cx + 50, cy - 36], fill=(255, 255, 255, 255))
    draw.ellipse([cx - 42, cy - 34, cx - 36, cy - 28], fill=(255, 255, 255, 255))
    draw.ellipse([cx + 52, cy - 34, cx + 58, cy - 28], fill=(255, 255, 255, 255))

    # 7. Glasses Frames
    draw.ellipse([cx - 100, cy - 90, cx - 5, cy + 5], outline=glasses_cyan, width=6)
    draw.ellipse([cx + 5, cy - 90, cx + 100, cy + 5], outline=glasses_cyan, width=6)
    draw.line([cx - 5, cy - 42, cx + 5, cy - 42], fill=glasses_cyan, width=6)

    # 8. Beak
    draw.polygon([(cx - 18, cy - 30), (cx + 18, cy - 30), (cx, cy + 8)], fill=beak_amber)
    draw.polygon([(cx, cy - 30), (cx + 18, cy - 30), (cx, cy + 8)], fill=beak_shadow)

    # 9. Smart Book in Front
    book_w, book_h = 130, 80
    book_rect = [cx - book_w // 2, cy + 70, cx + book_w // 2, cy + 70 + book_h]
    draw.rounded_rectangle(book_rect, radius=8, fill=book_coral, outline=(185, 28, 28, 255), width=3)
    # Book pages
    draw.rounded_rectangle([cx - book_w // 2 + 10, cy + 75, cx + book_w // 2 - 10, cy + 70 + book_h - 10], radius=4, fill=(254, 242, 242, 255))
    draw.line([cx, cy + 75, cx, cy + 70 + book_h - 10], fill=(203, 213, 225, 255), width=3)
    # Book text lines
    for ly in [cy + 85, cy + 97, cy + 109, cy + 121]:
        draw.line([cx - book_w // 2 + 18, ly, cx - 8, ly], fill=(203, 213, 225, 255), width=2)
        draw.line([cx + 8, ly, cx + book_w // 2 - 18, ly], fill=(203, 213, 225, 255), width=2)

    # 10. Academic Mortarboard Cap
    cap_y = cy - 145
    # Skullcap
    draw.ellipse([cx - 50, cap_y, cx + 50, cap_y + 40], fill=cap_dark)
    # Diamond Board
    diamond = [
        (cx, cap_y - 35),
        (cx + 145, cap_y),
        (cx, cap_y + 35),
        (cx - 145, cap_y)
    ]
    draw.polygon(diamond, fill=cap_dark, outline=(75, 85, 99, 255))
    # Cap button
    draw.ellipse([cx - 10, cap_y - 10, cx + 10, cap_y + 10], fill=tassel_gold)
    # Gold Tassel
    draw.line([cx, cap_y, cx + 70, cap_y + 20], fill=tassel_gold, width=4)
    draw.line([cx + 70, cap_y + 20, cx + 80, cap_y + 70], fill=tassel_gold, width=5)
    draw.ellipse([cx + 74, cap_y + 65, cx + 86, cap_y + 85], fill=tassel_gold)

    img.save(r"assets/images/pdf_icons/mascot_owl.png", "PNG")
    print("Mascot owl created successfully!")

def create_star_icon(is_filled, out_path):
    size = 128
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = size // 2, size // 2
    r_outer = 54
    r_inner = 23
    points = []
    for i in range(10):
        r = r_outer if i % 2 == 0 else r_inner
        angle = -math.pi / 2 + i * (math.pi / 5)
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))

    if is_filled:
        draw.polygon(points, fill=(245, 158, 11, 255), outline=(217, 119, 6, 255))
    else:
        draw.polygon(points, fill=(243, 244, 246, 255), outline=(156, 163, 175, 255))

    img.save(out_path, "PNG")
    print(f"Star saved to {out_path}")

if __name__ == "__main__":
    create_mascot_owl()
    create_star_icon(True, r"assets/images/pdf_icons/star_gold.png")
    create_star_icon(False, r"assets/images/pdf_icons/star_gray.png")
