# Dokumentasi Pembelajaran Services Layer `nobox_chat_basic`

Dokumen ini menjelaskan arsitektur komunikasi data pada folder `lib/core/services`. Folder ini merupakan jembatan (penghubung) antara aplikasi (UI/Provider) dengan dunia luar, yaitu server backend (API) dan sistem operasi perangkat (Notifikasi, Background Service).

---

## 1. Tujuan Folder `services`
Folder ini bertujuan untuk menempatkan **seluruh logika komunikasi data ke pihak eksternal** pada satu tempat terpisah. Hal ini mencakup HTTP request (REST API), koneksi websocket real-time (SignalR), integrasi Firebase Push Notification, hingga interaksi dengan Native Code (Android MethodChannel). 
Dengan adanya pemisahan ini, `Provider` tidak perlu tahu *bagaimana* cara melakukan *HTTP POST*, ia hanya cukup memanggil fungsi dari service untuk mengambil data.

## 2. Arsitektur Komunikasi Backend
Aplikasi ini menggunakan pola *Hybrid* untuk komunikasi backend:
1. **REST API (via Dio / `ApiClient`)**: Digunakan untuk aksi konvensional (Request - Response) seperti Login, Mengambil Riwayat Pesan, Kirim Pesan, dan Mengubah Status.
2. **WebSockets (via `SignalRService`)**: Digunakan untuk aliran data real-time (Stream) yang di-push oleh server secara sepihak, contoh: "Ada pesan baru masuk", "Indikator user sedang mengetik", atau "Status room berubah".

## 3. Service Paling Penting
- **`ApiClient`**: Otak dari semua request HTTP. Mengatur pengiriman JWT Token secara otomatis ke setiap endpoint.
- **`ChatService`**: Kelas raksasa (God Object) yang mengelola 80% fitur aplikasi seperti daftar inbox, riwayat chat, filter, agents, dll.
- **`SignalRService`**: Pengendali koneksi real-time. Jika service ini bermasalah, aplikasi tidak akan menerima pesan instan melainkan harus *refresh* manual.
- **`PushNotificationService`**: Penangan notifikasi yang muncul di tray layar (FCM dan Local Notification).

## 4. Alur API Request
1. UI memanggil fungsi di Provider.
2. Provider memanggil method di Service (misal: `ChatService.getConversations()`).
3. Service menyusun parameter JSON dan memanggil `ApiClient.post()`.
4. `ApiClient` melalui proses *Interceptor* -> (Menambahkan Header `Authorization: Bearer <Token>`) -> Mengirim ke Backend.
5. `ApiClient` menerima JSON dari Backend, menyerahkannya kembali ke Service.
6. Service mengubah JSON (Map) menjadi format Objek/Model (misal `Conversation`), dibungkus dengan `ApiResponse.success(...)`, lalu dikembalikan ke Provider.

## 5. Alur Realtime SignalR
1. Aplikasi login, mendapat JWT Token & *TenantId*.
2. `SignalRService` dipanggil untuk melakukan `connect()` dan `subscribeUserAgent()`.
3. Aplikasi stand-by (Listening).
4. Seseorang mengirim pesan ke akun NoBox pengguna. Backend meneruskan pesan ini via Hub SignalR.
5. SignalR memicu event `TerimaPesan` atau `TerimaSubSpv` di `SignalRService`.
6. Event ditangkap, lalu `SignalRService` memancarkan (emit) data tersebut melalui `StreamController`.
7. `ChatProvider` yang "mendengarkan" stream ini seketika mengubah data obrolan, menginstruksikan UI untuk *rebuild*.

## 6. Cara Authentication Bekerja
- Login ditangani `AuthService`.
- Backend mengembalikan *JWT Token*. Token disimpan di lokal via `FlutterSecureStorage`.
- `ApiClient` membaca token ini. Jika *expired/Unauthorized (HTTP 401)*, `ApiClient` memiliki fitur pencegat (*Interceptor*) cerdas: Ia akan menghentikan request sementara, melakukan **Silent Re-Login** di background menggunakan kredensial email/pass yang tersimpan, lalu mengulang (*retry*) request yang gagal tadi dengan token yang baru.

