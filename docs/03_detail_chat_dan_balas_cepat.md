# Bagian 3: Detail Ruang Obrolan (Chat Detail) & Fitur Balas Cepat (Quick Reply)

Dokumen ini menjelaskan alur kerja halaman detail obrolan (*Chat Detail Page*), mekanisme pengiriman dan status centang pesan (Sent, Delivered, Read), implementasi balas cepat (*Quick Reply*), serta cara pesan lawas dimuat secara dinamis.

---

## 1. Halaman Ruang Obrolan (Chat Detail Page)

### A. Tampilan UI
*   **Tampilan:** Struktur chat standar dengan header di bagian atas yang menampilkan nama kontak, status *online*, tombol informasi kontak, dan menu chat (bersihkan chat, dll). Bagian tengah adalah daftar balon pesan (*message bubbles*) yang diurutkan secara terbalik (pesan terbaru di bagian bawah). Bagian bawah adalah bilah input teks yang dinamis beserta tombol attachment, emoji picker, tombol kirim, dan tombol voice note.
*   **Letak File:** [`lib/presentation/screens/chat/chat_detail_page.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/chat/chat_detail_page.dart)

### B. Penyambungan & Inisialisasi
*   **Inisialisasi Chat (`initState` & `_initializeChat`):**
    1.  Membaca objek `ChatModel` yang dikirim dari halaman beranda saat membuka rute chat.
    2.  Memanggil `_loadInitialMessages()` untuk mengambil riwayat chat terakhir dari server.
    3.  Memanggil `_subscribeToSignalR()` untuk mulai mendengarkan pesan masuk secara real-time khusus di room/percakapan ini.
    4.  Memulai polling latar belakang (`_startChatSyncPolling()`) setiap 4 detik untuk menyelaraskan status centang jika koneksi web socket sempat terputus.

---

## 2. Pengiriman & Status Centang Pesan (Message Status / Acks)

Setiap pesan yang dikirim memiliki indikator tanda centang di bagian kanan bawah balon pesan.

### A. Logika Alur Pengiriman Pesan
1.  **Input & Kirim:** User mengetik pesan dan menekan tombol kirim. Sistem membuat objek `MessageRequest` dan mengirimkannya via `_chatService.sendMessage()`.
2.  **Rendering Instan (Optimistic Update):** Sebelum server merespons, pesan yang diketik akan langsung dimasukkan ke dalam daftar tampilan lokal (`_messages.add`) dengan status centang 1 abu-abu agar pengguna merasa aplikasi bekerja dengan cepat.

### B. Logika Indikator Status Centang (Acks)
Status pengiriman dibaca berdasarkan nilai **`ack` (Acknowledgement)** yang dikembalikan dari API / SignalR:
*   **Ack = 1 (Sent / Centang Satu Abu-Abu):** Pesan berhasil dikirim dari HP pengguna ke server NoBox.
*   **Ack = 2 (Sent to Gateway / Centang Dua Abu-Abu):** Pesan telah diteruskan ke server pihak ketiga (misalnya gateway WhatsApp / server Telegram).
*   **Ack = 3 (Delivered / Centang Dua Biru/Terbaca):** Penerima pesan telah menerima dan membaca obrolan tersebut.
*   **Sinkronisasi Real-Time:** Begitu ada event `TerimaPesan` dari SignalR, aplikasi mendeteksi properti `ack` dari pesan yang sama dan memperbarui status centangnya secara instan di UI tanpa perlu memuat ulang halaman.

---

## 3. Fitur Balas Cepat (Quick Reply)

Fitur ini membantu agen/pengguna membalas pesan pelanggan menggunakan template pesan yang telah disiapkan sebelumnya.

### A. Letak Logika & UI
*   Pendeteksian teks input diatur di listener `_messageController`.
*   Tampilan popup list template menggunakan fungsi widget `_buildQuickReplyList()`.

### B. Cara Kerja
1.  **Pemicu Karakter `/`:** Saat pengguna mengetik garis miring (`/`) di kolom input pesan, listener mendeteksi karakter tersebut dan mengaktifkan variabel status `_isShowingQuickReply = true`.
2.  **Pencarian Template:** Aplikasi melakukan pencarian template pesan (`_fetchQuickReplies`). Jika data belum di-cache, ia memanggil API `getQuickReplyTemplates()`. Pengguna bisa menyaring template dengan mengetik teks setelah tanda `/` (misalnya `/halo`).
3.  **Memasukkan Template:** Ketika salah satu template dari daftar diketuk, aplikasi mematikan status popup, lalu mengganti teks di kolom input dengan isi konten dari template tersebut dan mengembalikan fokus kursor ke ujung teks input.

---

## 4. Memuat Pesan Lawas (Scroll Backwards Pagination)

Agar tidak membebani memori HP dengan memuat ribuan pesan di awal, riwayat chat dimuat secara bertahap saat di-scroll ke atas.
*   **Cara Kerja:**
    1.  Daftar pesan ditampilkan secara terbalik (`reverse: true` pada `ListView.builder`).
    2.  `ScrollController` mendengarkan pergerakan scroll.
    3.  Ketika user menggeser layar ke atas mendekati batas akhir pesan lama (`pixels >= maxScrollExtent - 200`), sistem memanggil fungsi `_loadOlderMessages()`.
    4.  Aplikasi memanggil API riwayat pesan dengan menambahkan parameter `skip` (melompati pesan yang sudah tampil di layar) dan mengambil 50 pesan lebih lama dari database. Pesan baru ini disisipkan di atas list lokal secara mulus.
