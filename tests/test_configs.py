import os
import unittest
import configparser

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(BASE_DIR, "config")

class TestConfigs(unittest.TestCase):
    def test_plank_dock_config(self):
        settings_path = os.path.join(CONFIG_DIR, "desktop", "plank", "settings")
        self.assertTrue(os.path.isfile(settings_path))
        parser = configparser.ConfigParser()
        parser.read(settings_path)
        self.assertIn("PlankDockPreferences", parser.sections())
        prefs = parser["PlankDockPreferences"]
        self.assertEqual(prefs.get("zoomenabled"), "true")
        self.assertEqual(prefs.get("position"), "3") # Bottom
        self.assertEqual(prefs.get("alignment"), "3") # Center

    def test_plank_dock_items(self):
        launchers_dir = os.path.join(CONFIG_DIR, "desktop", "plank", "launchers")
        items = sorted(os.listdir(launchers_dir))
        self.assertEqual(len(items), 9, f"Expected 9 dock items, got {len(items)}")
        
        expected_substrings = [
            "dolphin",
            "firefox",
            "discover",
            "libreoffice-writer",
            "libreoffice-calc",
            "libreoffice-impress",
            "konsole",
            "systemsettings",
            "trash"
        ]
        for sub in expected_substrings:
            found = any(sub in it for it in items)
            self.assertTrue(found, f"Missing dock shortcut for: {sub}")

    def test_kwin_left_buttons(self):
        kwin_path = os.path.join(CONFIG_DIR, "desktop", "kwin", "kwinrc")
        self.assertTrue(os.path.isfile(kwin_path))
        with open(kwin_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("ButtonsOnLeft=XIA", content)

    def test_plasma_color_schemes(self):
        dark_scheme = os.path.join(CONFIG_DIR, "desktop", "plasma", "NOXEnOSDark.colors")
        light_scheme = os.path.join(CONFIG_DIR, "desktop", "plasma", "NOXEnOSLight.colors")
        self.assertTrue(os.path.isfile(dark_scheme))
        self.assertTrue(os.path.isfile(light_scheme))

    def test_mimeapps_associations(self):
        mime_path = os.path.join(CONFIG_DIR, "skel", ".config", "mimeapps.list")
        self.assertTrue(os.path.isfile(mime_path))
        with open(mime_path, "r", encoding="utf-8") as f:
            c = f.read()
        self.assertIn("libreoffice-writer.desktop", c)
        self.assertIn("libreoffice-calc.desktop", c)
        self.assertIn("libreoffice-impress.desktop", c)
        self.assertIn("firefox.desktop", c)
        self.assertIn("vlc.desktop", c)

    def test_calamares_modules(self):
        mod_dir = os.path.join(CONFIG_DIR, "installer", "calamares", "modules")
        expected_modules = ["welcome.conf", "locale.conf", "keyboard.conf", "partition.conf", "users.conf", "unpackfs.conf", "packages.conf", "bootloader.conf", "finished.conf"]
        for mod in expected_modules:
            p = os.path.join(mod_dir, mod)
            self.assertTrue(os.path.isfile(p), f"Calamares module config missing: {mod}")

if __name__ == "__main__":
    unittest.main()
