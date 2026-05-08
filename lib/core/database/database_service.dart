import 'package:sqflite/sqflite.dart' hide Batch;
import 'package:path/path.dart';

/// Central database service with schema versioning and migration support.
/// Version history:
///   v3 — Original English schema (poultry only)
///   v4 — Multi-animal support (cattle, goats), FK constraints, individual_animals table
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farma.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SCHEMA CREATION (fresh install)
  // ══════════════════════════════════════════════════════════════

  Future<void> _createDB(Database db, int version) async {
    await _createSharedTables(db);
    await _createPoultryTables(db);
    await _createCattleTables(db);
    await _createGoatTables(db);
    await _createIndividualAnimalTable(db);
  }

  /// Tables shared across all animal modules.
  Future<void> _createSharedTables(Database db) async {
    await db.execute('''
      CREATE TABLE farms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phoneNumber TEXT,
        address TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE partners (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        farmId TEXT NOT NULL,
        name TEXT NOT NULL,
        animalType TEXT NOT NULL DEFAULT 'poultry',
        entryDate TEXT NOT NULL,
        initialQuantity INTEGER NOT NULL,
        currentQuantity INTEGER NOT NULL,
        breedOrLineage TEXT,
        acquisitionCost REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        individualTrackingEnabled INTEGER NOT NULL DEFAULT 0,
        maleCount INTEGER NOT NULL DEFAULT 0,
        femaleCount INTEGER NOT NULL DEFAULT 0,
        -- Poultry-specific (nullable for other types)
        type TEXT,
        birdOrigin TEXT,
        -- Cattle-specific (nullable for other types)
        cattlePurpose TEXT,
        -- Goat-specific (nullable for other types)
        goatPurpose TEXT,
        FOREIGN KEY (farmId) REFERENCES farms(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        type TEXT NOT NULL,
        customCategory TEXT,
        description TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE mortality_records (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        cause TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Poultry-specific tables.
  Future<void> _createPoultryTables(Database db) async {
    await db.execute('''
      CREATE TABLE egg_production (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        size TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE slaughters (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        slaughteredQuantity INTEGER NOT NULL,
        totalWeightKg REAL,
        slaughterCost REAL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chicken_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        clientId TEXT,
        saleType TEXT NOT NULL,
        date TEXT NOT NULL,
        paymentStatus TEXT NOT NULL,
        amountPaid REAL DEFAULT 0,
        groups TEXT,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE egg_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        clientId TEXT,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        total REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        amountPaid REAL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE culled_bird_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        clientId TEXT,
        quantity INTEGER NOT NULL,
        pricePerHead REAL NOT NULL,
        total REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        amountPaid REAL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Cattle-specific tables.
  Future<void> _createCattleTables(Database db) async {
    await db.execute('''
      CREATE TABLE milk_production (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        quantityLiters REAL NOT NULL,
        session TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calf_births (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        sex TEXT,
        notes TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cattle_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        clientId TEXT,
        saleType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        weightKg REAL,
        pricePerKg REAL,
        total REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        amountPaid REAL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE milk_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        clientId TEXT,
        quantityLiters REAL NOT NULL,
        pricePerLiter REAL NOT NULL,
        total REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        amountPaid REAL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Goat-specific tables.
  Future<void> _createGoatTables(Database db) async {
    await db.execute('''
      CREATE TABLE goat_milk_production (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        quantityLiters REAL NOT NULL,
        session TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE kid_births (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        sex TEXT,
        notes TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE goat_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        clientId TEXT,
        saleType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        weightKg REAL,
        pricePerKg REAL,
        total REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        amountPaid REAL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goat_milk_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        clientId TEXT,
        quantityLiters REAL NOT NULL,
        pricePerLiter REAL NOT NULL,
        total REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        amountPaid REAL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Reserved for future individual animal tracking.
  Future<void> _createIndividualAnimalTable(Database db) async {
    await db.execute('''
      CREATE TABLE individual_animals (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        animalType TEXT NOT NULL,
        tagNumber TEXT,
        name TEXT,
        sex TEXT,
        birthDate TEXT,
        weightKg REAL,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        FOREIGN KEY (batchId) REFERENCES batches(id) ON DELETE CASCADE
      )
    ''');
  }

  // ══════════════════════════════════════════════════════════════
  //  MIGRATIONS
  // ══════════════════════════════════════════════════════════════

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS requests');
    }

    if (oldVersion < 3) {
      // Drop old Portuguese tables
      for (final table in [
        'exploracoes', 'parceiros', 'lotes', 'despesas', 'mortalidade',
        'producao_ovos', 'abates', 'venda_frangos', 'venda_ovos', 'venda_aves_descartadas',
      ]) {
        await db.execute('DROP TABLE IF EXISTS $table');
      }
    }

    if (oldVersion < 5) {
      await _safeAddColumn(db, 'batches', 'maleCount', 'INTEGER NOT NULL DEFAULT 0');
      await _safeAddColumn(db, 'batches', 'femaleCount', 'INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 4) {
      // Add new columns to batches
      await _safeAddColumn(db, 'batches', 'animalType', "TEXT DEFAULT 'poultry'");
      await _safeAddColumn(db, 'batches', 'individualTrackingEnabled', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'batches', 'cattlePurpose', 'TEXT');
      await _safeAddColumn(db, 'batches', 'goatPurpose', 'TEXT');

      // Create new animal tables
      await _createCattleTables(db);
      await _createGoatTables(db);
      await _createIndividualAnimalTable(db);
    }
  }

  /// Safely add a column (ignores if it already exists).
  Future<void> _safeAddColumn(Database db, String table, String column, String type) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    } catch (_) {
      // Column already exists — ignore
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  RAW ACCESS (used by repositories)
  // ══════════════════════════════════════════════════════════════

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteWhere(String table, {required String where, required List<Object?> whereArgs}) async {
    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
