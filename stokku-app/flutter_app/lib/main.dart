import "dart:math";
import "package:flutter/material.dart";
import "api_service.dart";
import "models.dart";

void main() {
  runApp(const StokkuApp());
}

class StokkuApp extends StatelessWidget {
  const StokkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Stokku Desktop Suite",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        fontFamily: "Segoe UI",
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StokkuApi _api = StokkuApi();

  String _role = "admin"; // "manager" | "admin" | "gudang"
  bool _isLoggedIn = false; // Tampilkan halaman login terlebih dahulu
  String _storeName = "Toko Kelontong Berkah";
  String _userName = "Rina Amelia";
  String _currentView =
      "dashboard"; // dashboard, products, add, invoices, statistics, profile

  // Form Login Controllers
  final TextEditingController _loginStoreCtrl =
      TextEditingController(text: "Toko Kelontong Berkah");
  final TextEditingController _loginUserCtrl =
      TextEditingController(text: "Rina Amelia");
  final TextEditingController _loginPassCtrl =
      TextEditingController(text: "admin123");
  bool _obscurePassword = true;
  String _selectedLoginRole = "admin"; // "admin" | "manager" | "gudang"

  // Search & Filter
  String _searchQuery = "";
  String _selectedCategory = "Semua";

  // Data Store
  late List<Product> _products;
  late List<Invoice> _invoices;
  late List<ProfitRecord> _profitRecords;
  late List<NotificationItem> _notifications;

