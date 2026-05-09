# Analisis Fitur Media Viewer

Halo! Mari kita bedah bareng arsitektur `presentation/screens/media`. Folder ini bertugas khusus sebagai panggung utama untuk menampilkan foto dan memutar video secara *full-screen*. 

Secara konsep arsitektur, layar-layar di sini didesain sebagai **"Dumb UI" (UI Bodoh)**—artinya mereka tidak punya logika koneksi ke database atau API. Mereka cuma nerima *"lemparan"* URL dari layar obrolan (ChatDetail) dan fokus merender visual sebaik mungkin.

---

## 1. Daftar Halaman

Di folder ini, cuma ada tiga aktor utama:

- **`image_viewer_screen.dart`**: Betul tebakanmu, ini khusus untuk **Satu Gambar**. Parameter utamanya cuma `imageUrl` dan `caption`. Layar ini biasa dipanggil kalau *user* nge-tap satu foto saja di balon *chat*.
- **`image_gallery_viewer_screen.dart`**: Nah, ini versi galeri (*swipe*). Menggunakan `PageView.builder`, layar ini menerima sekumpulan gambar (`List<ImageGalleryItem>`) sehingga *user* bisa nyapu jari (*swipe*) ke kiri dan kanan untuk melihat kumpulan foto (mirip *story* atau galeri WA). Parameter `initialIndex` mengatur foto mana yang pertama muncul.
- **`video_player_screen.dart`**: Panggung khusus video. Menerima `videoUrl`, mengunduh sekilas (*buffer*), lalu menampilkannya dengan *overlay control* (Play, Pause, Slider Progres) yang dibuat *custom* (merakit sendiri, bukan pakai *plugin* UI instan).

---

## 2. Bedah Teknis: Image Handling

Gimana cara aplikasi nanganin gambar?

- **Pemuatan URL (Loading):** Sayangnya, kode ini **TIDAK** pakai library caching pihak ketiga seperti `CachedNetworkImage`. Dia murni mengandalkan widget bawaan Flutter: `Image.network()`. 
  - *Catatan Senior:* Ini punya potensi kelemahan. Walau Flutter punya *image cache* internal di level *engine*, ia cepat hangus. Kalau *user* nutup gambar, lalu buka gambar itu lagi besok, ada kemungkinan memori HP akan *download* ulang gambarnya. Jika dibiarkan untuk *app* chatting besar, kuota user bakal boros.
- **Pinch to Zoom:** **Ya, sudah didukung!** Gambar dibungkus dengan mantap menggunakan widget **`InteractiveViewer`**. Widget sakti bawaan Flutter ini otomatis ngasih fitur *pinch-to-zoom* (cubit dua jari buat perbesar) dan *pan* (geser gambar saat sedang di-zoom) tanpa perlu bikin kalkulasi matriks ribet.
- **Caption:** Di *Image Viewer*, *caption* cuma di-render pakai `Container` biasa (kasih warna hitam tembus pandang 54%) di bagian paling bawah layar menggunakan `Column`. Sangat simpel tapi efektif.

---

## 3. Bedah Teknis: Video Handling

Untuk video, pendekatannya agak lebih berat:

- **Library Utama:** Murni memakai *plugin* resmi **`video_player`** (dari *flutter.dev*). Aplikasi ini *nggak* pakai `chewie` (meskipun `chewie` ngasih UI gratisan). Developer lamanya lebih milih merakit tombol *Play*, animasi *Fade* (muncul/hilang otomatis 3 detik), dan *Slider* secara *custom* di atas `Stack`.
- **Status Loading:** Pas *user* baru nge-klik video, layar ngeluarin status **Buffering**. Gimana caranya? Kalau variabel `_isInitialized` masih `false`, layar akan nampilin balok pemutar berputar (`CircularProgressIndicator`) ditengah layar dengan teks "Loading video...". Kalau URL putus/gagal dimuat, akan memicu status `_hasError = true` dan keluar tombol `Refresh / Coba lagi`.
- **Auto-Play:** **Ya, otomatis.** Di dalam fungsi `_initializePlayer()`, tepat sesudah video sukses dimuat, aplikasi langsung menembak `_controller.play()`. Jadi *user* tidak perlu capek nekan tombol *play* dua kali.

---

## 4. State & Memory Management (Pencegahan Bocor RAM)

Sebagai developer, kita wajib peduli sama "sampah" RAM. Gimana layar-layar ini beres-beres setelah ditutup?

- **Pembersihan (Dispose):** 
  - Pada layar gambar (ImageViewer), kodenya berbentuk `StatelessWidget`. Aman sentosa, gak ada memori berat yang harus dibersihkan secara manual. (Pada galeri, ada pembersihan `_pageController.dispose()`).
  - Pada layar Video, ini yang kritikal! Di dalam `dispose()`, mereka dengan patuh memanggil `_controller.dispose()`. Terus, karena mereka pakai banyak jam pasir (*Timer* buat *progress bar* dan *Timer* buat *auto-hide* UI), *timer-timer* itu dipanggil `cancel()` semuanya. Kalau ini lupa dikerjakan, audionya bakal terus nyala walau *user* udah nekan *back*, alias bocor alias *Memory Leak*!
- **Sumber Data:** Data media di sini **tidak ngambil dari API atau database HP (MediaStore)**. Semua data disuapi secara langsung (di-*pass as arguments*) dari si empunya acara: `chat_detail_page.dart`. Makanya proses *loading* layar ini nyaris 0 detik.

---

## 5. Hubungan dengan Core Layer

Apakah dia ngobrol dengan folder core?

**Jawabannya: TIDAK SAMA SEKALI.** 

File-file di `screens/media` ini bagaikan pulau terpencil yang super independen. Coba perhatikan *import*-nya: tak satupun dari file ini yang memanggil `MediaService`, `ImageCacheManager`, atau kawan-kawannya di folder `core`. 

Mereka benar-benar didesain sebagai komponen "Lempar Tangkap":
1. *ChatDetail* dapet URL dari server.
2. *ChatDetail* ngelempar URL tersebut ke *VideoPlayerScreen*.
3. *VideoPlayerScreen* muterin video dari URL tersebut. Selesai.

Keterpisahan ini (*loose coupling*) bagus untuk *testing*. Tapi, kalau ke depan kamu mau bikin gambar/video itu tersimpan selamanya (*download* ke galeri HP otomatis), barulah kamu harus "menjodohkan" layar ini dengan `MediaService` / utilitas *download* di layer *Core*. 

Paham ya alurnya sekarang? Lanjut ke folder mana lagi, *bro*?