## 7. Cara Cache Bekerja
- **Cache Gambar**: Ditangani oleh `image_cache_manager.dart` (menggunakan library `flutter_cache_manager`) untuk menyimpan unduhan gambar ke penyimpanan lokal sementara agar irit kuota.
- **Cache Data**: Data seperti list Tag, Funnel, dan Akun di-cache sementara di dalam memory (variabel statik) di Provider atau Service untuk menghemat API Call berulang kali.

## 8. Cara Notification Bekerja
Sistem menggunakan pendekatan ganda:
- **Foreground (Saat app dibuka)**: Pesan real-time tiba melalui `SignalRService`. Service ini kemudian akan memerintahkan sistem untuk mencetak notifikasi pop-up jika pengguna tidak sedang berada di dalam room tersebut.
- **Background / Terminated (App ditutup)**: Dihandle oleh `PushNotificationService` via Firebase Cloud Messaging (FCM). Backend akan menembak push notif. Sebuah proses terisolasi *(background isolate)* akan menangkap data FCM, merakit tampilan notifikasinya, dan menampilkannya memakai `flutter_local_notifications`.

## 9. Dependency Antar Service
Hampir seluruh service komunikasi HTTP (`AuthService`, `MediaService`, dll) memiliki dependensi ketat (bergantung) terhadap `ApiClient`. 
Service kecil seperti `TagService` dan `NoteService` sangat bergantung pada `ChatService` (karena secara harfiah mereka hanyalah *wrapper/proxy* yang memanggil kembali method di `ChatService`).

---

## Analisis File Service

### 1. `api_client.dart`
- **Fungsi utama**: Mengatur base HTTP Client (Dio), token inject, logging, dan *silent re-login*.
- **Endpoint**: Menampung base URL utama (`https://id.nobox.ai/`).
- **Method penting**: `_tryAutoReLogin()` (logic retry token menggunakan sistem *Completer* anti race-condition).
- **Alur data**: Wrapper untuk seluruh request `GET`/`POST`.
- **Dipanggil oleh**: Semua service berbasis HTTP.
- **Async/Realtime**: Async murni.
- **Potensi bug/error**: Looping infinitif jika token invalid namun server mengembalikan HTTP Code aneh yang disalahartikan interceptor, atau bug relogin bertumpuk (*race condition*).
- **Tingkat Kompleksitas**: Tinggi.

### 2. `auth_service.dart`
- **Fungsi utama**: Fungsi spesifik untuk negosiasi login dengan backend.
- **Endpoint**: `AccountAPI/GenerateToken`.
- **Method penting**: `login()`.
- **Dipanggil oleh**: `AuthProvider`.
- **Model**: `LoginRequest`, `ApiResponse`.
- **Tingkat Kompleksitas**: Sangat Rendah.

### 3. `chat_service.dart`
- **Fungsi utama**: "God Object" (Objek Raksasa) pengelola 80% fitur. Dari get chatrooms, messages, upload foto, get account, funnel, update detail, hingga resolve room.
- **Endpoint**: Mayoritas `Services/Chat/Chatrooms/*` dan `Services/Chat/Messages/*`.
- **Method penting**: `getConversations()`, `getMessageHistory()`, `sendMessage()`, `resolveConversation()`.
- **Dipanggil oleh**: `ChatProvider` dan di-*proxy* oleh semua sub-service kecil.
- **Model**: `Conversation`, `Message`, `MessageRequest`.
- **Potensi bug/error**: Sangat rawan error Null-Pointer karena sangat bergantung pada struktur JSON fleksibel (*dynamic mapping*) dari server. Parsing JSON yang keras (`int.parse`) bisa membuat layar putih jika server tiba-tiba mengembalikan string alih-alih angka.
- **Tingkat Kompleksitas**: Sangat Tinggi (Terkompleks).

### 4. `signalr_service.dart`
- **Fungsi utama**: Mengurus socket TCP berkelanjutan (*persistent stream*) menggunakan library SignalR.
- **Event Penting**: `TerimaPesan`, `TerimaSubSpv`, `UcChanged`.
- **Method penting**: `connect()`, `_subscribeUser()`.
- **Alur data**: Menerima Socket string JSON -> Parsing -> Emit ke `StreamController` -> Menampilkan Notifikasi Lokal.
- **Dipanggil oleh**: `main.dart` (saat startup) dan di-listen oleh Provider/Widget.
- **Async/Realtime**: Realtime.
- **Potensi bug/error**: Koneksi terputus tiba-tiba, gagal melakukan reconnect karena OS mematikan socket saat *idle*, atau gagal subscribe jika TenantId belum berhasil diambil.
- **Tingkat Kompleksitas**: Tinggi.

