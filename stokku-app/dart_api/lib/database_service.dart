import "package:mysql1/mysql1.dart";
import "sql_queries.dart";

/// Service untuk menangani seluruh operasi database MySQL.
/// Mengenkapsulasi query SQL dan transaksi secara terpisah dari HTTP router.
class DatabaseService {
  final MySqlConnection _db;

  DatabaseService(this._db);

  // ==========================================
  // PRODUK
  // ==========================================

  /// Mengambil semua produk
  Future<List<Map<String, dynamic>>> getProducts() async {
    final rows = await _db.query(SqlQueries.selectAllProducts);
    return rows
        .map((row) => {
              "id": row["id"],
              "name": row["name"],
              "sku": row["sku"],
              "category": row["category"],
              "cost": row["cost"],
              "price": row["price"],
              "stock": row["stock"],
              "rejectStock": row["reject_stock"],
              "minStock": row["min_stock"],
            })
        .toList();
  }

  /// Menambah produk baru beserta komposisi bahan dalam transaksi
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String sku,
    required String category,
    required int cost,
    required int price,
    required int stock,
    required int rejectStock,
    required int minStock,
    required List<dynamic> ingredients,
  }) async {
    await _db.query("START TRANSACTION");
    try {
      final result = await _db.query(
        SqlQueries.insertProduct,
        [
          name,
          sku,
          category,
          cost,
          price,
          stock - rejectStock,
          rejectStock,
          minStock,
        ],
      );
      final productId = result.insertId;

      for (final raw in ingredients) {
        final item = raw as Map<String, dynamic>;
        await _db.query(
          SqlQueries.insertProductIngredient,
          [
            productId,
            item["name"],
            item["quantity"],
            item["unit"],
            item["unitCost"],
          ],
        );
      }
      await _db.query("COMMIT");
      return {"id": productId, "cost": cost};
    } catch (_) {
      await _db.query("ROLLBACK");
      rethrow;
    }
  }

  /// Menghapus produk beserta relasi bahannya
  Future<int> deleteProduct(int productId) async {
    await _db.query("START TRANSACTION");
    try {
      await _db.query(SqlQueries.deleteProductIngredients, [productId]);
      await _db.query(SqlQueries.deleteProductInvoiceItems, [productId]);
      await _db.query(SqlQueries.deleteProduct, [productId]);
      await _db.query("COMMIT");
      return productId;
    } catch (_) {
      await _db.query("ROLLBACK");
      rethrow;
    }
  }

  // ==========================================
  // FAKTUR
  // ==========================================

  /// Mengambil semua daftar faktur
  Future<List<Map<String, dynamic>>> getInvoices() async {
    final rows = await _db.query(SqlQueries.selectAllInvoices);
    return rows
        .map((row) => {
              "id": row["id"],
              "number": row["invoice_number"],
              "customer": row["customer"],
              "contact": row["contact"],
              "paymentType": row["payment_type"],
              "status": row["payment_status"],
              "dueDate": row["due_date"]?.toString(),
              "total": row["total"],
              "createdAt": row["created_at"].toString(),
            })
        .toList();
  }

  /// Membuat faktur baru, memotong stok produk, dan mencatat transaksi
  Future<Map<String, dynamic>> createInvoice({
    required String customer,
    required String contact,
    required String paymentType,
    required String? dueDate,
    required Map<int, int> quantities,
  }) async {
    await _db.query("START TRANSACTION");
    try {
      final preparedLines = <Map<String, dynamic>>[];
      var total = 0;

      for (final entry in quantities.entries) {
        final productId = entry.key;
        final quantity = entry.value;

        final rows = await _db.query(
          SqlQueries.selectProductForUpdate,
          [productId],
        );
        if (rows.isEmpty || (rows.first["stock"] as int) < quantity) {
          throw StateError("Stok produk $productId tidak mencukupi.");
        }
        final price = rows.first["price"] as int;
        total += price * quantity;
        preparedLines.add({
          "productId": productId,
          "productName": rows.first["name"],
          "quantity": quantity,
          "cost": rows.first["cost"],
          "price": price,
        });
      }

      final countRows = await _db.query(SqlQueries.countInvoicesCurrentYear);
      final sequence = (countRows.first["total"] as int) + 1;
      final number =
          "INV-${DateTime.now().year}-${sequence.toString().padLeft(3, "0")}";

      final invoiceResult = await _db.query(
        SqlQueries.insertInvoice,
        [
          number,
          customer,
          contact,
          paymentType,
          paymentType == "cash" ? "paid" : "unpaid",
          dueDate,
          total,
        ],
      );

      for (final line in preparedLines) {
        await _db.query(
          SqlQueries.insertInvoiceLine,
          [
            invoiceResult.insertId,
            line["productId"],
            line["productName"],
            line["quantity"],
            line["cost"],
            line["price"],
            (line["quantity"] as int) * (line["price"] as int),
          ],
        );
        await _db.query(
          SqlQueries.updateProductStockDeduct,
          [line["quantity"], line["productId"]],
        );
      }
      await _db.query("COMMIT");
      return {
        "id": invoiceResult.insertId,
        "number": number,
        "total": total,
      };
    } catch (error) {
      await _db.query("ROLLBACK");
      rethrow;
    }
  }

  /// Menghapus faktur dan baris-barisnya
  Future<int> deleteInvoice(int invoiceId) async {
    await _db.query("START TRANSACTION");
    try {
      await _db.query(SqlQueries.deleteInvoiceComments, [invoiceId]);
      await _db.query(SqlQueries.deleteInvoiceItems, [invoiceId]);
      await _db.query(SqlQueries.deleteInvoiceLines, [invoiceId]);
      await _db.query(SqlQueries.deleteInvoice, [invoiceId]);
      await _db.query("COMMIT");
      return invoiceId;
    } catch (_) {
      await _db.query("ROLLBACK");
      rethrow;
    }
  }

  // ==========================================
  // STATISTIK
  // ==========================================

  /// Mengambil data statistik laba
  Future<List<Map<String, dynamic>>> getProfitStatistics(String period) async {
    final periodExpression = period == "month"
        ? "DATE_FORMAT(i.created_at, '%Y-%m-01')"
        : "DATE_SUB(DATE(i.created_at), INTERVAL WEEKDAY(i.created_at) DAY)";

    final queryStr = SqlQueries.selectProfitStatistics(periodExpression);
    final rows = await _db.query(queryStr);
    return rows
        .map((row) => {
              "periodStart": row["period_start"].toString(),
              "profit": row["profit"],
            })
        .toList();
  }

  // ==========================================
  // KOMENTAR FAKTUR
  // ==========================================

  /// Mengambil komentar dari faktur tertentu
  Future<List<Map<String, dynamic>>> getInvoiceComments(int invoiceId) async {
    final rows = await _db.query(
      SqlQueries.selectCommentsByInvoiceId,
      [invoiceId],
    );
    return rows
        .map((row) => {
              "id": row["id"],
              "actor": row["actor_name"],
              "message": row["message"],
              "createdAt": row["created_at"].toString(),
            })
        .toList();
  }

  /// Membuat komentar baru pada faktur
  Future<int> createInvoiceComment({
    required int invoiceId,
    required String actor,
    required String message,
  }) async {
    final invoice = await _db.query(SqlQueries.checkInvoiceExists, [invoiceId]);
    if (invoice.isEmpty) {
      throw StateError("Faktur tidak ditemukan.");
    }
    final result = await _db.query(
      SqlQueries.insertInvoiceComment,
      [invoiceId, actor, message],
    );
    return result.insertId!;
  }
}
