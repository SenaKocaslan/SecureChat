#!/bin/bash

# ================================================================
# Bilgi - Client Başlatma Script'i (AppImage)
# ================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

APPIMAGE="$PROJECT_DIR/Bilgi-x86_64.AppImage"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Bilgi - Secure Chat Client                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ -f "$APPIMAGE" ]; then
    echo "AppImage başlatılıyor..."
    chmod +x "$APPIMAGE"
    "$APPIMAGE"
else
    echo "HATA: AppImage bulunamadı!"
    echo "Beklenen dosya: $APPIMAGE"
    exit 1
fi
