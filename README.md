# Swifty Companion

42 Network öğrencilerinin profillerini, yeteneklerini ve projelerini görüntüleyen modern bir Android uygulaması. Flutter ile yazılmıştır ve 42 API'sinin en güncel versiyonunu (v2) kullanır.

[![Flutter](https://img.shields.io/badge/Flutter-3.24.5+-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android-green)](https://developer.android.com)
[![OAuth2](https://img.shields.io/badge/auth-OAuth2%20PKCE-brightgreen)](https://datatracker.ietf.org/doc/html/rfc7636)

---

## İçindekiler

- [Özellikler](#özellikler)
- [Ekran Akışı](#ekran-akışı)
- [Mimari](#mimari)
- [Gereksinimler](#gereksinimler)
- [Kurulum](#kurulum)
- [Konfigürasyon (.env)](#konfigürasyon-env)
- [42 Intra Uygulaması Ayarı](#42-intra-uygulaması-ayarı)
- [Çalıştırma](#çalıştırma)
- [Proje Yapısı](#proje-yapısı)
- [Subject'e Uyumluluk Matrisi](#subjecte-uyumluluk-matrisi)
- [Güvenlik Notu](#güvenlik-notu)
- [Sorun Giderme](#sorun-giderme)

---

## Özellikler

### Zorunlu Gereksinimler (Mandatory)
- **3 ekran**: Login → Home → Profile
- **42 Intra OAuth2** ile kullanıcı kimlik doğrulama (Authorization Code + PKCE)
- **Kullanıcı arama** (login ile)
- **7+ detay** her kullanıcı için: login, email, mobile, location, wallet, correction points, pool, grade
- **Skills**: level (örnek: `4.25`) + yüzde (`25%`) + görsel progress bar
- **Projects**: Tamamlananlar (başarılı ✓ / başarısız ✗) renklendirilmiş listede
- **Geri navigasyon**: Profile'dan Home'a back button
- **Kapsamlı error handling**: network, timeout, 401, 404 (user not found), 429 (rate limit), 5xx, iptal, vs.
- **Flexible layout**: `LayoutBuilder` + `CustomScrollView` + `SafeArea` — her ekran boyutunda doğru davranır
- **Tek token, tekrar kullanılabilir**: Token güvenli depoda cache'lenir, her istekte yeniden üretilmez

### Bonus
- **Otomatik token refresh**: Access token süresi dolmak üzereyken veya 401 alındığında arka planda `refresh_token` kullanılarak yenilenir. Kullanıcının oturumu kesintisiz devam eder.

### Ekstra (Extras)
- **Beyaz, sade, modern** Material 3 tasarım
- **Çoklu dil** (TR / EN) — cihaz diline göre otomatik seçim
- **Profil fotoğrafı önbelleği** (`cached_network_image`)
- **Çoklu cursus desteği**: Kullanıcı birden fazla cursus'ta ise chip selector
- **Pull-to-refresh** Home ve Profile ekranlarında
- **Animasyonlu geçişler** (fade + slide)
- **Email kopyalama** tek dokunuşla panoya
- **Safe null handling**: Telefonu gizli olan kullanıcılar, konumu olmayan (intra'da değil) kullanıcılar, skill'i boş olan cursus'lar vs. tümü düzgün gösterilir

---

## Ekran Akışı

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    Login     │       │     Home     │       │   Profile    │
│              │       │              │       │              │
│  [Sign in    │──OAuth│  • Kendi     │──tap──│  • Header +  │
│   with 42]   │──────▶│    profil    │───────│    Avatar    │
│              │       │    kartı     │       │  • 7 Detay   │
│              │       │  • Search    │       │  • Skills    │
│              │       │  • Logout    │       │  • Projects  │
└──────────────┘       └──────────────┘       └──────────────┘
      ▲                       │  ▲                   │
      │                       ▼  │                   │
      │                  Search user ────────────────┘
      │                       │
      └───── Logout ──────────┘
```

---

## Mimari

**Clean Architecture** (MVVM + katman ayrımı) prensibine göre yazıldı:

```
lib/
├── core/                # Framework-agnostic yardımcılar
│   ├── config/          # EnvConfig — .env değerlerine type-safe erişim
│   ├── errors/          # AppException hiyerarşisi
│   ├── router/          # go_router yapılandırması + auth guard
│   ├── theme/           # Renkler, tipografi, ThemeData
│   └── utils/           # Logger
├── data/                # Veri katmanı
│   ├── datasources/
│   │   ├── local/       # TokenStorage (Android Keystore)
│   │   └── remote/      # ApiClient (Dio) + AuthInterceptor + AuthService + UserApi
│   ├── models/          # UserModel, TokenModel, SkillModel, ProjectUserModel, CursusUserModel
│   └── repositories/    # AuthRepository, UserRepository
└── presentation/        # UI katmanı
    ├── providers/       # AuthProvider, HomeProvider, ProfileProvider (ChangeNotifier)
    ├── screens/         # Login, Home, Profile, Splash
    └── widgets/         # Yeniden kullanılabilir widget'lar
```

### Token Akışı

```
┌─────────────┐  1. Request   ┌──────────────────┐
│   Screen    │──────────────▶│  AuthInterceptor │
└─────────────┘               └──────────────────┘
                                        │
                         2. Token cached│?
                           ┌────────────┴────────────┐
                           ▼ YES & FRESH             ▼ EXPIRING/EXPIRED
                  ┌────────────────┐        ┌──────────────────┐
                  │  Add Bearer    │        │  Refresh Token   │
                  │  Header + send │        │  via /oauth/token│
                  └────────────────┘        └──────────────────┘
                                                    │
                                                    ▼ 
                                        ┌──────────────────────┐
                                        │ New token → storage  │
                                        │ Retry original call  │
                                        └──────────────────────┘
```

Eğer refresh de başarısız olursa (refresh_token revoke edilmiş olabilir), `AuthProvider.onSessionExpired()` tetiklenir ve kullanıcı otomatik olarak Login ekranına yönlendirilir.

---

## Gereksinimler

- **Flutter SDK** 3.24.5 veya üzeri
- **Dart** 3.5.4 veya üzeri
- **Java JDK** 17 (veya üzeri 21 dahil)
- **Android Studio** 2024.1+ *VEYA* Android SDK + `cmdline-tools;latest`
- **Android SDK Platform** 34 (veya üzeri) + Build Tools 34+
- **Android NDK** 26.1.10909125 (`flutter build` bunu otomatik indirir)
- **42 Intra Uygulaması** kayıtlı (UID + SECRET + Redirect URI)

---

## Kurulum

### 1. Flutter kurulumunu doğrula

```bash
flutter doctor
```

Çıktıda **Android toolchain** yeşil değilse:

```bash
# Android Studio kurulu ise SDK lisanslarını kabul et
flutter doctor --android-licenses

# cmdline-tools yoksa:
# Android Studio → SDK Manager → SDK Tools → Android SDK Command-line Tools (latest)
```

### 2. Bağımlılıkları yükle

```bash
flutter pub get
```

### 3. `.env` dosyasını oluştur

`.env.example` dosyasını baz alarak proje kökünde `.env` dosyası oluştur. (Detay için → [Konfigürasyon](#konfigürasyon-env))

```bash
cp .env.example .env
# .env'yi açıp kendi UID / SECRET değerlerini gir
```

### 4. Çalıştır

```bash
flutter run -d <device_id>
```

---

## Konfigürasyon (.env)

Proje kökünde `.env` dosyası **zorunludur**. Aşağıdaki anahtarları içermelidir:

| Key | Açıklama | Örnek |
|-----|----------|-------|
| `FORTYTWO_UID` | 42 intra uygulama UID (Client ID) | `u-s4t2ud-...` |
| `FORTYTWO_SECRET` | 42 intra uygulama secret | `s-s4t2ud-...` |
| `FORTYTWO_REDIRECT_URI` | OAuth callback URI | `com.bc.swiftycompanion://oauth/callback` |
| `FORTYTWO_API_BASE_URL` | API base URL | `https://api.intra.42.fr` |
| `FORTYTWO_AUTH_URL` | OAuth authorize endpoint | `https://api.intra.42.fr/oauth/authorize` |
| `FORTYTWO_TOKEN_URL` | OAuth token endpoint | `https://api.intra.42.fr/oauth/token` |
| `FORTYTWO_SCOPES` | OAuth scope'ları | `public` |

> ⚠️ **GÜVENLİK**: `.env` dosyası `.gitignore`'da olduğundan asla commit'lenmez. Subject gerekliliği: "credentials, API keys, env variables etc. must be saved locally in a .env file and ignored by git".

---

## 42 Intra Uygulaması Ayarı

Uygulamanın OAuth2 akışının çalışabilmesi için 42 intra'daki uygulamana aşağıdaki ayarları yapman gerekiyor:

1. https://profile.intra.42.fr/oauth/applications adresine git
2. Uygulamanı bul → **Edit** tıkla
3. **Redirect URI** alanına aşağıdakini ekle:
   ```
   com.bc.swiftycompanion://oauth/callback
   ```
4. Kaydet
5. **UID** ve **SECRET** değerlerini `.env` dosyasına yapıştır

> Bu redirect URI tam olarak **aynı** şekilde hem 42 intra'da, hem `.env` dosyasında, hem de `AndroidManifest.xml`'deki intent-filter'da bulunmalı. Aksi halde OAuth flow `redirect_uri_mismatch` hatası verir.

---

## Çalıştırma

### Debug build (geliştirme için)

```bash
flutter run
```

### Release APK

```bash
flutter build apk --release
```

APK çıktısı: `build/app/outputs/flutter-apk/app-release.apk`

### Statik analiz (lint kontrolü)

```bash
flutter analyze
```

Çıkış: `No issues found!`

### Unit testler

```bash
flutter test
```

Test coverage alanları: SkillModel hesaplamaları, TokenModel parse/expiry, UserRepository login validasyonu.

---

## Proje Yapısı

```
swifty-companion/
├── .env                                  # Secret'lar (gitignored)
├── .env.example                          # Template
├── .gitignore
├── README.md
├── pubspec.yaml
├── android/
│   ├── app/
│   │   ├── build.gradle                  # minSdk 24, targetSdk 35, Java 17
│   │   └── src/main/AndroidManifest.xml  # OAuth redirect intent-filter
│   └── gradle/wrapper/
│       └── gradle-wrapper.properties     # Gradle 8.7
├── assets/translations/
│   ├── en.json
│   └── tr.json
├── lib/
│   ├── main.dart                         # Entry + DI graph
│   ├── core/
│   ├── data/
│   └── presentation/
└── test/
    └── widget_test.dart                  # Unit tests
```

---

## Subject'e Uyumluluk Matrisi

| Gereksinim | Durum | Nerede |
|-----------|-------|--------|
| En az 2 ekran | ✓ 3 ekran (Login, Home, Profile) | `lib/presentation/screens/` |
| Tüm error case'leri handle etmek | ✓ Network, timeout, 401, 404, 429, 5xx, cancel | `lib/core/errors/` + `user_api.dart` |
| 2. ekran login bilgisi gösteriyor | ✓ ProfileScreen başlıkta login | `profile_screen.dart` |
| En az 4 detay + profil foto | ✓ 7 detay | `info_section.dart`, `profile_header.dart` |
| Skills (level + %) | ✓ Progress bar + yüzde + level | `skills_section.dart` |
| Projeler (başarılı + başarısız) | ✓ Renkli, badge'li liste | `projects_section.dart` |
| Geri navigasyon | ✓ Back button + `go_router.pop` | `profile_screen.dart` |
| Flexible layout | ✓ `LayoutBuilder` + `SafeArea` + responsive padding | Tüm ekranlar |
| Her query için token üretme | ✓ Token cached (TokenStorage), interceptor reuse | `auth_interceptor.dart` |
| Intra OAuth2 | ✓ Authorization Code + PKCE | `auth_service.dart` |
| `.env` + gitignore | ✓ | `.env` + `.gitignore` |
| **[BONUS]** Token refresh on expiry | ✓ Proaktif + reaktif refresh | `auth_interceptor.dart` |

---

## Güvenlik Notu

- **Token saklama**: `flutter_secure_storage` kullanılır. Android'de `EncryptedSharedPreferences` (AES256-GCM master key, Android Keystore ile korunan).
- **Secret'lar**: `.env` dosyasında, `.gitignore`'da. Git geçmişine asla girmez.
- **OAuth2 PKCE**: `code_verifier` + `code_challenge` otomatik üretilir (flutter_appauth tarafından). Bu, mobile app'lerde tavsiye edilen OAuth flow'udur.
- **HTTPS zorunlu**: `android:usesCleartextTraffic="false"` — yalnızca HTTPS trafiği.
- **Input validation**: Arama inputu regex + length filter ile sınırlanır (`UserRepository.isValidLogin`).

---

## Sorun Giderme

### `Missing .env key` hatası
`.env` dosyan yok veya eksik key var. `.env.example` ile karşılaştır.

### `redirect_uri_mismatch` OAuth hatası
42 intra'daki uygulamanın Redirect URI'si ile `.env`'deki `FORTYTWO_REDIRECT_URI` birbirinin **aynısı** olmalı.

### `License for package Android SDK Platform X not accepted`
```bash
flutter doctor --android-licenses
# Tüm sorulara y cevabı ver
```

### `Android NDK ... required` build hatası
`android/app/build.gradle` içinde `ndkVersion = "26.1.10909125"` olduğundan emin ol. Build sırasında NDK otomatik indirilir.

### `cmdline-tools component is missing`
Android Studio → Settings → Languages & Frameworks → Android SDK → SDK Tools → **Android SDK Command-line Tools (latest)** kutusunu işaretle ve apply et.

### Login ekranından çıkamıyorum (loop)
Token depolama bozulmuş olabilir. Uygulamayı sil-yeniden yükle veya `flutter clean && flutter run`.

---

## Kullanılan Kütüphaneler ve Gerekçeler

Savunmada sorulacak "neden X değil de Y?" sorusuna hazırlık:

| Kütüphane | Gerekçe |
|-----------|---------|
| `flutter_appauth` | OAuth2 + PKCE'yi native düzeyde yönetir. Browser ile güvenli entegrasyon, session temizleme. Alternatifler (`oauth2_client`, manuel webview) daha az güvenli ve bakımı zor. |
| `dio` | Interceptor zinciri ile token refresh'i kodlamak `http` paketine göre çok daha temiz. FormData, Retry, Upload gibi özellikler de hazır. |
| `flutter_secure_storage` | Android Keystore kullanır. SharedPreferences'e göre **hassas veri için şart**. |
| `provider` | Flutter ekibinin resmi olarak önerdiği state management. Bu boyuttaki proje için `riverpod` / `bloc` overkill olur. |
| `go_router` | Declarative navigation + auth guard (`redirect`) + deep linking desteği. Imperative `Navigator.push` yönteminden çok daha sürdürülebilir. |
| `easy_localization` | Basit JSON tabanlı i18n. `flutter_localizations` ile manuel ARB yönetiminden hem hızlı hem okunaklı. |
| `cached_network_image` | Profil fotoğrafları için disk cache — her açılışta network'e gitmez, UX iyi. |
| `flutter_dotenv` | `.env` dosyasını runtime'da okur. Subject gereği credential'lar burada. |

---

## Lisans

Bu proje 42 Network mobil başlangıç projesi olarak yapılmıştır; eğitim amaçlıdır.
