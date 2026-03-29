# ☕ SeedyCoffee — Panduan Run

## ⚡ Quick Start

### 1. Install dependencies
```powershell
flutter pub get
```

### 2. Isi `.env` dengan API keys kamu

Buka file `.env` di root project. **Format harus JSON persis seperti ini:**
```json
{
  "SUPABASE_URL": "https://xxxxxxxxxxxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "GEMINI_API_KEY": "AIzaSy...",
  "GEMINI_MODEL": "gemini-2.5-flash",
  "FONNTE_TOKEN": "",
  "MIDTRANS_CLIENT_KEY": "",
  "MIDTRANS_IS_PRODUCTION": "false",
  "APP_ENV": "development"
}
```

> **Supabase** → `supabase.com → Settings → API`
> - `SUPABASE_URL` = "Project URL" (mulai dengan `https://`)
> - `SUPABASE_ANON_KEY` = "anon public" key (mulai dengan `eyJ`)
>
> **Gemini** → `aistudio.google.com → Get API Key`
> - `GEMINI_API_KEY` = key yang mulai dengan `AIza`

### ⚠️ Jangan sampai salah:
- Nilai harus dalam **tanda kutip ganda** `"value"`
- Tidak boleh ada spasi/baris kosong di dalam nilai key
- Copy paste key langsung dari dashboard, jangan ketik manual

---

## 🚀 Cara Run

### Chrome (Web) — untuk development
```powershell
flutter run -d chrome --dart-define-from-file=.env
```

### Android Emulator
```powershell
flutter run -d emulator-5554 --dart-define-from-file=.env
```

### Android HP (USB)
```powershell
flutter run --dart-define-from-file=.env
```
> Pilih nomor device dari daftar yang muncul

### Build APK
```powershell
flutter build apk --dart-define-from-file=.env
flutter build apk --release --dart-define-from-file=.env
```

---

## 🔑 Demo Accounts (fallback tanpa Supabase)

| Role     | Email             | Password |
|----------|-------------------|----------|
| Customer | budi@demo.com     | budi123  |
| Admin    | admin@demo.com    | admin123 |
| Kasir    | kasir@demo.com    | kasir123 |

---

## 🐛 Troubleshooting

| Error | Penyebab | Solusi |
|-------|----------|--------|
| `Invalid API key` | Anon Key salah/kosong | Cek `SUPABASE_ANON_KEY` di `.env`, harus dimulai `eyJ` |
| `NoSuchMethodError: subtitle` | File lama belum di-replace | Replace **semua** file dari ZIP terbaru |
| Gemini masih demo mode | Lupa `--dart-define-from-file` | Wajib tambah flag saat `flutter run` |
| Upload foto gagal | Supabase Storage belum aktif | Cek bucket `menu-images` dan `banners` ada di Storage |
| `flutter pub get` error | Koneksi internet | Coba lagi |

---

## 📁 Struktur Direktori
```
seedycoffee/
├── .env                 ← API keys (JANGAN di-push ke GitHub)
├── .env.example         ← Template
├── .gitignore
├── pubspec.yaml
├── README.md
├── assets/
│   ├── images/BannerTest.png
│   └── icons/app_icon.svg
└── lib/
    ├── main.dart
    ├── core/            config, constants, theme, utils
    ├── models/          user, menu, banner, order, cart, notification
    ├── services/        auth, menu, banner, order, notification,
    │                    storage, whatsapp, ai, analytics
    ├── providers/       app_provider.dart
    ├── widgets/         brew_button, brew_snackbar, etc
    └── screens/
        ├── shared/      splash
        ├── auth/        login + OTP
        ├── user/        home, cart, menu_detail, order_detail,
        │                notification, profile
        ├── admin/       menu, banner, promo_wa, dashboard (AI)
        └── kasir/       kasir_screen
```
