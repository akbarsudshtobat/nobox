# Bagian 2: Daftar Obrolan (Chat List) & Logika Real-Time (SignalR / Integrasi Saluran)

Dokumen ini menjelaskan alur kerja halaman utama obrolan (*Chat List*), sistem pemuatan data tanpa henti (*infinite scroll*), mekanisme komunikasi real-time menggunakan *SignalR*, dan cara aplikasi mengenali serta menghubungkan akun chat seperti WhatsApp, Telegram, Tokopedia, Shopee, dll.

---

## 1. Halaman Beranda Chat (Chat List Page)

### A. Tampilan UI
*   **Tampilan:** Daftar obrolan vertikal yang mirip dengan WhatsApp. Di atasnya terdapat Tab Bar dengan kategori status chat (**All, Unassigned, Assigned, Resolved**). Di bagian pojok kanan atas terdapat tombol pencarian, tombol filter lanjutan, dan menu titik tiga (untuk mengganti tema, membuka pesan diarsipkan, dan logout). Di pojok kanan bawah terdapat tombol melayang (+) untuk membuat percakapan baru.
*   **Letak File:** [`lib/presentation/screens/chat/chat_list_page.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/chat/chat_list_page.dart)

### B. Penyambungan & Logika Utama
*   **Koneksi State:** Terhubung ke `ChatProvider` sebagai penyedia data chat room dan `ThemeProvider` untuk toggle visual mode gelap/terang.
*   **Cara Kerja:**
    1.  **Mengambil Data Awal (`initState`):** Saat pertama kali dibuka, aplikasi memanggil `context.read<ChatProvider>().fetchChats()` untuk meminta 20 chat pertama dari server.
    2.  **Filter Kategori Tab:** Ketika tab digeser/diklik (misal dari "All" ke "Unassigned"), fungsi `_onTabChanged()` dipanggil. Logikanya:
        *   Mengubah `activeFilter` di provider.
        *   Mereset posisi pagination ke 0.
        *   Melakukan fetch ulang ke server sesuai filter status terpilih.

---

## 2. Pemuatan Data Tanpa Henti (Infinite Scroll)

Untuk menjaga performa aplikasi agar tidak memuat ribuan data sekaligus, digunakan mekanisme pagination.
*   **Logika Kode:**
    *   Menggunakan `ScrollController` yang terpasang pada `ListView.builder`.
    *   **Pengecekan Posisi Scroll (`_onScroll`):** Begitu user men-scroll ke bawah dan posisinya tersisa 200 piksel sebelum mencapai batas terbawah (`pixels >= maxScrollExtent - 200`), sistem akan memanggil `chatProvider.fetchMoreChats()`.
    *   **Request Lanjutan:** Sistem mengirim parameter `skip` (jumlah chat yang sudah tampil) dan `take` (jumlah chat baru yang ingin diambil, yaitu 20 item) ke backend. Data baru tersebut kemudian digabungkan (*append*) ke dalam list chat yang sudah ada di provider.

---

## 3. Integrasi Saluran Obrolan (WhatsApp, Telegram, E-Commerce, dll)

Aplikasi NoBox Chat mengintegrasikan berbagai platform chat eksternal agar tampil dalam satu kotak masuk terpadu.

### A. Deteksi Saluran
Di database/API, setiap chat memiliki properti `chId` (Channel ID) dan `channelName`. Aplikasi mengidentifikasi saluran obrolan menggunakan widget khusus:
*   **Letak File:** [`lib/presentation/widgets/channel_icon.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/widgets/channel_icon.dart)
*   **Logika Identifikasi:**
    *   **WhatsApp:** `channelId` bernilai `1` / `1557` / `1561` atau jika nama mengandung kata "whatsapp" / "wa". Menampilkan logo `wa.png`.
    *   **Telegram:** `channelId` bernilai `2` atau nama mengandung "telegram". Menampilkan logo `telegram.png`.
    *   **Instagram / Facebook:** `channelId` bernilai `3` atau `4` (atau mengandung kata terkait). Menampilkan logo instagram/facebook.
    *   **Shopee, Tokopedia, TikTok:** Diidentifikasi lewat pencarian teks lowercase pada nama channel. Menampilkan logo shopee/tokopedia/tiktok.

### B. Membuat Percakapan Baru Berdasarkan Saluran
Saat tombol melayang (+) diklik, dialog membuat percakapan baru dibuka:
1.  Aplikasi memanggil API `getChannels()`, `getAccounts()`, dan `getContacts()` secara paralel.
2.  User dapat memilih **Tipe Obrolan** (Private/Group), **Saluran** (WhatsApp, Telegram, Tokopedia, dll), **Akun** pengirim yang terhubung, dan **Tujuan** (memilih dari kontak atau mengetik nomor HP secara manual).
3.  Ini memastikan pesan yang dikirim dari aplikasi NoBox Chat diteruskan ke server e-commerce atau chat gateway yang tepat (misalnya WA/Telegram API) berdasarkan Akun dan Channel yang dipilih.

---

## 4. Mekanisme Sinkronisasi Real-Time (SignalR Service)

Agar pesan baru langsung muncul di layar tanpa memuat ulang aplikasi, digunakan **SignalR** (protokol WebSocket yang disederhanakan).

*   **Letak File Service:** [`lib/core/services/signalr_service.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/core/services/signalr_service.dart)
*   **Cara Kerja Inisialisasi:**
    *   Koneksi dimulai saat login sukses atau setelah splash screen selesai dimuat (`SignalRService().connect()`).
    *   Menghubungkan ke endpoint hub SignalR dengan menyertakan Token Autentikasi JWT (JSON Web Token) di bagian header agar server tahu akun siapa yang terhubung.
*   **Mendengarkan Event Pesan Masuk:**
    *   SignalR mendengarkan event **`TerimaSubSpv`** untuk mendeteksi perubahan status ruang obrolan di halaman beranda.
    *   Begitu ada pesan masuk, server mengirim data chat room terbaru. Provider menangkap data ini lewat `updateRoomFromSignalR()` dan UI daftar obrolan akan langsung memperbarui urutan chat, isi pesan terakhir, serta jumlah pesan belum dibaca secara instan.
