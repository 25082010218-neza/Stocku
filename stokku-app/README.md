# Stokku — Aplikasi Inventaris & Penjualan (Desktop Suite)

Stokku adalah aplikasi inventaris, penjualan, dan pemantauan keuntungan untuk usaha retail ("Toko Kelontong Berkah").
Aplikasi ini telah dirapikan menjadi struktur folder siap pakai untuk **Aplikasi Desktop** yang dapat langsung dijalankan di **VS Code** (Visual Studio Code).

Palet antarmuka menggunakan tema **Biru & Putih** yang modern dengan tata letak desktop yang elegan, responsif, dan mempertahankan 100% tampilan serta fitur asli dari aplikasi Stokku.

---

## Struktur Folder Proyek

Struktur folder telah disusun rapi sesuai standar proyek Pemrograman Desktop:

```text
aplikasi_stocku/
├── .vscode/
│   ├── launch.json              # Konfigurasi Run / Debug langsung di VS Code (F5)
│   └── settings.json            # Konfigurasi path SDK Flutter & Dart
├── dart_api/                    # Backend REST API Dart (Shelf + MySQL)
│   ├── bin/
│   │   └── server.dart          # HTTP Router & Controller (bebas dari SQL mentah)
│   ├── lib/
│   │   ├── database_service.dart# Service eksekusi query & transaksi database
│   │   └── sql_queries.dart     # Kumpulan konstanta query SQL terpusat
│   ├── sql/
│   │   ├── schema.sql           # Skema DDL tabel database MySQL
│   │   ├── queries.sql          # Kumpulan query SQL (SELECT, INSERT, UPDATE, DELETE)
│   │   └── seed.sql             # Data awal / sampel produk dan faktur
│   ├── pubspec.yaml             # Dependensi server Dart
│   └── schema.sql               # Skema database MySQL
├── flutter_app/                 # Aplikasi Desktop Stokku (Flutter Windows Desktop)
│   ├── lib/
│   │   ├── api_service.dart     # Service komunikasi HTTP ke Dart API
│   │   ├── main.dart            # Seluruh antarmuka desktop Stokku (UI identik)
│   │   └── models.dart          # Model Product, Invoice, HPP, Komentar, Pareto
│   ├── pubspec.yaml             # Dependensi Flutter
│   └── windows/                 # Runner native Windows Desktop
├── src/                         # Sumber antarmuka Web React (Dashboard Suite)
│   ├── App.tsx                  # Kode komponen UI React Stokku
│   ├── index.css                # Style Tailwind CSS
│   ├── main.tsx                 # Entrypoint React
│   └── vite-env.d.ts            # Type definitions Vite
├── DATABASE_SETUP.md            # Panduan konfigurasi MySQL
└── README.md                    # Dokumentasi ini
```

> **Catatan Pembersihan:** File zip (`flutter_app.zip`, `src.zip`, `stocku.zip`, `stokku-project.zip`) dan file HTML seperti `stokku.html` serta `index.html` yang tidak diperlukan telah dihapus untuk memastikan folder rapi dan bersih.

---

## Cara Menjalankan Aplikasi di VS Code

### 1. Menjalankan Aplikasi Desktop (Flutter Windows)
Anda dapat menjalankan aplikasi langsung melalui antarmuka VS Code:
1. Buka folder `aplikasi_stocku` di VS Code.
2. Buka menu **Run and Debug** di bilah kiri (atau tekan `Ctrl + Shift + D`).
3. Pilih konfigurasi **`Stokku Desktop (Windows)`**.
4. Tekan tombol play hijau atau tekan tombol **`F5`**.
5. Jendela aplikasi desktop Stokku akan langsung terbuka di Windows.

*Atau melalui Terminal:*
```bash
cd flutter_app
flutter run -d windows
```

### 2. Menjalankan Backend Dart API (Opsional untuk Database MySQL)
Jika ingin menghubungkan aplikasi ke database MySQL:
1. Jalankan skema database di MySQL:
   ```bash
   mysql -u root -p < dart_api/schema.sql
   ```
2. Di VS Code, buka **Run and Debug** lalu pilih konfigurasi **`Stokku API Server`**, kemudian tekan **`F5`**.

*Atau melalui Terminal:*
```bash
cd dart_api
dart run bin/server.dart
```

---

## Akun dan Hak Akses Pengguna

Aplikasi menyediakan dua akun siap pakai:

| Akun | Role | Inisial | Hak Akses Utama |
| --- | --- | :---: | --- |
| **Budi Santoso** | Manager | `BS` | Ringkasan inventaris, ubah harga modal & jual, review faktur, berikan catatan koreksi, pantau statistik bisnis & Pareto Chart |
| **Rina Amelia** | Admin Stok | `RA` | Ringkasan inventaris, tambah produk baru dengan kalkulator HPP otomatis, kelola barang reject, buat faktur penjualan, lihat komentar |

