import os
import unittest

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PKG_DIR = os.path.join(BASE_DIR, "config", "packages")

def parse_list(filename):
    path = os.path.join(PKG_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        lines = [line.strip().split("#")[0].strip() for line in f]
    return [l for l in lines if l]

class TestPackageLists(unittest.TestCase):
    def test_all_lists_exist(self):
        for name in ["core.list", "desktop.list", "apps.list", "office.list", "installer.list", "remove.list"]:
            self.assertTrue(os.path.isfile(os.path.join(PKG_DIR, name)), f"Package list missing: {name}")

    def test_office_suite_completeness(self):
        office = parse_list("office.list")
        self.assertIn("libreoffice", office)
        self.assertIn("libreoffice-writer", office)
        self.assertIn("libreoffice-calc", office)
        self.assertIn("libreoffice-impress", office)
        self.assertIn("libreoffice-draw", office)
        self.assertIn("libreoffice-math", office)
        self.assertIn("libreoffice-base", office)
        self.assertIn("libreoffice-l10n-es", office)

    def test_apps_completeness(self):
        apps = parse_list("apps.list")
        self.assertIn("dolphin", apps)
        self.assertIn("firefox", apps)
        self.assertIn("vlc", apps)
        self.assertIn("spectacle", apps)
        self.assertIn("gwenview", apps)
        self.assertIn("konsole", apps)
        self.assertIn("plasma-discover", apps)

    def test_desktop_completeness(self):
        desktop = parse_list("desktop.list")
        self.assertIn("plasma-desktop", desktop)
        self.assertIn("plank", desktop)
        self.assertIn("sddm", desktop)

    def test_no_forbidden_cross_inclusions(self):
        remove_pkgs = set(parse_list("remove.list"))
        all_included = (
            set(parse_list("core.list")) |
            set(parse_list("desktop.list")) |
            set(parse_list("apps.list")) |
            set(parse_list("office.list")) |
            set(parse_list("installer.list"))
        )
        conflicts = remove_pkgs.intersection(all_included)
        self.assertEqual(len(conflicts), 0, f"Conflicting packages found in both include and remove lists: {conflicts}")

if __name__ == "__main__":
    unittest.main()
