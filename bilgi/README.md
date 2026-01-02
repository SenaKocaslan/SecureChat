# Monolith - Güvenli Mesajlaşma Uygulaması

**Monolith**, DES şifreleme ve LSB steganografi teknikleri kullanarak uçtan uca güvenli mesajlaşma sağlayan bir uygulamadır.

---

## 🎯 Proje Özeti

Bu proje, güvenli iletişim için iki ana güvenlik katmanı kullanır:

1. **LSB Steganografi**: Kullanıcı parolası, kayıt sırasında seçilen profil fotoğrafının piksellerine gizlenir
2. **DES Şifreleme**: Tüm mesajlar, kullanıcıya özel parola ile şifrelenir

## 🏗️ Mimari

```
bilgi/
├── bilgi/                    # Flutter Mobil Uygulama
│   ├── lib/
│   │   ├── screens/          # UI Ekranları
│   │   ├── services/         # İş mantığı servisleri
│   │   └── widgets/          # Yeniden kullanılabilir widgetlar
│   └── pubspec.yaml
│
├── server/                   # Python FastAPI Backend
│   ├── main.py              # API endpoints ve WebSocket
│   ├── models.py            # SQLAlchemy modelleri
│   ├── database.py          # Veritabanı bağlantısı
│   └── services/
│       ├── crypto_service.py # DES şifreleme
│       ├── lsb_service.py    # Steganografi
│       └── message_handler.py
│
└── requirements.txt          # Python bağımlılıkları
```

## 🚀 Kurulum

### Gereksinimler

- **Flutter SDK** >= 3.7.2
- **Python** >= 3.10
- **PostgreSQL** (veritabanı için)

### Server Kurulumu

```bash
# Virtual environment oluştur
cd bilgi/
python -m venv venv
source venv/bin/activate  # Linux/Mac
# veya venv\Scripts\activate  # Windows

# Bağımlılıkları yükle
pip install -r requirements.txt

# Veritabanını ayarla (PostgreSQL)
# database.py dosyasında bağlantı ayarlarını düzenle

# Sunucuyu başlat
cd server/
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Flutter Uygulaması (Geliştirme)

```bash
cd bilgi/

# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

### 📦 Hazır Dağıtım (AppImage)

Flutter SDK kurmadan uygulamayı çalıştırmak için hazır AppImage dosyasını kullanabilirsiniz:

```bash
# İndirilen dosyaya çalıştırma izni ver
chmod +x Bilgi-x86_64.AppImage

# Uygulamayı başlat
./Bilgi-x86_64.AppImage
```

### 🔨 AppImage Yeniden Derleme

Kaynak koddan yeni bir AppImage oluşturmak için:

```bash
cd bilgi/

# Linux release build
flutter build linux --release

# AppImage oluştur (appimagetool gerekli)
ARCH=x86_64 appimagetool AppDir/ Bilgi-x86_64.AppImage
```

## 📱 Özellikler

### Kullanıcı Yönetimi
- **Kayıt**: Kullanıcı adı + profil fotoğrafı (8 karakterlik parola gömülü)
- **Giriş**: Kullanıcı adı + parola ile kimlik doğrulama
- **Çıkış**: Güvenli oturum sonlandırma

### Mesajlaşma
- **Gerçek zamanlı mesajlaşma**: WebSocket üzerinden anlık mesaj iletimi
- **Uçtan uca şifreleme**: DES algoritması ile mesaj güvenliği
- **Mesaj durumları**: Gönderildi ✓ | İletildi ✓✓ | Okundu ✓✓ (mavi)

### Güvenlik
- **LSB Steganografi**: Parola, profil fotoğrafının RGB piksellerinde gizlenir
- **DES Şifreleme**: PKCS7 padding ile ECB modunda şifreleme
- **Sunucu tarafı yeniden şifreleme**: Mesajlar alıcının parolası ile tekrar şifrelenir

## 🔐 Güvenlik Akışı

