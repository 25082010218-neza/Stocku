# Stokku Mobile Web Prototype

Prototipe antarmuka aplikasi mobile manajemen stok toko **Stokku** berbasis HTML5, CSS3, dan Vanilla JavaScript.

## 📱 Ringkasan 7 Layar yang Dibuat

1. **01 — Login**:
   - Status bar modern (`09:41`, sinyal, wifi, baterai).
   - Form input Email & Password dengan styling rounded modern.
   - Tombol cepat **Akun Demo** (mengisi otomatis kredensial Budi) & tombol Google.
   - Tombol "Masuk" yang mengarahkan langsung ke Dashboard.

2. **02 — Registrasi**:
   - Header dengan tombol kembali (`<`).
   - Form pendaftaran lengkap: Nama Lengkap, Nama Toko, Email, Nomor WhatsApp, Password, Konfirmasi Password, serta checkbox Syarat & Ketentuan.

3. **03 — Dashboard Beranda**:
   - Kartu metrik: **Total Stok** (`1,284`) dan **Stok Menipis** (`12`).
   - Kartu **Menunggu Persetujuan**: Perubahan Harga Minyak Goreng dengan tombol aksi **Terima** (hijau) & **Tolak** (merah).
   - Daftar **Produk Perlu Perhatian** dengan status Kritis, Menipis, dan Stok Aman.
   - Bottom navigation bar interaktif.

4. **04 — Master Data Produk (List)**:
   - Pencarian real-time berdasarkan Nama / SKU produk.
   - Filter Chips Kategori: *Semua*, *Sembako*, *Minuman*, *Snack*.
   - Floating Action Button (**+**) untuk menambah produk baru.

5. **05 — Tambah Produk (Form)**:
   - Kotak upload foto produk (dashed border).
   - Form Nama, SKU, Kategori, Harga Grosir, Harga Eceran, Stok Awal, dan Batas Minimum.
   - Tombol **Simpan Produk** yang secara dinamis menambahkan item baru ke daftar produk dan mengupdate hitungan total stok.

6. **06 — Master Data Kategori/Supplier**:
   - Segmented control toggle: beralih antara daftar **Kategori** dan daftar **Supplier**.
   - Menampilkan total item pada masing-masing kategori dan supplier.

7. **07 — Profil & Logout**:
   - Banner hero biru dengan avatar profil Budi Santoso (Pemilik Toko).
   - Menu pengelolaan: Informasi Akun, Toko Saya, Kelola Pengguna/Staf, Riwayat Persetujuan, Keamanan.
   - Tombol **Keluar (Logout)** bergaris merah dengan konfirmasi keluar.

---

## 🚀 Fitur Unggulan Dual-View

Pada bagian atas halaman web terdapat toolbar dengan fitur:
- **Simulator HP**: Menampilkan 1 frame smartphone interaktif di tengah layar. Anda dapat mengklik tombol masuk, navigasi bawah, tambah produk, cari produk, hingga logout seperti menggunakan aplikasi nyata.
- **Galeri 7 Layar**: Menampilkan seluruh 7 layar berjajar secara horizontal persis seperti gambar desain yang diunggah.
- **Lompat Cepat**: Tombol navigasi cepat untuk langsung melihat layar mana saja yang diinginkan dengan 1 kali klik.

---

## 📂 Struktur File

Folder: `C:\Users\LENOVO\.gemini\antigravity\scratch\stokku-app\`
- `index.html` : Halaman utama (menggunakan file CSS dan JS terpisah).
- `style.css` : Lembar gaya CSS responsive dan desain mobile bezel frame.
- `script.js` : Logika navigasi, filter pencarian, penambahan produk dinamis, dan interaksi.
- `stokku-single.html` : Versi mandiri 1 file (HTML + CSS + JS inline) yang bisa langsung dibuka di browser mana pun tanpa kendala path.

---

## 🖥️ Cara Menjalankan

Cukup klik dua kali (double click) file `index.html` atau `stokku-single.html` di File Explorer, atau buka melalui browser Google Chrome / Edge.
