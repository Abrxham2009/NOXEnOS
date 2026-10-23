"""
NOXEnOS Branding and Artwork Generation Script
Extracts the user logo, generates multiple icon resolutions,
creates 5 exclusive 4K/Ultrawide wallpapers, and produces assets
for Calamares, Plymouth, SDDM, and the desktop environment.
"""

import os
import shutil
import math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageFont

SRC_LOGO = r"C:\Users\Abraham\.gemini\antigravity\brain\a6f31665-eb6a-4b89-a4dd-a666d2670793\.user_uploaded\media_1792671848862_33cb964d.jpg"
BASE_DIR = r"C:\Users\Abraham\Downloads\NOXEnOS"
BRANDING_DIR = os.path.join(BASE_DIR, "branding")
LOGOS_DIR = os.path.join(BRANDING_DIR, "logos")
WALLPAPERS_DIR = os.path.join(BRANDING_DIR, "wallpapers")
ICONS_DIR = os.path.join(BRANDING_DIR, "icons")
PLYMOUTH_DIR = os.path.join(BASE_DIR, "config", "plymouth", "noxenos")
SDDM_DIR = os.path.join(BASE_DIR, "config", "sddm", "noxenos")
CALAMARES_BRANDING_DIR = os.path.join(BASE_DIR, "config", "installer", "calamares", "branding", "noxenos")

def ensure_dirs():
    dirs = [
        LOGOS_DIR, WALLPAPERS_DIR, ICONS_DIR,
        PLYMOUTH_DIR, SDDM_DIR, CALAMARES_BRANDING_DIR
    ]
    for size in [16, 24, 32, 48, 64, 128, 256, 512]:
        dirs.append(os.path.join(ICONS_DIR, "hicolor", f"{size}x{size}", "apps"))
    dirs.append(os.path.join(ICONS_DIR, "hicolor", "scalable", "apps"))
    for d in dirs:
        os.makedirs(d, exist_ok=True)

