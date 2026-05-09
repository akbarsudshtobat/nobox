# Analisis Arsitektur Fitur Chat (The Core Feature)

Dokumen ini membedah arsitektur, state management, dan alur data pada folder `presentation/screens/chat`, yang merupakan jantung utama dari aplikasi NoBox Chat.

---

## 1. Peta Halaman (Halaman Utama vs Pendukung)

Folder ini berisi sekumpulan file UI yang saling terkait. Berikut adalah pemetaannya:

- **Halaman Utama:**
  - `chat_list_page.dart`: Halaman *Inbox*. Bertugas menampilkan daftar percakapan (Private, Group) menggunakan Tab filter. Dilengkapi dengan *endless scrolling* (lazy load) dan sinkronisasi realtime.
  - `chat_detail_page.dart`: Halaman Ruang Obrolan (*Room*). Halaman **paling masif dan kompleks**. Mengurus rendering balon pesan (teks, gambar, dokumen, *voice note*, lokasi) serta interaksi *typing*, *recording*, dan pemilihan emoji.

- **Manajemen Kontak:**
  - `contact_info_page.dart`: Menampilkan detail profil lawan bicara atau info grup (nama, foto, detail) yang diakses saat menekan area *header* di layar *chat detail*.
  - `edit_contact_page.dart`: Form utilitas untuk memperbarui data kontak yang tersimpan di server.

- **Fitur Lanjutan (Riwayat & Arsip):**
  - `archive_list_page.dart`: Berfungsi seperti halaman *inbox* khusus untuk daftar *chat* yang sengaja disembunyikan/diarsipkan oleh pengguna.
  - `starred_messages_page.dart`: Daftar pesan yang di-*bookmark* (bintang) agar mudah dicari kembali, tanpa perlu *scroll* jauh ke atas.
  - `conversation_history_page.dart`: Menampilkan riwayat obrolan terdahulu dengan menembak API *History* tersendiri.

- **Utility UI (Pendukung):**
  - `file_preview_screen.dart`: Layar layar-penuh yang dipanggil **sebelum** mengirim file. Berfungsi agar *user* bisa melihat gambar (zoomable), memutar video (dengan `video_player`), atau mengecek ukuran dokumen terlebih dahulu.
  - `location_picker_page.dart`: Layar interaktif menggunakan `flutter_map` dan OpenStreetMap. Pengguna bisa menggeser peta untuk memilih titik pin lokasi secara akurat.

---

## 2. Bedah Teknis: Chat Detail & Realtime

Fokus pada `chat_detail_page.dart`, yang merupakan otak dari interaksi pengguna:

- **Pagination & Loading:** 
  Halaman ini memanggil API `getMessageHistory` pada saat inisialisasi (`initState`). Meskipun *ListView* dilengkapi *ScrollController*, ia merender seluruh *list* dalam satu waktu (tidak ada mekanisme *lazy load* yang kentara pada pesan-pesan lama di dalam *room*, berbeda dengan `chat_list_page` yang memakai *lazy load*).
- **Integrasi SignalR (Realtime):**
  Begitu masuk, halaman ini menjalankan `_subscribeToSignalR()`. Ia memantau aliran *socket* (WebSockets). Apabila ada *event* `TerimaPesan` yang `roomId`-nya **cocok** dengan *room* yang sedang dibuka, pesan tersebut **langsung diinjeksi** ke dalam daftar obrolan menggunakan `setState()`—sehingga seketika muncul tanpa perlu memuat ulang API HTTP.
- **Hubungan dengan Provider & MessageModel:**
  Berbeda dengan halaman lain yang sangat tunduk pada *Provider*, `chat_detail_page` lebih mandiri. Halaman ini menyimpan status obrolan di tingkat *State* lokal (`List<Message> _messages`). Data mentah JSON dari API / SignalR langsung dikonversi menjadi objek `Message` (sebuah `MessageModel`), lalu dirender. 

---

## 3. Fitur Media & Lokasi

- **Media (`file_preview_screen.dart`):**
  Halaman ini cerdas. Menggunakan argumen Enum `FilePreviewType` (photo, video, document), ia menyesuaikan tampilannya:
  - **Photo**: Dibungkus `InteractiveViewer` untuk fitur *pinch-to-zoom*.
  - **Video**: Meng-generate *thumbnail* statis dulu dengan `video_thumbnail`. Jika user menekan *play*, barulah `VideoPlayerController` diinisialisasi untuk menghemat RAM.
  - Halaman ini *return* `true` atau `false` kembali ke `chat_detail_page` sebagai tanda "Jadi kirim" atau "Batal".
