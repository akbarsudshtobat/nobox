# Analisis Fitur About & Auth

Dokumen ini membedah isi dari folder `about` dan `auth` di dalam `lib/presentation/screens`. Pembahasan difokuskan pada bagaimana antarmuka (UI) dibangun, interaksinya dengan `Provider`, serta kualitas kode (*code smell*).

---

## 1. Folder: about

### File: `about_page.dart`
- **Fungsi Utama:** Layar profil dan informasi aplikasi (sejenis halaman "Tentang Kami"). Menampilkan deskripsi aplikasi, versi, teknologi pendukung, jumlah fitur, dan nama *developer*.
- **Komponen UI:** 
  - Dibangun menggunakan `Scaffold` standar.
  - Terdapat ikon aplikasi kustom menggunakan `Container` dengan efek gradien dan bayangan (shadow) elegan.
  - Widget yang menonjol adalah metode *helper* `_buildInfoCard()` yang membuat kartu informasi (seperti Teknologi, Platform, Developer) menjadi rapi dan seragam. 
  - Mendukung adaptasi *Dark Mode* (`isDark`) secara otomatis.
- **Data Statis vs Dinamis:** 
  - **Seluruh info di sini bersifat Statis (Hardcoded)!** 
  - Teks seperti `'Versi 1.0.0'` diketik langsung di dalam kode. Ini berarti jika aplikasi diperbarui ke versi 1.0.1, developer harus ingat untuk mengubah angka ini secara manual. 
  - *(Best Practice: Seharusnya menggunakan library `package_info_plus` agar nomor versi dibaca otomatis secara dinamis dari `pubspec.yaml` atau build Gradle).*

---

## 2. Folder: auth

### File: `login_page.dart`
- **Fungsi Utama:** Pintu gerbang utama. Menangani formulir akses masuk (login) pengguna, dilengkapi dengan fitur "ingat email" (*Remember Me*) dan tombol pengganti tema (terang/gelap) di sudut layar.
- **Interaksi Provider:** 
  - Halaman ini "mendengarkan" dua provider: **`ThemeProvider`** (untuk mengganti warna *background* dan teks secara langsung) dan **`AuthProvider`** (untuk proses login).
  - Saat tombol *Sign In* ditekan, fungsi `auth.login(_email, _password)` dipanggil. Tombol juga menempel pada `auth.isAuthenticating` untuk memunculkan indikator berputar (*loading*) dan mencegah tombol ditekan berkali-kali.
- **Validasi:** 
  - Fitur formulirnya (dibungkus dalam `Form(key: _formKey)`) bergantung pada folder utils.
  - Pada input email, disematkan kode `validator: AppValidator.validateEmail`.
  - Pada input sandi, disematkan `validator: AppValidator.validatePassword`. Tombol kirim tidak akan bereaksi jika validasi ini gagal (misal: format email salah).
- **Alur Post-Login:** 
  - Begitu API merespons dengan kesuksesan, aplikasi menghancurkan riwayat layar login agar tidak bisa di-*back* dan langsung berpindah ke layar utama menggunakan perintah: `Navigator.pushReplacementNamed(context, AppRoutes.home)`.
- **Error Handling:** 
  - Jika otentikasi ditolak (misal: *password salah* atau *internet putus*), halaman akan memunculkan spanduk peringatan merah di bagian bawah menggunakan `ScaffoldMessenger.of(context).showSnackBar()`.

---

## 3. Hubungan ke Core (Arsitektur Bersih)

Alur arsitektur login dalam aplikasi ini sudah mencerminkan *Separation of Concerns* (Pemisahan Tugas):
1. **Layar UI (`login_page.dart`)** menangkap input ketikan dari pengguna.
2. UI menyodorkan input tersebut ke **`AuthProvider`** (di layer `core/providers`). UI **sama sekali tidak tahu** menahu kemana data ini akan pergi selanjutnya.
3. `AuthProvider` menunjuk bawahannya, yaitu **`AuthService`** (di layer `core/services`).
4. `AuthService` membungkus email & sandi menjadi format JSON (`LoginRequest`), kemudian melemparkannya menggunakan **`ApiClient`** (Dio) menuju server backend.
5. Jika server menjawab `HTTP 200 OK`, `AuthService` membaca Token JWT yang masuk, memberikannya kembali ke `AuthProvider`.
6. `AuthProvider` menyimpan token ke lemari memori HP (Storage), mengubah status login, lalu memberitahu layar UI bahwa "Login sukses!". UI menyingkirkan *loading* dan berpindah layar.

---

## 4. Potensi *Code Smell* / Bug (Kebocoran Logika)

Meskipun secara umum kode UI ini rapi, ada **Satu "Code Smell" (Kebocoran Logika) yang cukup fatal** di dalam `login_page.dart`:

Terdapat baris kode ini saat login berhasil:
```dart
// Start SignalR connection for real-time messaging
SignalRService().connect();
Navigator.pushReplacementNamed(context, AppRoutes.home);
