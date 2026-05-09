# Analisis Fitur Splash: Sang Penentu Alur

Halo! Selamat datang di sesi bedah fitur dasar. Kali ini kita akan membedah folder `splash` yang isinya `splash_page.dart`. Layar ini mungkin terlihat simpel (cuma logo muter-muter), tapi secara fungsional, ini adalah **Gerbang Utama** atau "penjaga pintu" yang menentukan nasib *user*: ke beranda atau ke halaman login?

Mari kita bedah secara mendalam.

---

## 1. Fungsi Utama

- **Mengapa ini jadi titik masuk pertama?**
  Setelah `main.dart` dijalankan oleh sistem operasi Android/iOS, aplikasi butuh waktu sepersekian detik untuk memuat *resource* inti ke memori (RAM). Daripada layar pengguna *blank* putih/hitam (yang bikin kelihatan *laggy*), kita menampilkan *Splash Screen* sebagai "jeda visual yang cantik" agar *user* tidak kabur duluan.
- **Aktivitas di Belakang Layar:**
  Sembari *user* ngeliatin logo berputar, *splash screen* sibuk bekerja kasar. Ia secara serentak mengeksekusi tiga hal menggunakan `Future.wait`:
  1. Ngecek status otentikasi (Token Login).
  2. Memuat preferensi Tema (Terang/Gelap).
  3. Memuat Setelan Chat (Background/Wallpaper *user*).

---

## 2. Logika Navigasi (The Router Logic)

- **Cara cek status Login & Provider yang bertugas:**
  Halaman ini **tidak** mengecek *database* atau `SecureStorage` secara mandiri. Ia menyuruh mandornya, yaitu `AuthProvider`, dengan perintah: `auth.checkAuth()`. 
- **Percabangan (If-Else):**
  Setelah mandor selesai mengecek memori HP, ia melaporkan hasilnya via variabel `auth.isLoggedIn`.
  - Jika **`true`**: *User* sudah punya "tiket" (Token JWT). Halaman akan berpindah ke `AppRoutes.home` (Inbox). Selain itu, sistem diam-diam menyalakan mesin *socket* (`SignalRService().connect()`) dengan jeda (*delay*) 2 detik agar tidak bikin macet proses perpindahan layar.
  - Jika **`false`**: Tiket hangus atau tidak ada. *User* ditendang ke `AppRoutes.login`.
  - **Fallback Aman:** Jika HP tiba-tiba *error* / memori rusak saat proses pengecekan (masuk ke blok `catch(e)`), aplikasi otomatis melempar *user* kembali ke `AppRoutes.login`. Ini pertahanan yang *solid*.

---

## 3. Komponen UI & Animasi

- **Visual yang Ditampilkan:**
  Hanya komponen statis ringan. Gambar logo (`Image.asset`), teks judul ("NoBoxChat"), teks *subtitle*, dan indikator berputar (`CircularProgressIndicator`). Menariknya, logo ini dibungkus widget `Hero(tag: 'app_logo')`—artinya saat pindah ke halaman *Login*, logo ini akan "terbang" bertransisi dengan mulus ke posisi logo di halaman *Login*.
- **Isu Risiko Kinerja (*Hardcoded Delay*):**
  Ada satu baris kode di sini yang **Cukup Berbahaya** untuk kenyamanan *user* (*User Experience* / UX):
  ```dart
  await Future.delayed(const Duration(seconds: 5));
  ```
  **Kenapa berisiko?** Meskipun `Future.wait` untuk memuat data (Theme, Auth, Config) mungkin selesai dalam waktu 0.5 detik, baris kode ini **memaksa** layar *splash screen* mandek (*freeze*) selama 5 detik mutlak. Akibatnya aplikasi terasa sangat berat dan lelet saat pertama kali dibuka. 
  *(Saran untuk Junior: Gunakan delay maksimal 1.5 detik saja untuk efek transisi estetika, jangan kelamaan!)*

---

## 4. Hubungan dengan Layer Core

Sesuai dengan prinsip *Clean Architecture* (Kode yang Bersih), *Splash Screen* sangat sopan dan **tidak mau tahu** urusan dapur.
- Layar ini **TIDAK** pernah mengimpor `FlutterSecureStorage` atau `AuthService`.
- Semua urusan *"Cek apakah token ada di memori"* sepenuhnya didelegasikan (diserahkan) kepada `AuthProvider` di layer Core. 
- Hubungan ini memastikan bahwa jika besok-besok *Storage* aplikasi dipindah dari *SecureStorage* ke *SharedPrefs* (atau sebaliknya), UI *Splash Screen* sama sekali tidak perlu diubah.

---

## 5. Tips & Best Practice

Perhatikan baris navigasi ini:
```dart
Navigator.pushReplacementNamed(context, AppRoutes.home);
```

- **Kenapa menggunakan `pushReplacementNamed`?**
  Dalam sistem navigasi ponsel (terutama Android), setiap layar ditumpuk seperti tumpukan piring (*Stack*). Jika kita memakai navigasi standar `Navigator.pushNamed`, maka layar *Splash* akan menjadi piring terbawah, dan layar *Home* ditumpuk di atasnya.
- **Akibat jika salah pakai:**
  Jika kita pakai *push* biasa, lalu di halaman *Home* si *user* iseng menekan **Tombol Back fisik** di HP Android, mereka akan terlempar kembali ke layar *Splash Screen*! (Lalu *Splash Screen* muter lagi, lalu *user* dilempar ke *Home* lagi. Terjebak dalam *loop*).
- **Fungsi Replacement:**
  Dengan `pushReplacementNamed`, "Piring" *Splash Screen* dicabut dan **dibuang** dari memori, barulah "Piring" *Home* diletakkan. Sehingga ketika *user* menekan tombol *Back* di *Home*, aplikasinya akan *exit* (keluar/tutup) sebagaimana mestinya aplikasi normal bekerja. 

Paham kan seberapa krusialnya *Splash Screen* walau cuma tampil 5 detik? 
Ada pertanyaan atau mau kita lanjut bedah komponen presentasi yang lain?