- **Lokasi (`location_picker_page.dart`):**
  Begitu layar dibuka, ia menggunakan `geolocator` untuk mencari koordinat GPS ponsel dan langsung menerbangkan peta ke titik tersebut. Pengguna bisa menggeser *map* secara bebas. Posisi pin tengah menangkap koordinat `LatLng` terbaru. Saat ditekan "Kirim", koordinat tersebut diserahkan ke `chat_detail_page` untuk dirakit menjadi URL *Google Maps* dan dikirim via *ChatService*.

---

## 4. State Management (The Brain)

- **Sinkronisasi Inbox (`chat_list_page`):**
  Bagaimana *inbox* naik turun otomatis? `chat_list_page` dibungkus dengan `Consumer<ChatProvider>`. Ketika SignalR menerima pesan baru dari *background*, `ChatProvider` akan mengeksekusi *method* `updateRoomFromSignalR()` yang menyalin pesan terakhir ke depan *list*, merubah unread count, lalu memanggil `notifyListeners()`. UI seketika merender ulang letak antrean pesannya.
- **Status Online/Typing (`chat_detail_page`):**
  Ini diurus oleh `ChatStatusProvider`. Ketika klien berlangganan ke *event* tertentu di SignalR, server memancarkan sinyal apakah *agent* sedang mengetik. Status ini "ditangkap" oleh `ChatStatusProvider`, dan AppBar di halaman detail akan mengganti subjudulnya dari "Terakhir dilihat..." menjadi "Sedang mengetik...".

---

## 5. User Journey (Alur Pengguna)

Berikut adalah urutan teknis apa yang terjadi di belakang layar saat *user* berinteraksi:

1. **User klik *chat* di List:** Argumen `ChatModel` dilempar via rute Navigator.
2. **Masuk ke Detail:** Halaman menampilkan layar kosong / *loading*. Di *background*, menembak API HTTP `getMessageHistory`.
3. **Ketik pesan:** *State* lokal `_isComposing` menyala (mengubah tombol mic menjadi ikon *send* kertas).
4. **Klik kirim:**
   - **(Optimistic UI Update):** Pesan langsung muncul di layar (`setState` di `_messages`) dengan tanda centang abu-abu transparan/jam pasir (Status: *Sent*). UI otomatis *scroll* ke bawah.
5. **Aktivitas Service:** `ChatService.sendMessage` dipanggil, membungkus *text* dan *RoomID* lalu mengirimnya via protokol HTTP POST (Dio).
6. **Perubahan UI:** Setelah server menjawab HTTP 200 (Sukses), kode mengeksekusi `setState` mengubah status pesan tersebut menjadi centang (Status: *Delivered*/Terkirim).

---

## 6. Review Kode & Potensi Isu

Setelah meninjau arsitekturnya, terdapat beberapa hal kritis (*code smells*) yang sebaiknya diperbaiki untuk skalabilitas:

1. **Fat Widget (Widget Terlalu Raksasa):**
   - **Isu:** File `chat_detail_page.dart` sangat gemuk (mendekati 4000 baris kode). Ia menampung segalanya: UI *Appbar*, pemutar *Voice Note*, *Audio Recorder*, pengirim gambar, SignalR *listener*, dan API *call*. Ini sangat melanggar prinsip *Single Responsibility*.
   - **Saran:** Ekstrak bagian Input teks beserta tombol-tombol lampirannya ke dalam file terpisah, misal `widgets/chat_input_bar.dart`. Pindahkan logika pemutar audio ke `widgets/audio_message_bubble.dart`.
2. **State Management Pesan yang *Volatile*:**
   - **Isu:** Daftar pesan disimpan pada `List<Message> _messages` yang berbentuk *StatefulWidget* biasa. Ini berarti jika pengguna menekan tombol *Back* (kembali ke inbox), lalu masuk ke *room* yang sama, aplikasi akan memuat ulang daftar pesan dari API server dari 0 lagi. Ini boros *bandwith* dan terasa lambat.
   - **Saran:** Seharusnya `List<Message>` disimpan di dalam `ChatProvider` dengan skema *Map* seperti `Map<String, List<Message>> cachePesan`. Sehingga saat *user* bolak-balik halaman, pesannya langsung muncul dari memori HP.
3. **Penanganan Internet Mati (Offline Mode):**
   - **Isu:** Jika internet putus saat user mengirim pesan, API akan melempar *Error*. Aplikasi memunculkan `SnackBar` merah. **Namun**, pesan tadi sudah telanjur terlukis di UI (Optimistic update) dengan status *sent*. Pengguna tidak punya cara intuitif (misal tombol "Coba Kirim Ulang") untuk mengirim ulang *bubble* pesan yang gagal tersebut selain mengetik ulang.
   - **Saran:** Implementasikan status `MessageStatus.failed` dengan memberikan tanda seru (❗️) warna merah di balon pesan beserta fungsi klik untuk *Retry*.
