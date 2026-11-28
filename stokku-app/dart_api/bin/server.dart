import "dart:convert";
import "dart:io";

import "package:mysql1/mysql1.dart";
import "package:shelf/shelf.dart";
import "package:shelf/shelf_io.dart" as shelf_io;
import "package:shelf_router/shelf_router.dart";

import "package:stokku_api/database_service.dart";

Future<void> main() async {
  final connection = await MySqlConnection.connect(
    ConnectionSettings(
      host: Platform.environment["DB_HOST"] ?? "127.0.0.1",
      port: int.tryParse(Platform.environment["DB_PORT"] ?? "") ?? 3306,
      user: Platform.environment["DB_USER"] ?? "stokku",
      password: Platform.environment["DB_PASSWORD"] ?? "",
      db: Platform.environment["DB_NAME"] ?? "stokku",
    ),
  );

  final dbService = DatabaseService(connection);

  final router = Router()
    ..get("/api/health", (Request request) => _json({"status": "ok"}))
    ..get("/api/products", (Request request) => _handleGetProducts(dbService))
    ..get("/api/invoices", (Request request) => _handleGetInvoices(request, dbService))
    ..get("/api/invoices/<id>/comments", (Request request, String id) => _handleGetInvoiceComments(request, id, dbService))
    ..get("/api/statistics/profit", (Request request) => _handleGetProfitStatistics(request, dbService))
    ..post("/api/products", (Request request) => _handleCreateProduct(request, dbService))
    ..post("/api/invoices", (Request request) => _handleCreateInvoice(request, dbService))
    ..post("/api/invoices/<id>/comments", (Request request, String id) => _handleCreateInvoiceComment(request, id, dbService))
    ..delete("/api/products/<id>", (Request request, String id) => _handleDeleteProduct(request, id, dbService))
    ..delete("/api/invoices/<id>", (Request request, String id) => _handleDeleteInvoice(request, id, dbService));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(_errors())
      .addHandler(router.call);

  final port = int.tryParse(Platform.environment["PORT"] ?? "") ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln("Stokku API aktif di http://${server.address.host}:${server.port}");
}

// ==========================================
// CONTROLLER: PRODUK
// ==========================================

Future<Response> _handleGetProducts(DatabaseService service) async {
  final products = await service.getProducts();
  return _json(products);
}

Future<Response> _handleCreateProduct(Request request, DatabaseService service) async {
  if (!_hasRole(request, const {"gudang"})) {
    return _json({"error": "Tambah Produk hanya dapat diakses oleh Staf Gudang."}, status: 403);
  }
  final body = await _body(request);
  final ingredients = (body["ingredients"] as List<dynamic>? ?? const []);
  final stock = _positiveInt(body["stock"], allowZero: true);
  final rejectStock = _positiveInt(body["rejectStock"], allowZero: true);

  if (rejectStock > stock || ingredients.isEmpty) {
    return _json({"error": "Komposisi wajib diisi dan reject tidak boleh melebihi stok."}, status: 422);
  }

  final cost = ingredients.fold<int>(0, (sum, raw) {
    final item = raw as Map<String, dynamic>;
    return sum + ((_number(item["quantity"]) * _number(item["unitCost"])).round());
  });

  final result = await service.createProduct(
    name: body["name"].toString(),
    sku: body["sku"].toString(),
    category: body["category"].toString(),
    cost: cost,
    price: _positiveInt(body["price"]),
    stock: stock,
    rejectStock: rejectStock,
    minStock: _positiveInt(body["minStock"], allowZero: true),
    ingredients: ingredients,
  );

  return _json(result, status: 201);
}

Future<Response> _handleDeleteProduct(Request request, String id, DatabaseService service) async {
  if (!_hasRole(request, const {"gudang"})) {
    return _json({"error": "Hapus produk hanya dapat dilakukan oleh Staf Gudang."}, status: 403);
  }
  final productId = int.tryParse(id);
  if (productId == null) {
    return _json({"error": "ID produk tidak valid."}, status: 400);
  }

  await service.deleteProduct(productId);
  return _json({"status": "deleted", "id": productId});
}

// ==========================================
// CONTROLLER: FAKTUR
// ==========================================

Future<Response> _handleGetInvoices(Request request, DatabaseService service) async {
  if (!_hasRole(request, const {"admin", "manager"})) {
    return _json({"error": "Fitur Faktur hanya dapat diakses oleh Admin atau Manager."}, status: 403);
  }
  final invoices = await service.getInvoices();
  return _json(invoices);
}

