# Dokumentasi Pembelajaran Konfigurasi, Theme, dan Utils `nobox_chat_basic`

Dokumen ini membedah isi dari folder `lib/core/theme`, `lib/core/utils`, dan file inti `lib/core/app_config.dart`. Bagian ini merupakan pilar penyangga (*supporting pillar*) yang menjembatani tampilan (UI), rute, dan pengaturan jaringan.

---

## 1. Tujuan Folder `theme`
Folder ini bertujuan sebagai **pusat kendali identitas visual aplikasi**. Segala sesuatu yang berkaitan dengan warna *branding*, gaya tulisan (Tipografi), bentuk tombol, atau skema mode gelap (Dark Mode) dan terang didefinisikan di sini. Dengan memusatkan styling, aplikasi akan memiliki tampilan yang konsisten dan mudah diubah cukup dari 1 file saja.

## 2. Tujuan Folder `utils`
Kata *Utils* merupakan singkatan dari *Utilities* (perkakas). Folder ini bertujuan menyimpan **fungsi-fungsi kecil, statis, dan independen** yang bisa digunakan secara berulang-ulang dari mana saja. File-file di sini murni berupa bantuan (*helper*) dan **tidak boleh** memuat logika bisnis rumit atau melakukan request API.

---

## Analisis File per File

### 1. `app_config.dart` (Di root folder `core`)
- **Fungsi Utama**: Menjadi pusat seluruh konfigurasi vital *(Environment Variables)*. Disinilah *Base URL* server, daftar endpoint API, dan konstanta penyimpanan lokal didaftarkan.
- **Method/Variabel Penting**: `baseUrl`, `inboxSendEndpoint`, `tokenKey`.
- **Dipakai Di**: Di-*import* oleh semua file `services` (seperti `ChatService`, `ApiClient`) dan provider yang butuh membaca key Shared Preferences.
- **Mempengaruhi**: **Seluruh Aplikasi**. Jika `baseUrl` salah 1 karakter saja, seluruh aplikasi akan mati (gagal terhubung ke internet).
- **Potensi Masalah / Code Smell**: Penggunaan *Hardcoded URL* (URL diketik langsung). Sebaiknya menggunakan library seperti `flutter_dotenv` untuk memisahkan URL antara tahap *Development* (pengembangan) dan *Production* (publikasi).
- **Status**: **SANGAT KRUSIAL**

### 2. `app_routes.dart` (Folder `utils`)
- **Fungsi Utama**: Menyimpan daftar string (URL) untuk navigasi perpindahan layar. Daripada mengetik `Navigator.pushNamed(context, '/login')` berulang kali, kita menggunakan `AppRoutes.login` untuk menghindari salah ketik (*typo*).
- **Method/Variabel Penting**: Variabel statik seperti `splash = '/'`, `home = '/home'`.
- **Dipakai Di**: Di dalam `main.dart` (pada properti `routes`) dan ketika memanggil perpindahan halaman via `Navigator`.
- **Mempengaruhi**: Pemetaan layar (Screen Mapping).
- **Potensi Masalah / Code Smell**: Aman. Sangat direkomendasikan polanya.
- **Status**: **KRUSIAL**

### 3. `app_validator.dart` (Folder `utils`)
- **Fungsi Utama**: Melakukan pengecekan validitas input ketikan pengguna (misal: apakah format email ada tanda `@`-nya? apakah password cukup panjang?).
- **Method/Variabel Penting**: `validateEmail()`, `validatePassword()`.
- **Dipakai Di**: Formulir (`TextFormField`) khususnya di halaman `LoginPage`.
- **Mempengaruhi**: Pintu masuk pengguna sebelum menekan tombol login.
- **Potensi Masalah / Code Smell**: Validasi password minimal 8 karakter di-*hardcode*. Jika *business rule* dari backend berubah (misal diperbolehkan minimal 6 huruf), maka file ini juga harus diubah.
- **Status**: **PENDUKUNG**

### 4. `globals.dart` (Folder `utils`)
- **Fungsi Utama**: Menyediakan `GlobalKey` agar aplikasi dapat melakukan aksi tertentu **tanpa membutuhkan `context`**. Sangat bermanfaat untuk Background Service.
- **Method/Variabel Penting**: `navigatorKey` (Untuk pindah halaman), `scaffoldMessengerKey` (Untuk memunculkan *Snackbar / Toast* error).
- **Dipakai Di**: Di *inject* ke root `MaterialApp` di `main.dart`, lalu digunakan contohnya oleh `AuthProvider` saat harus melempar (mendepak) pengguna otomatis ke layar login karena sesi kedaluwarsa.
- **Mempengaruhi**: Eksekusi *background action*.
- **Potensi Masalah / Code Smell**: Harus berhati-hati, memanggil fungsi via global key bisa error (*Null Pointer*) jika key belum dipasang secara utuh oleh Flutter saat awal aplikasi menyala.
- **Status**: **PENDUKUNG**

