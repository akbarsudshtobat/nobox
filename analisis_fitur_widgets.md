# Analisis Komponen Reusable (Widgets)

Bicara soal folder `presentation/widgets`, kita sedang membedah kotak perkakas (*toolbox*) dari aplikasi ini. Widget di sini dirancang bagaikan bongkahan Lego: ukurannya kecil, punya satu tugas spesifik, dan bisa dipakai berulang kali di berbagai halaman.

Mari kita *review* teknis mendalam ala *Senior Developer*:

---

## 1. Kategori: Dialogs & Modals (Pop-up)

Folder ini penuh dengan dialog untuk aksi cepat:
- **`add_agent_dialog`, `add_funnel_dialog`, `add_note_dialog`**: 
  Ketiga dialog ini memiliki *pattern* yang sama. Mereka adalah *StatefulWidget* yang me-maintain filter pencariannya sendiri (lokal). Saat *user* menekan tombol "Simpan" atau "Assign", mereka **tidak** mengolah datanya sendiri. Mereka akan mengambil Provider (contoh: `Provider.of<ChatProvider>(context, listen: false)`), menembakkan *function*-nya, memunculkan *loading spinner* di atas dialog, lalu melakukan `Navigator.pop(context)` 2 kali jika sukses (untuk menutup *loading* dan menutup dialog).
- **`forward_dialog`**:
  Berfungsi untuk meneruskan pesan. Mirip dengan di atas, tapi ia bertugas menampilkan daftar *contact/room* aktif, lalu mengirim perintah iterasi API *SendMessage* ke kontak yang dipilih.
- **`tag_selection_dialog`**:
  Memungkinkan *user* memilih tag/kategori dari obrolan. Biasanya ini menggunakan *CheckboxListTile* dengan *state* lokal berbentuk `List<String> selectedTags`, sebelum akhirnya melempar sekumpulan ID tag tersebut kembali ke *Provider* untuk di-*save*.

---

## 2. Kategori: Chat Components (Inti Percakapan)

Ini adalah widget paling sering dipanggil di aplikasi!

- **`message_bubble_widget.dart`**: 
  Widget ini punya kecerdasan parsial. Bukannya langsung menggambar balon UI, ia melakukan pengecekan `enum MessageType`. Hebatnya, ia juga punya fitur "Fallback Heuristic": kalau API bilang tipenya `text` tapi isi kontennya ada "🎥 Video" atau berekstensi `.mp4`, ia akan menimpa perintah API dan memanggil `_buildVideoMessage()`.
  Selain itu, ia disematkan logika kalkulasi matriks *GestureDetector* mendeteksi *horizontal drag* (geser kiri/kanan) untuk memunculkan ikon panah balas (*swipe to reply*) lengkap dengan efek getar (*Haptic Feedback*).
- **`audio_player_widget.dart`**: 
  Widget ini sangat defensif (aman). Alih-alih me-*streaming* audio langsung dari URL (yang sering *buggy* di format `.m4a` iOS), widget ini diam-diam men-*download* audio ke memori sementara HP (`getTemporaryDirectory`), dan merender *Slider* UI yang diikat ke `onPositionChanged` dari paket `audioplayers`.
- **`voice_recording_bottom_sheet.dart`**: 
  Widget ini mengatur emosi visual! Menggunakan `AnimationController` untuk memompa (`ScaleTransition`) sebuah bulatan merah seolah-olah "berdenyut" (*pulse*) saat merekam. Ia mengelola State mandiri: `Recording` (merah berdenyut) dan status `Ready` (menampilkan pemutar mini untuk *preview* suara sebelum dikirim).
- **`quick_reply_overlay.dart`**: 
  Biasanya menggunakan `OverlayEntry` atau `Positioned`. Ketika *user* mengetik garis miring `/`, kotak melayang (*floating*) ini muncul di atas keyboard. Begitu *user* mengetik huruf selanjutnya, ia mem-*filter* *list* balasan template dari *provider* dan menampilkannya di *overlay* tersebut.

---

## 3. Kategori: Feedback & Loading (User Experience)

