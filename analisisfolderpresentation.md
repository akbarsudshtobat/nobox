# Dokumentasi Pembelajaran UI/Tampilan (`presentation` layer)

Dokumen ini membedah arsitektur bagian *Front-End* dari proyek `nobox_chat_basic` yang berlokasi di dalam folder `lib/presentation`. Di sinilah segala interaksi visual dengan pengguna terjadi.

---

## 1. Tujuan Folder `presentation`
Tujuan utama folder ini adalah mengatur **tampilan visual (UI) dan interaksi langsung pengguna (UX)**. Folder ini bertugas me-*render* komponen-komponen ke layar (seperti tombol, teks, gambar, daftar obrolan) dan menangkap input (seperti ketikan *keyboard* atau usapan layar). 

**Aturan Emas**: Folder `presentation` **tidak boleh** memuat logika bisnis murni, kalkulasi rumit, apalagi menembak (*request*) API langsung. Ia hanya boleh meminta atau "mendengarkan" (*listen*) ke `Provider`.

## 2. Struktur UI: Perbedaan `screens` dan `widgets`
Agar kode tidak menumpuk dalam 1 file raksasa, *Presentation Layer* dibagi menjadi 2 folder utama:
- **`screens` (Layar / Halaman)**: Berisi kelas-kelas besar yang mewakili 1 layar penuh aplikasi. Biasanya kelas di sini menggunakan komponen `Scaffold` (yang punya `AppBar` dan `Body`). File di sini didaftarkan pada rute navigasi.
- **`widgets` (Potongan Komponen)**: Berisi potongan-potongan UI kecil yang sifatnya "bisa dipakai ulang" (*Reusable*). Contohnya adalah bentuk Balon Chat, Dialog konfirmasi, atau Animasi *Loading*.

---

## 3. Daftar Fitur Utama (`screens`)

Aplikasi ini dibagi berdasarkan modul (fitur) di dalam folder `screens`:

### A. Fitur `splash`
- **Fungsi Utama**: Layar pembuka (jeda) ketika aplikasi baru saja di-klik ikonnya dari *Home Screen* HP.
- **Halaman**: `splash_page.dart`.
- **Provider Dominan**: Menggunakan `AuthProvider` untuk memeriksa secara diam-diam apakah pengguna sudah pernah login sebelumnya (Mengecek *Token* di storage).

### B. Fitur `auth`
- **Fungsi Utama**: Pintu gerbang masuk aplikasi untuk keamanan.
- **Halaman**: `login_page.dart`.
- **Provider Dominan**: `AuthProvider`. Berinteraksi menangkap email dan password untuk dilempar ke provider.

### C. Fitur `chat` (Inti Aplikasi)
- **Fungsi Utama**: Menampilkan kotak masuk (Inbox), melihat riwayat obrolan pelanggan, pengaturan kontak, dan mengontrol fungsi tim CS (agen).
- **Halaman Penting**: 
  - `chat_list_page.dart`: Halaman *Inbox* daftar chat.
  - `chat_detail_page.dart`: Ruang interaksi chat untuk 1 kontak tertentu.
  - `contact_info_page.dart`: Halaman profil kontak pelanggan (Tags, Notes, Funnel).
  - `archive_list_page.dart`: Ruang penyimpanan (*Archive*) obrolan yang ditutup/disembunyikan.
- **Provider Dominan**: Mengandalkan **`ChatProvider`** secara masif untuk daftar obrolan & *real-time update*, dan **`ContactDetailProvider`** untuk halaman info sisi kanan.

### D. Fitur `media`
- **Fungsi Utama**: Layar pemutar (*player*) media secara layar penuh (*fullscreen*).
- **Halaman**: `video_player_screen.dart`, `image_viewer_screen.dart`, dll.
- **Provider Dominan**: Mandiri. Biasanya tidak butuh Provider secara mendalam karena hanya menerima parameter URL file lalu menampilkannya.

### E. Fitur `about`
- **Fungsi Utama**: Menampilkan informasi versi aplikasi.
- **Halaman**: `about_page.dart`.

---

## 4. Alur Navigasi (User Journey: Splash -> Auth -> Chat)

1. **Memulai (Splash)**: Layar memunculkan logo perusahaan selama 2 detik. Sistem mengecek *Local Storage*.
2. **Pengecekan (Decision)**:
   - Jika **TIDAK ADA** JWT Token yang tersimpan ➔ Arahkan pengguna ke layar **Auth (Login)**.
   - Jika **ADA** JWT Token (User pernah login) ➔ Langsung lemparkan pengguna melompati Auth menuju **Chat List (Home)**.
3. **Aksi Login (Auth)**: Pengguna memasukkan kredensial. Jika valid, Provider memanggil Service. Saat sukses, layar otomatis dialihkan ke **Chat List (Home)**.
4. **Interaksi (Chat)**: Dari halaman *Home*, pengguna memilih salah satu pesan pelanggan. Aplikasi menumpuk layer baru menggunakan `Navigator.push` menuju **Chat Detail**. Jika pengguna menekan tombol *Back* (Kembali), layar Chat Detail dihancurkan (*pop*), dan pengguna kembali ke beranda.

