-- =======================================================
-- STOKKU DATABASE SCHEMA (DDL)
-- Database: stokku
-- Charset: utf8mb4 / utf8mb4_unicode_ci
-- =======================================================

CREATE DATABASE IF NOT EXISTS stokku
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE stokku;

-- -------------------------------------------------------
-- 1. TABEL PRODUK (products)
-- Menyimpan katalog barang, harga modal (HPP), harga jual,
-- stok fisik layak jual, stok reject, dan batas minimum.
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  sku VARCHAR(50) NOT NULL UNIQUE,
  category VARCHAR(80) NOT NULL,
  cost BIGINT UNSIGNED NOT NULL,
  price BIGINT UNSIGNED NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,
  reject_stock INT UNSIGNED NOT NULL DEFAULT 0,
  min_stock INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -------------------------------------------------------
-- 2. TABEL KOMPOSISI / BAHAN PRODUK (product_ingredients)
-- Digunakan untuk kalkulator HPP otomatis pada produk racikan.
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_ingredients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(150) NOT NULL,
  quantity DECIMAL(12,3) UNSIGNED NOT NULL,
  unit VARCHAR(30) NOT NULL,
  unit_cost BIGINT UNSIGNED NOT NULL,
  CONSTRAINT fk_ingredient_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------
-- 3. TABEL FAKTUR PENJUALAN (invoices)
-- Mencatat transaksi penjualan, pelanggan, tipe pembayaran (cash/credit),
-- status pembayaran (paid/unpaid/credit), tempo, dan total tagihan.
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_number VARCHAR(40) NOT NULL UNIQUE,
  customer VARCHAR(150) NOT NULL,
  contact VARCHAR(150) NOT NULL DEFAULT "",
  payment_type ENUM("cash", "credit") NOT NULL DEFAULT "cash",
  payment_status ENUM("paid", "unpaid", "credit") NOT NULL DEFAULT "unpaid",
  due_date DATE NULL,
  total BIGINT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -------------------------------------------------------
-- 4. TABEL BARIS / ITEM FAKTUR (invoice_lines)
-- Detail barang dan kuantitas yang dibeli pada setiap faktur.
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoice_lines (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  product_name VARCHAR(150) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  unit_cost BIGINT UNSIGNED NOT NULL,
  unit_price BIGINT UNSIGNED NOT NULL,
  subtotal BIGINT UNSIGNED NOT NULL,
  CONSTRAINT fk_line_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
  CONSTRAINT fk_line_product
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

-- -------------------------------------------------------
-- 5. TABEL KOMENTAR / REVIEW FAKTUR (invoice_comments)
-- Catatan koreksi dari Manager untuk Admin mengenai suatu faktur.
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoice_comments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_id BIGINT UNSIGNED NOT NULL,
  actor_role ENUM("manager", "admin", "gudang") NOT NULL DEFAULT "manager",
  actor_name VARCHAR(150) NOT NULL,
  message VARCHAR(500) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comment_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------
-- INDEKS OPTIMASI
-- -------------------------------------------------------
CREATE INDEX idx_invoices_status_due_date
  ON invoices (payment_status, due_date);

CREATE INDEX idx_invoice_comments_invoice
  ON invoice_comments (invoice_id, created_at);