- **`connection_status_banner.dart`**: 
  Banner merah menyebalkan yang muncul otomatis dari atas kalau internet *down*. Widget ini sangat cerdas: ia punya variabel `_hasEverConnected`. Banner ini **ogah** muncul pas aplikasi pertama kali dibuka (karena pasti koneksi SignalR masih proses menyambung). Ia hanya mendengarkan `StreamSubscription` dari SignalR, dan jika mendeteksi putus di tengah jalan, baru ia akan *expand* turun.
- **`chat_list_skeleton`, `message_shimmer`, `room_shimmer`**: 
  *Shimmer* adalah teknik psikologi UX. Ketimbang maksa *user* ngeliatin *spinner* muter-muter (yang bikin *user* merasa nunggu lama), *shimmer* menggambar cetakan kotak-kotak kosong (replika avatar dan teks) abu-abu yang disapu animasi kilap cahaya dari kiri ke kanan. Ini memberi ilusi bahwa aplikasi sedang sibuk *"melukis data"* sehingga terasa lebih responsif dan modern.

---

## 4. Kategori: Input Helpers

- **`searchable_dropdown.dart`**: 
  Komponen ini krusial. Dropdown bawaan Android/iOS sangat payah kalau datanya di atas 30 item. Menggulir layar untuk mencari "Divisi Keuangan" di antara 100 opsi sangat menyiksa. Widget ini membungkus *list* ke dalam modal atau *overlay* yang memiliki kolom input pencarian (`TextField`) di bagian paling atasnya. Mengetik di sana langsung menyusutkan opsi di bawahnya.

---

## 5. Hubungan State Management di Widget (The Best Practice)

Apakah widget kecil ini boleh manggil `Provider.of` secara langsung?

- **Aturan Emas:** JANGAN mendengarkan (*listen*) *State Provider* langsung di dalam widget komponen yang dilooping berkali-kali!
- **Implementasi di Project ini:** Sudah sangat baik. File seperti `MessageBubbleWidget` menerima datanya disuapin lewat *Constructor* (`final Message message;`). Ia tidak pasang kuping ke `ChatProvider(listen:true)`. Kenapa? Bayangkan jika kamu punya 500 pesan (*bubble*) di layar, dan 1 *bubble* pasang kuping ke Provider. Saat 1 pesan baru masuk, Provider teriak *notifyListeners()*, maka 500 pesan lama itu ikut di-render ulang secara buta! HP *user* bisa kepanasan (*overheat*).
- Pemanggilan `Provider.of(..., listen: false)` hanya diizinkan di widget ini jika ia berupa *Action Button* (misal: tombol tekan "Simpan"), karena itu perintah eksekusi sepihak, bukan rutinitas re-render UI.

---

## 6. Review Performa & Potensi Lag

Mana widget yang jadi beban berat aplikasi?

**Juaranya adalah: `MessageBubbleWidget.dart`**
- Meskipun arsitekturnya sudah lumayan bagus, widget ini memendam "bom waktu" performa. Di dalam 1 *bubble*, ia menjalankan *Regex URL matcher* (deteksi *link* http di kalimat), menghitung logika ukuran maksimal teks, me-render *box shadow*, dan memegang *listener gesture drag update*.
- **Risiko Lag:** Kalau halaman *Detail Chat* lupa menggunakan pembungkus `ListView.builder` (yang hanya merender apa yang tampil di layar), dan malah mem-*build* ratusan *bubble* sekaligus di belakang layar, maka aplikasi akan mengalami *Frame Drop* (patah-patah) yang parah saat *scroll* ke atas/bawah. 
- *Audio* dan *Voice Record* relatif aman karena mereka tidak akan jalan serentak (ada *handling* memberhentikan *player* satu saat *player* lain menyala).

Kumpulan *widgets* ini sudah masuk kategori rapi dan dapat digunakan ulang lintas fitur (*Highly Reusable*). Semakin sedikit UI nyampur di layar utama (*screens*), dan semakin banyak dilempar ke `widgets`, aplikasimu akan semakin bersih dan rapi!
