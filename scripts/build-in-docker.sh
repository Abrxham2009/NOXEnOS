#!/usr/bin/env bash
# ==============================================================================
# NOXEnOS Build Inside Docker Container
# Builds the ISO cleanly inside an isolated Ubuntu 24.04 container.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[*] Construyendo imagen del contenedor Docker de compilación..."
docker build -t noxenos-builder -f "$PROJECT_ROOT/Dockerfile" "$PROJECT_ROOT"

echo "[*] Ejecutando compilación de la ISO con privilegios dentro de Docker..."
docker run --rm --privileged \
    -v "$PROJECT_ROOT":/workspace \
    noxenos-builder /bin/bash /workspace/scripts/build-iso.sh

echo "[+] Compilación en Docker finalizada. Revisa la carpeta output/."
