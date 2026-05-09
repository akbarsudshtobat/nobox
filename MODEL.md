# Dokumentasi Folder `models` (lib/core/model)

Folder `models` adalah **Jantung Data** dari aplikasi NoBox Chat. 
Fungsi utama folder ini adalah sebagai **Penerjemah** yang mengubah data mentah berbentuk teks JSON dari Server/API menjadi Objek Dart yang rapi, terstruktur, dan aman digunakan oleh aplikasi (UI).

Berikut adalah daftar *file* yang ada di dalam folder ini beserta penjelasannya (diurutkan dari yang paling dasar hingga paling krusial):

## 1. `api_response.dart` (Pembungkus Dasar)
*   **Fungsi**: Bertindak sebagai kotak pembungkus (*wrapper*) standar untuk semua balasan dari API. Sebelum aplikasi membaca isi datanya, ia akan mengecek kotak ini dulu.
*   **Detail**: Memisahkan apakah balasan dari server itu sukses atau gagal (error jaringan).
*   **Field Penting**:
    *   `isError` (bool): Penanda jika *request* gagal.
    *   `data` (T): Isi datanya sesungguhnya (bisa berupa daftar obrolan, pesan detail, dll).

## 2. `login_request.dart` (Model Sederhana)
*   **Fungsi**: Membentuk format paket data untuk dikirim ke *endpoint* API saat proses *Login*.
*   **Detail**: Menerjemahkan input dari *text field* menjadi bentuk JSON.
*   **Field Penting**:
    *   `username` dan `password`.
    *   Method `.toJson()`: Mengubah objek Dart menjadi teks JSON.

## 3. `quick_reply_model.dart` (Model Tambahan)
*   **Fungsi**: Menerjemahkan data *template balasan cepat* (*auto-text*) dari API.
*   **Detail**: Memungkinkan agen mengetik *shortcut* (misal: `/halo`) yang nantinya akan me-*load* teks panjang.
*   **Field Penting**:
    *   `command`: Kata kunci ketikan pendek.
    *   `content`: Isi teks panjang yang akan dikirim.

## 4. `message_request.dart` (Data Pengiriman)
*   **Fungsi**: Membentuk format paket data ketika agen membalas pesan ke pelanggan.
*   **Detail**: Berisi semua parameter wajib yang diminta *backend* agar pesan tidak salah alamat.
*   **Field Penting**:
    *   `receiver`: Tujuan nomor pelanggan.
    *   `contactId`: Alamat/ID Kamar obrolan yang spesifik.
    *   `content`: Isi ketikan pesan dari agen.

---

## 5. `conversation.dart` (Otak Halaman Inbox/List Chat)
*   **Fungsi**: Mem-*parsing* daftar "Kamar Obrolan" (*Chat Rooms*) dari API untuk ditampilkan di halaman depan aplikasi.
*   **Detail**: *File* ini melakukan banyak "pekerjaan kotor" (memiliki banyak penanganan *error/fallback*). Seringkali *backend* mengirimkan nama kunci (*keys*) JSON yang berubah-ubah (misalnya `Tags` kadang `tags`, `ContactId` kadang `CtId`). *File* ini bertugas menyeragamkannya.
*   **Field Penting**:
    *   `id`: ID Kamar Obrolan.
    *   `contactId`: ID yang dibutuhkan saat kita mau membalas pesan pelanggan.
    *   `unreadCount`: Indikator angka pesan yang belum dibaca.
    *   **Method `toChatModel()`**: Sebuah fungsi konversi krusial yang menyaring data `Conversation` yang "kotor" menjadi objek `ChatModel` yang bersih dan aman dipakai oleh UI aplikasi.

## 6. `message.dart` (Model Paling Vital & Kompleks)
*   **Fungsi**: Mengatur struktur data untuk satu buah gelembung pesan (*chat bubble*) dan menyimpan *class* `ChatModel`.
*   **Detail**: *File* inilah yang cerdas mendeteksi apakah pesan dari API berupa Teks, Gambar, Voice Note, Video, Document, atau Pesan Sistem/Bot.
*   **Field Penting (`Message`)**:
    *   `isMe` (bool): Sangat krusial. Penentu arah gelembung pesan. Jika `true` (Kanan/Agen), jika `false` (Kiri/Pelanggan).
    *   `messageType`: Penentu tampilan (merender *player* audio, memunculkan gambar, atau teks biasa).
    *   `content`: Isi teks yang dibaca oleh pengguna.

---

## Alur Singkat: Bagaimana API dan Model Bekerja Sama

Agar lebih mudah dipahami, bayangkan alur logistik ekspedisi:

1. **Aplikasi Request**: Aplikasi mengirim data via **`login_request.dart`** atau **`message_request.dart`** ke *Server*.
2. **Paket Datang**: *Server* membalas dengan kotak paket yang diterima oleh **`api_response.dart`**.
3. **Bongkar Muat**: Kotak dibuka, dan isinya diserahkan ke "Pabrik Penerjemah" yaitu metode `fromJson()` milik **`conversation.dart`** (untuk daftar kontak) atau **`message.dart`** (untuk isi obrolan).
4. **Siap Dipakai UI**: Data mentah tadi kini berubah bentuk menjadi rapi. Oleh aplikasi, data ini disimpan sementara (di dalam *Provider State*) lalu dicetak ke layar *handphone* sebagai UI yang indah.
