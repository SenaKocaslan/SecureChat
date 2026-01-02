<p align="center">
  <img src="bilgi/assets/images/welcome.png" alt="Secure Chat Logo" width="120"/>
</p>

<h1 align="center">🔐 Secure Chat</h1>

<p align="center">
  <strong>Steganografi ve DES Şifreleme ile Güvenli Mesajlaşma Uygulaması</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.7.2+-02569B?style=for-the-badge&logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/FastAPI-0.115.5-009688?style=for-the-badge&logo=fastapi" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/PostgreSQL-12+-336791?style=for-the-badge&logo=postgresql" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python" alt="Python"/>
</p>

---

## 📋 İçindekiler

- [Proje Hakkında](#-proje-hakkında)
- [Özellikler](#-özellikler)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Sistem Mimarisi](#-sistem-mimarisi)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [API Referansı](#-api-referansı)
- [Güvenlik](#-güvenlik)
- [English Documentation](#-english-documentation-click-to-expand)
- [Lisans](#-lisans--license)

---

## 🎯 Proje Hakkında

**Secure Chat**, uçtan uca şifreli güvenli bir mesajlaşma uygulamasıdır. Proje iki ana bileşenden oluşur:

| Bileşen | Teknoloji | Açıklama |
|---------|-----------|----------|
| 📱 **İstemci** | Flutter/Dart | Çok platformlu mobil/masaüstü uygulama |
| 🖥️ **Sunucu** | Python FastAPI | REST API + WebSocket sunucusu |

### Nasıl Çalışır?

1. **Kayıt sırasında** kullanıcı şifresi LSB steganografi ile bir resme gömülür
2. **Mesajlar** DES algoritması ile şifrelenir
3. **Sunucu** mesajı alıcının anahtarıyla yeniden şifreler
4. **WebSocket** üzerinden anlık iletim sağlanır

---

## ✨ Özellikler

- 🔒 **LSB Steganografi** - Şifre görüntü içinde gizlenir
- 🔐 **DES Şifreleme** - Tüm mesajlar şifrelenir
- ⚡ **Gerçek Zamanlı** - WebSocket ile anlık mesajlaşma
- 👥 **Online Durumu** - Kullanıcıların çevrimiçi/çevrimdışı durumu
- ✓✓ **Mesaj Durumu** - Gönderildi / İletildi / Okundu takibi
- 😊 **Emoji Desteği** - Zengin emoji picker

---

## 📸 Ekran Görüntüleri

<p align="center">
  <img src="docs/images/login_screen.png" alt="Login Screen" width="280"/>
  <img src="docs/images/register_screen.png" alt="Register Screen" width="280"/>
  <img src="docs/images/chat_screen.png" alt="Chat Screen" width="280"/>
</p>

<p align="center">
  <em>Giriş Ekranı • Kayıt Ekranı • Sohbet Ekranı</em>
</p>

---

## 🏗️ Sistem Mimarisi

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SECURE CHAT MİMARİSİ                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│   📱 FLUTTER     │      │   🔧 SERVİSLER    │      │   🖥️ FASTAPI     │
│     CLIENT       │      │     (DART)       │      │     SERVER       │
├──────────────────┤      ├──────────────────┤      ├──────────────────┤
│                  │      │                  │      │                  │
│  WelcomeScreen   │─────▶│  StegoService    │─────▶│  REST Endpoints  │
│       │          │      │  (LSB Gömme)     │      │       │          │
│       ▼          │      │                  │      │       ▼          │
│  RegisterScreen  │─────▶│  DesService      │─────▶│  LSB Extract     │
│       │          │      │  (Şifreleme)     │      │       │          │
│       ▼          │      │                  │      │       ▼          │
│  LoginScreen     │─────▶│  ApiService      │─────▶│  Crypto Service  │
│       │          │      │  (HTTP)          │      │       │          │
│       ▼          │      │                  │      │       ▼          │
│  ChatScreen      │◀────▶│  WebSocket       │◀────▶│  Message Handler │
│                  │      │  Service         │      │                  │
└──────────────────┘      └──────────────────┘      └────────┬─────────┘
                                                              │
                                                              ▼
                                                   ┌──────────────────┐
                                                   │   🗄️ PostgreSQL   │
                                                   │     DATABASE     │
                                                   ├──────────────────┤
                                                   │  • Users         │
                                                   │  • Messages      │
                                                   │  • Stego Images  │
                                                   └──────────────────┘
```

### 📝 Kayıt Akışı

<p align="center">
  <img src="docs/images/kayit_akisi.png" alt="Kayıt Akışı" width="700"/>
</p>

<details>
<summary>📊 ASCII Diyagram (Tıklayın)</summary>

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Kullanıcı│    │ Flutter │    │  Stego  │    │ Server  │    │Database │
└────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘
     │              │              │              │              │
     │ 1. Form doldur              │              │              │
     │ (username +  │              │              │              │
     │  şifre +     │              │              │              │
     │  resim)      │              │              │              │
     │─────────────▶│              │              │              │
     │              │              │              │              │
     │              │ 2. embedText │              │              │
     │              │   (resim,    │              │              │
     │              │    şifre)    │              │              │
     │              │─────────────▶│              │              │
     │              │              │              │              │
     │              │◀─────────────│              │              │
     │              │ Stego PNG    │              │              │
     │              │              │              │              │
     │              │ 3. POST /register           │              │
     │              │    (username, stego_image)  │              │
     │              │────────────────────────────▶│              │
     │              │              │              │              │
     │              │              │              │ 4. LSB extract│
     │              │              │              │    (şifre)   │
     │              │              │              │─────────────▶│
     │              │              │              │              │
     │              │              │              │ 5. Kaydet    │
     │              │              │              │   (user,     │
     │              │              │              │    password) │
     │              │              │              │─────────────▶│
     │              │              │              │              │
     │              │◀────────────────────────────│              │
     │              │ {user_id, message}          │              │
     │              │              │              │              │
     │◀─────────────│              │              │              │
     │ Chat ekranı  │              │              │              │
     │              │              │              │              │
```
</details>

### 💬 Mesaj Şifreleme Akışı

<p align="center">
  <img src="docs/images/mesaj_sifreleme_akisi.png" alt="Mesaj Şifreleme Akışı" width="700"/>
</p>

<details>
<summary>📊 ASCII Diyagram (Tıklayın)</summary>

```
    ┌────────────────────────────────────────────────────────────┐
    │                    MESAJ ŞİFRELEME AKIŞI                    │
    └────────────────────────────────────────────────────────────┘

    GÖNDEREN                    SUNUCU                      ALICI
    ────────                    ──────                      ─────

    ╔═══════════════╗
    ║ 📝 Mesaj Yaz  ║
    ╚═══════╤═══════╝
            │
            ▼
    ╔═══════════════╗
    ║ 🔒 DES Şifrele║
    ║ (Kendi şifresi)║
    ╚═══════╤═══════╝
            │
            │  encrypted_for_sender
            ▼
                            ╔═══════════════╗
                            ║ 🔓 DES Çöz    ║
                            ║(Sender şifresi)║
                            ╚═══════╤═══════╝
                                    │
                                    │  plain_text
                                    ▼
                            ╔═══════════════╗
                            ║ 🔒 DES Şifrele║
                            ║(Alıcı şifresi)║
                            ╚═══════╤═══════╝
                                    │
                                    │  encrypted_for_receiver
                                    ▼
                                                        ╔═══════════════╗
                                                        ║ 🔓 DES Çöz    ║
                                                        ║ (Kendi şifresi)║
                                                        ╚═══════╤═══════╝
                                                                │
                                                                ▼
                                                        ╔═══════════════╗
                                                        ║ 📖 Mesajı Oku ║
                                                        ╚═══════════════╝
```
</details>

---

## 🚀 Kurulum

### Gereksinimler

**Sunucu:**
- Python 3.8+
- PostgreSQL 12+

**İstemci:**
- Flutter SDK 3.7.2+
- Dart SDK 3.0+

### 1️⃣ Veritabanı Kurulumu

```bash
# PostgreSQL'de veritabanı oluştur
psql -U postgres

CREATE DATABASE chat_app;
CREATE USER chat_user WITH PASSWORD 'chat_pass';
GRANT ALL PRIVILEGES ON DATABASE chat_app TO chat_user;
\q
```

### 2️⃣ Sunucu Kurulumu

```bash
# Proje dizinine git
cd c:\Users\90544\Downloads\bilgi

# Sanal ortam oluştur
python -m venv venv
.\venv\Scripts\activate

# Bağımlılıkları yükle
pip install -r requirements.txt

# Sunucuyu başlat
cd server
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### 3️⃣ İstemci Kurulumu

```bash
# Flutter dizinine git
cd c:\Users\90544\Downloads\bilgi\bilgi

# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run -d windows
```

---

## 📖 Kullanım

### Kayıt Olma

1. **"Sign Up"** butonuna tıklayın
2. Kullanıcı adı girin (min. 3 karakter)
3. Şifre girin (**tam 8 karakter**)
4. İsteğe bağlı profil resmi seçin
5. **"Kayıt Ol"** butonuna tıklayın

> ⚠️ **Önemli:** Şifre tam 8 karakter olmalıdır (DES anahtarı)

### Giriş Yapma

1. **"Login"** butonuna tıklayın
2. Kullanıcı adı ve şifrenizi girin
3. **"Login"** butonuna tıklayın

### Mesaj Gönderme

1. Sol panelden bir kullanıcı seçin
   - 🟢 Çevrimiçi
   - ⚫ Çevrimdışı
2. Mesajınızı yazın
3. Gönder butonuna tıklayın

### Mesaj Durumları

| Simge | Durum | Açıklama |
|-------|-------|----------|
| ✓ | Gönderildi | Sunucuya ulaştı |
| ✓✓ | İletildi | Alıcıya iletildi |
| ✓✓ (mavi) | Okundu | Alıcı mesajı okudu |

---

## 📡 API Referansı

| Endpoint | Metot | Açıklama |
|----------|-------|----------|
| `/` | GET | Sunucu durumu |
| `/register` | POST | Yeni kullanıcı kaydı |
| `/login` | POST | Kullanıcı girişi |
| `/logout` | POST | Çıkış yapma |
| `/users` | GET | Kullanıcı listesi |
| `/users/{id}/photo` | GET | Profil fotoğrafı |
| `/messages/send` | POST | Mesaj gönderme |
| `/messages/{me}/{other}` | GET | Mesaj geçmişi |
| `/ws/{user_id}` | WS | WebSocket bağlantısı |

---

## 🔒 Güvenlik

### Kullanılan Teknolojiler

| Teknoloji | Kullanım Alanı |
|-----------|----------------|
| **LSB Steganografi** | Şifre resme gömülür (64 bit) |
| **DES ECB** | Mesaj şifreleme |
| **PKCS7 Padding** | Block padding |
| **WebSocket TLS** | Güvenli iletişim |

### Güvenlik Özellikleri

- ✅ Şifreler veritabanında düz metin saklanmaz
- ✅ Mesajlar sunucuda alıcının anahtarıyla şifrelenir
- ✅ Her kullanıcının benzersiz DES anahtarı vardır
- ✅ Steganografik resim görsel olarak değişmez

---

## 📁 Proje Yapısı

```
bilgi/
├── 📄 requirements.txt      # Python bağımlılıkları
├── 📁 server/               # FastAPI sunucusu
│   ├── main.py             # API endpoints
│   ├── models.py           # SQLAlchemy modelleri
│   ├── database.py         # DB bağlantısı
│   └── services/
│       ├── crypto_service.py   # DES şifreleme
│       ├── lsb_service.py      # Steganografi
│       └── message_handler.py  # Mesaj işleme
│
└── 📁 bilgi/                # Flutter istemcisi
    ├── pubspec.yaml        # Flutter bağımlılıkları
    └── lib/
        ├── main.dart       # Uygulama girişi
        ├── screens/        # UI ekranları
        │   ├── welcome_screen.dart
        │   ├── register_screen.dart
        │   ├── login_screen.dart
        │   └── chat_screen.dart
        └── services/       # İş mantığı
            ├── api_service.dart
            ├── des_service.dart
            ├── stego_service.dart
            └── websocket_service.dart
```

---

## 🛠️ Sorun Giderme

| Sorun | Çözüm |
|-------|-------|
| Bağlantı hatası | Sunucunun `127.0.0.1:8000`'de çalıştığını kontrol edin |
| Kayıt başarısız | Kullanıcı adı benzersiz olmalı |
| Şifre hatası | Şifre tam 8 karakter olmalı |
| Resim hatası | PNG formatı kullanın (kayıpsız) |

---

<p align="center">
  <strong>🔐 Secure Chat</strong> - Güvenli Mesajlaşma<br/>
  Versiyon 1.0.0 | 2024
</p>

---

<details>
<summary><h2>🇬🇧 English Documentation (Click to expand)</h2></summary>

## 🎯 About The Project

**Secure Chat** is an end-to-end encrypted messaging application. The project consists of two main components:

| Component | Technology | Description |
|-----------|------------|-------------|
| 📱 **Client** | Flutter/Dart | Cross-platform mobile/desktop application |
| 🖥️ **Server** | Python FastAPI | REST API + WebSocket server |

### How It Works

1. **During registration**, user password is embedded into an image using LSB steganography
2. **Messages** are encrypted with DES algorithm
3. **Server** re-encrypts messages with the recipient's key
4. **WebSocket** provides real-time delivery

---

## ✨ Features

- 🔒 **LSB Steganography** - Password hidden within image
- 🔐 **DES Encryption** - All messages are encrypted
- ⚡ **Real-Time** - Instant messaging via WebSocket
- 👥 **Online Status** - User online/offline tracking
- ✓✓ **Message Status** - Sent / Delivered / Read tracking
- 😊 **Emoji Support** - Rich emoji picker

---

## 🚀 Installation

### Requirements

**Server:**
- Python 3.8+
- PostgreSQL 12+

**Client:**
- Flutter SDK 3.7.2+
- Dart SDK 3.0+

### 1️⃣ Database Setup

```bash
# Create database in PostgreSQL
psql -U postgres

CREATE DATABASE chat_app;
CREATE USER chat_user WITH PASSWORD 'chat_pass';
GRANT ALL PRIVILEGES ON DATABASE chat_app TO chat_user;
\q
```

### 2️⃣ Server Setup

```bash
# Navigate to project directory
cd bilgi

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
.\venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Start server
cd server
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### 3️⃣ Client Setup

```bash
# Navigate to Flutter directory
cd bilgi/bilgi

# Install dependencies
flutter pub get

# Run application
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux
```

---

## 📖 Usage

### Registration

1. Click **"Sign Up"** button
2. Enter username (min. 3 characters)
3. Enter password (**exactly 8 characters**)
4. Optionally select a profile picture
5. Click **"Register"** button

> ⚠️ **Important:** Password must be exactly 8 characters (DES key requirement)

### Login

1. Click **"Login"** button
2. Enter your username and password
3. Click **"Login"** button

### Sending Messages

1. Select a user from the left panel
   - 🟢 Online
   - ⚫ Offline
2. Type your message
3. Click send button or press Enter

### Message Status

| Icon | Status | Description |
|------|--------|-------------|
| ✓ | Sent | Reached server |
| ✓✓ | Delivered | Delivered to recipient |
| ✓✓ (blue) | Read | Recipient read the message |

---

## 📡 API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Server status |
| `/register` | POST | New user registration |
| `/login` | POST | User login |
| `/logout` | POST | Logout |
| `/users` | GET | User list |
| `/users/{id}/photo` | GET | Profile photo |
| `/messages/send` | POST | Send message |
| `/messages/{me}/{other}` | GET | Message history |
| `/ws/{user_id}` | WS | WebSocket connection |

---

## 🔒 Security

### Technologies Used

| Technology | Usage |
|------------|-------|
| **LSB Steganography** | Password embedded in image (64 bits) |
| **DES ECB** | Message encryption |
| **PKCS7 Padding** | Block padding |
| **WebSocket TLS** | Secure communication |

### Security Features

- ✅ Passwords are not stored as plain text
- ✅ Messages are encrypted with recipient's key on server
- ✅ Each user has a unique DES key
- ✅ Steganographic image appears visually unchanged

---

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection error | Check server is running at `127.0.0.1:8000` |
| Registration failed | Username must be unique |
| Password error | Password must be exactly 8 characters |
| Image error | Use PNG format (lossless) |

</details>

---

## 📄 Lisans / License

Bu proje **MIT Lisansı** altında lisanslanmıştır.  
This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2024 Secure Chat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<p align="center">
  Made with ❤️ using Flutter & FastAPI<br/>
  <a href="#-proje-hakkinda">🇹🇷 Türkçe</a> • <a href="#-about-the-project">🇬🇧 English</a>
</p>
