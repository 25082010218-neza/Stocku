# Integrasi Flutter, Dart API, dan MySQL

Arsitektur yang digunakan:

`Flutter Desktop / React Web → REST API Dart (Shelf) → DatabaseService → MySQL`

Aplikasi klien tidak terhubung langsung ke MySQL agar kata sandi database tidak tertanam di aplikasi klien dan validasi stok dapat dijalankan secara aman dalam transaksi database di sisi server.

---

## 1. Pemisahan Kode Program dan File SQL

Untuk menjaga kerapian arsitektur (*Clean Code & Separation of Concerns*), seluruh kode program backend dan instruksi SQL telah dipisahkan secara modular:

```text
dart_api/
├── bin/
│   └── server.dart             # HTTP Routing & Controller (murni tanpa string SQL)
├── lib/
│   ├── database_service.dart   # Service eksekusi query & transaksi database
│   └── sql_queries.dart        # Kumpulan konstanta query SQL terpusat
├── sql/
│   ├── schema.sql              # Skema DDL pembuatan database & tabel
│   ├── queries.sql             # Kumpulan query SQL (SELECT, INSERT, UPDATE, DELETE)
│   └── seed.sql                # Data awal / sampel produk dan faktur
└── schema.sql                  # Salinan skema utama untuk kemudahan impor
```

---

## 2. Menyiapkan Database MySQL

Jalankan skema database ke MySQL melalui terminal:

```bash
# 1. Buat database dan struktur tabel:
mysql -u root -p < dart_api/sql/schema.sql

# 2. (Opsional) Masukkan data awal produk dan faktur sampel:
mysql -u root -p < dart_api/sql/seed.sql
```

Tabel yang dibuat meliputi:
* **`products`**: Data barang, harga modal, harga jual, stok layak jual, stok reject, dan min stock.
* **`product_ingredients`**: Komposisi bahan untuk kalkulasi HPP otomatis.
* **`invoices`**: Header transaksi penjualan (tipe pembayaran cash/credit, status paid/unpaid/credit).
* **`invoice_lines`**: Rincian item produk yang terjual dalam faktur.
* **`invoice_comments`**: Catatan review / koreksi faktur antar role.

---

## 3. Menjalankan Server API Dart

```bash
cd dart_api
dart pub get

# Jalankan server dengan kredensial MySQL Anda:
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=stokku \
DB_USER=root \
DB_PASSWORD=password_anda \
dart run bin/server.dart
```

Uji koneksi melalui browser atau curl:
`GET http://localhost:8080/api/health`

---

## 4. Hak Akses & Endpoint API

| Endpoint | Method | Role Akses | Keterangan |
| --- | :---: | :---: | --- |
| `/api/products` | GET | Semua | Mengambil seluruh katalog produk |
| `/api/products` | POST | Gudang | Menambah produk baru (dengan transaksi komposisi HPP) |
| `/api/products/:id` | DELETE | Gudang | Menghapus data produk |
| `/api/invoices` | GET | Admin, Manager | Mengambil riwayat faktur penjualan |
| `/api/invoices` | POST | Admin | Membuat faktur baru & potong stok otomatis |
| `/api/invoices/:id` | DELETE | Admin | Menghapus faktur penjualan |
| `/api/invoices/:id/comments` | GET | Admin, Manager | Mengambil komentar review faktur |
| `/api/invoices/:id/comments` | POST | Manager | Mengirim komentar koreksi faktur |
| `/api/statistics/profit` | GET | Manager | Agregasi omzet & keuntungan bulanan/mingguan |
