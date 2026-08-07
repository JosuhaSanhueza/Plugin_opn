#!/bin/sh

# Script oficial de actualización remota desde GitHub para Escolarapp Game Manager

REPO_URL="https://raw.githubusercontent.com/JosuhaSanhueza/BlockList/main/os-gamecontrol-1.0.tar.gz"
WORK_DIR="/tmp/escolarapp_update"

echo "=== 🚀 Escolarapp Game Manager: Actualizador Automático ==="

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

echo "1. Descargando última versión desde GitHub..."
fetch -o os-gamecontrol-1.0.tar.gz "$REPO_URL" || curl -o os-gamecontrol-1.0.tar.gz "$REPO_URL"

if [ ! -f os-gamecontrol-1.0.tar.gz ]; then
    echo "❌ Error: No se pudo descargar la actualización desde GitHub."
    exit 1
fi

echo "2. Descomprimiendo e Instalando..."
tar -xvf os-gamecontrol-1.0.tar.gz
sh install.sh

echo "3. Limpiando temporales..."
rm -rf "$WORK_DIR"

echo "=== ✅ ¡Actualización desde GitHub completada exitosamente! ==="