  // Widget Logo Stokku
  static Widget buildAppLogo({double size = 42, double radius = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          "assets/images/logo.png",
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
            size: Size(size, size),
            painter: _StokkuLogoPainter(),
          ),
        ),
      ),
    );
  }

  // Formatting helpers
  static String formatRupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(".");
      }
      buffer.write(s[i]);
    }
    return "Rp ${buffer.toString()}";
  }

  static String formatCompactRupiah(int value) {
    if (value >= 1000000) {
      final jt = (value / 1000000).toStringAsFixed(1);
      return "Rp $jt jt";
    }
    return formatRupiah(value);
  }

  static String getMonthName(int month) {
    const months = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];
    return (month >= 1 && month <= 12) ? months[month] : "Bulan $month";
  }

  static String getShortMonthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    return (month >= 1 && month <= 12) ? months[month] : "$month";
  }

  String get _userInitials {
    final parts = _userName.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    if (_role == "manager") return "BS";
    if (_role == "gudang") return "GD";
    return "RA";
  }

  @override
  void initState() {
    super.initState();
    _initInitialData();
    _fetchApiProducts();
  }

  @override
  void dispose() {
    _loginStoreCtrl.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _api.close();
    super.dispose();
  }

  void _initInitialData() {
    _products = [
      Product(
          id: 1,
          name: "Minyak Goreng 1L",
          sku: "MK-001",
          category: "Sembako",
          cost: 12000,
          price: 14500,
          stock: 2,
          rejectStock: 0,
          minStock: 8),
      Product(
          id: 2,
          name: "Beras Premium 5kg",
          sku: "BR-005",
          category: "Sembako",
          cost: 58000,
          price: 68000,
          stock: 5,
          rejectStock: 0,
          minStock: 10),
      Product(
          id: 3,
          name: "Gula Pasir 1kg",
          sku: "GL-010",
          category: "Sembako",
          cost: 12500,
          price: 14500,
          stock: 45,
          rejectStock: 0,
          minStock: 10),
      Product(
          id: 4,
          name: "Teh Celup Kotak",
          sku: "TH-022",
          category: "Minuman",
          cost: 4800,
          price: 6500,
          stock: 30,
          rejectStock: 0,
          minStock: 8),
      Product(
          id: 5,
          name: "Kopi Sachet 10pcs",
          sku: "KP-031",
          category: "Minuman",
          cost: 9500,
          price: 12000,
          stock: 25,
          rejectStock: 0,
          minStock: 8),
      Product(
          id: 6,
          name: "Keripik Singkong Balado",
          sku: "SN-014",
          category: "Makanan Ringan",
          cost: 6500,
          price: 9000,
          stock: 50,
          rejectStock: 0,
          minStock: 12),
    ];

    _invoices = [
      Invoice(
        id: 1,
        number: "INV-2026-001",
        customer: "Warung Bu Sari",
        contact: "0812 3456 7890",
        paymentType: "credit",
        status: "credit",
        dueDate: "2026-10-30",
        date: "15 Okt 2026",
        lines: [
          InvoiceLine(
              productId: 3,
              productName: "Gula Pasir 1kg",
              quantity: 5,
              unitPrice: 14500),
        ],
        total: 72500,
        comments: [],
      ),
      Invoice(
        id: 2,
        number: "INV-2026-002",
        customer: "Toko Berkah Mandiri",
        contact: "0813 9876 5432",
        paymentType: "cash",
        status: "paid",
        date: "16 Okt 2026",
        lines: [
          InvoiceLine(
              productId: 2,
              productName: "Beras Premium 5kg",
              quantity: 2,
              unitPrice: 68000),
          InvoiceLine(
              productId: 5,
              productName: "Kopi Sachet 10pcs",
              quantity: 1,
              unitPrice: 12000),
        ],
        total: 148000,
        comments: [],
      ),
      Invoice(
        id: 3,
        number: "INV-2026-003",
        customer: "Kedai Kopi Mantap",
        contact: "0857 1234 8899",
        paymentType: "credit",
        status: "unpaid",
        dueDate: "2026-11-05",
        date: "17 Okt 2026",
        lines: [
          InvoiceLine(
              productId: 5,
              productName: "Kopi Sachet 10pcs",
              quantity: 8,
              unitPrice: 12000),
          InvoiceLine(
              productId: 3,
              productName: "Gula Pasir 1kg",
              quantity: 4,
              unitPrice: 14500),
        ],
        total: 154000,
        comments: [],
      ),
      Invoice(
        id: 4,
        number: "INV-2026-004",
        customer: "Bu Siti Sembako",
        contact: "0821 7766 5544",
        paymentType: "cash",
        status: "paid",
        date: "18 Okt 2026",
        lines: [
          InvoiceLine(
              productId: 1,
              productName: "Minyak Goreng 2L",
              quantity: 4,
              unitPrice: 32000),
        ],
        total: 128000,
        comments: [],
      ),
      Invoice(
        id: 5,
        number: "INV-2026-005",
        customer: "Depot Barokah",
        contact: "0819 5544 3322",
        paymentType: "credit",
        status: "credit",
        dueDate: "2026-11-12",
        date: "19 Okt 2026",
        lines: [
          InvoiceLine(
              productId: 6,
              productName: "Keripik Singkong Balado",
              quantity: 10,
              unitPrice: 9000),
        ],
        total: 90000,
        comments: [],
      ),
    ];

    _profitRecords = [
      ProfitRecord(date: "2026-07-04", profit: 340000),
      ProfitRecord(date: "2026-07-11", profit: 465000),
      ProfitRecord(date: "2026-07-19", profit: 295000),
      ProfitRecord(date: "2026-07-27", profit: 525000),
      ProfitRecord(date: "2026-08-05", profit: 410000),
      ProfitRecord(date: "2026-08-13", profit: 580000),
      ProfitRecord(date: "2026-08-22", profit: 490000),
      ProfitRecord(date: "2026-08-29", profit: 635000),
      ProfitRecord(date: "2026-09-06", profit: 545000),
      ProfitRecord(date: "2026-09-14", profit: 710000),
      ProfitRecord(date: "2026-09-23", profit: 620000),
      ProfitRecord(date: "2026-09-29", profit: 680000),
      ProfitRecord(date: "2026-10-02", profit: 680000),
      ProfitRecord(date: "2026-10-09", profit: 795000),
      ProfitRecord(date: "2026-10-15", profit: 745000),
      ProfitRecord(date: "2026-10-25", profit: 820000),
      ProfitRecord(date: "2026-11-03", profit: 780000),
      ProfitRecord(date: "2026-11-12", profit: 860000),
    ];

    _notifications = [
      NotificationItem(
        id: 1,
        product: "Beras Premium 5kg",
        actor: "Budi Santoso",
        oldCost: 56000,
        newCost: 58000,
        oldPrice: 65000,
        newPrice: 68000,
        date: "Hari ini, 09.42",
      ),
      NotificationItem(
        id: 2,
        product: "Kopi Sachet 10pcs",
        actor: "Budi Santoso",
        oldCost: 9000,
        newCost: 9500,
        oldPrice: 11500,
        newPrice: 12000,
        date: "Kemarin, 15.18",
      ),
    ];
  }

  Future<void> _fetchApiProducts() async {
    final list = await _api.getProducts();
    if (list.isNotEmpty && mounted) {
      setState(() {
        _products = list;
      });
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _switchRole(String nextRole) {
    setState(() {
      _role = nextRole;
      if (nextRole == "manager") {
        _userName = "Budi Santoso";
      } else if (nextRole == "gudang") {
        _userName = "Bambang Gudang";
      } else {
        _userName = "Rina Amelia";
      }
      if (nextRole == "admin" &&
          (_currentView == "statistics" || _currentView == "add")) {
        _currentView = "invoices";
      } else if (nextRole == "gudang" &&
          (_currentView == "statistics" || _currentView == "invoices")) {
        _currentView = "products";
      } else if (nextRole == "manager" && _currentView == "add") {
        _currentView = "dashboard";
      }
    });
    final roleLabel = nextRole == 'manager'
        ? 'Manager'
        : nextRole == 'gudang'
            ? 'Staf Gudang'
            : 'Admin Pesanan';
    _showToast("Masuk sebagai $roleLabel");
  }

  // Edit Product Data Dialog (Gudang Only)
  void _openEditProductDialog(Product product) {
    if (_role != "gudang") return;
    final nameCtrl = TextEditingController(text: product.name);
    final skuCtrl = TextEditingController(text: product.sku);
    final categoryCtrl = TextEditingController(text: product.category);
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final rejectCtrl =
        TextEditingController(text: product.rejectStock.toString());
    final minStockCtrl =
        TextEditingController(text: product.minStock.toString());
    final priceCtrl = TextEditingController(text: product.price.toString());
    final costCtrl = TextEditingController(text: product.cost.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Edit Data Produk",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Role: Gudang · ${product.name}",
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama Produk",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skuCtrl,
                        decoration: const InputDecoration(
                          labelText: "Kode SKU",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: "Kategori",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Stok Layak Jual (pcs)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rejectCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Stok Reject (pcs)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Batas Min. Stok",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Harga Jual (Rp)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Harga Modal / HPP (Rp)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newSku = skuCtrl.text.trim().toUpperCase();
              final newCat = categoryCtrl.text.trim();
              final newStock = int.tryParse(stockCtrl.text) ?? product.stock;
              final newReject =
                  int.tryParse(rejectCtrl.text) ?? product.rejectStock;
              final newMinStock =
                  int.tryParse(minStockCtrl.text) ?? product.minStock;
              final newPrice = int.tryParse(priceCtrl.text) ?? product.price;
              final newCost = int.tryParse(costCtrl.text) ?? product.cost;

              if (newName.isNotEmpty && newSku.isNotEmpty) {
                setState(() {
                  product.name = newName;
                  product.sku = newSku;
                  if (newCat.isNotEmpty) product.category = newCat;
                  product.stock = newStock;
                  product.rejectStock = newReject;
                  product.minStock = newMinStock;
                  product.price = newPrice;
                  product.cost = newCost;
                });
                Navigator.pop(ctx);
                _showToast("Data produk \"$newName\" berhasil diperbarui");
              }
            },
            child: const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }

  // Tambah Data ke Barang Reject Dialog (Gudang Only)
  void _openRecordRejectDialog(Product product) {
    if (_role != "gudang") return;
    final rejectAddCtrl = TextEditingController(text: "1");
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tambah Barang Reject",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(product.name,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Stok Layak Jual",
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text("${product.stock} pcs",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const VerticalDivider(),
                    Column(
                      children: [
                        const Text("Reject Saat Ini",
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text("${product.rejectStock} pcs",
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rejectAddCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Jumlah Barang Reject Ditambahkan (pcs)",
                  hintText: "Contoh: 2",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.add_circle_outline_rounded,
                      color: Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: "Alasan Kerusakan / Catatan",
                  hintText: "Contoh: Kemasan sobek, bocor, kadaluarsa",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "* Stok layak jual akan otomatis berkurang sesuai jumlah reject.",
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final qty = int.tryParse(rejectAddCtrl.text) ?? 0;
              if (qty <= 0) {
                _showToast("Jumlah barang reject harus lebih dari 0");
                return;
              }
              if (qty > product.stock) {
                _showToast(
                    "Jumlah reject tidak boleh melebihi stok tersedia (${product.stock} pcs)!");
                return;
              }
              setState(() {
                product.stock -= qty;
                product.rejectStock += qty;
              });
              Navigator.pop(ctx);
              _showToast(
                  "Berhasil menambahkan $qty pcs barang reject untuk ${product.name}");
            },
            child: const Text("Simpan Barang Reject"),
          ),
        ],
      ),
    );
  }

  // Edit Price Dialog (Manager)
  void _openEditPriceDialog(Product product) {
    if (_role != "manager") return;
    final costController = TextEditingController(text: product.cost.toString());
    final priceController =
        TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ubah Harga Produk",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(product.name,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Harga Modal / HPP (Rp)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Harga Jual (Rp)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newCost = int.tryParse(costController.text) ?? product.cost;
              final newPrice =
                  int.tryParse(priceController.text) ?? product.price;

              if (newCost > 0 && newPrice > 0) {
                setState(() {
                  product.cost = newCost;
                  product.price = newPrice;
                  _notifications.insert(
                    0,
                    NotificationItem(
                      id: DateTime.now().millisecondsSinceEpoch,
                      product: product.name,
                      actor: "Budi Santoso",
                      oldCost: product.cost,
                      newCost: newCost,
                      oldPrice: product.price,
                      newPrice: newPrice,
                      date: "Baru saja",
                    ),
                  );
                });
                Navigator.pop(ctx);
                _showToast("Harga ${product.name} berhasil diperbarui");
              }
            },
            child: const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }

  // Delete Product Confirmation (Gudang Only)
  void _confirmDeleteProduct(Product product) {
    if (_role != "gudang") return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Hapus Produk",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Apakah Anda yakin ingin menghapus produk \"${product.name}\" (${product.sku})?",
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Kategori: ${product.category} · Stok: ${product.stock} pcs",
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _products.removeWhere((p) => p.id == product.id);
              });
              _api.deleteProduct(product.id);
              _showToast("Produk \"${product.name}\" berhasil dihapus");
            },
            child: const Text("Hapus Produk"),
          ),
        ],
      ),
    );
  }

  // Notifications Dialog
  void _openNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.history_rounded, color: Color(0xFFD97706)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Riwayat Perubahan Harga",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Dapat dipantau oleh Manager & Admin",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          height: 380,
          child: _notifications.isEmpty
              ? const Center(child: Text("Belum ada riwayat perubahan"))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.price_change_outlined,
                            color: Color(0xFF2563EB), size: 18),
                      ),
                      title: Text(item.product,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            "${item.actor} mengubah harga: ${formatRupiah(item.oldPrice)} ➔ ${formatRupiah(item.newPrice)}",
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF334155)),
                          ),
                          Text(item.date,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return _buildLoginScreen();
    }

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar (Desktop Navigation)
          _buildSidebar(),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(),

                // Scrollable Body Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _buildCurrentView(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Logo & Brand Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                buildAppLogo(size: 42, radius: 12),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stokku",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB)),
                    ),
                    Text(
                      "DESKTOP SUITE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Navigation Menu List
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MENU UTAMA",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  key: "dashboard",
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: "Ringkasan",
                ),
                _buildNavItem(
                  key: "products",
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: "Daftar produk",
                ),
                if (_role == "gudang")
                  _buildNavItem(
                    key: "add",
                    icon: Icons.add_circle_outline_rounded,
                    activeIcon: Icons.add_circle_rounded,
                    label: "Tambah produk",
                  ),
                if (_role == "admin" || _role == "manager")
                  _buildNavItem(
                    key: "invoices",
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    label: "Faktur",
                  ),
                if (_role == "manager")
                  _buildNavItem(
                    key: "statistics",
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics_rounded,
                    label: "Statistik",
                  ),
                _buildNavItem(
                  key: "profile",
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: "Profil",
                ),
              ],
            ),
          ),

          // Role Switcher / User Profile Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showAccountSwitchDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _role == "manager"
                          ? const Color(0xFFEFF6FF)
                          : _role == "gudang"
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFE0F2FE),
                      child: Text(
                        _userInitials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _role == "manager"
                              ? const Color(0xFF2563EB)
                              : _role == "gudang"
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _role == "manager"
                                ? "Manager"
                                : _role == "gudang"
                                    ? "Staf Gudang"
                                    : "Admin Pesanan",
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.unfold_more_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String key,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentView == key;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _currentView = key;
              if (key != "products") _searchQuery = "";
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountSwitchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Pilih Akun",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: _role == "manager",
                selectedTileColor: const Color(0xFFEFF6FF),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Text("BS",
                      style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold)),
                ),
                title: const Text("Budi Santoso",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Manager"),
                trailing: _role == "manager"
                    ? const Icon(Icons.check, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _switchRole("manager");
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: _role == "admin",
                selectedTileColor: const Color(0xFFE0F2FE),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Text("RA",
                      style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold)),
                ),
                title: const Text("Rina Amelia",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Admin Pesanan"),
                trailing: _role == "admin"
                    ? const Icon(Icons.check, color: Color(0xFF0284C7))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _switchRole("admin");
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: _role == "gudang",
                selectedTileColor: const Color(0xFFFEF3C7),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Text("GD",
                      style: TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold)),
                ),
                title: const Text("Bambang Gudang",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Staf Gudang"),
                trailing: _role == "gudang"
                    ? const Icon(Icons.check, color: Color(0xFFD97706))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _switchRole("gudang");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    String title = "Ringkasan Inventaris";
    if (_currentView == "products") title = "Daftar Produk";
    if (_currentView == "add") title = "Tambah Produk";
    if (_currentView == "invoices") title = "Faktur & Pemesanan";
    if (_currentView == "statistics") title = "Statistik Bisnis";
    if (_currentView == "profile") title = "Profil Akun";

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _role == "manager"
                    ? "Akun Manager"
                    : _role == "gudang"
                        ? "Staf Gudang"
                        : "Admin Pesanan",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B)),
              ),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded,
                        size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      _storeName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Notification Bell with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Color(0xFF475569)),
                    onPressed: _openNotificationsDialog,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== VIEW ROUTER ====================
  Widget _buildCurrentView() {
    switch (_currentView) {
      case "dashboard":
        return _buildDashboardView();
      case "products":
        return _buildProductsView();
      case "add":
        return _buildAddProductView();
      case "invoices":
        return _buildInvoicesView();
      case "statistics":
        return _buildStatisticsView();
      case "profile":
        return _buildProfileView();
      default:
        return _buildDashboardView();
    }
  }

  // ==================== 1. DASHBOARD ====================
  Widget _buildDashboardView() {
    final totalStock = _products.fold<int>(0, (sum, p) => sum + p.stock);
    final totalSKU = _products.length;
    final lowStockItems =
        _products.where((p) => p.stock <= p.minStock).toList();
    final inventoryValue =
        _products.fold<int>(0, (sum, p) => sum + (p.cost * p.stock));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 4 Metrics Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 48) / 4;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMetricCard(
                  width: cardWidth.clamp(220, 300),
                  title: "Stok Layak Jual",
                  value: "$totalStock pcs",
                  icon: Icons.layers_outlined,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
                _buildMetricCard(
                  width: cardWidth.clamp(220, 300),
                  title: "Jumlah Produk",
                  value: "$totalSKU SKU",
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                ),
                _buildMetricCard(
                  width: cardWidth.clamp(220, 300),
                  title: "Stok Menipis / Kritis",
                  value: "${lowStockItems.length} Produk",
                  icon: Icons.warning_amber_rounded,
                  iconColor: lowStockItems.isNotEmpty
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                  bgColor: lowStockItems.isNotEmpty
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                ),
                if (_role == "manager")
                  _buildMetricCard(
                    width: cardWidth.clamp(220, 300),
                    title: "Nilai Inventaris (Modal)",
                    value: formatCompactRupiah(inventoryValue),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        // Urgent Action / Attention Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notification_important_outlined,
                          color: Color(0xFFEA580C), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Perlu Segera Diperhatikan (Stok Menipis)",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentView = "products"),
                    icon: const Text("Semua Produk",
                        style: TextStyle(fontSize: 13)),
                    label: const Icon(Icons.arrow_forward_rounded, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (lowStockItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "Seluruh stok produk berada dalam batas aman.",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = lowStockItems[index];
                    final isCritical = item.stock <= (item.minStock / 2);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      leading: CircleAvatar(
                        backgroundColor: isCritical
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        child: Icon(
                          isCritical
                              ? Icons.error_outline_rounded
                              : Icons.warning_amber_rounded,
                          color: isCritical
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      title: Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                          "SKU: ${item.sku} · Min: ${item.minStock} pcs · Sisa: ${item.stock} pcs"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCritical
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCritical
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Text(
                              isCritical ? "Kritis" : "Menipis",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCritical
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                          if (_role == "manager") ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: "Ubah Harga",
                              onPressed: () => _openEditPriceDialog(item),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ==================== 2. DAFTAR PRODUK ====================
  Widget _buildProductsView() {
    final filtered = _products.where((p) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == "Semua" || p.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText:
                      "Cari berdasarkan nama produk, SKU, atau kategori...",
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(width: 16),
            if (_role == "gudang")
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() => _currentView = "add"),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Tambah Produk",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                ["Semua", "Sembako", "Minuman", "Makanan Ringan"].map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSel,
                  label: Text(cat),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? Colors.white : const Color(0xFF475569),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF2563EB),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: isSel
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0)),
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Product Cards / Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(
                    child: Text("Tidak ada produk yang cocok dengan pencarian.",
                        style: TextStyle(color: Color(0xFF64748B))),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isCritical = item.stock <= (item.minStock / 2);
                    final isLow = item.stock <= item.minStock;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF2563EB), size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.sku} · ${item.category}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatRupiah(item.price),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              if (_role == "manager")
                                Text("Modal: ${formatRupiah(item.cost)}",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8))),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text("${item.stock} pcs",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCritical
                                          ? const Color(0xFFFEF2F2)
                                          : isLow
                                              ? const Color(0xFFFFFBEB)
                                              : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isCritical
                                          ? "Kritis"
                                          : isLow
                                              ? "Menipis"
                                              : "Aman",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCritical
                                            ? const Color(0xFFDC2626)
                                            : isLow
                                                ? const Color(0xFFB45309)
                                                : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.rejectStock > 0)
                                Text("Reject: ${item.rejectStock}",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFDC2626))),
                            ],
                          ),
                          if (_role == "gudang") ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.warning_amber_rounded,
                                  size: 20, color: Color(0xFFDC2626)),
                              tooltip: "Tambah Barang Reject",
                              onPressed: () => _openRecordRejectDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: Color(0xFF2563EB)),
                              tooltip: "Edit Data Produk",
                              onPressed: () => _openEditProductDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: Color(0xFFDC2626)),
                              tooltip: "Hapus Produk",
                              onPressed: () => _confirmDeleteProduct(item),
                            ),
                          ],
                          if (_role == "manager") ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: Color(0xFF2563EB)),
                              tooltip: "Ubah Harga",
                              onPressed: () => _openEditPriceDialog(item),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================== 3. TAMBAH PRODUK (GUDANG ONLY) ====================
  Widget _buildAddProductView() {
    return AddProductForm(
      onProductAdded: (newProduct) {
        setState(() {
          _products.insert(0, newProduct);
          _currentView = "products";
        });
        _showToast(
            "Produk \"${newProduct.name}\" berhasil ditambahkan oleh Staf Gudang!");
      },
    );
  }

  // ==================== 4. FAKTUR ====================
  Widget _buildInvoicesView() {
    return InvoicesComponent(
      role: _role,
      invoices: _invoices,
      products: _products,
      onInvoiceCreated: (newInv) {
        setState(() {
          _invoices.insert(0, newInv);
          // calculate profit
          int profit = 0;
          for (final line in newInv.lines) {
            final p = _products.firstWhere((item) => item.id == line.productId,
                orElse: () => _products.first);
            profit += (line.unitPrice - p.cost) * line.quantity;
            p.stock -= line.quantity;
          }
          _profitRecords.add(ProfitRecord(
              date: DateTime.now().toIso8601String().substring(0, 10),
              profit: profit));
        });
        _showToast("${newInv.number} berhasil dibuat!");
      },
      onUpdateInvoiceStatus: (inv, newStatus) {
        setState(() {
          inv.status = newStatus;
        });
        final label = newStatus == "paid"
            ? "Lunas"
            : newStatus == "credit"
                ? "Kredit"
                : "Belum Lunas";
        _showToast("Status ${inv.number} berhasil diperbarui: $label");
      },
      onAddComment: (invId, commentText) {
        setState(() {
          final inv = _invoices.firstWhere((i) => i.id == invId);
          inv.comments.add(
            InvoiceComment(
              id: DateTime.now().millisecondsSinceEpoch,
              actor: _userName,
              message: commentText,
              date: "Baru saja",
            ),
          );
        });
        _showToast("Komentar koreksi berhasil dikirim!");
      },
      onDeleteInvoice: (inv) {
        setState(() {
          _invoices.removeWhere((i) => i.id == inv.id);
        });
        _api.deleteInvoice(inv.id);
        _showToast("Faktur ${inv.number} berhasil dihapus");
      },
    );
  }

  // ==================== 5. STATISTIK (MANAGER ONLY) ====================
  Widget _buildStatisticsView() {
    return StatisticsComponent(
      profitRecords: _profitRecords,
      products: _products,
      invoices: _invoices,
    );
  }

  // ==================== 6. PROFIL ====================
  Widget _buildProfileView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: _role == "manager"
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFE0F2FE),
                child: Text(
                  _userInitials,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _role == "manager"
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _role == "manager"
                          ? "Role: Manager"
                          : _role == "gudang"
                              ? "Role: Staf Gudang"
                              : "Role: Admin Pesanan",
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 20),
          _buildProfileDetailRow("Nama Usaha / Toko", _storeName),
          _buildProfileDetailRow("Username", _userName),
          _buildProfileDetailRow(
              "Platform", "Stokku Desktop Suite (Windows x64)"),
          _buildProfileDetailRow(
              "Status Sesi", "Aktif (Offline / Local Persistence Ready)"),
          const SizedBox(height: 32),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAccountSwitchDialog,
                icon: const Icon(Icons.switch_account_rounded, size: 18),
                label: const Text("Ganti Akun"),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => _isLoggedIn = false);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("Keluar (Logout)"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ==================== LOGIN SCREEN ====================
  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      buildAppLogo(size: 64, radius: 18),
                      const SizedBox(height: 14),
                      const Text(
                        "Stokku",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Aplikasi Inventaris & Penjualan (Desktop Suite)",
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 20),

                // Form Username
                const Text(
                  "Username / Nama Pengguna",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginUserCtrl,
                  decoration: InputDecoration(
                    hintText: "Masukkan username Anda",
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Form Password
                const Text(
                  "Password / Kata Sandi",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginPassCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Masukkan password akun",
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Pilihan Role (Admin, Manager, Gudang)
                const Text(
                  "Pilih Hak Akses (Role)",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleSelectOption(
                        title: "Admin",
                        desc: "Pesanan & faktur",
                        icon: Icons.receipt_long_outlined,
                        isSelected: _selectedLoginRole == "admin",
                        onTap: () =>
                            setState(() => _selectedLoginRole = "admin"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleSelectOption(
                        title: "Manager",
                        desc: "Statistik & laba",
                        icon: Icons.analytics_outlined,
                        isSelected: _selectedLoginRole == "manager",
                        onTap: () =>
                            setState(() => _selectedLoginRole = "manager"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleSelectOption(
                        title: "Gudang",
                        desc: "Produk & reject",
                        icon: Icons.inventory_2_outlined,
                        isSelected: _selectedLoginRole == "gudang",
                        onTap: () =>
                            setState(() => _selectedLoginRole = "gudang"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Submit Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _performLogin,
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text(
                      "Masuk ke Menu Utama",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectOption({
    required String title,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performLogin() {
    final user = _loginUserCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      _showToast("Mohon masukkan Username dan Password!");
      return;
    }

    setState(() {
      _userName = user;
      _role = _selectedLoginRole;
      _isLoggedIn = true;
      _currentView = _role == "admin" ? "invoices" : "dashboard";
    });
    final roleLabel = _role == 'manager'
        ? 'Manager'
        : _role == 'gudang'
            ? 'Staf Gudang'
            : 'Admin Pesanan';
    _showToast("Selamat datang, $_userName ($roleLabel)!");
  }
}

// ==========================================
// COMPONENT: ADD PRODUCT FORM (GUDANG)
// ==========================================
class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key, this.onProductAdded});

  final ValueChanged<Product>? onProductAdded;

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController(text: "5");
  final _initialStockCtrl = TextEditingController(text: "10");
  final _rejectCtrl = TextEditingController(text: "0");
  String _category = "Sembako";

  // Dynamic Ingredients for HPP calculation
  final List<IngredientItem> _ingredients = [];

  int get _calculatedHpp {
    if (_ingredients.isEmpty) return 0;
    return _ingredients.fold<int>(0, (sum, i) => sum + i.totalCost);
  }

  int get _saleableStock {
    final initial = int.tryParse(_initialStockCtrl.text) ?? 0;
    final reject = int.tryParse(_rejectCtrl.text) ?? 0;
    return (initial - reject).clamp(0, 999999);
  }

  void _addIngredientDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "1");
    final costCtrl = TextEditingController();
    String unit = "pcs";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Bahan Baku",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Nama Bahan",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Jumlah",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: unit,
                    items: ["pcs", "kg", "gram", "liter", "pak"]
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => unit = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Biaya per Satuan (Rp)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = double.tryParse(qtyCtrl.text) ?? 1;
              final cost = int.tryParse(costCtrl.text) ?? 0;
              if (name.isNotEmpty && cost > 0) {
                setState(() {
                  _ingredients.add(IngredientItem(
                      name: name, quantity: qty, unit: unit, unitCost: cost));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Tambahkan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Formulir Produk Baru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
              "Khusus Admin Stok untuk menambahkan SKU dan menghitung HPP otomatis",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 24),

          // Main Inputs Grid
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Nama Produk",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _skuCtrl,
                  decoration: InputDecoration(
                    labelText: "SKU (Kode Produk)",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ["Sembako", "Minuman", "Makanan Ringan", "Umum"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Harga Jual (Rp)",
                    prefixText: "Rp ",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Batas Stok Minimum",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _initialStockCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: "Stok Awal",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _rejectCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: "Barang Reject / Rusak",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Komposisi Bahan & Kalkulasi HPP
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Komposisi Bahan & Perhitungan HPP",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("HPP = Σ (Jumlah bahan × Biaya per satuan)",
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _addIngredientDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text("Tambah Bahan"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_ingredients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                          "Belum ada bahan baku ditambahkan. Klik 'Tambah Bahan' di atas.",
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13)),
                    ),
                  )
                else
                  Column(
                    children: _ingredients.map((item) {
                      return ListTile(
                        dense: true,
                        title: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            "${item.quantity} ${item.unit} @ ${_MainScreenState.formatRupiah(item.unitCost)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_MainScreenState.formatRupiah(item.totalCost),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _ingredients.remove(item)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("HPP / Modal Satuan Otomatis:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _MainScreenState.formatRupiah(_calculatedHpp),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Stok Layak Jual:",
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text("$_saleableStock pcs",
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Nilai Inventaris:",
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text(
                        _MainScreenState.formatRupiah(
                            _calculatedHpp * _saleableStock),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final sku = _skuCtrl.text.trim().toUpperCase();
                final price = int.tryParse(_priceCtrl.text) ?? 0;
                final minStock = int.tryParse(_minStockCtrl.text) ?? 5;
                final initialStock = int.tryParse(_initialStockCtrl.text) ?? 10;
                final reject = int.tryParse(_rejectCtrl.text) ?? 0;
                final saleableStock = (initialStock - reject).clamp(0, 999999);
                final cost =
                    _calculatedHpp > 0 ? _calculatedHpp : (price * 0.7).round();

                if (name.isNotEmpty && sku.isNotEmpty && price > 0) {
                  final newProd = Product(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: name,
                    sku: sku,
                    category: _category,
                    cost: cost,
                    price: price,
                    stock: saleableStock,
                    rejectStock: reject,
                    minStock: minStock,
                  );
                  if (widget.onProductAdded != null) {
                    widget.onProductAdded!(newProd);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "$name ($sku) [Min: $minStock, Reject: $reject] berhasil ditambahkan!")),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text("Simpan Produk ke Inventaris",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENT: INVOICES
// ==========================================
class InvoicesComponent extends StatelessWidget {
  const InvoicesComponent({
    super.key,
    required this.role,
    required this.invoices,
    required this.products,
    required this.onInvoiceCreated,
    required this.onAddComment,
    this.onUpdateInvoiceStatus,
    this.onDeleteInvoice,
  });

  final String role;
  final List<Invoice> invoices;
  final List<Product> products;
  final ValueChanged<Invoice> onInvoiceCreated;
  final void Function(int invoiceId, String comment) onAddComment;
  final void Function(Invoice invoice, String newStatus)? onUpdateInvoiceStatus;
  final ValueChanged<Invoice>? onDeleteInvoice;

  void _openCreateInvoiceDialog(BuildContext context) {
    if (role != "admin") return;
    final customerCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String paymentType = "cash";
    DateTime dueDate = DateTime.now().add(const Duration(days: 14));

    final lines = <InvoiceLine>[
      if (products.isNotEmpty)
        InvoiceLine(
          productId: products.first.id,
          productName: products.first.name,
          quantity: 1,
          unitPrice: products.first.price,
        ),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final total = lines.fold<int>(0, (sum, l) => sum + l.subtotal);

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Buat Faktur Baru",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: customerCtrl,
                      decoration: InputDecoration(
                        labelText: "Nama Pelanggan / Toko",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactCtrl,
                      decoration: InputDecoration(
                        labelText: "Nomor Kontak / WhatsApp",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Status Faktur: ",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        ChoiceChip(
                          label: const Text("Lunas"),
                          selected: paymentType == "cash",
                          onSelected: (_) =>
                              setDialogState(() => paymentType = "cash"),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("Belum Lunas"),
                          selected: paymentType == "unpaid",
                          onSelected: (_) =>
                              setDialogState(() => paymentType = "unpaid"),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("Kredit"),
                          selected: paymentType == "credit",
                          onSelected: (_) =>
                              setDialogState(() => paymentType = "credit"),
                        ),
                      ],
                    ),
                    if (paymentType == "credit" || paymentType == "unpaid") ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text("Jatuh Tempo: ",
                              style: TextStyle(fontSize: 13)),
                          Text(
                            "${dueDate.day}-${dueDate.month}-${dueDate.year}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setDialogState(() => dueDate = picked);
                              }
                            },
                            child: const Text("Ubah"),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text("Daftar Item Faktur:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...lines.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final line = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: line.productId,
                              items: products
                                  .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child:
                                          Text("${p.name} (Stok: ${p.stock})")))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final p = products
                                      .firstWhere((item) => item.id == val);
                                  setDialogState(() {
                                    lines[idx] = InvoiceLine(
                                      productId: p.id,
                                      productName: p.name,
                                      quantity: 1,
                                      unitPrice: p.price,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: "Qty"),
                              controller: TextEditingController(
                                  text: line.quantity.toString()),
                              onSubmitted: (val) {
                                final qty = int.tryParse(val) ?? 1;
                                setDialogState(() {
                                  lines[idx] = InvoiceLine(
                                    productId: line.productId,
                                    productName: line.productName,
                                    quantity: qty,
                                    unitPrice: line.unitPrice,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_MainScreenState.formatRupiah(line.subtotal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              if (lines.length > 1) {
                                setDialogState(() => lines.removeAt(idx));
                              }
                            },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        if (products.isNotEmpty) {
                          setDialogState(() {
                            lines.add(InvoiceLine(
                              productId: products.first.id,
                              productName: products.first.name,
                              quantity: 1,
                              unitPrice: products.first.price,
                            ));
                          });
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Tambah Item Produk"),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Faktur:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          _MainScreenState.formatRupiah(total),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final cust = customerCtrl.text.trim();
                  if (cust.isNotEmpty && lines.isNotEmpty) {
                    final statusVal = paymentType == "cash"
                        ? "paid"
                        : paymentType == "credit"
                            ? "credit"
                            : "unpaid";
                    final invoice = Invoice(
                      id: DateTime.now().millisecondsSinceEpoch,
                      number:
                          "INV-${DateTime.now().year}-${(invoices.length + 1).toString().padLeft(3, '0')}",
                      customer: cust,
                      contact: contactCtrl.text.trim(),
                      paymentType: paymentType == "credit" ? "credit" : "cash",
                      status: statusVal,
                      dueDate: (paymentType == "credit" ||
                              paymentType == "unpaid")
                          ? "${dueDate.day}-${dueDate.month}-${dueDate.year}"
                          : null,
                      date:
                          "${DateTime.now().day} ${_MainScreenState.getShortMonthName(DateTime.now().month)} ${DateTime.now().year}",
                      lines: lines,
                      total: total,
                    );
                    onInvoiceCreated(invoice);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Simpan & Cetak Faktur"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetailAndCommentDialog(BuildContext context, Invoice inv) {
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final statusLower = inv.status.toLowerCase();
          final isPaid = statusLower == "paid" || statusLower == "lunas";
          final isCredit = statusLower == "credit" || statusLower == "kredit";
          final statusLabel = isPaid
              ? "Lunas"
              : isCredit
                  ? "Kredit"
                  : "Belum Lunas";
          final statusColor = isPaid
              ? const Color(0xFF16A34A)
              : isCredit
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD97706);

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(child: Text("Detail ${inv.number}")),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 480,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pelanggan: ${inv.customer} (${inv.contact})",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        "Tanggal: ${inv.date} · Pembayaran: ${inv.paymentType.toUpperCase()}"),
                    if (inv.dueDate != null)
                      Text("Jatuh tempo: ${inv.dueDate}",
                          style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    if (role == "admin") ...[
                      Row(
                        children: [
                          const Text("Status Faktur: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: isPaid
                                ? "paid"
                                : isCredit
                                    ? "credit"
                                    : "unpaid",
                            items: const [
                              DropdownMenuItem(
                                  value: "paid", child: Text("Lunas")),
                              DropdownMenuItem(
                                  value: "unpaid", child: Text("Belum Lunas")),
                              DropdownMenuItem(
                                  value: "credit", child: Text("Kredit")),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  inv.status = val;
                                });
                                onUpdateInvoiceStatus?.call(inv, val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Divider(),
                    const Text("Rincian Item:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...inv.lines.map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${l.productName} × ${l.quantity}"),
                              Text(_MainScreenState.formatRupiah(l.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_MainScreenState.formatRupiah(inv.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Komentar Koreksi Manager:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    if (inv.comments.isEmpty)
                      const Text("Belum ada komentar koreksi dari Manager.",
                          style:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                    else
                      ...inv.comments.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.actor,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFF2563EB))),
                                    Text(c.date,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF94A3B8))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.message,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          )),
                    if (role == "manager") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentCtrl,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText:
                              "Tulis catatan koreksi (maks 500 karakter)...",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final text = commentCtrl.text.trim();
                            if (text.isNotEmpty) {
                              onAddComment(inv.id, text);
                              setDialogState(() {
                                inv.comments.add(InvoiceComment(
                                  id: DateTime.now().millisecondsSinceEpoch,
                                  actor: "Budi Santoso",
                                  message: text,
                                  date: "Baru saja",
                                ));
                                commentCtrl.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text("Kirim Catatan Koreksi"),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text("Cetak Nota"),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openPrintInvoiceDialog(context, inv);
                },
              ),
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tutup")),
            ],
          );
        },
      ),
    );
  }

  void _openPrintInvoiceDialog(BuildContext context, Invoice inv) {
    final statusLower = inv.status.toLowerCase();
    final isPaid = statusLower == "paid" || statusLower == "lunas";
    final isCredit = statusLower == "credit" || statusLower == "kredit";
    final statusText = isPaid
        ? "LUNAS"
        : isCredit
            ? "KREDIT"
            : "BELUM LUNAS";
    final statusColor = isPaid
        ? const Color(0xFF16A34A)
        : isCredit
            ? const Color(0xFF2563EB)
            : const Color(0xFFD97706);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.print_rounded, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cetak Nota Faktur Pemesanan",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(inv.number,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Store Header
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          "TOKO KELONTONG BERKAH",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Pusat Grosir & Eceran Kebutuhan Usaha Retail",
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Text(
                          "Jl. Raya Pasar No. 12 · WhatsApp: 0812-3456-7890",
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 8),

                  // Invoice Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("No. Faktur: ${inv.number}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("Tanggal: ${inv.date}",
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                          const Text("Kasir / Admin: Rina Amelia",
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Pelanggan: ${inv.customer}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          if (inv.contact.isNotEmpty)
                            Text("Kontak: ${inv.contact}",
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // Item Table Header
                  const Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: Text("Item Produk",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(
                          flex: 2,
                          child: Text("Qty",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(
                          flex: 3,
                          child: Text("Harga Satuan",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(
                          flex: 3,
                          child: Text("Subtotal",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Item Rows
                  ...inv.lines.map((l) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 5,
                                child: Text(l.productName,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                flex: 2,
                                child: Text("${l.quantity}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                flex: 3,
                                child: Text(
                                    _MainScreenState.formatRupiah(l.unitPrice),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                flex: 3,
                                child: Text(
                                    _MainScreenState.formatRupiah(l.subtotal),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1.5),

                  // Total & Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL AKHIR:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        _MainScreenState.formatRupiah(inv.total),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  if (inv.dueDate != null && !isPaid) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Jatuh Tempo Pembayaran: ${inv.dueDate}",
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626)),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Signatures
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text("Penerima / Pelanggan,",
                              style: TextStyle(fontSize: 11)),
                          SizedBox(height: 45),
                          Text("( .............................. )",
                              style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      Column(
                        children: [
                          Text("Hormat Kami / Kasir,",
                              style: TextStyle(fontSize: 11)),
                          SizedBox(height: 45),
                          Text("Rina Amelia (Admin)",
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Terima kasih atas pesanan dan kerja sama Anda!",
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text("Cetak Nota Sekarang"),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      "Nota ${inv.number} berhasil dikirim ke antrian pencetakan!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Daftar Faktur Penjualan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    "Kelola transaksi, status pembayaran, dan komentar koreksi",
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
            if (role == "admin")
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openCreateInvoiceDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text("Buat Faktur Baru",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: invoices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text("Belum ada faktur yang tercatat.")),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final statusLower = inv.status.toLowerCase();
                    final isPaid =
                        statusLower == "paid" || statusLower == "lunas";
                    final isCredit =
                        statusLower == "credit" || statusLower == "kredit";
                    final statusLabel = isPaid
                        ? "Lunas"
                        : isCredit
                            ? "Kredit"
                            : "Belum Lunas";
                    final statusBg = isPaid
                        ? const Color(0xFFF0FDF4)
                        : isCredit
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFFFFBEB);
                    final statusColor = isPaid
                        ? const Color(0xFF16A34A)
                        : isCredit
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFD97706);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.receipt_outlined,
                            color: Color(0xFF2563EB)),
                      ),
                      title: Row(
                        children: [
                          Text(inv.number,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle:
                          Text("Pelanggan: ${inv.customer} · ${inv.date}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_MainScreenState.formatRupiah(inv.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          if (role == "admin") ...[
                            PopupMenuButton<String>(
                              tooltip:
                                  "Update Status (Lunas, Belum Lunas, Kredit)",
                              icon: const Icon(
                                  Icons.published_with_changes_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20),
                              onSelected: (newStatus) {
                                onUpdateInvoiceStatus?.call(inv, newStatus);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: "paid",
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded,
                                          color: Color(0xFF16A34A), size: 18),
                                      SizedBox(width: 8),
                                      Text("Tandai Lunas"),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: "unpaid",
                                  child: Row(
                                    children: [
                                      Icon(Icons.pending_actions_outlined,
                                          color: Color(0xFFD97706), size: 18),
                                      SizedBox(width: 8),
                                      Text("Tandai Belum Lunas"),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: "credit",
                                  child: Row(
                                    children: [
                                      Icon(Icons.credit_score_outlined,
                                          color: Color(0xFF2563EB), size: 18),
                                      SizedBox(width: 8),
                                      Text("Tandai Kredit"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.print_outlined,
                                  color: Color(0xFF2563EB), size: 20),
                              tooltip: "Cetak Nota / Faktur",
                              onPressed: () =>
                                  _openPrintInvoiceDialog(context, inv),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined,
                                color: Color(0xFF64748B), size: 20),
                            tooltip: "Detail & Koreksi",
                            onPressed: () =>
                                _openDetailAndCommentDialog(context, inv),
                          ),
                          if (role == "manager")
                            IconButton(
                              icon: const Icon(Icons.print_outlined,
                                  color: Color(0xFF64748B), size: 20),
                              tooltip: "Cetak Nota",
                              onPressed: () =>
                                  _openPrintInvoiceDialog(context, inv),
                            ),
                          if (role == "admin") ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626), size: 20),
                              tooltip: "Hapus Faktur",
                              onPressed: () =>
                                  _confirmDeleteInvoice(context, inv),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteInvoice(BuildContext context, Invoice inv) {
    if (role != "admin") return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Hapus Faktur",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Apakah Anda yakin ingin menghapus faktur \"${inv.number}\" untuk pelanggan \"${inv.customer}\"?",
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Total: ${_MainScreenState.formatRupiah(inv.total)} · Tanggal: ${inv.date}",
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteInvoice?.call(inv);
            },
            child: const Text("Hapus Faktur"),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENT: STATISTIK & PARETO (MANAGER)
// ==========================================
class StatisticsComponent extends StatefulWidget {
  const StatisticsComponent({
    super.key,
    required this.profitRecords,
    required this.products,
    required this.invoices,
  });

  final List<ProfitRecord> profitRecords;
  final List<Product> products;
  final List<Invoice> invoices;

  @override
  State<StatisticsComponent> createState() => _StatisticsComponentState();
}

class _StatisticsComponentState extends State<StatisticsComponent> {
  String _period = "month"; // week | month
  int? _selectedMonthIndex;

  // Helper untuk mendapatkan nama bulan dalam bahasa Indonesia
  String _getMonthNameFromDate(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) {
      const monthNames = [
        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"
      ];
      return monthNames[parsed.month - 1];
    }
    // Fallback jika format teks non-standar
    if (dateStr.contains("07") || dateStr.toLowerCase().contains("jul"))
      return "Juli";
    if (dateStr.contains("08") || dateStr.toLowerCase().contains("agu"))
      return "Agustus";
    if (dateStr.contains("09") || dateStr.toLowerCase().contains("sep"))
      return "September";
    if (dateStr.contains("10") || dateStr.toLowerCase().contains("okt"))
      return "Oktober";
    if (dateStr.contains("11") || dateStr.toLowerCase().contains("nov"))
      return "November";
    if (dateStr.contains("12") || dateStr.toLowerCase().contains("des"))
      return "Desember";
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final totalModal =
        widget.products.fold<int>(0, (sum, p) => sum + (p.cost * p.stock));
    final potentialRevenue =
        widget.products.fold<int>(0, (sum, p) => sum + (p.price * p.stock));
    final estimatedProfit = potentialRevenue - totalModal;
    final potentialMargin = potentialRevenue > 0
        ? ((estimatedProfit / potentialRevenue) * 100).toStringAsFixed(1)
        : "0";
    final rejectLoss = widget.products
        .fold<int>(0, (sum, p) => sum + (p.cost * p.rejectStock));

    // Grouping by Category for Bar Chart
    final categoryMap = <String, _CategoryStat>{};
    for (final p in widget.products) {
      final cat = p.category.isEmpty ? "Lainnya" : p.category;
      if (!categoryMap.containsKey(cat)) {
        categoryMap[cat] = _CategoryStat(name: cat);
      }
      categoryMap[cat]!.skuCount += 1;
      categoryMap[cat]!.totalStock += p.stock;
      categoryMap[cat]!.totalCost += p.cost * p.stock;
    }
    final categoryList = categoryMap.values.toList()
      ..sort((a, b) => b.totalStock.compareTo(a.totalStock));
    final maxCategoryStock = categoryList.fold<int>(
        0, (max, c) => c.totalStock > max ? c.totalStock : max);

    // Invoices statistics for Donut Chart
    final paidInvoices =
        widget.invoices.where((i) => i.status == "paid").toList();
    final unpaidInvoices =
        widget.invoices.where((i) => i.status == "unpaid").toList();
    final creditInvoices =
        widget.invoices.where((i) => i.status == "credit").toList();

    final paidCount = paidInvoices.length;
    final unpaidCount = unpaidInvoices.length;
    final creditCount = creditInvoices.length;
    final totalInvoicesCount = widget.invoices.length;

    final paidTotalNominal =
        paidInvoices.fold<int>(0, (sum, i) => sum + i.total);
    final unpaidTotalNominal =
        unpaidInvoices.fold<int>(0, (sum, i) => sum + i.total);
    final creditTotalNominal =
        creditInvoices.fold<int>(0, (sum, i) => sum + i.total);
    final grandTotalFaktur =
        paidTotalNominal + unpaidTotalNominal + creditTotalNominal;

    // Monthly Profit Records
    final monthlySorted = List<ProfitRecord>.from(widget.profitRecords);
    final maxMonthlyProfit =
        monthlySorted.fold<int>(0, (max, r) => r.profit > max ? r.profit : max);
    final totalProfitSum =
        monthlySorted.fold<int>(0, (sum, r) => sum + r.profit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary KPIs
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 48) / 4;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatBox(
                    cardWidth.clamp(220, 300),
                    "Total Modal Stok",
                    _MainScreenState.formatCompactRupiah(totalModal),
                    const Color(0xFF2563EB)),
                _buildStatBox(
                    cardWidth.clamp(220, 300),
                    "Potensi Omzet",
                    _MainScreenState.formatCompactRupiah(potentialRevenue),
                    const Color(0xFF0284C7)),
                _buildStatBox(
                    cardWidth.clamp(220, 300),
                    "Perkiraan Keuntungan",
                    _MainScreenState.formatCompactRupiah(estimatedProfit),
                    const Color(0xFF16A34A)),
                _buildStatBox(cardWidth.clamp(220, 300), "Margin Potensi",
                    "$potentialMargin %", const Color(0xFF7C3AED)),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        if (rejectLoss > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626)),
                const SizedBox(width: 12),
                Text(
                  "Kerugian Barang Reject: ${_MainScreenState.formatRupiah(rejectLoss)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 28),

        // SECTION 1: DIAGRAM TOTAL PENJUALAN BULANAN (LINE CHART: JANUARI HINGGA BULAN TERAKHIR)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Diagram Total Penjualan Bulanan (Line Chart)",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                          "Grafik garis penjualan dari Januari hingga bulan terakhir dengan nilai sumbu Y dalam Rupiah",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart_rounded,
                            size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text("Januari — November 2026",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visual Line Chart Canvas (Bebas Overflow)
              LayoutBuilder(
                builder: (context, constraints) {
                  const List<MonthlySalesData> salesSeries = [
                    MonthlySalesData(
                        monthIndex: 1,
                        shortMonth: "Jan",
                        monthName: "Januari",
                        totalSales: 8450000,
                        totalInvoices: 42),
                    MonthlySalesData(
                        monthIndex: 2,
                        shortMonth: "Feb",
                        monthName: "Februari",
                        totalSales: 9800000,
                        totalInvoices: 48),
                    MonthlySalesData(
                        monthIndex: 3,
                        shortMonth: "Mar",
                        monthName: "Maret",
                        totalSales: 11250000,
                        totalInvoices: 56),
                    MonthlySalesData(
                        monthIndex: 4,
                        shortMonth: "Apr",
                        monthName: "April",
                        totalSales: 10600000,
                        totalInvoices: 52),
                    MonthlySalesData(
                        monthIndex: 5,
                        shortMonth: "Mei",
                        monthName: "Mei",
                        totalSales: 13400000,
                        totalInvoices: 65),
                    MonthlySalesData(
                        monthIndex: 6,
                        shortMonth: "Jun",
                        monthName: "Juni",
                        totalSales: 12850000,
                        totalInvoices: 63),
                    MonthlySalesData(
                        monthIndex: 7,
                        shortMonth: "Jul",
                        monthName: "Juli",
                        totalSales: 14700000,
                        totalInvoices: 71),
                    MonthlySalesData(
                        monthIndex: 8,
                        shortMonth: "Agu",
                        monthName: "Agustus",
                        totalSales: 16350000,
                        totalInvoices: 78),
                    MonthlySalesData(
                        monthIndex: 9,
                        shortMonth: "Sep",
                        monthName: "September",
                        totalSales: 18200000,
                        totalInvoices: 88),
                    MonthlySalesData(
                        monthIndex: 10,
                        shortMonth: "Okt",
                        monthName: "Oktober",
                        totalSales: 19850000,
                        totalInvoices: 94),
                    MonthlySalesData(
                        monthIndex: 11,
                        shortMonth: "Nov",
                        monthName: "November",
                        totalSales: 21500000,
                        totalInvoices: 102),
                  ];

                  final totalSalesSum = salesSeries.fold<int>(
                      0, (sum, item) => sum + item.totalSales);
                  final highestSalesMonth = salesSeries
                      .reduce((a, b) => a.totalSales > b.totalSales ? a : b);
                  final avgMonthlySales =
                      (totalSalesSum / salesSeries.length).round();

                  return Column(
                    children: [
                      SizedBox(
                        height: 270,
                        width: constraints.maxWidth,
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, 270),
                          painter: _MonthlySalesLineChartPainter(
                            salesData: salesSeries,
                            selectedIndex: _selectedMonthIndex,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildParetoSummary("Total Penjualan",
                              _MainScreenState.formatRupiah(totalSalesSum)),
                          _buildParetoSummary("Rata-rata / Bulan",
                              _MainScreenState.formatRupiah(avgMonthlySales)),
                          _buildParetoSummary("Penjualan Tertinggi",
                              "${highestSalesMonth.monthName} (${_MainScreenState.formatCompactRupiah(highestSalesMonth.totalSales)})"),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // SECTION 2 & 3: GRID (DIAGRAM BATANG KATEGORI PRODUK & DONUT STATUS PEMBAYARAN FAKTUR)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildCategoryBarChart(
                              categoryList, maxCategoryStock)),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildInvoiceDonutCard(
                          paidCount: paidCount,
                          unpaidCount: unpaidCount,
                          creditCount: creditCount,
                          totalCount: totalInvoicesCount,
                          paidNominal: paidTotalNominal,
                          unpaidNominal: unpaidTotalNominal,
                          creditNominal: creditTotalNominal,
                          grandTotal: grandTotalFaktur,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildCategoryBarChart(categoryList, maxCategoryStock),
                      const SizedBox(height: 24),
                      _buildInvoiceDonutCard(
                        paidCount: paidCount,
                        unpaidCount: unpaidCount,
                        creditCount: creditCount,
                        totalCount: totalInvoicesCount,
                        paidNominal: paidTotalNominal,
                        unpaidNominal: unpaidTotalNominal,
                        creditNominal: creditTotalNominal,
                        grandTotal: grandTotalFaktur,
                      ),
                    ],
                  );
          },
        ),
      ],
    );
  }

  // Widget Diagram Batang Kategori Produk
  Widget _buildCategoryBarChart(List<_CategoryStat> categories, int maxStock) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Diagram Batang Kategori Produk",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Jumlah SKU & total stok fisik per kategori produk",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 28),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal/Vertical bars per category
          if (categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text("Belum ada data produk"),
              ),
            )
          else
            ...categories.map((cat) {
              final percent = maxStock > 0
                  ? (cat.totalStock / maxStock).clamp(0.0, 1.0)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        Text(
                          "${cat.skuCount} SKU · ${cat.totalStock} Unit",
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percent > 0.02 ? percent : 0.02,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Nilai Stok: ${_MainScreenState.formatRupiah(cat.totalCost)}",
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // Widget Donut Chart Status Pembayaran Faktur
  Widget _buildInvoiceDonutCard({
    required int paidCount,
    required int unpaidCount,
    required int creditCount,
    required int totalCount,
    required int paidNominal,
    required int unpaidNominal,
    required int creditNominal,
    required int grandTotal,
  }) {
    final paidPercent =
        totalCount > 0 ? ((paidCount / totalCount) * 100).round() : 0;
    final unpaidPercent =
        totalCount > 0 ? ((unpaidCount / totalCount) * 100).round() : 0;
    final creditPercent =
        totalCount > 0 ? ((creditCount / totalCount) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status Pembayaran Faktur",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Distribusi faktur Lunas, Belum Lunas, & Kredit",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              Icon(Icons.pie_chart_rounded, color: Color(0xFF16A34A), size: 28),
            ],
          ),
          const SizedBox(height: 24),

          // Donut Chart + Center Total
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _InvoiceDonutPainter(
                      paidCount: paidCount,
                      unpaidCount: unpaidCount,
                      creditCount: creditCount,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$totalCount",
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        "Total Faktur",
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // Legend & Breakdown
          _buildDonutLegendRow(
            color: const Color(0xFF16A34A),
            label: "Lunas",
            count: paidCount,
            percent: paidPercent,
            nominal: _MainScreenState.formatRupiah(paidNominal),
          ),
          const SizedBox(height: 8),
          _buildDonutLegendRow(
            color: const Color(0xFFD97706),
            label: "Belum Lunas",
            count: unpaidCount,
            percent: unpaidPercent,
            nominal: _MainScreenState.formatRupiah(unpaidNominal),
          ),
          const SizedBox(height: 8),
          _buildDonutLegendRow(
            color: const Color(0xFF2563EB),
            label: "Kredit",
            count: creditCount,
            percent: creditPercent,
            nominal: _MainScreenState.formatRupiah(creditNominal),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendRow({
    required Color color,
    required String label,
    required int count,
    required int percent,
    required String nominal,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$label ($count faktur · $percent%)",
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B)),
          ),
        ),
        Text(
          nominal,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildStatBox(double width, String title, String value, Color color) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildParetoSummary(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _CategoryStat {
  _CategoryStat({
    required this.name,
    this.skuCount = 0,
    this.totalStock = 0,
    this.totalCost = 0,
  });

  final String name;
  int skuCount;
  int totalStock;
  int totalCost;
}

// ==========================================
// PAINTER: DONUT CHART UNTUK STATUS FAKTUR
// ==========================================
class _InvoiceDonutPainter extends CustomPainter {
  _InvoiceDonutPainter({
    required this.paidCount,
    required this.unpaidCount,
    required this.creditCount,
  });

  final int paidCount;
  final int unpaidCount;
  final int creditCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 14;
    const strokeWidth = 22.0;

    final total = paidCount + unpaidCount + creditCount;
    if (total == 0) {
      final emptyPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }

    final paintPaid = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintUnpaid = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintCredit = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var startAngle = -pi / 2;

    void drawSegment(int count, Paint paint) {
      if (count <= 0) return;
      final sweepAngle = (count / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(paidCount, paintPaid);
    drawSegment(unpaidCount, paintUnpaid);
    drawSegment(creditCount, paintCredit);
  }

  @override
  bool shouldRepaint(covariant _InvoiceDonutPainter oldDelegate) =>
      oldDelegate.paidCount != paidCount ||
      oldDelegate.unpaidCount != unpaidCount ||
      oldDelegate.creditCount != creditCount;
}

// ==========================================
// MODEL & PAINTER: LINE CHART PENJUALAN BULANAN
// ==========================================
class MonthlySalesData {
  const MonthlySalesData({
    required this.monthIndex,
    required this.shortMonth,
    required this.monthName,
    required this.totalSales,
    this.totalInvoices = 0,
  });

  final int monthIndex;
  final String shortMonth;
  final String monthName;
  final int totalSales;
  final int totalInvoices;
}

class _MonthlySalesLineChartPainter extends CustomPainter {
  _MonthlySalesLineChartPainter({
    required this.salesData,
    this.selectedIndex,
  });

  final List<MonthlySalesData> salesData;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (salesData.isEmpty) return;

    const leftPadding = 75.0;
    const rightPadding = 24.0;
    const topPadding = 38.0;
    const bottomPadding = 36.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Nilai tertinggi untuk skala sumbu Y
    final maxDataSales = salesData.fold<int>(
        0, (max, item) => item.totalSales > max ? item.totalSales : max);
    final maxScale = maxDataSales > 0 ? (maxDataSales * 1.15).ceil() : 10000000;

    // 1. Gambar Garis Kisi Horizontal dan Label Ticks Sumbu Y
    const gridLineCount = 5;
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    const textStyleY = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i <= gridLineCount; i++) {
      final yRatio = i / gridLineCount;
      final y = topPadding + chartHeight * (1.0 - yRatio);
      final value = (maxScale * yRatio).round();

      // Garis horizontal
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Label sumbu Y (nominal Rupiah)
      final tp = TextPainter(
        text: TextSpan(
          text: _MainScreenState.formatCompactRupiah(value),
          style: textStyleY,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(leftPadding - tp.width - 10, y - tp.height / 2));
    }

    // 2. Hitung Titik Koordinat Garis (X & Y)
    final points = <Offset>[];
    final stepX = chartWidth / (salesData.length - 1);

    for (int i = 0; i < salesData.length; i++) {
      final x = leftPadding + i * stepX;
      final normalizedY = (salesData[i].totalSales / maxScale).clamp(0.0, 1.0);
      final y = topPadding + chartHeight * (1.0 - normalizedY);
      points.add(Offset(x, y));
    }

    // 3. Gambar Area Gradien Biru di Bawah Garis
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, topPadding + chartHeight);
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      } else {
        final p0 = points[i - 1];
        final p1 = points[i];
        final midX = (p0.dx + p1.dx) / 2;
        fillPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }
    }
    fillPath.lineTo(points.last.dx, topPadding + chartHeight);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2563EB).withOpacity(0.24),
        const Color(0xFF2563EB).withOpacity(0.01),
      ],
    ).createShader(
        Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight));

    final areaPaint = Paint()..shader = fillGradient;
    canvas.drawPath(fillPath, areaPaint);

    // 4. Gambar Garis Kurva Halus (Line Chart)
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, strokePaint);

    // 5. Gambar Titik Node, Nilai Penjualan di Atas Titik, dan Label Bulan Sumbu X
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotCenterPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    const textStyleX = TextStyle(
      color: Color(0xFF475569),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    const textStyleValue = TextStyle(
      color: Color(0xFF1E293B),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // Gunakan nama lengkap jika lebar per kolom mencukupi (>= 60px)
    final useFullName = (chartWidth / salesData.length) >= 60;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final item = salesData[i];
      final isSelected = selectedIndex == i;

      // Garis bantu vertikal saat node dipilih
      if (isSelected) {
        final selectGuidePaint = Paint()
          ..color = const Color(0xFF2563EB).withOpacity(0.3)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(p.dx, topPadding),
          Offset(p.dx, topPadding + chartHeight),
          selectGuidePaint,
        );
      }

      // Lingkaran node titik
      canvas.drawCircle(p, isSelected ? 7.5 : 5.0, dotOuterPaint);
      canvas.drawCircle(p, isSelected ? 7.5 : 5.0, dotBorderPaint);
      canvas.drawCircle(p, isSelected ? 3.5 : 2.5, dotCenterPaint);

      // Badge nilai penjualan di atas titik
      final valStr = _MainScreenState.formatCompactRupiah(item.totalSales);
      final tpVal = TextPainter(
        text: TextSpan(text: valStr, style: textStyleValue),
        textDirection: TextDirection.ltr,
      )..layout();

      final valRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(p.dx, p.dy - 16),
          width: tpVal.width + 10,
          height: tpVal.height + 4,
        ),
        const Radius.circular(5),
      );
      final pillPaint = Paint()
        ..color = isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill;
      final pillBorder = Paint()
        ..color = isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(valRect, pillPaint);
      canvas.drawRRect(valRect, pillBorder);
      tpVal.paint(
          canvas, Offset(p.dx - tpVal.width / 2, p.dy - 16 - tpVal.height / 2));

      // Label sumbu X: Bulan dari Januari hingga bulan terakhir
      final labelText = useFullName ? item.monthName : item.shortMonth;
      final tpX = TextPainter(
        text: TextSpan(
          text: labelText,
          style: isSelected
              ? textStyleX.copyWith(
                  color: const Color(0xFF2563EB), fontWeight: FontWeight.bold)
              : textStyleX,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tpX.paint(
          canvas, Offset(p.dx - tpX.width / 2, topPadding + chartHeight + 10));
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlySalesLineChartPainter oldDelegate) =>
      oldDelegate.salesData != salesData ||
      oldDelegate.selectedIndex != selectedIndex;
}

// ==========================================
// PAINTER: LOGO STOKKU (CUSTOM DESKTOP ICON)
// ==========================================
class _StokkuLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Blue gradient background (squircle)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0091FF), Color(0xFF0066FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rrectBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.24),
    );
    canvas.drawRRect(rrectBg, bgPaint);

    // 2. White inner window frame
    final strokeWidth = size.width * 0.075;
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inset = size.width * 0.20;
    final frameRect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    final innerRRect = RRect.fromRectAndRadius(
      frameRect,
      Radius.circular(size.width * 0.15),
    );
    canvas.drawRRect(innerRRect, framePaint);

    // 3. Horizontal divider line (header separator)
    final hY = frameRect.top + frameRect.height * 0.32;
    canvas.drawLine(
      Offset(frameRect.left, hY),
      Offset(frameRect.right, hY),
      framePaint,
    );

    // 4. Vertical divider line (sidebar separator)
    final vX = frameRect.left + frameRect.width * 0.36;
    canvas.drawLine(
      Offset(vX, hY),
      Offset(vX, frameRect.bottom),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
