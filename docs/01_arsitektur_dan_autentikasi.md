# Bagian 1: Arsitektur Project & Alur Autentikasi (Splash & Login)

Dokumen ini menjelaskan struktur dasar project **NoBox Chat Basic**, arsitektur kode, sistem manajemen state, routing, serta detail implementasi alur masuk aplikasi (Splash Screen & Login Page).

---

## 1. Arsitektur & Struktur Folder Project

Project ini dibangun dengan arsitektur berbasis fitur yang memisahkan antara logika bisnis (*core*) dan tampilan (*presentation*).

```text
lib/
├── core/                   # Logika Bisnis & Layanan
│   ├── model/              # Model data (Message, Conversation, dll)
│   ├── providers/          # State Management (Provider)
│   ├── services/           # Penghubung API & Protokol (SignalR, API Client)
│   ├── theme/              # Pengaturan Tema (AppTheme)
│   └── utils/              # Helper & Router (AppRoutes, AppValidator)
│
├── presentation/           # Tampilan Antarmuka (UI)
│   ├── screens/            # Halaman utama aplikasi (Splash, Auth, Chat, dll)
│   └── widgets/            # Komponen UI yang dapat digunakan kembali (reusable widgets)
│
└── main.dart               # Entry point utama aplikasi
```

### Inisialisasi Aplikasi (`lib/main.dart`)
*   **Letak File:** [`lib/main.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/main.dart)
*   **Peran:** Sebagai titik masuk utama aplikasi. Di sini dilakukan konfigurasi multi-provider (`MultiProvider`) agar seluruh state provider seperti `AuthProvider`, `ChatProvider`, `ThemeProvider`, dan lainnya dapat diakses secara global di seluruh halaman aplikasi.
*   **Cara Kerja:**
    1.  Menjalankan `WidgetsFlutterBinding.ensureInitialized()` untuk memastikan framework Flutter siap.
    2.  Membungkus `MyApp` dengan `MultiProvider` yang memuat semua state manager.
    3.  Mengatur rute navigasi menggunakan konfigurasi rute di `AppRoutes`.

---

## 2. Fitur: Splash Screen (Halaman Awal)

### A. Tampilan UI
*   **Tampilan:** Layar latar belakang putih bersih, menampilkan logo aplikasi (`assets/nobox2.png`), teks nama aplikasi **"NoBox Chat"**, *subtitle* **"Ai Powered Chatbot"**, dan indikator pemuatan melingkar (*CircularProgressIndicator*).
*   **Letak File:** [`lib/presentation/screens/splash/splash_page.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/splash/splash_page.dart)

### B. Penyambungan & Logika
*   **Koneksi State:** Menggunakan `context.read<AuthProvider>()`, `context.read<ThemeProvider>()`, dan `context.read<ChatSettingsProvider>()`.
*   **Cara Kerja:**
    1.  **Inisialisasi (`initState`):** Saat pertama kali dibuka, layar memanggil fungsi `_checkLogin()`.
    2.  **Pemuatan Paralel (`Future.wait`):** Memuat status autentikasi (`checkAuth()`), konfigurasi tema (`loadTheme()`), dan preferensi obrolan (`loadSettings()`) secara bersamaan dengan batas waktu (*timeout*) 5 detik.
    3.  **Jeda Estetika:** Memberikan jeda minimal 5 detik (`Future.delayed`) agar transisi terasa halus dan logo sempat terbaca oleh pengguna.
    4.  **Navigasi Dinamis:**
        *   **Jika sudah Login (`auth.isLoggedIn == true`):** Mengarahkan pengguna langsung ke halaman Beranda/Daftar Chat (`AppRoutes.home`) dan menginisialisasi koneksi real-time chat `SignalRService().connect()` secara tertunda 2 detik agar tidak mengganggu performa rendering awal.
        *   **Jika belum Login:** Mengarahkan pengguna ke halaman Login (`AppRoutes.login`).

---

## 3. Fitur: Autentikasi (Halaman Login)

### A. Tampilan UI
*   **Tampilan:** Form masuk yang berpusat di tengah layar. Berisi logo aplikasi, teks branding, input teks **Username (Email)**, input teks **Password** dengan tombol tampilkan/sembunyikan kata sandi (ikon mata), kotak centang **"Remember Email"**, tombol masuk biru **"Sign In"**, dan tombol pengubah tema (Dark/Light mode) di pojok kanan atas.
*   **Letak File:** [`lib/presentation/screens/auth/login_page.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/auth/login_page.dart)

### B. Penyambungan & Logika
*   **Koneksi State & Service:** Terhubung ke `AuthProvider` untuk mengeksekusi request login, `ThemeProvider` untuk toggle tema, dan `SignalRService` untuk mengaktifkan koneksi pesan instant setelah login berhasil.
*   **Cara Kerja:**
    1.  **Ingat Email (`_loadRememberedEmail`):** Di method `initState()`, aplikasi mengambil data email yang pernah disimpan di memori perangkat. Jika ada, kolom email langsung terisi otomatis dan status checkbox "Remember Email" menjadi aktif.
    2.  **Validasi Form:** Saat tombol "Sign In" diklik, form divalidasi terlebih dahulu melalui `_formKey.currentState!.validate()`. Pengecekan format email dan minimal panjang password dilakukan oleh class pembantu [`lib/core/utils/app_validator.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/core/utils/app_validator.dart).
    3.  **Proses Kirim Data (`_login`):**
        *   Status tombol berubah menjadi *loading* (CircularProgressIndicator) melalui state `auth.isAuthenticating` agar mencegah double click.
        *   Mengirim request login ke backend via `auth.login(email, password)`.
    4.  **Penanganan Respons:**
        *   **Jika Sukses:** Jika kotak "Remember Email" dicentang, email disimpan ke penyimpanan lokal. Jika tidak, data email dihapus. Aplikasi lalu menjalankan koneksi real-time chat `SignalRService().connect()` dan berpindah ke halaman utama (`AppRoutes.home`).
        *   **Jika Gagal:** Menampilkan pop-up peringatan merah (*SnackBar*) di bagian bawah layar berisi pesan kegagalan dari server.
