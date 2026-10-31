import math
import os
from PIL import Image, ImageDraw, ImageFilter

def create_gradient_circle(draw, cx, cy, radius, color_start, color_end, steps=30):
    for i in range(steps):
        r = radius * (1 - i / steps)
        factor = i / steps
        r_c = int(color_start[0] * (1 - factor) + color_end[0] * factor)
        g_c = int(color_start[1] * (1 - factor) + color_end[1] * factor)
        b_c = int(color_start[2] * (1 - factor) + color_end[2] * factor)
        a_c = int(color_start[3] * (1 - factor) + color_end[3] * factor)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(r_c, g_c, b_c, a_c))

def draw_star(draw, cx, cy, r_outer, r_inner, color, points_count=4):
    points = []
    angle_step = math.pi / points_count
    for i in range(points_count * 2):
        r = r_outer if i % 2 == 0 else r_inner
        ang = -math.pi / 2 + i * angle_step
        points.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    draw.polygon(points, fill=color)

def generate_main_miniapp_icon(out_path):
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = 256, 256

    # 1. Ambient Glow
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([cx - 210, cy - 210, cx + 210, cy + 210], fill=(36, 161, 222, 60))
    gdraw.ellipse([cx - 170, cy - 170, cx + 170, cy + 170], fill=(79, 70, 229, 90))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    img.paste(glow, (0, 0), glow)

    # 2. Main Circular Card Plate (Telegram Blue gradient)
    plate = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(plate)
    
    # Outer border ring
    pdraw.ellipse([cx - 190, cy - 190, cx + 190, cy + 190], fill=(36, 161, 222, 230), outline=(255, 255, 255, 120), width=6)
    
    # Inner smooth gradient
    create_gradient_circle(pdraw, cx, cy, 184, (14, 116, 144, 255), (36, 161, 222, 255), steps=25)
    img = Image.alpha_composite(img, plate)
    draw = ImageDraw.Draw(img)

    # 3. Smartphone / Mini App screen frame
    phone_w, phone_h = 160, 240
    px, py = cx - 35, cy - 100
    phone_rect = [px - phone_w // 2, py, px + phone_w // 2, py + phone_h]
    
    # Phone shadow
    pshadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ps_draw = ImageDraw.Draw(pshadow)
    ps_draw.rounded_rectangle([px - phone_w // 2 + 8, py + 12, px + phone_w // 2 + 16, py + phone_h + 16], radius=24, fill=(15, 23, 42, 140))
    pshadow = pshadow.filter(ImageFilter.GaussianBlur(12))
    img = Image.alpha_composite(img, pshadow)
    draw = ImageDraw.Draw(img)

    # Phone body
    draw.rounded_rectangle(phone_rect, radius=24, fill=(15, 23, 42, 255), outline=(226, 232, 240, 255), width=5)
    
    # Phone screen (App UI preview)
    screen_rect = [phone_rect[0] + 8, phone_rect[1] + 16, phone_rect[2] - 8, phone_rect[3] - 16]
    draw.rounded_rectangle(screen_rect, radius=16, fill=(241, 245, 249, 255))
    
    # Phone notch & speaker
    draw.rounded_rectangle([px - 22, py + 6, px + 22, py + 12], radius=3, fill=(51, 65, 85, 255))
    
    # Screen mini app header
    draw.rounded_rectangle([screen_rect[0] + 8, screen_rect[1] + 10, screen_rect[2] - 8, screen_rect[1] + 34], radius=6, fill=(79, 70, 229, 255))
    draw.line([screen_rect[0] + 16, screen_rect[1] + 22, screen_rect[0] + 50, screen_rect[1] + 22], fill=(255, 255, 255, 220), width=3)
    
    # Mini app calendar cards
    colors = [(16, 185, 129, 255), (245, 158, 11, 255), (14, 165, 233, 255)]
    for i, c in enumerate(colors):
        cy_card = screen_rect[1] + 44 + i * 40
        draw.rounded_rectangle([screen_rect[0] + 8, cy_card, screen_rect[2] - 8, cy_card + 32], radius=6, fill=(255, 255, 255, 255), outline=(226, 232, 240, 255), width=1)
        draw.ellipse([screen_rect[0] + 14, cy_card + 9, screen_rect[0] + 28, cy_card + 23], fill=c)
        draw.line([screen_rect[0] + 34, cy_card + 12, screen_rect[2] - 16, cy_card + 12], fill=(71, 85, 105, 255), width=2)
        draw.line([screen_rect[0] + 34, cy_card + 20, screen_rect[0] + 75, cy_card + 20], fill=(148, 163, 184, 255), width=2)

    # 4. Cute Peeking Owl Mascot (right side)
    ox, oy = cx + 80, cy + 30
    # Owl body
    draw.ellipse([ox - 55, oy - 65, ox + 55, oy + 70], fill=(79, 70, 229, 255), outline=(55, 48, 163, 255), width=3)
    # Owl eyes
    draw.ellipse([ox - 45, oy - 45, ox - 5, oy - 5], fill=(255, 255, 255, 255))
    draw.ellipse([ox + 5, oy - 45, ox + 45, oy - 5], fill=(255, 255, 255, 255))
    # Pupils looking left
    draw.ellipse([ox - 32, oy - 30, ox - 14, oy - 12], fill=(30, 27, 75, 255))
    draw.ellipse([ox + 18, oy - 30, ox + 36, oy - 12], fill=(30, 27, 75, 255))
    # Beak
    draw.polygon([(ox - 10, oy - 12), (ox + 10, oy - 12), (ox, oy + 6)], fill=(245, 158, 11, 255))
    # Glasses
    draw.ellipse([ox - 48, oy - 48, ox - 2, oy - 2], outline=(6, 182, 212, 255), width=4)
    draw.ellipse([ox + 2, oy - 48, ox + 48, oy - 2], outline=(6, 182, 212, 255), width=4)
    draw.line([ox - 2, oy - 25, ox + 2, oy - 25], fill=(6, 182, 212, 255), width=4)
    # Mini mortarboard cap
    draw.polygon([(ox, oy - 80), (ox + 45, oy - 65), (ox, oy - 50), (ox - 45, oy - 65)], fill=(30, 27, 75, 255))
    draw.line([ox, oy - 65, ox + 28, oy - 50], fill=(251, 191, 36, 255), width=3)

    # 5. Telegram Paper Plane flying dynamically across
    # Plane shadow
    plane_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    psd = ImageDraw.Draw(plane_shadow)
    plane_pts = [
        (cx - 130, cy + 130),
        (cx + 40, cy + 20),
        (cx - 50, cy + 100)
    ]
    psd.polygon(plane_pts, fill=(15, 23, 42, 100))
    plane_shadow = plane_shadow.filter(ImageFilter.GaussianBlur(10))
    img = Image.alpha_composite(img, plane_shadow)
    draw = ImageDraw.Draw(img)

    # Telegram Paper Plane
    p_nose = (cx + 50, cy + 15)
    p_left = (cx - 135, cy + 100)
    p_center = (cx - 55, cy + 90)
    p_right = (cx - 85, cy + 130)

    # Wing left
    draw.polygon([p_nose, p_left, p_center], fill=(255, 255, 255, 255))
    # Wing right
    draw.polygon([p_nose, p_center, p_right], fill=(203, 213, 225, 255))
    # Fold shadow
    draw.polygon([p_center, (cx - 70, cy + 105), p_right], fill=(148, 163, 184, 255))

    # 6. Sparkles & Highlights
    draw_star(draw, cx - 110, cy - 100, 18, 6, (255, 255, 255, 240))
    draw_star(draw, cx + 130, cy - 80, 22, 8, (251, 191, 36, 255))
    draw_star(draw, cx + 150, cy + 120, 16, 5, (255, 255, 255, 200))
    draw_star(draw, cx - 140, cy + 30, 14, 5, (6, 182, 212, 230))

    img.save(out_path, "PNG")
    print(f"Generated Main Mini App Bot icon -> {out_path}")

def generate_ai_director_icon(out_path):
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = 256, 256

    # 1. Violet & Gold Ambient Glow
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([cx - 210, cy - 210, cx + 210, cy + 210], fill=(139, 92, 246, 70))
    gdraw.ellipse([cx - 170, cy - 170, cx + 170, cy + 170], fill=(245, 158, 11, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(30))
    img.paste(glow, (0, 0), glow)

    # 2. Outer Crystal Ring with Golden Gradient
    plate = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(plate)
    pdraw.ellipse([cx - 190, cy - 190, cx + 190, cy + 190], fill=(109, 40, 217, 240), outline=(251, 191, 36, 220), width=6)
    
    # Inner Deep AI Gradient (Space Violet to Dark Indigo)
    create_gradient_circle(pdraw, cx, cy, 184, (30, 27, 75, 255), (88, 28, 135, 255), steps=25)
    img = Image.alpha_composite(img, plate)
    draw = ImageDraw.Draw(img)

    # 3. Neural Connections Network (glowing lines)
    node_coords = [
        (cx - 110, cy - 70), (cx + 110, cy - 70),
        (cx - 120, cy + 60), (cx + 120, cy + 60),
        (cx - 60, cy - 110), (cx + 60, cy - 110),
        (cx, cy + 120)
    ]
    for pt1 in node_coords:
        for pt2 in node_coords:
            if 60 < math.dist(pt1, pt2) < 170:
                draw.line([pt1, pt2], fill=(167, 139, 250, 90), width=2)
    for pt in node_coords:
        draw.ellipse([pt[0] - 5, pt[1] - 5, pt[0] + 5, pt[1] + 5], fill=(196, 181, 253, 220))

    # 4. Central Glowing AI Sphere / Brain Crystal
    sphere_r = 100
    create_gradient_circle(draw, cx, cy + 20, sphere_r, (76, 29, 149, 240), (139, 92, 246, 240), steps=20)
    draw.ellipse([cx - sphere_r, cy + 20 - sphere_r, cx + sphere_r, cy + 20 + sphere_r], outline=(216, 180, 254, 200), width=4)

    # 5. Cyber Owl Mascot Head with Hologram Visor
    ox, oy = cx, cy + 15
    # Head
    draw.ellipse([ox - 75, oy - 65, ox + 75, oy + 55], fill=(49, 46, 129, 255), outline=(99, 102, 241, 255), width=3)
    # Ear tufts
    draw.polygon([(ox - 65, oy - 45), (ox - 85, oy - 100), (ox - 35, oy - 65)], fill=(30, 27, 75, 255))
    draw.polygon([(ox + 65, oy - 45), (ox + 85, oy - 100), (ox + 35, oy - 65)], fill=(30, 27, 75, 255))
    draw.polygon([(ox - 58, oy - 50), (ox - 75, oy - 90), (ox - 38, oy - 65)], fill=(245, 158, 11, 255))
    draw.polygon([(ox + 58, oy - 50), (ox + 75, oy - 90), (ox + 38, oy - 65)], fill=(245, 158, 11, 255))

    # Glowing AI Cyber Visor / Glasses
    draw.rounded_rectangle([ox - 62, oy - 38, ox + 62, oy + 2], radius=16, fill=(15, 23, 42, 240), outline=(6, 182, 212, 255), width=4)
    # Cyan eye lines / digital gaze
    draw.rounded_rectangle([ox - 48, oy - 24, ox - 12, oy - 12], radius=5, fill=(6, 182, 212, 255))
    draw.rounded_rectangle([ox + 12, oy - 24, ox + 48, oy - 12], radius=5, fill=(6, 182, 212, 255))
    # Beak
    draw.polygon([(ox - 14, oy + 6), (ox + 14, oy + 6), (ox, oy + 24)], fill=(245, 158, 11, 255))

    # 6. Golden Royal Director Crown (top of head)
    crown_y = oy - 95
    crown_w = 120
    crown_pts = [
        (ox - crown_w // 2, crown_y + 35),
        (ox - crown_w // 2, crown_y),
        (ox - crown_w // 4, crown_y + 15),
        (ox, crown_y - 12),
        (ox + crown_w // 4, crown_y + 15),
        (ox + crown_w // 2, crown_y),
        (ox + crown_w // 2, crown_y + 35),
    ]
    # Crown shadow
    draw.polygon([(p[0], p[1] + 4) for p in crown_pts], fill=(120, 53, 15, 200))
    # Crown fill with Gold
    draw.polygon(crown_pts, fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=3)
    # Crown base band
    draw.rounded_rectangle([ox - crown_w // 2 - 4, crown_y + 30, ox + crown_w // 2 + 4, crown_y + 44], radius=6, fill=(217, 119, 6, 255), outline=(254, 240, 138, 255), width=2)
    # Crown jewels (rubies and emeralds)
    draw.ellipse([ox - 30, crown_y + 33, ox - 18, crown_y + 41], fill=(239, 68, 68, 255))
    draw.ellipse([ox - 6, crown_y + 33, ox + 6, crown_y + 41], fill=(16, 185, 129, 255))
    draw.ellipse([ox + 18, crown_y + 33, ox + 30, crown_y + 41], fill=(239, 68, 68, 255))

    # 7. AI Sparkles / YandexGPT stars
    draw_star(draw, cx - 130, cy - 80, 26, 9, (251, 191, 36, 255))
    draw_star(draw, cx + 135, cy - 85, 28, 10, (254, 240, 138, 255))
    draw_star(draw, cx - 120, cy + 120, 20, 7, (167, 139, 250, 255))
    draw_star(draw, cx + 125, cy + 115, 24, 8, (6, 182, 212, 255))

    # Text / Badge element: "PRO AI"
    draw.rounded_rectangle([cx - 48, cy + 95, cx + 48, cy + 125], radius=10, fill=(245, 158, 11, 255), outline=(255, 255, 255, 220), width=2)
    # Mini stars on badge
    draw_star(draw, cx - 30, cy + 110, 8, 3, (255, 255, 255, 255))
    draw_star(draw, cx + 30, cy + 110, 8, 3, (255, 255, 255, 255))
    # Crown icon in badge
    draw.polygon([(cx - 10, cy + 116), (cx - 10, cy + 105), (cx - 5, cy + 110), (cx, cy + 103), (cx + 5, cy + 110), (cx + 10, cy + 105), (cx + 10, cy + 116)], fill=(255, 255, 255, 255))

    img.save(out_path, "PNG")
    print(f"Generated AI Director Bot icon -> {out_path}")

if __name__ == '__main__':
    out_dir = r"assets/images/pdf_icons"
    os.makedirs(out_dir, exist_ok=True)
    generate_main_miniapp_icon(os.path.join(out_dir, "bot_main_miniapp.png"))
    generate_ai_director_icon(os.path.join(out_dir, "bot_ai_director.png"))