### 5. `push_notification_service.dart`
- **Fungsi utama**: Menangani FCM token, Push dari Firebase, dan merakit tampilan notifikasi lokal di status bar.
- **Method penting**: `_firebaseMessagingBackgroundHandler()` (isolate terpisah), `showChatNotification()`.
- **Dipanggil oleh**: Lifecycle App (`main.dart`).
- **Async/Realtime**: Background Task & Async.
- **Potensi bug/error**: Notifikasi muncul *double* (ganda) antara FCM dan SignalR jika keduanya aktif, crash pada isolate jika library tidak mendukung background execution.
- **Tingkat Kompleksitas**: Tinggi (Berurusan dengan platform spesifik Android/iOS).

### 6. `notification_service.dart`
- **Fungsi utama**: Berfungsi ganda / mirip dengan *PushNotificationService*, namun ditujukan spesifik membuat style notifikasi lokal "*MessagingStyle*" (tipe notifikasi chat menumpuk).
- **Potensi bug/error**: Sering tabrakan fungsi dengan `push_notification_service.dart`.
- **Tingkat Kompleksitas**: Menengah.

### 7. `background_service_manager.dart`
- **Fungsi utama**: Pemanggil Native Android Service (Kotlin) lewat `MethodChannel` untuk menahan OS agar tidak mematikan aplikasi saat di-*minimize*.
- **Dipanggil oleh**: State observer `AppLifecycleState.paused` / `resumed`.
- **Tingkat Kompleksitas**: Rendah.

### 8. Sub-Services Proxy (`contact_detail_service.dart`, `filter_api_service.dart`, `note_service.dart`, dll)
- **Fungsi utama**: Memecah pemanggilan kode di Provider agar terlihat seolah-olah arsitektur mikro, padahal seluruh *class* ini isinya hanya meneruskan (mem-proxy) pemanggilan kembali ke `ChatService`.
- **Tingkat Kompleksitas**: Sangat Rendah.

---

## Kesimpulan Eksekutif

### Service Paling Krusial
1. `api_client.dart`
2. `chat_service.dart`
3. `signalr_service.dart`

### Service Paling Kompleks
`chat_service.dart` dikarenakan menyatukan begitu banyak logika *endpoint*, manipulasi `TenantId`, konversi List Model secara masif dalam 1 file tunggal. 

### Service Rawan Bug
- `signalr_service.dart` (Koneksi socket yang tidak stabil/terputus bisa menyebabkan chat *stuck*).
- `push_notification_service.dart` (Berurusan dengan izin notifikasi native dan background handler yang sensitif terhadap RAM HP Android China).

### Urutan Belajar Services
Bagi developer baru, sangat disarankan membaca alur program ini dengan urutan:
1. `auth_service.dart` (Dasar pemanggilan 1 API).
2. `api_client.dart` (Bagaimana interceptor menempelkan token ke auth_service).
3. Salah satu *Proxy Service* misal `tag_service.dart` (Untuk melihat bagaimana service dibungkus).
4. `chat_service.dart` (Melihat API fetch yang lebih rumit, json to model, pagination query).
5. `signalr_service.dart` (Mengerti *StreamController*, WebSocket, *SubscribeEvent*).
6. `push_notification_service.dart` (Yang paling terakhir, karena melibatkan library eksternal dan Native Method).

### Flow Aplikasi Keseluruhan (UI → Provider → Service → API)
`Tombol UI di-tap` 
→ `ChatProvider.resolveChat(id)` 
→ Memeriksa state, menyalakan indikator loading 
→ `ChatService.resolveConversation(id)` 
→ Memformat parameter JSON, menyuntik JWT (opsional) 
→ `ApiClient.post(url)` 
→ Server mengolah dan mengembalikan HTTP 200 (OK) 
→ `ApiClient` meneruskan response 
→ `ChatService` merakit `ApiResponse.success` 
→ `ChatProvider` mematikan indikator loading & merubah status item chat di layar 
→ `UI` berkedip dan mengupdate perubahan.
