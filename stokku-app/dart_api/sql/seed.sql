-- =======================================================
-- STOKKU SAMPLE / SEED DATA
-- Database: stokku
-- =======================================================

USE stokku;

-- 1. Seed Data Produk
INSERT INTO products (id, name, sku, category, cost, price, stock, reject_stock, min_stock) VALUES
(1, 'Minyak Goreng 2L', 'MK-001', 'Sembako', 28000, 32000, 24, 1, 8),
(2, 'Beras Premium 5kg', 'BR-005', 'Sembako', 58000, 68000, 15, 0, 10),
(3, 'Gula Pasir 1kg', 'GL-010', 'Sembako', 12500, 14500, 45, 0, 10),
(4, 'Teh Celup Kotak', 'TH-022', 'Minuman', 4800, 6500, 30, 0, 8),
(5, 'Kopi Sachet 10pcs', 'KP-031', 'Minuman', 9500, 12000, 25, 0, 8),
(6, 'Keripik Singkong Balado', 'SN-014', 'Makanan Ringan', 6500, 9000, 50, 2, 12)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 2. Seed Data Faktur
INSERT INTO invoices (id, invoice_number, customer, contact, payment_type, payment_status, due_date, total, created_at) VALUES
(1, 'INV-2026-001', 'Toko Berkah Mandiri', '0812 3456 7890', 'cash', 'paid', NULL, 128000, '2026-10-15 10:00:00'),
(2, 'INV-2026-002', 'Warung Bu Sri', '0813 9988 7766', 'credit', 'unpaid', '2026-11-20', 204000, '2026-10-16 11:30:00'),
(3, 'INV-2026-003', 'Kantin Sejahtera', '0857 1122 3344', 'credit', 'credit', '2026-11-05', 154000, '2026-10-17 14:15:00'),
(4, 'INV-2026-004', 'Bu Siti Sembako', '0821 7766 5544', 'cash', 'paid', NULL, 128000, '2026-10-18 09:45:00'),
(5, 'INV-2026-005', 'Depot Barokah', '0819 5544 3322', 'credit', 'credit', '2026-11-12', 90000, '2026-10-19 16:20:00')
ON DUPLICATE KEY UPDATE invoice_number=VALUES(invoice_number);

-- 3. Seed Data Baris Faktur
INSERT INTO invoice_lines (invoice_id, product_id, product_name, quantity, unit_cost, unit_price, subtotal) VALUES
(1, 1, 'Minyak Goreng 2L', 4, 28000, 32000, 128000),
(2, 2, 'Beras Premium 5kg', 3, 58000, 68000, 204000),
(3, 5, 'Kopi Sachet 10pcs', 8, 9500, 12000, 96000),
(3, 3, 'Gula Pasir 1kg', 4, 12500, 14500, 58000),
(4, 1, 'Minyak Goreng 2L', 4, 28000, 32000, 128000),
(5, 6, 'Keripik Singkong Balado', 10, 6500, 9000, 90000);
