# Bagian 4: Pengiriman Media, Pesan Berbintang, & Filter Lanjutan

Dokumen ini menjelaskan cara kerja pengiriman berbagai jenis media (Gambar, Dokumen, Rekaman Suara/Voice Note, Lokasi), pengelolaan Pesan Berbintang (*Starred Messages*), Obrolan Diarsipkan (*Archived Chats*), serta penjelasan teknis mendalam tentang Fitur Filter Obrolan.

---

## 1. Fitur Pengiriman & Pemutaran Media

Aplikasi NoBox Chat mendukung pengiriman pesan multimedia dengan integrasi package/library khusus Flutter.

### A. Pengiriman Gambar & File Dokumen
*   **Gambar (`image_picker`):** User mengetuk opsi kamera/galeri di panel lampiran. Sistem memanggil kamera atau membuka galeri HP. File gambar yang dipilih diubah ukurannya dan dikirim ke server via API unggah media.
*   **File/Dokumen (`file_picker`):** Membuka explorer file perangkat untuk memilih dokumen (PDF, DOCX, dll). File divalidasi ukuran maksimalnya lalu dikirim menggunakan metode HTTP POST multipart form data.
*   **Preview File:** Menggunakan [`lib/presentation/screens/chat/file_preview_screen.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/chat/file_preview_screen.dart) untuk menampilkan gambar atau dokumen sebelum diputuskan untuk dikirim.

### B. Rekaman Suara / Voice Note (VN)
*   **Perekaman Suara (`record`):** Menggunakan package `record` di dalam bottom sheet VN. Saat tombol mikrofon ditahan, perekam suara merekam suara ke file temporer (.m4a) di memori HP, menghitung durasi rekamannya, dan menampilkan visualizer gelombang suara.
*   **Pemutaran Suara (`audioplayers`):** Menggunakan package `audioplayers`. Pada balon obrolan suara, pengguna bisa menekan tombol Play/Pause. Sistem akan mengalirkan audio dari URL server atau memori lokal secara otomatis lengkap dengan slider penanda durasi pemutaran.

### C. Berbagi Lokasi Peta (`latlong2` & `location_picker_page.dart`)
*   **Letak File:** [`lib/presentation/screens/chat/location_picker_page.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/chat/location_picker_page.dart)
*   **Cara Kerja:** Membuka peta interaktif yang mendeteksi GPS pengguna. User dapat menggeser pin peta untuk memilih koordinat yang diinginkan. Ketika dikonfirmasi, koordinat latitude dan longitude dikirim sebagai pesan teks format khusus atau JSON lokasi yang nantinya dirender sebagai tautan peta yang bisa diklik.

---

## 2. Fitur Pesan Berbintang (Starred Messages)

Sama seperti WhatsApp, pengguna bisa menandai pesan penting agar mudah diakses kembali.
*   **Letak File Tampilan:** [`lib/presentation/screens/chat/starred_messages_page.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/chat/starred_messages_page.dart)
*   **Logika & State Penyambungan:**
    1.  Di ruang obrolan, jika pesan ditekan lama, user bisa mengetuk ikon **Bintang**.
    2.  Fungsi `chatProvider.toggleStar(messageId)` dijalankan.
    3.  Pesan yang dibintangi beserta metadata-nya (konten, waktu, pengirim) disimpan di penyimpanan lokal menggunakan `SharedPreferences` agar data tidak hilang meskipun aplikasi ditutup.
    4.  Halaman `StarredMessagesPage` membaca data dari penyimpanan lokal tersebut dan merendernya dalam bentuk daftar ringkas.

---

## 3. Fitur Filter Obrolan Mendalam (Advanced Filters)

Menjelaskan secara detail implementasi **Arsitektur Dua Jalur** filter obrolan.

### A. Alur Pemanggilan Dropdown Filter
Di dalam [`lib/presentation/screens/chat/chat_list_page.dart`](file:///d:/UBIG/proyek/nobox_chat_basic/lib/presentation/screens/chat/chat_list_page.dart#L1401), dialog filter dijalankan di dalam widget `FutureBuilder` yang menanti 10 pemanggilan API referensi data secara paralel:
*   `chatService.getChannels()`, `chatService.getAccounts()`, `chatService.getContacts()`, `chatService.getGroups()`, `chatService.getCampaigns()`, `provider.getFunnels()`, `chatService.getDeals()`, `provider.getTags()`, `provider.getAgents()`, `chatService.getLinks()`.

### B. Eksekusi Filter Jalur 1 (Server-Side)
Ketika tombol **"Apply"** diklik, filter **Jalur 1** diteruskan ke pemanggilan parameter API `getConversations`:
*   `accountIds` (pilihan akun ganda via checkbox)
*   `contactId` (CtRealId kontak)
*   `groupId` (ID grup)
*   `campaignId` (ID Kampanye)
*   `dealId` (ID Deal)
*   `humanAgentId` (ID Agen Manusia)

### C. Eksekusi Filter Jalur 2 (Client-Side / Lokal)
Di file [`lib/core/providers/chat_provider.dart` (Fungsi getter `chats`)](file:///d:/UBIG/proyek/nobox_chat_basic/lib/core/providers/chat_provider.dart#L652), data chat yang didapatkan dari server disaring kembali secara lokal sebelum dikirim ke UI:
1.  **Mute AI:** Memfilter apakah chatbot AI dinonaktifkan (`muteAiAgent == true/false`).
2.  **Read Status:** Memfilter obrolan yang belum dibaca (`unreadCount > 0`) atau sudah dibaca (`unreadCount == 0`).
3.  **Channel:** Membandingkan string channel (seperti 'WhatsApp', 'Telegram') dengan `channelType` chat yang sudah di-resolve dari data Akun.
4.  **Chat Type:** Memisahkan chat personal atau chat grup (`isGroup == true/false`).
5.  **Tags & Funnels:** Mengambil data ID tag/funnel pada obrolan, mencocokkannya ke database cache nama tag/funnel, lalu membandingkannya dengan string filter yang dipilih oleh user.
