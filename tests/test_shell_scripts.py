import os
import unittest
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS_DIR = os.path.join(BASE_DIR, "scripts")

class TestShellScripts(unittest.TestCase):
    def test_scripts_exist(self):
        expected = [
            "build-iso.sh",
            "check-dependencies.sh",
            "verify-iso.sh",
            "test-build.sh",
            "noxo-control",
            "noxo-welcome",
        ]
        for name in expected:
            p = os.path.join(SCRIPTS_DIR, name)
            self.assertTrue(os.path.isfile(p), f"Script missing: {name}")

    def test_scripts_shebang(self):
        for fname in os.listdir(SCRIPTS_DIR):
            if fname.endswith(".sh") or fname.startswith("noxo-"):
                p = os.path.join(SCRIPTS_DIR, fname)
                with open(p, "r", encoding="utf-8") as f:
                    first_line = f.readline().strip()
                self.assertTrue(first_line.startswith("#!/bin/bash") or first_line.startswith("#!/usr/bin/env bash"),
                                f"Invalid shebang in {fname}: {first_line}")

    def test_bash_syntax(self):
        # Check if bash is available on host
        git_bash = r"C:\Program Files\Git\bin\bash.exe"
        bash_cmd = git_bash if os.path.isfile(git_bash) else "bash"
        
        for fname in os.listdir(SCRIPTS_DIR):
            if fname.endswith(".sh") or fname.startswith("noxo-"):
                p = os.path.join(SCRIPTS_DIR, fname)
                res = subprocess.run([bash_cmd, "-n", p], capture_output=True, text=True)
                self.assertEqual(res.returncode, 0, f"Syntax error in {fname}: {res.stderr}")

if __name__ == "__main__":
    unittest.main()
