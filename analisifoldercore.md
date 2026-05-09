# Dokumentasi Ringkasan Arsitektur Folder `core`

Dokumen ini merangkum analisis keseluruhan dari folder `lib/core` pada proyek `nobox_chat_basic`. Folder `core` merupakan jantung dan pondasi utama dari aplikasi Flutter ini, tempat di mana seluruh logika bisnis, pengaturan data, jaringan, dan utilitas pendukung disatukan.

---

## 1. Peran Utama Folder `core`
Dalam arsitektur aplikasi ini, folder `core` berperan sebagai **Mesin Penggerak Utama (The Engine)**. Jika folder `ui` (User Interface) diibaratkan sebagai bodi mobil dan kursi penumpang, maka `core` adalah mesin, transmisi, dan tangki bahan bakarnya.

Folder `core` secara ketat memisahkan tampilan (UI) dari logika (Logic). Segala proses yang berkaitan dengan pengolahan data, penyambungan ke server internet, penyimpanan sesi login, hingga perhitungan state management semuanya dikerjakan murni di dalam folder `core`. 

Tujuan pemisahan ini adalah untuk menciptakan **Clean Architecture**, di mana kode logika bisa di-test (diuji) secara independen tanpa harus membuka layar UI, dan jika tampilan UI dirombak total di masa depan, logika di dalam `core` tidak perlu ikut diubah.

---

## 2. Hubungan Antar Komponen (Model, Providers, Services, Theme, Utils)

Di dalam `core`, komponen-komponen saling bekerja sama membentuk sebuah rantai eksekusi (*Data Flow*):

1. **`models`**: Berperan sebagai **Cetakan Data**. Saat data mentah (JSON) turun dari server, ia akan dicetak menjadi objek kuat (*strongly-typed*) menggunakan Model agar mudah dibaca dan aman dari *typo*.
2. **`services`**: Berperan sebagai **Kurir / Penghubung Eksternal**. Tugasnya murni berkomunikasi dengan dunia luar (seperti memanggil REST API backend, membuka WebSocket SignalR, atau menangani Notifikasi HP). Setelah mengambil JSON dari luar, *Service* menggunakan `models` untuk mencetak JSON tersebut.
3. **`providers`**: Berperan sebagai **Manajer State (State Management)**. *Provider* adalah bos yang memerintah *Service* ("Tolong ambilkan data chat!"). Setelah *Service* memberikan data (dalam bentuk `models`), *Provider* menyimpan data tersebut di dalam variabelnya, kemudian berteriak (`notifyListeners`) untuk menyuruh UI me-refresh layarnya agar data terbaru tampil.
4. **`theme`**: Berperan sebagai **Buku Aturan Visual**. Menyediakan panduan warna dan gaya konsisten agar UI (yang berada di luar folder `core`) dan komponen di dalam `core` (seperti Notifikasi) bisa menggunakan palet desain yang sama.
5. **`utils`**: Berperan sebagai **Kotak Perkakas (Toolbox)**. Menyediakan fungsi-fungsi bantuan kecil (seperti rute peta aplikasi, validasi format email, key global) yang siap digunakan kapan saja oleh `providers`, `services`, maupun `ui` tanpa saling mengikat (*loosely coupled*).

**Alur Ringkas (Siklus)**: 
*(Tombol di UI ditekan)* ➔ `Provider` memproses state ➔ `Provider` memanggil `Service` ➔ `Service` menggunakan `Utils` & `app_config` untuk mengakses API ➔ API mengembalikan JSON ➔ `Service` mencetak JSON jadi `Model` ➔ `Provider` menerima `Model` dan memperbarui State ➔ UI meminjam `Theme` untuk menampilkan `Model` tersebut.

---

## 3. Penjelasan Khusus `app_config.dart`

File `lib/core/app_config.dart` memiliki kedudukan istimewa karena berada langsung di *root* folder `core`.

### A. Apa fungsinya?
Fungsinya adalah sebagai **Pusat Konfigurasi Lingkungan (Environment Center)**. File ini berisi sekumpulan variabel statik (konstanta) yang bersifat global. Ia mencegah tersebarnya "String Ajaib" (*Magic Strings*) di berbagai tempat di dalam kode. Jika alamat server API berubah, developer tidak perlu mencari dan mengubahnya di 10 file yang berbeda, melainkan cukup mengganti 1 baris kode di dalam `app_config.dart`.

### B. Konfigurasi apa saja yang disimpannya?
1. **Base URL**: Alamat induk server backend (contoh: `https://id.nobox.ai/`).
2. **Endpoint API**: Ratusan string jalur spesifik menuju API (contoh: `inboxUrl`, `sendMessageEndpoint`, `updateChatroomEndpoint`).
3. **Key Penyimpanan Lokal (Storage Keys)**: Kunci (*key*) untuk menyimpan dan membaca data di memori HP, seperti `auth_token` untuk token JWT, dan `last_username`.
4. **Konstanta Aplikasi**: Pengaturan logika dasar seperti `messagePageSize = 20` (jumlah pesan maksimum yang dimuat dalam satu kali *scroll* halaman).

### C. Di mana file ini dipanggil saat aplikasi pertama kali berjalan?
File ini murni berisi variabel `static const` sehingga **tidak perlu diinisialisasi atau "dijalankan" secara khusus**. File ini langsung **dibaca (*accessed*)** secara otomatis kapan pun dipanggil.
- Saat aplikasi pertama kali menyala dan me-*load* `ApiClient` (sebagai *Singleton*), `ApiClient` akan langsung membaca `AppConfig.baseUrl` untuk menyiapkan koneksi internet dasar.
- Saat Splash Screen muncul, `AuthProvider` akan otomatis membaca `AppConfig.tokenKey` untuk membongkar brankas memori HP mencari sisa sesi login sebelumnya.
