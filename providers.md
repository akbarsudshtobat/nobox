# Dokumentasi Pembelajaran State Management `nobox_chat_basic`

Dokumen ini menjelaskan arsitektur state management yang digunakan dalam folder `lib/core/providers`. Project ini menggunakan pattern **Provider** (berbasis `ChangeNotifier` dari framework Flutter) untuk mengelola state aplikasi.

---

## 1. Tujuan Folder `providers`
Folder ini bertujuan untuk **memisahkan logika bisnis (business logic) dan penyimpanan data (state) dari tampilan Antarmuka (UI)**. Dengan pemisahan ini:
- Kode UI (Widget) menjadi lebih bersih dan hanya bertugas untuk menampilkan data (render) serta mendengarkan event/klik dari pengguna.
- Logika aplikasi seperti pemanggilan API, penanganan data chat, filter, dan status login dipusatkan dan dikelola secara efisien di memori.

## 2. Cara State Management Bekerja di Project Ini
1. **Inisialisasi**: Class Provider turunan dari `ChangeNotifier` menyimpan variabel internal (state).
2. **Event/Aksi**: Saat user berinteraksi dengan UI (misal klik "Kirim Pesan" atau "Filter"), UI akan memanggil method yang ada di dalam Provider (`context.read<MyProvider>().doSomething()`).
3. **Proses & Update Data**: Provider melakukan proses (misalnya memanggil `ChatService` untuk request API). Setelah data kembali, Provider memperbarui variabel internalnya.
4. **Notifikasi**: Provider memanggil fungsi `notifyListeners()`.
5. **Rebuild UI**: Widget yang telah didaftarkan untuk mendengarkan Provider tersebut (melalui `Consumer` atau `context.watch`) secara otomatis me-render ulang tampilannya dengan data yang terbaru.

## 3. Provider Paling Penting
- **`AuthProvider`**: Penggerak utama keamanan dan identitas aplikasi (Token management, login status).
- **`ChatProvider`**: "Otak" aplikasi yang menampung seluruh state pesan, pagination, daftar obrolan, dan sinkronisasi real-time.

## 4. Alur Perubahan State (Flow)
Contoh alur (State Flow) saat pesan baru masuk via Web-Socket / Background:
1. SignalR menerima event `TerimaSubSpv`.
2. Listener SignalR memanggil method `updateRoomFromSignalR()` di `ChatProvider`.
3. `ChatProvider` mengubah state `_chats` lokal (seperti mengupdate `lastMessage`, menaikkan `unreadCount`, dll) tanpa melakukan hit API ulang.
4. `notifyListeners()` dieksekusi.
5. Widget `ChatListPage` mendeteksi perubahan dan memperbarui baris chat lawan bicara secara instan.

## 5. Hubungan Provider dengan Service dan UI
- **UI (Pages/Widgets)**: Lapisan presentasi. Menampilkan apa yang ada di Provider.
- **Provider**: Pengelola State dan Cache di memori. Bertugas menerjemahkan perintah dari UI untuk dilanjutkan ke Service, dan memberitahu UI jika ada data baru.
- **Service (`chat_service.dart`, `auth_service.dart`)**: Eksekutor yang berhubungan dengan dunia luar. Melakukan HTTP Request ke Backend server (API) atau membaca/menulis ke database lokal, dan mengembalikan raw data (Model/DTO) ke Provider.

## 6. Dependency Antar Provider
Sebagian besar provider bersifat independen satu sama lain. Namun:
- `AuthProvider` mengatur `Token` global. Jika `AuthProvider` melakukan *Logout*, data sensitif di `ChatProvider` biasanya harus dikosongkan (diatur melalui logika UI setelah pindah halaman).
- Cache Providers (`FilterCacheProvider`, `NewConversationCacheProvider`) murni bertugas sebagai penyokong data referensi (statis) untuk fungsi filter dan pembuatan chat baru di `ChatProvider`.

## 7. Flow Data: API → Provider → UI (Studi Kasus: Memuat Inbox)
1. **UI**: Halaman depan (`ChatListPage`) memanggil `context.read<ChatProvider>().fetchChats()`.
2. **Provider**: Set state `_isLoading = true` lalu `notifyListeners()`. (UI menampilkan efek Shimmer / Loading).
3. **Service**: Provider memanggil `ChatService.getConversations(...)`. Service lalu meneruskan request ke Backend via `ApiClient`.
4. **Service**: Menerima JSON dari Backend, diubah menjadi object `Conversation`, lalu dilempar balik ke Provider.
5. **Provider**: Mengolah data `Conversation` menjadi `ChatModel` (termasuk menempelkan status Pin/Arsip dari penyimpanan lokal). State `_chats` terupdate, `_isLoading = false`, lalu panggil `notifyListeners()`.
6. **UI**: Shimmer hilang, me-render `ListView` berisi daftar percakapan terbaru.

---

## Detail Analisis per Provider