---

## 5. Analisis Folder `widgets`

Folder ini ibarat "Laci Perkakas" yang berisi berbagai macam jenis komponen:
1. **Balon Pesan & Konten**: `message_bubble_widget.dart` (Logika tampilan bubble kiri/kanan berdasarkan status pengirim), `audio_player_widget.dart` (Pemutar *Voice Note* berbentuk gelombang/slider).
2. **Animasi Kerangka (Skeleton / Shimmer)**: `chat_list_skeleton.dart` & `room_shimmer_widget.dart`. Menampilkan kotak-kotak abu-abu berkedip halus saat aplikasi sedang *Loading* menarik data dari API, supaya pengguna tidak melihat layar kosong melompong.
3. **Pop-up Dialog**: `add_agent_dialog.dart`, `tag_selection_dialog.dart`, `forward_dialog.dart`. Jendela kecil yang mengambang di atas layar saat pengguna ingin mentransfer obrolan ke tim lain atau menambahkan label tag.
4. **Komponen Interaktif**: `voice_recording_bottom_sheet.dart` (Menu usap dari bawah untuk merekam suara), `searchable_dropdown.dart` (Kotak pilih dengan fitur pencarian).
5. **Indikator**: `connection_status_banner.dart` (Pita merah/oranye peringatan jika internet putus atau SignalR terputus).

**Cara Komunikasi Widget dengan Provider**:
- **Membaca Data (Read/Watch)**: Widget mengambil data (misalnya data balon pesan ke-3) dengan membungkus UI menggunakan `Consumer<ChatProvider>` atau memanggil `context.watch<ChatProvider>()`.
- **Melakukan Aksi (Write/Action)**: Saat pengguna menekan "Kirim Pesan", widget mengeksekusi `context.read<ChatProvider>().sendMessage(teks_pesan)`.
- **Hasil Instan (Callback)**: Beberapa Dialog menggunakan metode lempar (*throw back*), seperti `Navigator.pop(context, hasil_pilihan)`, lalu halaman utamanya lah yang bertugas melaporkan hasil pilihan tersebut ke Provider.

---

## 6. Panduan & Urutan Belajar

### Urutan Belajar Folder `presentation`
Sangat diharamkan langsung melompat ke layar Chat. Mulailah secara sistematis:
1. `splash` ➔ File sangat kecil dan logikanya linier.
2. `auth` ➔ Belajar dasar bagaimana `TextFormField` mengirim data.
3. `media` ➔ Melihat bagaimana layar dipanggil dengan membawa *arguments* (Data bawaan).
4. `widgets` ➔ Memahami kotak-kotak kecil penyusun bangunan sebelum merakit gedungnya. (Lihat `message_bubble_widget` dulu).
5. `chat` ➔ Paling belakang. Setelah paham kotak-kotaknya, baru masuk ke layar utamanya.

### Hubungan `presentation` dengan `core` (Data Flow)
`presentation` **bergantung total** pada `core`.
- Tampilan UI (*screens*) memakai warna dari `core/theme`.
- Aturan validasi email di layar *Login* memanggil fungsi dari `core/utils/app_validator.dart`.
- Layar memanggil fungsi di *Provider* (berada di `core/providers`).
- **Penting**: UI **TIDAK PERNAH** tahu keberadaan (*Services* / API / `ApiClient`). Antarmuka hanya menagih data ke Provider seakan-akan Provider adalah sang "pemilik data".

### Tips Memahami Kode UI yang Kompleks (Terutama Chat)
File seperti `chat_detail_page.dart` (bisa mencapai 1000+ baris kode) akan membuat pusing jika dibaca dari atas ke bawah.
1. **Gulir cepat ke bawah** dan cari metode `Widget build(BuildContext context)`. Inilah kerangka utamanya.
2. Temukan pembagian `Scaffold`:
   - `appBar`: Bagian atas layar (Nama Kontak, Foto Profil).
   - `body`: Bagian tengah layar. Biasanya berisi `ListView` (untuk me-looping balon pesan) yang dibungkus dengan komponen `RefreshIndicator`.
   - `bottomNavigationBar` / `bottomSheet`: Area pengetikan teks (`TextField` dan tombol kirim).
3. **Pecah Pikiran**: Jika layar membingungkan, abaikan bagian atas dan bawah, **fokus baca blok `body` saja**, lihat bagaimana ia me-looping data `messages` menjadi barisan komponen `message_bubble_widget`.
4. Pakailah tombol fitur di IDE (Android Studio / VS Code) seperti *Collapse All* untuk melipat baris blok kode agar hierarki (*tree*) *widget*-nya terlihat.
