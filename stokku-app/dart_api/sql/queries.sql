-- =======================================================
-- STOKKU SQL QUERIES COLLECTION (DML)
-- Seluruh query SQL yang digunakan oleh API backend Stokku
-- =======================================================

-- =======================================================
-- 1. MODUL PRODUK (PRODUCTS & INGREDIENTS)
-- =======================================================

-- [Q_PROD_01] Mengambil semua daftar produk diurutkan dari yang terbaru
SELECT id, name, sku, category, cost, price, stock, reject_stock, min_stock 
FROM products 
ORDER BY created_at DESC;

-- [Q_PROD_02] Menambahkan produk baru
INSERT INTO products (name, sku, category, cost, price, stock, reject_stock, min_stock) 
VALUES (?, ?, ?, ?, ?, ?, ?, ?);

-- [Q_PROD_03] Menambahkan rincian bahan / komposisi HPP produk
INSERT INTO product_ingredients (product_id, name, quantity, unit, unit_cost) 
VALUES (?, ?, ?, ?, ?);

-- [Q_PROD_04] Mengunci dan mengecek stok produk sebelum faktur dibuat (FOR UPDATE)
SELECT name, cost, price, stock 
FROM products 
WHERE id = ? 
FOR UPDATE;

-- [Q_PROD_05] Memotong stok produk saat faktur berhasil disimpan
UPDATE products 
SET stock = stock - ? 
WHERE id = ?;

-- [Q_PROD_06] Menghapus bahan produk (cascade fallback)
DELETE FROM product_ingredients 
WHERE product_id = ?;

-- [Q_PROD_07] Menghapus relasi item faktur produk jika ada
DELETE FROM invoice_items 
WHERE product_id = ?;

-- [Q_PROD_08] Menghapus data produk utama
DELETE FROM products 
WHERE id = ?;


-- =======================================================
-- 2. MODUL FAKTUR (INVOICES & LINES)
-- =======================================================

-- [Q_INV_01] Mengambil seluruh riwayat faktur penjualan
SELECT id, invoice_number, customer, contact, payment_type, payment_status, due_date, total, created_at 
FROM invoices 
ORDER BY created_at DESC;

-- [Q_INV_02] Menghitung total faktur dalam tahun berjalan untuk nomor urut otomatis
SELECT COUNT(*) AS total 
FROM invoices 
WHERE YEAR(created_at) = YEAR(CURRENT_DATE());

-- [Q_INV_03] Menyimpan header faktur penjualan baru
INSERT INTO invoices (invoice_number, customer, contact, payment_type, payment_status, due_date, total) 
VALUES (?, ?, ?, ?, ?, ?, ?);

-- [Q_INV_04] Menyimpan baris detail barang pada faktur
INSERT INTO invoice_lines (invoice_id, product_id, product_name, quantity, unit_cost, unit_price, subtotal) 
VALUES (?, ?, ?, ?, ?, ?, ?);

-- [Q_INV_05] Mengubah status pembayaran faktur (paid / unpaid / credit)
UPDATE invoices 
SET payment_status = ? 
WHERE id = ?;

-- [Q_INV_06] Menghapus seluruh komentar pada faktur
DELETE FROM invoice_comments 
WHERE invoice_id = ?;

-- [Q_INV_07] Menghapus seluruh baris detail barang pada faktur
DELETE FROM invoice_lines 
WHERE invoice_id = ?;

-- [Q_INV_08] Menghapus faktur utama
DELETE FROM invoices 
WHERE id = ?;


-- =======================================================
-- 3. MODUL STATISTIK KEUNTUNGAN (PROFIT & PARETO)
-- =======================================================

-- [Q_STAT_MONTHLY] Statistik keuntungan bulanan
SELECT DATE_FORMAT(i.created_at, '%Y-%m-01') AS period_start, 
       SUM((il.unit_price - il.unit_cost) * il.quantity) AS profit 
FROM invoices i 
INNER JOIN invoice_lines il ON il.invoice_id = i.id 
GROUP BY period_start 
ORDER BY period_start ASC;

-- [Q_STAT_WEEKLY] Statistik keuntungan mingguan
SELECT DATE_SUB(DATE(i.created_at), INTERVAL WEEKDAY(i.created_at) DAY) AS period_start, 
       SUM((il.unit_price - il.unit_cost) * il.quantity) AS profit 
FROM invoices i 
INNER JOIN invoice_lines il ON il.invoice_id = i.id 
GROUP BY period_start 
ORDER BY period_start ASC;


-- =======================================================
-- 4. MODUL KOMENTAR REVIEW FAKTUR (COMMENTS)
-- =======================================================

-- [Q_COMM_01] Mengambil semua komentar pada sebuah faktur
SELECT id, actor_name, message, created_at 
FROM invoice_comments 
WHERE invoice_id = ? 
ORDER BY created_at ASC;

-- [Q_COMM_02] Mengecek keberadaan faktur sebelum komentar ditambahkan
SELECT id 
FROM invoices 
WHERE id = ?;

-- [Q_COMM_03] Menyimpan komentar koreksi baru dari Manager
INSERT INTO invoice_comments (invoice_id, actor_role, actor_name, message) 
VALUES (?, 'manager', ?, ?);
