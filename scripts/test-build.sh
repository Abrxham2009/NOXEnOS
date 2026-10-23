#!/usr/bin/env bash
# ==============================================================================
# NOXEnOS Test Suite Runner
# Executes automated checks on branding, configs, package lists, and scripts.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=================================================="
echo "    NOXEnOS Linux - Ejecución de Pruebas          "
echo "=================================================="

# 1. Shell scripts syntax check (bash -n)
echo "[*] Comprobando sintaxis de scripts Bash..."
find "$PROJECT_ROOT/scripts" -type f -name "*.sh" -o -name "noxo-*" | while read -r s; do
    if bash -n "$s"; then
        echo " [+] Sintaxis correcta: $(basename "$s")"
    else
        echo " [-] ERROR de sintaxis en: $s" >&2
        exit 1
    fi
done

# 2. Python test suite
if command -v python3 >/dev/null 2>&1; then
    PY="python3"
elif command -v python >/dev/null 2>&1; then
    PY="python"
fi

if [ -n "$PY" ]; then
    echo "[*] Ejecutando suite de pruebas automatizadas en Python..."
    $PY -m unittest discover -s "$PROJECT_ROOT/tests" -p "test_*.py" -v
else
    echo "[!] Python no encontrado, saltando pruebas unitarias de Python."
fi

echo "=================================================="
echo "    ¡Todas las pruebas pasaron satisfactoriamente! "
echo "=================================================="
