import os
import unittest
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRANDING_DIR = os.path.join(BASE_DIR, "branding")
WALLPAPERS_DIR = os.path.join(BRANDING_DIR, "wallpapers")
LOGOS_DIR = os.path.join(BRANDING_DIR, "logos")
ICONS_DIR = os.path.join(BRANDING_DIR, "icons")

class TestBranding(unittest.TestCase):
    def test_original_logo_exists(self):
        orig = os.path.join(LOGOS_DIR, "logo-original.jpg")
        self.assertTrue(os.path.isfile(orig), "Original logo file is missing")

    def test_logos_and_svg_exist(self):
        for fname in ["noxenos-emblem.png", "noxenos-full.png", "noxenos.svg"]:
            p = os.path.join(LOGOS_DIR, fname)
            self.assertTrue(os.path.isfile(p), f"Logo file missing: {fname}")
            self.assertGreater(os.path.getsize(p), 0)

    def test_wallpapers_exist_and_dimensions(self):
        expected = {
            "noxenos-dark-futuristic.png": (3840, 2160),
            "noxenos-default.png": (3840, 2160),
            "noxenos-abstract-minimal.png": (3840, 2160),
            "noxenos-neon-gradient.png": (3840, 2160),
            "noxenos-light-pure.png": (3840, 2160),
            "noxenos-ultrawide.png": (3440, 1440),
        }
        for name, dims in expected.items():
            wp_path = os.path.join(WALLPAPERS_DIR, name)
            self.assertTrue(os.path.isfile(wp_path), f"Wallpaper missing: {name}")
            with Image.open(wp_path) as img:
                self.assertEqual(img.size, dims, f"Dimension mismatch for {name}: {img.size} vs {dims}")

    def test_icon_hierarchy(self):
        sizes = [16, 24, 32, 48, 64, 128, 256, 512]
        for sz in sizes:
            icon_file = os.path.join(ICONS_DIR, "hicolor", f"{sz}x{sz}", "apps", "noxenos.png")
            self.assertTrue(os.path.isfile(icon_file), f"Icon missing for size {sz}")
            with Image.open(icon_file) as img:
                self.assertEqual(img.size, (sz, sz))

    def test_calamares_assets(self):
        cal_dir = os.path.join(BASE_DIR, "config", "installer", "calamares", "branding", "noxenos")
        for asset in ["noxenos-logo.png", "squid.png", "sidebar.png", "branding.desc"]:
            p = os.path.join(cal_dir, asset)
            self.assertTrue(os.path.isfile(p), f"Calamares asset missing: {asset}")

    def test_plymouth_assets(self):
        ply_dir = os.path.join(BASE_DIR, "config", "plymouth", "noxenos")
        for asset in ["logo.png", "progress-track.png", "progress-fill.png", "noxenos.plymouth", "noxenos.script"]:
            p = os.path.join(ply_dir, asset)
            self.assertTrue(os.path.isfile(p), f"Plymouth asset missing: {asset}")

    def test_sddm_assets(self):
        sddm_dir = os.path.join(BASE_DIR, "config", "sddm", "noxenos")
        for asset in ["background.png", "badge.png", "metadata.desktop", "theme.conf"]:
            p = os.path.join(sddm_dir, asset)
            self.assertTrue(os.path.isfile(p), f"SDDM asset missing: {asset}")

if __name__ == "__main__":
    unittest.main()
