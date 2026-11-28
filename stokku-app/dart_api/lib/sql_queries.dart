/// Kumpulan query SQL untuk aplikasi Stokku API.
/// Seluruh string query SQL dipisahkan secara terpusat di file ini
/// sehingga tidak tercampur dengan controller atau routing HTTP.
class SqlQueries {
  // ----------------------------------------------------
  // PRODUK
  // ----------------------------------------------------
  static const String selectAllProducts = '''
    SELECT id, name, sku, category, cost, price, stock, reject_stock, min_stock
    FROM products
    ORDER BY created_at DESC
  ''';

  static const String insertProduct = '''
    INSERT INTO products (name, sku, category, cost, price, stock, reject_stock, min_stock)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const String insertProductIngredient = '''
    INSERT INTO product_ingredients (product_id, name, quantity, unit, unit_cost)
    VALUES (?, ?, ?, ?, ?)
  ''';

  static const String selectProductForUpdate = '''
    SELECT name, cost, price, stock
    FROM products
    WHERE id = ?
    FOR UPDATE
  ''';

  static const String updateProductStockDeduct = '''
    UPDATE products
    SET stock = stock - ?
    WHERE id = ?
  ''';

  static const String deleteProductIngredients = '''
    DELETE FROM product_ingredients
    WHERE product_id = ?
  ''';

  static const String deleteProductInvoiceItems = '''
    DELETE FROM invoice_items
    WHERE product_id = ?
  ''';

  static const String deleteProduct = '''
    DELETE FROM products
    WHERE id = ?
  ''';

  // ----------------------------------------------------
  // FAKTUR
  // ----------------------------------------------------
  static const String selectAllInvoices = '''
    SELECT id, invoice_number, customer, contact, payment_type, payment_status,
           due_date, total, created_at
    FROM invoices
    ORDER BY created_at DESC
  ''';

  static const String countInvoicesCurrentYear = '''
    SELECT COUNT(*) AS total
    FROM invoices
    WHERE YEAR(created_at) = YEAR(CURRENT_DATE())
  ''';

  static const String insertInvoice = '''
    INSERT INTO invoices (invoice_number, customer, contact, payment_type, payment_status, due_date, total)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ''';

  static const String insertInvoiceLine = '''
    INSERT INTO invoice_lines (invoice_id, product_id, product_name, quantity, unit_cost, unit_price, subtotal)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ''';

  static const String deleteInvoiceComments = '''
    DELETE FROM invoice_comments
    WHERE invoice_id = ?
  ''';

  static const String deleteInvoiceItems = '''
    DELETE FROM invoice_items
    WHERE invoice_id = ?
  ''';

  static const String deleteInvoiceLines = '''
    DELETE FROM invoice_lines
    WHERE invoice_id = ?
  ''';

  static const String deleteInvoice = '''
    DELETE FROM invoices
    WHERE id = ?
  ''';

  // ----------------------------------------------------
  // STATISTIK KEUNTUNGAN
  // ----------------------------------------------------
  static String selectProfitStatistics(String periodExpression) => '''
    SELECT $periodExpression AS period_start,
           SUM((il.unit_price - il.unit_cost) * il.quantity) AS profit
    FROM invoices i
    INNER JOIN invoice_lines il ON il.invoice_id = i.id
    GROUP BY period_start
    ORDER BY period_start ASC
  ''';

  // ----------------------------------------------------
  // KOMENTAR FAKTUR
  // ----------------------------------------------------
  static const String selectCommentsByInvoiceId = '''
    SELECT id, actor_name, message, created_at
    FROM invoice_comments
    WHERE invoice_id = ?
    ORDER BY created_at ASC
  ''';

  static const String checkInvoiceExists = '''
    SELECT id
    FROM invoices
    WHERE id = ?
  ''';

  static const String insertInvoiceComment = '''
    INSERT INTO invoice_comments (invoice_id, actor_role, actor_name, message)
    VALUES (?, 'manager', ?, ?)
  ''';
}
