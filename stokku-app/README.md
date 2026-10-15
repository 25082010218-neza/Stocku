# Stokku

Stokku adalah aplikasi inventaris, penjualan, dan pemantauan keuntungan untuk
usaha retail. Proyek ini terdiri dari tiga bagian:

1. **Web React** sebagai dashboard utama dan prototipe antarmuka.
2. **REST API Dart** sebagai penghubung aman ke database MySQL.
3. **Aplikasi Flutter** sebagai fondasi klien mobile.

Palet antarmuka menggunakan biru dan putih dengan font **Plus Jakarta Sans**.
Tampilan dibuat responsif untuk desktop maupun perangkat berukuran kecil.

## Daftar Isi

- [Arsitektur](#arsitektur)
- [Akun dan Hak Akses](#akun-dan-hak-akses)
- [Fitur Aplikasi](#fitur-aplikasi)
- [Alur Utama](#alur-utama)
- [Struktur Proyek](#struktur-proyek)
- [Model Data MySQL](#model-data-mysql)
- [REST API Dart](#rest-api-dart)
- [Menjalankan Proyek](#menjalankan-proyek)
- [HTML Mandiri](#html-mandiri)
- [Catatan Implementasi dan Keamanan](#catatan-implementasi-dan-keamanan)

## Arsitektur

Arsitektur persistensi yang disarankan:

```text
┌──────────────────┐
│ React Web        │
│ Flutter Mobile   │
└────────┬─────────┘
         │ HTTP / JSON
         ▼
┌──────────────────┐
│ REST API Dart    │
│ Shelf + Router   │
└────────┬─────────┘
         │ Transaksi SQL
         ▼
┌──────────────────┐
│ MySQL            │
└──────────────────┘
```

Aplikasi klien tidak terhubung langsung ke MySQL. Seluruh kredensial database,
validasi role, penguncian stok, dan transaksi disimpan di sisi server Dart.

> **Status implementasi:** dashboard React saat ini menggunakan state lokal untuk
> demonstrasi interaktif. REST API Dart, skema MySQL, dan service Flutter sudah
> tersedia sebagai lapisan persistensi. Untuk produksi, pemanggilan state React
> perlu diarahkan ke endpoint API yang sama.

## Akun dan Hak Akses

Aplikasi menyediakan dua akun demonstrasi.

### Manager

- **Nama:** Budi Santoso
- **Role:** Manager
- **Inisial:** BS

Manager berfokus pada pengawasan, harga, analitik, dan koreksi transaksi.

### Admin Stok

- **Nama:** Rina Amelia
- **Role:** Admin Stok
- **Inisial:** RA

Admin berfokus pada operasional produk, stok, dan pembuatan faktur.

### Matriks Hak Akses

| Modul/Fitur | Manager | Admin Stok |
| --- | :---: | :---: |
| Ringkasan inventaris | Lihat | Lihat |
| Daftar produk | Lihat | Lihat |
| Mengubah harga modal dan jual | Ya | Tidak |
| Tambah produk | Tidak | Ya |
| Komposisi bahan/HPP | Tidak | Ya |
| Pencatatan barang reject | Tidak | Ya |
| Membuat faktur | Tidak | Ya |
| Melihat faktur | Ya | Ya |
| Cetak/PDF dan bagikan faktur | Ya | Ya |
| Memberikan komentar koreksi faktur | Ya | Tidak |
| Melihat komentar koreksi | Ya | Ya |
| Statistik bisnis | Ya | Tidak |
| Pareto keuntungan | Ya | Tidak |
| Riwayat perubahan harga | Ya | Ya |
| Profil, ganti akun, dan logout | Ya | Ya |

Pembatasan akses diterapkan pada antarmuka React dan endpoint Dart. Header role
yang digunakan oleh API saat ini adalah `x-stokku-role`.

## Fitur Aplikasi

### 1. Ringkasan Inventaris

Halaman awal menampilkan:

- Total stok yang dapat dijual.
- Jumlah produk/SKU.
- Jumlah produk dengan stok menipis atau kritis.
- Nilai inventaris untuk Manager.
- Daftar produk yang perlu segera diperhatikan.

Status stok dihitung dari jumlah stok dan batas minimum:

- **Aman:** stok di atas batas minimum.
- **Menipis:** stok sama dengan atau di bawah batas minimum.
- **Kritis:** stok sama dengan atau di bawah setengah batas minimum.

### 2. Daftar Produk

Fitur daftar produk mencakup:

- Pencarian berdasarkan nama, SKU, dan kategori.
- Filter kategori.
- Informasi harga jual, stok layak jual, dan jumlah reject.
- Indikator kondisi stok.
- Aksi perubahan harga khusus Manager.

Setiap perubahan harga oleh Manager dicatat ke riwayat notifikasi yang dapat
dilihat oleh kedua role.

### 3. Tambah Produk — Khusus Admin

Menu Tambah Produk tidak ditampilkan untuk Manager. Admin dapat mengisi:

- Nama produk.
- SKU.
- Kategori.
- Harga jual.
- Batas stok minimum.
- Stok awal.
- Barang reject atau rusak.

#### Komposisi Bahan dan HPP

Admin dapat menambahkan beberapa komponen bahan:

- Nama bahan.
- Jumlah.
- Satuan, misalnya `pcs`, `kg`, `gram`, `liter`, atau `pak`.
- Biaya per satuan.

HPP/modal satuan dihitung otomatis:

```text
HPP = Σ (jumlah bahan × biaya per satuan)
```

Nilai inventaris dan kerugian reject:

```text
Stok layak jual       = stok awal - stok reject
Nilai inventaris      = HPP × stok layak jual
Potensi rugi reject   = HPP × stok reject
```

### 4. Faktur

#### Admin

Admin dapat:

- Membuat faktur.
- Mengisi nama pelanggan/toko dan kontak.
- Memilih beberapa produk.
- Menentukan jumlah setiap produk.
- Melihat subtotal dan total otomatis.
- Memilih pembayaran `Cash` atau `Credit`.
- Menentukan tanggal jatuh tempo untuk Credit.
- Menyimpan faktur dan memotong stok.
- Melihat komentar koreksi Manager.

Status pembayaran ditentukan otomatis:

- **Cash:** Lunas.
- **Credit:** Belum lunas.

#### Manager

Manager tidak dapat membuat faktur, tetapi dapat:

- Melihat seluruh faktur yang dibuat Admin.
- Membuka panel review faktur.
- Menambahkan komentar koreksi maksimal 500 karakter.
- Melihat riwayat komentar pada setiap faktur.

Komentar Manager dapat digunakan untuk menandai kesalahan jumlah, produk,
pelanggan, harga, atau informasi pembayaran.

#### Output Faktur

Faktur dapat:

- Dicetak.
- Disimpan sebagai PDF melalui dialog cetak browser.
- Dibagikan melalui WhatsApp.

### 5. Statistik — Khusus Manager

Halaman Statistik hanya tersedia bagi Manager dan menampilkan:

- Total modal stok.
- Potensi omzet.
- Perkiraan keuntungan.
- Margin potensi.
- Jumlah dan estimasi kerugian barang reject.
- Kontribusi nilai jual setiap produk.

#### Pareto Chart Keuntungan

Pareto Chart menyediakan pilihan:

- **Mingguan**
- **Bulanan**

Elemen grafik:

- Batang biru menunjukkan keuntungan setiap periode.
- Periode diurutkan dari kontribusi keuntungan terbesar.
- Garis kuning menunjukkan persentase kumulatif hingga 100%.
- Ringkasan menunjukkan total keuntungan, periode terbaik, dan keuntungan
  tertinggi.

Keuntungan faktur dihitung dari:

```text
Keuntungan item = (harga jual - harga modal saat transaksi) × jumlah
```

Harga modal disimpan sebagai snapshot `unit_cost` pada detail faktur. Statistik
historis tetap konsisten walaupun harga modal produk kemudian berubah.

### 6. Notifikasi Perubahan Harga

Notifikasi menampilkan:

- Produk yang diubah.
- Pengguna yang melakukan perubahan.
- Harga lama dan harga baru.
- Waktu perubahan.

Riwayat dapat dibaca Manager dan Admin.

### 7. Profil dan Sesi

Halaman Profil menampilkan:

- Nama pengguna.
- Role akun.
- Nama toko: **Toko Kelontong Berkah**.
- Pilihan ganti akun.
- Tombol logout.

Setelah logout, pengguna diarahkan ke layar pemilihan akun.

## Alur Utama

### Alur Produk

```text
Admin mengisi produk
  → menambahkan komposisi bahan
  → sistem menghitung HPP
  → sistem memisahkan stok layak jual dan reject
  → produk disimpan
```

### Alur Faktur

```text
Admin membuat faktur
  → API mengunci baris produk dengan SELECT ... FOR UPDATE
  → API memvalidasi stok
  → faktur dan detail disimpan
  → stok dipotong
  → transaksi di-commit
```

Jika salah satu proses gagal, transaksi dibatalkan dengan `ROLLBACK`.

### Alur Koreksi

```text
Admin membuat faktur
  → Manager membuka Faktur
  → Manager melakukan review
  → Manager menambahkan komentar koreksi
  → Admin membaca dan menindaklanjuti komentar
```

### Alur Statistik

```text
Detail faktur menyimpan harga jual dan modal
  → API menghitung selisih keuntungan
  → transaksi dikelompokkan per minggu/bulan
  → Pareto Chart mengurutkan kontribusi terbesar
  → garis kumulatif dihitung hingga 100%
```

## Struktur Proyek

```text
.
├── src/
│   ├── App.tsx              # UI utama, role, produk, faktur, komentar, statistik
│   ├── index.css            # Tailwind CSS dan Plus Jakarta Sans
│   ├── main.tsx             # Entrypoint React
│   └── vite-env.d.ts        # Tipe environment Vite
├── dart_api/
│   ├── bin/
│   │   └── server.dart      # REST API, role guard, transaksi, dan query MySQL
│   ├── migrations/
│   │   └── 002_invoice_profit.sql
│   ├── .env.example         # Contoh environment database
│   ├── pubspec.yaml         # Dependensi server Dart
│   └── schema.sql           # Skema database lengkap
├── flutter_app/
│   ├── lib/
│   │   ├── api_service.dart # HTTP client ke REST API Stokku
│   │   ├── main.dart        # Entrypoint dan layar Flutter dasar
│   │   └── models.dart      # Model Product dan input Faktur
│   └── pubspec.yaml         # Dependensi Flutter
├── .figma/make/             # Konfigurasi environment Figma Make
├── DATABASE_SETUP.md        # Panduan khusus database dan API
├── stokku.html              # Build HTML mandiri dengan CSS/JS tertanam
├── index.html               # Shell HTML Vite
├── package.json             # Dependensi dan script web
├── pnpm-lock.yaml           # Lockfile pnpm
├── tsconfig.json            # Konfigurasi TypeScript
└── vite.config.ts           # Konfigurasi Vite, React, Tailwind, dan Figma Make
```

### Teknologi

#### Web

- React 19
- TypeScript 5.7
- Vite 8
- Tailwind CSS 4
- Plus Jakarta Sans

#### Server

- Dart SDK 3.4 atau lebih baru
- Shelf
- Shelf Router
- mysql1
- MySQL dengan tabel InnoDB

#### Mobile

- Flutter
- HTTP client
- Material 3

## Model Data MySQL

### `products`

Menyimpan produk, SKU, kategori, HPP, harga jual, stok layak jual, stok reject,
dan batas minimum.

### `product_ingredients`

Menyimpan komposisi bahan setiap produk:

- Produk induk.
- Nama bahan.
- Kuantitas.
- Satuan.
- Biaya satuan.

### `invoices`

Menyimpan:

- Nomor faktur.
- Pelanggan dan kontak.
- Jenis serta status pembayaran.
- Jatuh tempo.
- Total transaksi.
- Waktu pembuatan.

### `invoice_lines`

Menyimpan detail item faktur:

- Produk.
- Nama produk saat transaksi.
- Kuantitas.
- Snapshot harga modal.
- Harga jual.
- Subtotal.

### `invoice_comments`

Menyimpan komentar koreksi Manager:

- Faktur terkait.
- Role dan nama pemberi komentar.
- Isi komentar.
- Waktu pembuatan.

## REST API Dart

Base URL lokal:

```text
http://localhost:8080/api
```

| Method | Endpoint | Role | Keterangan |
| --- | --- | --- | --- |
| GET | `/health` | Publik | Status API |
| GET | `/products` | Klien | Daftar produk |
| POST | `/products` | Admin | Membuat produk dan bahan |
| GET | `/invoices` | Admin, Manager | Daftar faktur |
| POST | `/invoices` | Admin | Membuat faktur dan memotong stok |
| GET | `/invoices/:id/comments` | Admin, Manager | Membaca komentar |
| POST | `/invoices/:id/comments` | Manager | Menambahkan koreksi |
| GET | `/statistics/profit?period=week` | Manager | Keuntungan mingguan |
| GET | `/statistics/profit?period=month` | Manager | Keuntungan bulanan |

Contoh header role:

```http
x-stokku-role: manager
```

Header tersebut hanya merupakan implementasi demonstrasi. Produksi harus
mengambil role dari token autentikasi yang ditandatangani dan diverifikasi server.

## Menjalankan Proyek

### Persyaratan

- Node.js 22
- pnpm 10
- Dart SDK 3.4+
- Flutter yang kompatibel dengan Dart 3.4+
- MySQL 8+

Versi Node.js dan pnpm proyek juga dicatat di `.mise.toml`.

### 1. Web React

Instal dependensi:

```bash
pnpm install
```

Build produksi:

```bash
pnpm build
```

Jalankan development server di luar environment Figma Make:

```bash
pnpm dev
```

Di Figma Make, server development sudah dijalankan otomatis.

### 2. Database MySQL

```bash
mysql -u root -p < dart_api/schema.sql
```

Untuk database yang dibuat sebelum penambahan statistik Pareto:

```bash
mysql -u root -p < dart_api/migrations/002_invoice_profit.sql
```

### 3. REST API Dart

Salin nilai dari `dart_api/.env.example` ke environment sistem, lalu:

```bash
cd dart_api
dart pub get

DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=stokku \
DB_USER=stokku \
DB_PASSWORD=password_anda \
dart run bin/server.dart
```

Tes:

```bash
curl http://localhost:8080/api/health
```

### 4. Flutter

```bash
cd flutter_app
flutter pub get
flutter run --dart-define=STOKKU_API_URL=http://10.0.2.2:8080/api
```

`10.0.2.2` digunakan Android Emulator untuk mengakses host. Pada perangkat
fisik, gunakan IP lokal komputer. Pada produksi, gunakan URL HTTPS.

## HTML Mandiri

File `stokku.html` berisi CSS dan JavaScript web yang sudah ditanam ke satu file.
File dapat dibuka langsung di browser untuk mendemonstrasikan aplikasi tanpa
menjalankan Vite.

Perubahan yang dibuat di source React tidak otomatis memperbarui file ini.
Setelah pengembangan, HTML mandiri perlu diregenerasi dari hasil build terbaru.

## Catatan Implementasi dan Keamanan

- Jangan menyimpan password MySQL di source code atau repository.
- Gunakan pengguna MySQL dengan hak akses minimum.
- Gunakan HTTPS untuk API produksi.
- Batasi CORS ke domain resmi aplikasi.
- Ganti header role demonstrasi dengan autentikasi berbasis token.
- Validasi kembali seluruh input di server walaupun sudah divalidasi di klien.
- Jalankan backup database secara terjadwal.
- Gunakan migration runner untuk deployment database produksi.
- Tambahkan pagination untuk produk, faktur, dan komentar ketika data membesar.
- Tambahkan pengujian integrasi untuk transaksi stok dan otorisasi sebelum
  digunakan pada data produksi.

Dokumentasi detail pemasangan database tersedia di
[`DATABASE_SETUP.md`](DATABASE_SETUP.md).
