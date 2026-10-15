# Notif Transaksi Demo (Flutter)

Starter project untuk simulator notifikasi lokal Android. Semua notifikasi diberi label **DEMO** dan menyatakan bahwa notifikasi bukan transaksi asli.

## Build APK tanpa memasang Flutter di Termux

Cara ini menggunakan GitHub Actions untuk build di cloud, sementara Termux dipakai untuk menyiapkan file bila perlu.

1. Unduh ZIP starter ini dan ekstrak.
2. Buat repository baru di GitHub.
3. Upload isi folder `notif_demo_flutter` ke repository (pastikan folder `.github/workflows` ikut ter-upload; GitHub kadang menyembunyikan folder titik di file picker).
4. Buka tab **Actions** pada repository dan jalankan workflow **Build Flutter APK**. Jika Actions belum aktif, aktifkan terlebih dahulu.
5. Setelah workflow selesai, buka hasil run → **Artifacts** → unduh `notif-demo-apk`.
6. Ekstrak artifact dan install `app-release.apk` di HP. Android mungkin meminta izin memasang aplikasi dari sumber tersebut.
7. Buka aplikasi dan izinkan notifikasi saat diminta.

Workflow akan membuat kerangka project Android Flutter di runner GitHub, memasukkan kode aplikasi, lalu membangun APK. Jadi folder `android/` di ZIP ini hanya berisi contoh permission, bukan project Android lengkap.

## Build lokal di komputer
Install Flutter SDK dan Android SDK, buat project dengan `flutter create notif_demo_flutter`, salin `lib/main.dart` dan `pubspec.yaml` dari starter ini, lalu gabungkan permission `POST_NOTIFICATIONS` ke manifest bawaan. Jalankan:
```bash
flutter pub get
flutter build apk --release
```
APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.

## Catatan
- Ini simulator notifikasi lokal, bukan integrasi dengan bank/dompet digital.
- Nominal dan pengirim hanyalah teks simulasi.
- Jangan gunakan notifikasi ini sebagai bukti pembayaran.