```
Kayıt:
1. Kullanıcı profil fotoğrafı seçer
2. 8 karakterlik rastgele parola oluşturulur
3. Parola, LSB ile fotoğrafa gömülür
4. Stego-fotoğraf sunucuya gönderilir
5. Sunucu parolayı extract edip veritabanına kaydeder

Mesaj Gönderimi:
1. Gönderen mesajı kendi parolası ile DES şifreler
2. Şifreli mesaj sunucuya gönderilir
3. Sunucu, gönderenin parolası ile decrypt eder
4. Sunucu, alıcının parolası ile re-encrypt eder
5. Alıcı (online ise) WebSocket ile mesajı alır
```

## 🛠️ Teknoloji Stack

### Mobil (Flutter)
| Paket | Açıklama |
|-------|----------|
| `dart_des` | DES şifreleme |
| `image` | LSB steganografi için görüntü işleme |
| `web_socket_channel` | Gerçek zamanlı mesajlaşma |
| `http` | REST API iletişimi |
| `emoji_picker_flutter` | Emoji desteği |

### Backend (Python FastAPI)
| Paket | Açıklama |
|-------|----------|
| `fastapi` | REST API framework |
| `uvicorn` | ASGI server |
| `websockets` | WebSocket desteği |
| `sqlalchemy` | ORM |
| `psycopg2-binary` | PostgreSQL driver |
| `pycryptodome` | DES şifreleme |
| `pillow` | LSB steganografi |

## 📡 API Endpoints

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/` | Sağlık kontrolü |
| `POST` | `/register` | Yeni kullanıcı kaydı |
| `POST` | `/login` | Kullanıcı girişi |
| `POST` | `/logout/{user_id}` | Çıkış yapma |
| `GET` | `/users` | Kullanıcı listesi |
| `GET` | `/user/{user_id}/photo` | Profil fotoğrafı |
| `POST` | `/message` | Mesaj gönder |
| `GET` | `/messages/{me_id}/{other_id}` | Sohbet geçmişi |
| `WebSocket` | `/ws/{user_id}` | Gerçek zamanlı bağlantı |

## 🗄️ Veritabanı Şeması

### Users Tablosu
```sql
CREATE TABLE users (
              SERIAL PRIMARY KEY,
    usidername    VARCHAR UNIQUE NOT NULL,
    stego_image BYTEA NOT NULL,
    password    TEXT NOT NULL,
    is_online   BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT NOW()
);
```

### Messages Tablosu
```sql
CREATE TABLE messages (
    id                SERIAL PRIMARY KEY,
    sender_id         INTEGER REFERENCES users(id),
    receiver_id       INTEGER REFERENCES users(id),
    encrypted_content VARCHAR NOT NULL,
    is_delivered      BOOLEAN DEFAULT FALSE,
    is_read           BOOLEAN DEFAULT FALSE,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 👥 Ekip Rolleri

| Kişi | Görev |
|------|-------|
| **Kişi 1** | Flutter Steganografi Servisi (LSB Embed) |
| **Kişi 2** | Python LSB Extract Servisi (Server) |
| **Kişi 3** | DES Şifreleme/Çözme Servisleri |

## 📋 Kullanım Kılavuzu

### İlk Kullanım
1. Uygulamayı açın
2. "Kayıt Ol" butonuna tıklayın
3. Kullanıcı adınızı girin
4. Profil fotoğrafı seçin
5. Sistem otomatik parola üretecek ve fotoğrafa gömecektir
6. **ÖNEMLİ**: Gösterilen parolayı güvenli bir yerde saklayın!

### Giriş Yapma
1. Kullanıcı adınızı girin
2. Kayıt sırasında size verilen 8 karakterlik parolayı girin
3. "Giriş" butonuna tıklayın

### Mesajlaşma
1. Sol panelden sohbet etmek istediğiniz kullanıcıyı seçin
2. Alt kısımdaki metin kutusuna mesajınızı yazın
3. Gönder butonuna tıklayın
4. Mesajlarınız otomatik olarak şifrelenir ve gönderilir

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

---

**Not**: DES algoritması günümüzde kriptografik olarak güvenli kabul edilmemektedir. Bu proje eğitim ve demonstrasyon amaçlıdır. Gerçek uygulamalarda AES-256 gibi modern algoritmalar tercih edilmelidir.
