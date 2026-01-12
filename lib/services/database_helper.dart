import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/request.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bizmanager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Clients
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT,
        phoneNumber TEXT,
        address TEXT,
        notes TEXT
      )
    ''');

    // Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT,
        defaultPrice REAL
      )
    ''');

    // Requests (Orders)
    await db.execute('''
      CREATE TABLE requests (
        id TEXT PRIMARY KEY,
        clientId TEXT,
        productName TEXT,
        amount REAL,
        totalPrice REAL,
        date TEXT,
        amountPaid REAL,
        paymentStatus INTEGER
      )
    ''');
  }

  // --- CRUD Clients ---
  Future<void> insertClient(Client client) async {
    final db = await database;
    await db.insert(
      'clients',
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final result = await db.query('clients');
    return result.map((json) => Client.fromMap(json)).toList();
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  // --- CRUD Products ---
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Requests ---
  Future<void> insertRequest(Request request) async {
    final db = await database;
    await db.insert(
      'requests',
      request.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Request>> getRequests() async {
    final db = await database;
    final result = await db.query('requests', orderBy: 'date DESC');
    return result.map((json) => Request.fromMap(json)).toList();
  }

  Future<void> updateRequest(Request request) async {
    final db = await database;
    await db.update(
      'requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }
}