### 1. `auth_provider.dart`
- **Fungsi utama**: Mengelola otentikasi user (Login, Logout, Silent Re-Login).
- **State yang disimpan**: `_currentUser` (email), `_token` (JWT token), `_isLoading`, `_isAuthenticating`.
- **Method penting**: `login()`, `logout()`, `checkAuth()`, `tryAutoReLogin()`.
- **Kapan `notifyListeners` dipanggil**: Mulai proses login, login berhasil/gagal, setelah memuat cache lokal, dan saat logout.
- **Dipakai oleh**: `SplashPage`, `LoginPage`, `ProfilePage`, dan Interceptors (`ApiClient`).
- **Terhubung ke**: `AuthService`, `FlutterSecureStorage` (menyimpan kredensial), `SharedPreferences`.
- **Potensi bug/issue**: *Race condition* jika token kedaluwarsa secara bersamaan saat banyak API call terjadi; atau silent re-login yang looping jika password lama tersimpan sedangkan kredensial di server sudah diubah.
- **Status**: **KRUSIAL**

### 2. `chat_provider.dart`
- **Fungsi utama**: Mengelola list chat utama (Inbox), pagination (infinite scroll), fitur filter kompleks, dan aksi inbox (Pin, Archive, Mark as Read).
- **State yang disimpan**: `_chats` (List), pagination status (`_currentSkip`, `_hasMore`), `_isLoading`, semua variabel filter (Group, Tag, Funnel, Status, dll), serta set lokal (`_pinnedIds`, `_archivedIds`).
- **Method penting**: `fetchChats()`, `refreshFirstPage()`, `fetchMoreChats()`, `updateRoomFromSignalR()`, `applyAdvancedFilters()`.
- **Kapan `notifyListeners` dipanggil**: Sering! Saat mulai loading, selesai loading, fetch data tambahan, update list dari SignalR, saat toggle arsip/pin, dan filter diubah.
- **Dipakai oleh**: `ChatListPage`, `ChatSearchPage`, `ChatDetailPage`, Widget Filter.
- **Terhubung ke**: `ChatService`, `SharedPreferences` (untuk simpan data offline state UI).
- **Potensi bug/issue**: Logika terlalu gemuk (1000+ baris). Rawan terjadi bug pada *Unread Badge* atau status *Archived* jika state offline/lokal tidak sinkron dengan response terbaru API server.
- **Status**: **SANGAT KRUSIAL**

### 3. `chat_settings_provider.dart`
- **Fungsi utama**: Mengelola kustomisasi tampilan background (wallpaper/warna) di ruang obrolan.
- **State yang disimpan**: `_backgroundColor`, `_backgroundImagePath`.
- **Method penting**: `loadSettings()`, `setBackgroundColor()`, `setBackgroundImage()`.
- **Kapan `notifyListeners` dipanggil**: Saat user mengganti warna/gambar wallpaper.
- **Dipakai oleh**: `ChatDetailPage` (background message area).
- **Terhubung ke**: `SharedPreferences`.
- **Potensi bug/issue**: Aman. Masalah kecil jika path image lokal terhapus oleh OS tapi path string-nya masih tersimpan.
- **Status**: **PENDUKUNG**

### 4. `chat_status_provider.dart`
- **Fungsi utama**: Mengelola status "Online", "Offline", dan indikator "Typing..." per-kontak secara realtime.
- **State yang disimpan**: `_userStatus` (Map user -> status string), `_typingUsers` (Set kumpulan user id yang sedang mengetik).
- **Method penting**: `setOnline()`, `setTyping()`, `setLastSeen()`.
- **Kapan `notifyListeners` dipanggil**: Ketika event user mengetik/online diterima dari websocket.
- **Dipakai oleh**: AppBar di `ChatDetailPage`.
- **Terhubung ke**: Logic SignalR event.
- **Potensi bug/issue**: Status "typing" bisa nyangkut (terus berputar) jika aplikasi lawan mengirim sinyal "start typing", lalu app-nya *crash* sebelum mengirim "stop typing".
- **Status**: **PENDUKUNG**

### 5. `filter_cache_provider.dart` & `new_conversation_cache_provider.dart`
- **Fungsi utama**: Berfungsi murni sebagai tempat singgah (cache) data referensi statis seperti daftar Channel, Funnel, Tags, dan Akun, agar UI *Dropdown/BottomSheet* tidak perlu terus memuat API setiap kali dibuka.
- **State yang disimpan**: `_tags`, `_funnels`, `_channels`, `_accounts` (berupa List/Map), `_isDataLoaded`.
- **Method penting**: `updateFilterData()`, `updateConversationData()`, `invalidateCache()`.
- **Kapan `notifyListeners` dipanggil**: Hanya saat memuat data cache baru secara *bulk* (bersamaan).
- **Dipakai oleh**: `FilterBottomSheet` widget, halaman `NewConversationPage`.
- **Terhubung ke**: Tidak ada koneksi API langsung di dalamnya; data disuap (di-inject) dari halaman/controller yang mengambil data.
- **Potensi bug/issue**: Data menjadi kedaluwarsa *(stale)* jika admin web dashboard mengubah nama tag/channel, tetapi aplikasi belum mereset cache-nya (misal karena belum logout/restart).
- **Status**: **PENDUKUNG**

