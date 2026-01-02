#!/bin/bash

# ================================================================
# Bilgi - Secure Chat | Complete Setup Script (Linux/macOS)
# ================================================================
# Bu script projeyi sıfırdan kurar ve çalıştırır.
# İşlemler:
#   1. Python 3.10+ kontrolü
#   2. PostgreSQL kurulumu ve yapılandırması
#   3. Database oluşturma (chat_app, chat_user)
#   4. Python virtual environment ve bağımlılıklar
#   5. AppImage çalıştırma izni
# ================================================================

set -e

# Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Proje kök dizini
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}        Bilgi - Secure Chat | Setup Script${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[$1/5] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ================================================================
# Ana kurulum
# ================================================================

print_header

# 1) Python kontrolü
print_step "1" "Python kontrolü yapılıyor..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    print_success "$PYTHON_VERSION bulundu"
else
    print_error "Python3 bulunamadı!"
    echo ""
    echo "Python 3.10+ yüklemek için:"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
        echo "  Fedora:        sudo dnf install python3 python3-pip"
        echo "  Arch:          sudo pacman -S python python-pip"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install python3"
    fi
    exit 1
fi

# 2) PostgreSQL kontrolü ve kurulum
echo ""
print_step "2" "PostgreSQL kontrolü yapılıyor..."

check_postgres() {
    if command -v psql &> /dev/null; then
        return 0
    fi
    return 1
}

install_postgres_linux() {
    # Ubuntu/Debian
    if command -v apt &> /dev/null; then
        print_info "PostgreSQL yükleniyor (apt)..."
        sudo apt update -qq
        sudo apt install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        return 0
    fi
    
    # Fedora/RHEL
    if command -v dnf &> /dev/null; then
        print_info "PostgreSQL yükleniyor (dnf)..."
        sudo dnf install -y postgresql postgresql-server
        sudo postgresql-setup --initdb 2>/dev/null || true
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        return 0
    fi
    
    # Arch
    if command -v pacman &> /dev/null; then
        print_info "PostgreSQL yükleniyor (pacman)..."
        sudo pacman -S postgresql --noconfirm
        sudo -u postgres initdb -D /var/lib/postgres/data 2>/dev/null || true
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        return 0
    fi
    
    return 1
}

install_postgres_macos() {
    if command -v brew &> /dev/null; then
        print_info "PostgreSQL yükleniyor (Homebrew)..."
        brew install postgresql@15
        brew services start postgresql@15
        return 0
    fi
    return 1
}

if check_postgres; then
    print_success "PostgreSQL bulundu"
else
    print_info "PostgreSQL yükleniyor..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! install_postgres_linux; then
            print_error "PostgreSQL otomatik yüklenemedi. Lütfen manuel yükleyin."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! install_postgres_macos; then
            print_error "Homebrew bulunamadı. Lütfen PostgreSQL'i manuel yükleyin."
            exit 1
        fi
    else
        print_error "Desteklenmeyen işletim sistemi. PostgreSQL'i manuel yükleyin."
        exit 1
    fi
    
    print_success "PostgreSQL yüklendi"
fi

# PostgreSQL servisinin çalıştığından emin ol
echo ""
print_step "3" "PostgreSQL servisi başlatılıyor..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v systemctl &> /dev/null; then
        sudo systemctl start postgresql 2>/dev/null || true
    fi
fi
print_success "PostgreSQL servisi aktif"

# Database ve kullanıcı oluştur
echo ""
print_step "4" "Database oluşturuluyor..."

# pg_hba.conf'u güncelle (peer auth yerine md5)
update_pg_hba() {
    local pg_hba=""
    
    # pg_hba.conf konumunu bul
    if [ -f "/etc/postgresql/*/main/pg_hba.conf" ]; then
        pg_hba=$(ls /etc/postgresql/*/main/pg_hba.conf 2>/dev/null | head -1)
    elif [ -f "/var/lib/pgsql/data/pg_hba.conf" ]; then
        pg_hba="/var/lib/pgsql/data/pg_hba.conf"
    fi
    
    if [ -n "$pg_hba" ] && [ -f "$pg_hba" ]; then
        # md5 auth için kontrol et ve güncelle
        if ! grep -q "host.*all.*all.*127.0.0.1.*md5" "$pg_hba" 2>/dev/null; then
            print_info "pg_hba.conf güncelleniyor..."
            echo "host    all             all             127.0.0.1/32            md5" | sudo tee -a "$pg_hba" > /dev/null
            echo "host    all             all             ::1/128                 md5" | sudo tee -a "$pg_hba" > /dev/null
            sudo systemctl reload postgresql 2>/dev/null || sudo systemctl restart postgresql 2>/dev/null || true
        fi
    fi
}

# Database bilgileri
DB_NAME="chat_app"
DB_USER="chat_user"
DB_PASS="chat_pass"

# Kullanıcı var mı kontrol et ve oluştur
create_db_user() {
    sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" 2>/dev/null | grep -q 1
    if [ $? -ne 0 ]; then
        print_info "Kullanıcı '$DB_USER' oluşturuluyor..."
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" 2>/dev/null
    else
        print_info "Kullanıcı '$DB_USER' zaten mevcut"
    fi
}

# Database var mı kontrol et ve oluştur
create_database() {
    sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null | grep -q 1
    if [ $? -ne 0 ]; then
        print_info "Database '$DB_NAME' oluşturuluyor..."
        sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null
    else
        print_info "Database '$DB_NAME' zaten mevcut"
    fi
}

# İzinleri ayarla
grant_privileges() {
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null
    # PostgreSQL 15+ için schema izni
    sudo -u postgres psql -d $DB_NAME -c "GRANT ALL ON SCHEMA public TO $DB_USER;" 2>/dev/null || true
}

update_pg_hba
create_db_user
create_database
grant_privileges

print_success "Database yapılandırması tamamlandı"
echo -e "    Database: ${CYAN}$DB_NAME${NC}"
echo -e "    User:     ${CYAN}$DB_USER${NC}"
echo -e "    Password: ${CYAN}$DB_PASS${NC}"
echo -e "    Host:     ${CYAN}localhost:5432${NC}"

# 5) Python Virtual Environment ve bağımlılıklar
echo ""
print_step "5" "Python bağımlılıkları yükleniyor..."
cd "$PROJECT_DIR"

if [ ! -d "venv" ]; then
    print_info "Virtual environment oluşturuluyor..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q

print_success "Python bağımlılıkları yüklendi"
echo "    Paketler: fastapi, uvicorn, sqlalchemy, psycopg2, pillow, pycryptodome"

# AppImage için FUSE kontrolü ve kurulum
echo ""
print_info "AppImage bağımlılıkları kontrol ediliyor..."

# libfuse2 kontrolü
if ! ldconfig -p 2>/dev/null | grep -q libfuse.so.2; then
    print_info "libfuse2 yükleniyor (AppImage için gerekli)..."
    if command -v apt &> /dev/null; then
        sudo apt install -y libfuse2
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y fuse-libs
    elif command -v pacman &> /dev/null; then
        sudo pacman -S fuse2 --noconfirm
    fi
    print_success "libfuse2 yüklendi"
else
    print_success "libfuse2 zaten yüklü"
fi

# AppImage çalıştırma izni
if [ -f "$PROJECT_DIR/Bilgi-x86_64.AppImage" ]; then
    chmod +x "$PROJECT_DIR/Bilgi-x86_64.AppImage"
    print_success "AppImage hazır"
else
    print_info "AppImage bulunamadı (Bilgi-x86_64.AppImage)"
fi

# ================================================================
# Kurulum tamamlandı
# ================================================================

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}           KURULUM BAŞARIYLA TAMAMLANDI!${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo -e "${BLUE}Projeyi çalıştırmak için:${NC}"
echo ""
echo "  1) Server'ı başlat (yeni terminal):"
echo -e "     ${CYAN}./run_server.sh${NC}"
echo ""
echo "  2) Uygulamayı başlat (başka terminal):"
echo -e "     ${CYAN}./run_client.sh${NC}"
echo ""
echo -e "${YELLOW}NOT:${NC} Farklı bilgisayarlarda çalıştırmak için:"
echo "     Uygulamadaki 'Server IP Ayarla' butonunu kullanın"
echo ""