Pengguna dapat berganti peran kapan saja melalui menu **Ganti Akun** di pojok kiri bawah sidebar atau keluar ke halaman login.

---

## Fitur-Fitur Utama Aplikasi Stokku

1. **Ringkasan (Dashboard):**
   - KPI total stok layak jual, total SKU, jumlah stok menipis/kritis, dan nilai inventaris.
   - Peringatan otomatis produk yang berada di batas minimum/kritis beserta aksi cepat.

2. **Daftar Produk:**
   - Filter pencarian instan berdasarkan nama produk, SKU, atau kategori.
   - Filter kategori cepat: *Semua*, *Sembako*, *Minuman*, *Makanan Ringan*.
   - Status stok dinamis (*Aman*, *Menipis*, *Kritis*).
   - Dialog khusus Manager untuk mengubah harga beli (modal) dan harga jual.

3. **Tambah Produk & Kalkulasi HPP (Admin):**
   - Input SKU, Nama, Kategori, Harga Jual, Batas Minimum, Stok Awal, dan Barang Reject.
   - **Komposisi Bahan Baku:** Admin dapat menambah bahan baku (nama, kuantitas, satuan `pcs/kg/gram/liter/pak`, biaya per satuan).
   - **Kalkulasi Otomatis:**
     - `HPP / Modal Satuan = Σ (Jumlah bahan × Biaya per satuan)`
     - `Stok Layak Jual = Stok Awal - Stok Reject`
     - `Nilai Inventaris = HPP × Stok Layak Jual`
     - `Potensi Rugi Reject = HPP × Stok Reject`

4. **Faktur & Pemesanan:**
   - Pembuatan faktur multi-item dengan kalkulasi subtotal dan total otomatis.
   - Pilihan metode pembayaran: **Cash (Lunas)** atau **Credit (Tempo)** dengan tanggal jatuh tempo.
   - Pengurangan stok otomatis saat faktur disimpan.
   - **Kolaborasi Koreksi:** Manager dapat menambahkan catatan koreksi faktur (maks 500 karakter) yang dapat dibaca oleh Admin.

5. **Statistik Bisnis line chart, bar chart dan pie chart (Manager):**
   - Metrik modal stok, potensi omzet, perkiraan keuntungan, margin potensi %, dan estimasi kerugian reject.
   - ** line Chart:** Menampilkan garis keuntungan periode (diurutkan dari kontribusi terbesar) dan kurva kumulatif 0–100% untuk periode Mingguan maupun Bulanan.
   - diagram batan, yang menampilkan jumlah produk produk yang masuk kedalam kategori jenis apa, seperti makanan,snack, minuman, dll.
   - Pie chart, yang menampilkan seluruh data faktur yang memisahkan antara pembeli atau client yang telah melakukan pembayaran, menyicil, hingga belum membayar sama sekali terhadap produk yang telah dipesan dan dicatat oleh role admin.




6. **Notifikasi Riwayat Harga:**
   - Ikon lonceng di header mencatat seluruh riwayat perubahan harga oleh Manager (harga lama ➔ harga baru) secara transparan.

7. **Profil & Sesi:**
   - Informasi usaha *Toko Kelontong Berkah*, ganti akun, dan fitur logout.
  
<img width="947" height="513" alt="Screenshot 2026-11-23 165806" src="https://github.com/user-attachments/assets/0b1eb137-e760-4fe1-a681-53a411633e1a" />
<img width="947" height="513" alt="Screenshot 2026-11-23 165752" src="https://github.com/user-attachments/assets/6e74726b-7f12-41e5-8eb1-5de813f70a09" />
<img width="944" height="509" alt="Screenshot 2026-11-23 165745" src="https://github.com/user-attachments/assets/ac252231-d6c6-4c12-8d8a-b6df7855e299" />
<img width="946" height="515" alt="Screenshot 2026-11-23 165735" src="https://github.com/user-attachments/assets/86006b71-bc84-4ca2-8d0d-b373fa73e8c8" />
<img width="948" height="515" alt="Screenshot 2026-11-23 165726" src="https://github.com/user-attachments/assets/f148d6af-4df7-4e1b-9c36-c21bedfa8ca5" />
<img width="946" height="511" alt="Screenshot 2026-11-23 165717" src="https://github.com/user-attachments/assets/7b57970c-1811-4d20-8c1d-6bbf93fff808" />
<img width="943" height="512" alt="Screenshot 2026-11-23 165709" src="https://github.com/user-attachments/assets/52b7436c-e19d-45ce-981f-9d108432a5f8" />
<img width="948" height="512" alt="Screenshot 2026-11-23 165652" src="https://github.com/user-attachments/assets/beb65e95-925f-414b-a338-0c64b3f15236" />
<img width="710" height="509" alt="Screenshot 2026-11-23 163745" src="https://github.com/user-attachments/assets/e403bcf6-f516-49de-a5af-2847e0c4f9ae" />