Future<Response> _handleCreateInvoice(Request request, DatabaseService service) async {
  if (!_hasRole(request, const {"admin"})) {
    return _json({"error": "Fitur Faktur hanya dapat diakses oleh Admin."}, status: 403);
  }
  final body = await _body(request);
  final rawLines = (body["lines"] as List<dynamic>? ?? const []);
  final paymentType = body["paymentType"] == "credit" ? "credit" : "cash";

  if (rawLines.isEmpty || (paymentType == "credit" && body["dueDate"] == null)) {
    return _json({"error": "Item dan tanggal tempo untuk kredit wajib diisi."}, status: 422);
  }

  final quantities = <int, int>{};
  for (final raw in rawLines) {
    final line = raw as Map<String, dynamic>;
    final productId = _positiveInt(line["productId"]);
    quantities[productId] = (quantities[productId] ?? 0) + _positiveInt(line["quantity"]);
  }

  try {
    final result = await service.createInvoice(
      customer: body["customer"].toString(),
      contact: body["contact"]?.toString() ?? "",
      paymentType: paymentType,
      dueDate: body["dueDate"]?.toString(),
      quantities: quantities,
    );
    return _json(result, status: 201);
  } on StateError catch (error) {
    return _json({"error": error.message}, status: 409);
  }
}

Future<Response> _handleDeleteInvoice(Request request, String id, DatabaseService service) async {
  if (!_hasRole(request, const {"admin"})) {
    return _json({"error": "Hapus faktur hanya dapat dilakukan oleh Admin."}, status: 403);
  }
  final invoiceId = int.tryParse(id);
  if (invoiceId == null) {
    return _json({"error": "ID faktur tidak valid."}, status: 400);
  }

  await service.deleteInvoice(invoiceId);
  return _json({"status": "deleted", "id": invoiceId});
}

// ==========================================
// CONTROLLER: STATISTIK
// ==========================================

Future<Response> _handleGetProfitStatistics(Request request, DatabaseService service) async {
  if (!_hasRole(request, const {"manager"})) {
    return _json({"error": "Statistik keuntungan hanya dapat diakses oleh Manager."}, status: 403);
  }
  final period = request.url.queryParameters["period"] == "month" ? "month" : "week";
  final items = await service.getProfitStatistics(period);

  return _json({
    "period": period,
    "items": items,
  });
}

// ==========================================
// CONTROLLER: KOMENTAR FAKTUR
// ==========================================

Future<Response> _handleGetInvoiceComments(Request request, String invoiceId, DatabaseService service) async {
  if (!_hasRole(request, const {"admin", "manager"})) {
    return _json({"error": "Komentar Faktur hanya dapat dilihat oleh Admin atau Manager."}, status: 403);
  }
  final id = int.tryParse(invoiceId);
  if (id == null) return _json({"error": "ID faktur tidak valid."}, status: 400);

  final comments = await service.getInvoiceComments(id);
  return _json(comments);
}

Future<Response> _handleCreateInvoiceComment(Request request, String invoiceId, DatabaseService service) async {
  if (!_hasRole(request, const {"manager"})) {
    return _json({"error": "Komentar koreksi hanya dapat dibuat oleh Manager."}, status: 403);
  }
  final id = int.tryParse(invoiceId);
  if (id == null) return _json({"error": "ID faktur tidak valid."}, status: 400);

  final body = await _body(request);
  final message = body["message"]?.toString().trim() ?? "";
  if (message.isEmpty || message.length > 500) {
    return _json({"error": "Komentar wajib diisi dan maksimal 500 karakter."}, status: 422);
  }

  final actor = body["actor"]?.toString().trim().isNotEmpty == true ? body["actor"].toString() : "Manager";

  try {
    final commentId = await service.createInvoiceComment(
      invoiceId: id,
      actor: actor,
      message: message,
    );
    return _json({"id": commentId, "invoiceId": id, "message": message}, status: 201);
  } on StateError catch (error) {
    return _json({"error": error.message}, status: 404);
  }
}

// ==========================================
// HELPER & MIDDLEWARE
// ==========================================

Future<Map<String, dynamic>> _body(Request request) async {
  final value = jsonDecode(await request.readAsString());
  if (value is! Map<String, dynamic>) throw const FormatException("JSON object diperlukan.");
  return value;
}

num _number(dynamic value) => value is num ? value : num.parse(value.toString());

int _positiveInt(dynamic value, {bool allowZero = false}) {
  final number = _number(value).toInt();
  if (allowZero ? number < 0 : number <= 0) throw const FormatException("Angka tidak valid.");
  return number;
}

bool _hasRole(Request request, Set<String> roles) => roles.contains(request.headers["x-stokku-role"]);

Response _json(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: const {"content-type": "application/json; charset=utf-8"},
    );

Middleware _cors() => (innerHandler) => (request) async {
      if (request.method == "OPTIONS") return _withCors(Response.ok(""));
      return _withCors(await innerHandler(request));
    };

Response _withCors(Response response) => response.change(headers: {
      ...response.headers,
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET, POST, DELETE, OPTIONS",
      "access-control-allow-headers": "content-type, authorization, x-stokku-role",
    });

Middleware _errors() => (innerHandler) => (request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (error) {
        return _json({"error": error.message}, status: 400);
      } catch (error, stackTrace) {
        stderr.writeln("$error\n$stackTrace");
        return _json({"error": "Terjadi kesalahan pada server."}, status: 500);
      }
    };