def process_logos():
    print("[*] Processing logos...")
    # Copy original
    orig_dest = os.path.join(LOGOS_DIR, "logo-original.jpg")
    shutil.copy2(SRC_LOGO, orig_dest)

    img = Image.open(SRC_LOGO).convert("RGBA")
    w, h = img.size

    # Save full square logo as PNG
    full_png = os.path.join(LOGOS_DIR, "noxenos-full.png")
    img.save(full_png, "PNG")

    # Emblem isolation: The top ~720 pixels contain the 'N' symbol with ring & star
    # Crop the central symbol box
    emblem_box = (int(w * 0.12), int(h * 0.12), int(w * 0.88), int(h * 0.68))
    emblem = img.crop(emblem_box)
    
    # Make black background transparent or soft dark gradient
    # We create a transparent version of the emblem
    emblem_rgba = emblem.convert("RGBA")
    datas = emblem_rgba.getdata()
    newData = []
    for item in datas:
        # Distance from pure dark background (item[0], item[1], item[2])
        r, g, b, a = item
        brightness = (r + g + b) / 3.0
        # If very close to background darkness (#07090e -> ~10-15)
        if brightness < 18:
            newData.append((r, g, b, 0))
        elif brightness < 40:
            alpha = int(((brightness - 18) / 22.0) * 255)
            newData.append((r, g, b, alpha))
        else:
            newData.append((r, g, b, 255))
    
    emblem_rgba.putdata(newData)
    emblem_square = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    # Resize emblem proportionally into 512x512
    emblem_resized = emblem_rgba.copy()
    emblem_resized.thumbnail((460, 460), Image.Resampling.LANCZOS)
    offset = ((512 - emblem_resized.width) // 2, (512 - emblem_resized.height) // 2)
    emblem_square.paste(emblem_resized, offset, emblem_resized)

    emblem_path = os.path.join(LOGOS_DIR, "noxenos-emblem.png")
    emblem_square.save(emblem_path, "PNG")

    # Generate Linux app icons in all standard resolutions
    for size in [16, 24, 32, 48, 64, 128, 256, 512]:
        icon_path = os.path.join(ICONS_DIR, "hicolor", f"{size}x{size}", "apps", "noxenos.png")
        resized = emblem_square.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(icon_path, "PNG")

    # Save emblem as launcher icon and dock icon
    shutil.copy2(os.path.join(ICONS_DIR, "hicolor", "128x128", "apps", "noxenos.png"),
                 os.path.join(LOGOS_DIR, "noxenos-icon-128.png"))
    shutil.copy2(os.path.join(ICONS_DIR, "hicolor", "256x256", "apps", "noxenos.png"),
                 os.path.join(LOGOS_DIR, "noxenos-icon-256.png"))

    # Create SVG representation (SVG with embedded high-res base64 or vector wrapper)
    import base64
    with open(os.path.join(ICONS_DIR, "hicolor", "256x256", "apps", "noxenos.png"), "rb") as f:
        b64 = base64.b64encode(f.read()).decode('utf-8')
    
    svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="6" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>
  <image width="256" height="256" xlink:href="data:image/png;base64,{b64}"/>
</svg>'''
    with open(os.path.join(ICONS_DIR, "hicolor", "scalable", "apps", "noxenos.svg"), "w", encoding="utf-8") as f:
        f.write(svg_content)
    with open(os.path.join(LOGOS_DIR, "noxenos.svg"), "w", encoding="utf-8") as f:
        f.write(svg_content)

    print("[+] Logos and icons generated successfully.")
    return emblem_square, img

def generate_wallpapers(emblem_img, full_img):
    print("[*] Generating 5 exclusive NOXEnOS wallpapers...")
    
    # 1. Dark Futuristic (Default) 3840x2160 4K
    print(" -> 1. noxenos-dark-futuristic.png (Default 4K)")
    w, h = 3840, 2160
    dark_bg = Image.new("RGBA", (w, h), (10, 13, 20, 255))
    draw = ImageDraw.Draw(dark_bg)
    
    # Atmospheric radial glow at center
    cx, cy = w // 2, h // 2 - 50
    glow_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    
    for radius in range(900, 100, -30):
        alpha = int((1.0 - (radius / 900.0)) * 60)
        # Gradient from electric cyan (0, 180, 255) to purple (138, 43, 226)
        r_col = int(20 + 80 * (radius / 900.0))
        g_col = int(80 + 40 * (1.0 - radius / 900.0))
        b_col = int(180 + 75 * (1.0 - radius / 900.0))
        glow_draw.ellipse(
            [cx - radius, cy - int(radius * 0.75), cx + radius, cy + int(radius * 0.75)],
            fill=(r_col, g_col, b_col, alpha)
        )
    
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(80))
    dark_bg = Image.alpha_composite(dark_bg, glow_layer)

    # Ambient grid / stars
    star_draw = ImageDraw.Draw(dark_bg)
    import random
    random.seed(42)
    for _ in range(400):
        sx = random.randint(0, w)
        sy = random.randint(0, h)
        s_size = random.choice([1, 1, 2, 2, 3])
        s_alpha = random.randint(40, 220)
        star_draw.ellipse([sx, sy, sx + s_size, sy + s_size], fill=(200, 220, 255, s_alpha))

    # Center the emblem with majestic size (800x800)
    emb_big = emblem_img.resize((820, 820), Image.Resampling.LANCZOS)
    dark_bg.paste(emb_big, (cx - 410, cy - 410), emb_big)

    dark_bg.convert("RGB").save(os.path.join(WALLPAPERS_DIR, "noxenos-dark-futuristic.png"), "PNG")
    # Also copy as default.png
    dark_bg.convert("RGB").save(os.path.join(WALLPAPERS_DIR, "noxenos-default.png"), "PNG")

    # 2. Abstract Minimalist (4K 3840x2160)
    print(" -> 2. noxenos-abstract-minimal.png")
    abs_bg = Image.new("RGBA", (w, h), (14, 16, 26, 255))
    abs_draw = ImageDraw.Draw(abs_bg)
    
    # Elegant curved bands across the canvas
    curve_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(curve_layer)
    # Band 1: Deep indigo/violet wave
    cdraw.polygon([
        (0, h), (0, int(h * 0.65)),
        (int(w * 0.3), int(h * 0.5)),
        (int(w * 0.7), int(h * 0.8)),
        (w, int(h * 0.4)), (w, h)
    ], fill=(45, 25, 80, 140))
    
    # Band 2: Electric cyan wave
    cdraw.polygon([
        (0, h), (0, int(h * 0.75)),
        (int(w * 0.4), int(h * 0.6)),
        (int(w * 0.8), int(h * 0.85)),
        (w, int(h * 0.55)), (w, h)
    ], fill=(0, 100, 180, 100))
    
    curve_layer = curve_layer.filter(ImageFilter.GaussianBlur(60))
    abs_bg = Image.alpha_composite(abs_bg, curve_layer)
    
    # Subtle modern geometric glass card in center
    card_w, card_h = 700, 700
    card = Image.new("RGBA", (card_w, card_h), (255, 255, 255, 12))
    card_draw = ImageDraw.Draw(card)
    card_draw.rounded_rectangle([0, 0, card_w, card_h], radius=48, outline=(255, 255, 255, 30), width=2)
    card = card.filter(ImageFilter.GaussianBlur(1))
    
    emb_card = emblem_img.resize((500, 500), Image.Resampling.LANCZOS)
    card.paste(emb_card, ((card_w - 500) // 2, (card_h - 500) // 2), emb_card)
    abs_bg.paste(card, (cx - card_w // 2, cy - card_h // 2), card)

    abs_bg.convert("RGB").save(os.path.join(WALLPAPERS_DIR, "noxenos-abstract-minimal.png"), "PNG")

    # 3. Neon Gradient (4K 3840x2160)
    print(" -> 3. noxenos-neon-gradient.png")
    neon_bg = Image.new("RGB", (w, h))
    # Render smooth mesh-like gradient
    # Top-left: electric cyan (#0052d4), center: rich violet (#7928ca), bottom-right: midnight indigo (#0a0f24)
    neon_draw = ImageDraw.Draw(neon_bg)
    for y in range(0, h, 4):
        ty = y / h
        r = int(10 * (1 - ty) + 80 * ty * (1 - ty) * 4 + 8 * ty)
        g = int(50 * (1 - ty) + 30 * ty)
        b = int(140 * (1 - ty) + 160 * math.sin(ty * math.pi) + 50 * ty)
        neon_draw.rectangle([0, y, w, y + 4], fill=(r, g, b))
    
    # Soft glowing radial overlays
    neon_rgba = neon_bg.convert("RGBA")
    neon_glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ng_draw = ImageDraw.Draw(neon_glow)
    ng_draw.ellipse([cx - 800, cy - 700, cx + 800, cy + 700], fill=(130, 40, 220, 110))
    ng_draw.ellipse([cx - 400, cy - 400, cx + 400, cy + 400], fill=(0, 210, 255, 120))
    neon_glow = neon_glow.filter(ImageFilter.GaussianBlur(120))
    neon_final = Image.alpha_composite(neon_rgba, neon_glow)
    
    emb_neon = emblem_img.resize((760, 760), Image.Resampling.LANCZOS)
    neon_final.paste(emb_neon, (cx - 380, cy - 380), emb_neon)
    neon_final.convert("RGB").save(os.path.join(WALLPAPERS_DIR, "noxenos-neon-gradient.png"), "PNG")

    # 4. Light Pure Minimalist (4K 3840x2160)
    print(" -> 4. noxenos-light-pure.png")
    light_bg = Image.new("RGBA", (w, h), (242, 244, 249, 255))
    lg_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    lg_draw = ImageDraw.Draw(lg_layer)
    # Subtle pastel cyan and violet light pools
    lg_draw.ellipse([cx - 900, cy - 700, cx + 900, cy + 700], fill=(220, 235, 255, 160))
    lg_draw.ellipse([cx - 400, cy - 300, cx + 800, cy + 800], fill=(235, 225, 255, 140))
    lg_layer = lg_layer.filter(ImageFilter.GaussianBlur(100))
    light_bg = Image.alpha_composite(light_bg, lg_layer)
    
    # Centered dark emblem with soft shadow
    emb_light = emblem_img.resize((700, 700), Image.Resampling.LANCZOS)
    # Generate drop shadow
    shadow = Image.new("RGBA", (780, 780), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([40, 40, 740, 740], fill=(0, 20, 60, 45))
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    light_bg.paste(shadow, (cx - 390, cy - 370), shadow)
    light_bg.paste(emb_light, (cx - 350, cy - 350), emb_light)
    light_bg.convert("RGB").save(os.path.join(WALLPAPERS_DIR, "noxenos-light-pure.png"), "PNG")

    # 5. Ultrawide 21:9 (3440x1440)
    print(" -> 5. noxenos-ultrawide.png (21:9)")
    uw_w, uw_h = 3440, 1440
    uw_bg = Image.new("RGBA", (uw_w, uw_h), (9, 12, 18, 255))
    uw_cx, uw_cy = uw_w // 2, uw_h // 2
    
    uw_glow = Image.new("RGBA", (uw_w, uw_h), (0, 0, 0, 0))
    uw_draw = ImageDraw.Draw(uw_glow)
    # Wide horizon glow
    for r in range(uw_w // 2, 200, -80):
        alpha = int((1.0 - (r / (uw_w // 2))) * 70)
        uw_draw.ellipse(
            [uw_cx - r, uw_cy - int(r * 0.35), uw_cx + r, uw_cy + int(r * 0.35)],
            fill=(20, 70, 160, alpha)
        )
    uw_glow = uw_glow.filter(ImageFilter.GaussianBlur(90))
    uw_bg = Image.alpha_composite(uw_bg, uw_glow)

    # Stars
    u_draw = ImageDraw.Draw(uw_bg)
    random.seed(99)
    for _ in range(350):
        sx = random.randint(0, uw_w)
        sy = random.randint(0, uw_h)
        s_sz = random.choice([1, 1, 2, 2])
        u_draw.ellipse([sx, sy, sx + s_sz, sy + s_sz], fill=(220, 230, 255, random.randint(40, 200)))

    emb_uw = emblem_img.resize((620, 620), Image.Resampling.LANCZOS)
    uw_bg.paste(emb_uw, (uw_cx - 310, uw_cy - 310), emb_uw)
    uw_bg.convert("RGB").save(os.path.join(WALLPAPERS_DIR, "noxenos-ultrawide.png"), "PNG")

    print("[+] All 5 wallpapers created successfully.")

def generate_subsystem_assets(emblem_img, full_img):
    print("[*] Generating Calamares, Plymouth, and SDDM branding assets...")

    # Calamares installer assets
    # 1. Branding logo (displayed in header or sidebar)
    cal_logo = emblem_img.resize((128, 128), Image.Resampling.LANCZOS)
    cal_logo.save(os.path.join(CALAMARES_BRANDING_DIR, "noxenos-logo.png"), "PNG")
    cal_logo.save(os.path.join(CALAMARES_BRANDING_DIR, "squid.png"), "PNG")

    # 2. Installer welcome banner / sidebar (200x500 or 600x120)
    sidebar = Image.new("RGBA", (200, 600), (14, 17, 26, 255))
    s_draw = ImageDraw.Draw(sidebar)
    # Vertical gradient accent line
    s_draw.rectangle([196, 0, 200, 600], fill=(0, 180, 255, 255))
    emb_side = emblem_img.resize((140, 140), Image.Resampling.LANCZOS)
    sidebar.paste(emb_side, (30, 40), emb_side)
    sidebar.save(os.path.join(CALAMARES_BRANDING_DIR, "sidebar.png"), "PNG")

    # Plymouth splash screen assets
    ply_logo = emblem_img.resize((192, 192), Image.Resampling.LANCZOS)
    ply_logo.save(os.path.join(PLYMOUTH_DIR, "logo.png"), "PNG")

    # Progress bar and dots for Plymouth
    pbar = Image.new("RGBA", (240, 8), (40, 45, 60, 255))
    pdraw = ImageDraw.Draw(pbar)
    pdraw.rounded_rectangle([0, 0, 240, 8], radius=4, fill=(30, 35, 48, 255))
    pbar.save(os.path.join(PLYMOUTH_DIR, "progress-track.png"), "PNG")

    pfill = Image.new("RGBA", (240, 8), (0, 0, 0, 0))
    pfdraw = ImageDraw.Draw(pfill)
    pfdraw.rounded_rectangle([0, 0, 240, 8], radius=4, fill=(0, 210, 255, 255))
    pfill.save(os.path.join(PLYMOUTH_DIR, "progress-fill.png"), "PNG")

    bullet = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(bullet)
    bdraw.ellipse([0, 0, 16, 16], fill=(0, 210, 255, 255))
    bullet.save(os.path.join(PLYMOUTH_DIR, "bullet.png"), "PNG")

    # SDDM Login screen assets
    sddm_bg = Image.open(os.path.join(WALLPAPERS_DIR, "noxenos-dark-futuristic.png"))
    # Resize for SDDM default 1920x1080
    sddm_bg_1080 = sddm_bg.resize((1920, 1080), Image.Resampling.LANCZOS)
    sddm_bg_1080.save(os.path.join(SDDM_DIR, "background.png"), "PNG")
    sddm_badge = emblem_img.resize((96, 96), Image.Resampling.LANCZOS)
    sddm_badge.save(os.path.join(SDDM_DIR, "badge.png"), "PNG")

    print("[+] Subsystem assets generated successfully.")

if __name__ == "__main__":
    ensure_dirs()
    emblem, full = process_logos()
    generate_wallpapers(emblem, full)
    generate_subsystem_assets(emblem, full)
    print("[***] BRANDING PIPELINE COMPLETED SUCCESSFULLY [***]")
