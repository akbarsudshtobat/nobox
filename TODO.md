# TODO - Perbaikan error pengiriman pesan/file

## Langkah 1
- [x] Telusuri kode Flutter: cari tempat pengiriman pesan (`sendMessage`) dan payload `ExtId/AccountIds`.

## Langkah 2
- [x] Validasi penyebab dari log: payload sudah benar tapi backend error `'long' does not contain a definition for 'ExtId'`.

## Langkah 3
- [ ] Update kontrak payload sesuai mentor di `lib/core/services/chat_service.dart` (method `sendMessage()`):
  - [ ] ambil `ExtId` dari `Entity.Extra.ExtId` (bukan `IdExt`)
  - [ ] paksa `ExtId` dan `AccountIds` selalu bertipe `String` (termasuk bila perlu koma untuk multiple akun)

## Langkah 4
- [ ] Jalankan test pengiriman pesan lagi dari aplikasi/terminal log untuk memastikan error hilang.