### 6. `locale_provider.dart`
- **Fungsi utama**: Mengatur kamus terjemahan dan preferensi bahasa (Indonesia / English).
- **State yang disimpan**: `_locale` (Enum AppLocale ID/EN). Di file ini juga ada *hardcoded dictionary* terjemahan string UI.
- **Method penting**: `setLocale()`, `toggleLocale()`, `t(key)`.
- **Kapan `notifyListeners` dipanggil**: Saat bahasa diganti.
- **Dipakai oleh**: Praktis *seluruh halaman dan komponen aplikasi* yang menggunakan teks string.
- **Terhubung ke**: `SharedPreferences`.
- **Potensi bug/issue**: Sangat aman. Namun, seiring berkembangnya project, file ini akan membesar drastis karena menampung semua dictionary kata aplikasi secara internal *(hardcoded)*.
- **Status**: **PENDUKUNG**

### 7. `theme_provider.dart`
- **Fungsi utama**: Mengubah tema aplikasi dari Mode Gelap (Dark Mode) ke Mode Terang (Light Mode).
- **State yang disimpan**: `_themeMode` (ThemeMode).
- **Method penting**: `loadTheme()`, `toggleTheme()`.
- **Kapan `notifyListeners` dipanggil**: Ketika toogle tema digeser di menu Setting.
- **Dipakai oleh**: Root widget aplikasi (`MaterialApp` di `main.dart`).
- **Terhubung ke**: `SharedPreferences`.
- **Potensi bug/issue**: Sangat stabil/aman.
- **Status**: **PENDUKUNG**

---

## Panduan Belajar

### Urutan Belajar Providers (Dari Termudah)
1. **`ThemeProvider` & `ChatSettingsProvider`**: Paling mudah. Mempelajari konsep mengubah variabel dan menyimpan di `SharedPreferences`.
2. **`FilterCacheProvider` & `NewConversationCacheProvider`**: Mempelajari bagaimana `Provider` digunakan sekadar sebagai "kulkas penyimpanan" list Array statis.
3. **`LocaleProvider`**: Memahami bagaimana mengganti sebuah state (`AppLocale`) bisa memicu perombakan UI massal (karena teks diseluruh sistem diganti).
4. **`ChatStatusProvider`**: Mulai belajar logic dinamis menggunakan Map dan Set untuk indikator typing.
5. **`AuthProvider`**: Mempelajari hal krusial: Autentikasi, JWT, *Secure Storage*, dan logika intersep *background auto-login*.
6. **`ChatProvider`**: Terakhir, kelas berat. Masterpiece project ini. Penuh dengan state manajemen pagination (`skip/take`), custom mapping, filter lanjutan, dan handling *Websocket / SignalR*.

### Provider Paling Kompleks
**`ChatProvider`** (Lebih dari 1000 baris kode). Mengelola tumpang-tindih fungsionalitas: List Chat Server vs Offline Storage (Read/Archived), memetakan ID ke nama (Tag/Funnel manual map), Advanced Filter dinamis, dan sinkronisasi real-time instan dengan SignalR Event tanpa me-refresh seluruh pagination list.

### Provider yang Paling Sering Memicu Rebuild UI
- **`ChatProvider`** (Khususnya fungsi `updateRoomFromSignalR`).
- **`ChatStatusProvider`** (Khususnya state "User is typing..." karena data ini bisa di-trigger masuk berulang kali setiap sepersekian detik oleh server ketika ada lawan bicara yang sedang mengetik pesan).

### Tips Debugging State Management di Flutter
1. **Gunakan Flutter Inspector**: Aktifkan fitur _Highlight Repaints_. Jika pesan chat baru masuk dan seluruh halaman *flicker/berkedip* nge-rebuild dari ujung ke ujung, berarti penempatan `Consumer` atau `context.watch` kurang spesifik. Pindahkan `Consumer` ke scope widget sekecil mungkin.
2. **Jangan Memanggil API di dalam `build()`**: Jika suatu widget memanggil Provider untuk ngambil data, taruh di dalam method `initState()` atau pemicu klik tombol. Jangan pernah menaruhnya langsung di root `build()`, karena akan memicu *infinite loop API call*.
3. **Awas Null / State Mati**: Jika UI tiba-tiba tidak update padahal data log menunjukkan sukses, pastikan `notifyListeners()` sudah dipanggil SETELAH data diperbarui, BUKAN sebelumnya.
4. **Print Trace**: Gunakan `debugPrint('Provider X: Data berbuah')` persis sebelum memanggil `notifyListeners()`. Hal ini sangat membantu untuk melihat flow data secara temporal di console Android Studio / VSCode Anda.
