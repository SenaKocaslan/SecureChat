#!/bin/bash

# ================================================================
# Bilgi - Hızlı Başlatma Script'i (Universal Start Script)
# ================================================================
# Bu script projeyi hızlıca ayağa kaldırır.
# 1. Eğer kurulum yapılmamışsa (venv yoksa), setup.sh çalıştırır.
# 2. Server'ı ayrı bir terminalde (veya arka planda) başlatır.
# 3. Client (AppImage) uygulamasını başlatır.
# ================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Renk tanımları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}                 Bilgi - Başlatılıyor...                        ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""

# ----------------------------------------------------------------
# 1. Kurulum Kontrolü
# ----------------------------------------------------------------

if [ ! -d "venv" ] && [ ! -d ".venv" ]; then
    print_warning "Kurulum bulunamadı (venv eksik)."
    print_info "İlk kurulum başlatılıyor (setup.sh)..."
    echo ""
    
    if [ -f "./setup.sh" ]; then
        chmod +x ./setup.sh
        ./setup.sh
        
        # Setup başarısız olursa çık
        if [ $? -ne 0 ]; then
            print_error "Kurulum başarısız oldu. Lütfen hataları kontrol edin."
            exit 1
        fi
    else
        print_error "setup.sh bulunamadı! Lütfen proje dosyalarının tam olduğundan emin olun."
        exit 1
    fi
    echo ""
    print_success "Kurulum tamamlandı."
fi

# ----------------------------------------------------------------
# 2. Server Başlatma
# ----------------------------------------------------------------

print_info "Server başlatılıyor..."

SERVER_SCRIPT="$PROJECT_DIR/run_server.sh"
chmod +x "$SERVER_SCRIPT"

# Server'ı yeni terminalde açmaya çalış
SERVER_STARTED=false

TERMINALS=("gnome-terminal" "konsole" "xfce4-terminal" "xterm" "terminator" "termite" "alacritty" "tilix")
TERMINAL_CMD=""

for term in "${TERMINALS[@]}"; do
    if command -v "$term" &> /dev/null; then
        TERMINAL_CMD="$term"
        break
    fi
done

if [ -n "$TERMINAL_CMD" ]; then
    # Terminale özel argümanlar
    case "$TERMINAL_CMD" in
        "gnome-terminal")
            "$TERMINAL_CMD" --title="Bilgi Server" -- bash -c "$SERVER_SCRIPT; exec bash"
            ;;
        "konsole")
            "$TERMINAL_CMD" -e bash -c "$SERVER_SCRIPT; exec bash" &
            ;;
        "xfce4-terminal")
            "$TERMINAL_CMD" --title="Bilgi Server" -e "bash -c '$SERVER_SCRIPT; exec bash'" &
            ;;
        "xterm")
            "$TERMINAL_CMD" -T "Bilgi Server" -e "$SERVER_SCRIPT; bash" &
            ;;
        *)
            # Diğerleri için genel deneme
            "$TERMINAL_CMD" -e "$SERVER_SCRIPT" &
            ;;
    esac
    print_success "Server yeni pencerede başlatıldı ($TERMINAL_CMD)."
    SERVER_STARTED=true
else
    print_warning "Ayrı terminal penceresi açılamadı. Server arka planda başlatılıyor..."
    # Arka planda başlat, logları dosyaya yaz
    nohup "$SERVER_SCRIPT" > server.log 2>&1 &
    SERVER_PID=$!
    echo "Server PID: $SERVER_PID"
    print_info "Logları görmek için: tail -f server.log"
    SERVER_STARTED=true
fi

# Server'ın biraz açılmasını bekle
sleep 3

# ----------------------------------------------------------------
# 3. Client Başlatma
# ----------------------------------------------------------------

CLIENT_SCRIPT="$PROJECT_DIR/run_client.sh"

if [ -f "$CLIENT_SCRIPT" ]; then
    print_info "Client başlatılıyor..."
    chmod +x "$CLIENT_SCRIPT"
    "$CLIENT_SCRIPT"
else
    print_error "Client script'i bulunamadı (run_client.sh)!"
fi

# ----------------------------------------------------------------
# Kapanış
# ----------------------------------------------------------------

echo ""
print_success "İşlem tamamlandı."
if [ -n "$SERVER_PID" ]; then
    print_warning "Server arka planda çalışmaya devam ediyor (PID: $SERVER_PID)."
    print_info "Kapatmak için: kill $SERVER_PID"
fi
