#!/bin/bash

# ================================================================
# Bilgi - Server Başlatma Script'i
# ================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Virtual environment aktive et
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo "Virtual environment bulunamadı! Önce setup.sh çalıştırın."
    exit 1
fi

# Bilgisayarın IP adreslerini bul
get_local_ip() {
    # Linux
    if command -v ip &> /dev/null; then
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1
    # macOS
    elif command -v ifconfig &> /dev/null; then
        ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1
    else
        echo "Bilinmiyor"
    fi
}

LOCAL_IP=$(get_local_ip)

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Bilgi - Secure Chat Server                         ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Server:     http://0.0.0.0:8000                             ║"
echo "║  API Docs:   http://localhost:8000/docs                      ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  🌐 DİĞER BİLGİSAYARLAR İÇİN:                                ║"
echo "║  Bu IP'yi uygulamada 'Server IP Ayarla' ile girin:           ║"
echo "║                                                              ║"
printf "║     %-55s║\n" "➜  $LOCAL_IP"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd server
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