### 5. `app_theme.dart` (Folder `theme`)
- **Fungsi Utama**: Mengumpulkan palet warna (Color Palette) yang menjadi gaya khas aplikasi.
- **Method/Variabel Penting**: `primaryColor`, `darkSurface`, `textPrimary`.
- **Dipakai Di**: Ke seluruh UI komponen widget (seperti warna tombol, warna *bubble chat*, dll).
- **Mempengaruhi**: Visual (*Look and Feel*).
- **Potensi Masalah / Code Smell**: Cenderung *statis*. Proyek ini sepertinya tidak membungkus warnanya menggunakan `ThemeData` native milik Flutter, melainkan hanya menembak variabel warna langsung (`color: AppTheme.primaryColor`). Meskipun berhasil, hal ini akan sedikit menyulitkan jika nantinya warna ingin diubah otomatis (*dynamic color* / *Material You*).
- **Status**: **PENDUKUNG**

---

## Fokus Khusus

### A. Flow Navigasi & Struktur Aplikasi (`app_routes.dart`)
Berdasarkan daftar rute, logika berpindah (*Flow Navigasi*) aplikasi ini adalah sebagai berikut:
1. **Layar Masuk (`/`)**: Aplikasi selalu dibuka dengan `SplashPage`. Di layar ini, sistem mengecek *Token* yang ada di lokal (Via `AuthProvider.checkAuth()`).
2. **Pengecekan Cabang**:
   - Jika Token/Sesi **Kosong/Gagal**: Navigasi diubah ke halaman **Login (`/login`)**.
   - Jika Token **Tersedia/Valid**: Navigasi langsung dilempar ke halaman **Home (`/home`)**.
3. **Halaman Utama (`/home`)**: Inilah beranda aplikasi (List Kontak / Inbox). Dari sini pengguna bisa membuka percakapan ke:
   - **Layar Obrolan (`/chat-detail`)**: Tempat mengirim dan membaca pesan.
   - **Layar Obrolan Arsip (`/archived-chats`)**: Melihat pesan yang telah masuk brankas/disembunyikan.

### B. Sistem Tema (`app_theme.dart`)
Theme dalam aplikasi ini dibuat sangat sederhana berupa sekumpulan "Konstanta Warna". 
- Warna Utama (`primaryColor`): Biru (`#1E88E5`).
- Warna Dasar Gelap (`darkSurface`): Hitam Abu-abu (`#1E1E1E`).

Tidak ada penetapan ukuran font atau jenis font spesifik, yang berarti aplikasi sepenuhnya menggunakan Font bawaan OS (Roboto di Android, SF Pro di Apple) dengan ukuran default dari Flutter.

---

## Panduan Belajar

### Urutan Belajar Folder Core
Agar mudah memahami *pondasi* aplikasi tanpa melihat logika fiturnya dulu, baca kode dengan urutan:
1. `app_config.dart` (Pahami alamat server API mana yang sedang dituju oleh aplikasi ini).
2. `app_routes.dart` (Pahami peta halamannya).
3. `app_theme.dart` (Pahami warna-warna kuncinya).
4. `globals.dart` (Pahami "jalan pintas" navigasinya).
5. `app_validator.dart` (Pahami aturan loginnya).

### File Paling Krusial
**`app_config.dart`**. File ini adalah "Kompas" aplikasi. Jika aplikasi lain ingin menyalin proyek ini (*White Labeling*), mereka 90% cukup mengganti isi *URL API* di file ini, dan aplikasi bisa langsung berjalan di server yang berbeda.

### Tips Memahami Struktur Aplikasi dari Routes
Saat mulai memperbaiki atau membuat fitur di proyek Flutter milik orang lain, **jangan langsung membaca folder `UI` atau `Widget`**. 
1. Bukalah selalu file **Routes** (seperti `app_routes.dart` atau file router milik *GoRouter*). 
2. Dari situ, lihat file mana yang diikat pada rute `/` (beranda). 
3. Lacak (*Trace*) kode di halaman beranda itu dan amati tombol apa saja yang melakukan `Navigator.push` ke halaman lain. Ini seperti membaca "Peta Gedung" sebelum anda masuk dan mencari letak ruangan.
