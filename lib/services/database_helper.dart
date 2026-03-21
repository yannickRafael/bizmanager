import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/farm.dart';
import '../models/batch.dart';
import '../models/expense.dart';
import '../models/mortality.dart';
import '../models/egg_production.dart';
import '../models/slaughter.dart';
import '../models/sale.dart';
import '../models/partner.dart';

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

    return await openDatabase(
      path, 
      version: 3, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Legacy Tables (kept for compatibility or reused)
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT,
        phoneNumber TEXT,
        address TEXT,
        notes TEXT
      )
    ''');

    await _createV3Tables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS requests');
    }

    if (oldVersion < 3) {
      // Drop all Portuguese v2 tables to migrate cleanly to English
      await db.execute('DROP TABLE IF EXISTS exploracoes');
      await db.execute('DROP TABLE IF EXISTS parceiros');
      await db.execute('DROP TABLE IF EXISTS lotes');
      await db.execute('DROP TABLE IF EXISTS despesas');
      await db.execute('DROP TABLE IF EXISTS mortalidade');
      await db.execute('DROP TABLE IF EXISTS producao_ovos');
      await db.execute('DROP TABLE IF EXISTS abates');
      await db.execute('DROP TABLE IF EXISTS venda_frangos');
      await db.execute('DROP TABLE IF EXISTS venda_ovos');
      await db.execute('DROP TABLE IF EXISTS venda_aves_descartadas');
      
      await _createV3Tables(db);
    }
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE farms (
        id TEXT PRIMARY KEY,
        name TEXT,
        address TEXT,
        notes TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE partners (
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        phone TEXT,
        address TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        farmId TEXT,
        name TEXT,
        type TEXT,
        birdOrigin TEXT,
        entryDate TEXT,
        initialQuantity INTEGER,
        currentQuantity INTEGER,
        breedOrLineage TEXT,
        acquisitionCost REAL,
        status TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        batchId TEXT,
        type TEXT,
        customCategory TEXT,
        description TEXT,
        amount REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE mortality_records (
        id TEXT PRIMARY KEY,
        batchId TEXT,
        quantity INTEGER,
        cause TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE egg_production (
        id TEXT PRIMARY KEY,
        batchId TEXT,
        unit TEXT,
        quantity REAL,
        size TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE slaughters (
        id TEXT PRIMARY KEY,
        batchId TEXT,
        slaughteredQuantity INTEGER,
        totalWeightKg REAL,
        slaughterCost REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chicken_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT,
        clientId TEXT,
        saleType TEXT,
        date TEXT,
        paymentStatus TEXT,
        amountPaid REAL,
        groups TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE egg_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT,
        clientId TEXT,
        unit TEXT,
        quantity REAL,
        unitPrice REAL,
        total REAL,
        paymentStatus TEXT,
        amountPaid REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE culled_bird_sales (
        id TEXT PRIMARY KEY,
        batchId TEXT,
        clientId TEXT,
        quantity INTEGER,
        pricePerHead REAL,
        total REAL,
        paymentStatus TEXT,
        amountPaid REAL,
        date TEXT
      )
    ''');
  }

  // --- CRUD Clients ---
  Future<void> insertClient(Client client) async => await (await database).insert('clients', client.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Client>> getClients() async => (await (await database).query('clients')).map((json) => Client.fromMap(json)).toList();
  Future<void> updateClient(Client client) async => await (await database).update('clients', client.toMap(), where: 'id = ?', whereArgs: [client.id]);
  Future<void> deleteClient(String id) async => await (await database).delete('clients', where: 'id = ?', whereArgs: [id]);

  // --- CRUD Farm ---
  Future<void> insertFarm(Farm farm) async => await (await database).insert('farms', farm.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Farm>> getFarms() async => (await (await database).query('farms')).map((json) => Farm.fromMap(json)).toList();
  Future<void> updateFarm(Farm farm) async => await (await database).update('farms', farm.toMap(), where: 'id = ?', whereArgs: [farm.id]);
  Future<void> deleteFarm(String id) async => await (await database).delete('farms', where: 'id = ?', whereArgs: [id]);

  // --- CRUD Partner ---
  Future<void> insertPartner(Partner p) async => await (await database).insert('partners', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Partner>> getPartners() async => (await (await database).query('partners')).map((json) => Partner.fromMap(json)).toList();
  Future<void> updatePartner(Partner p) async => await (await database).update('partners', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  Future<void> deletePartner(String id) async => await (await database).delete('partners', where: 'id = ?', whereArgs: [id]);

  // --- CRUD Batch ---
  Future<void> insertBatch(Batch batch) async => await (await database).insert('batches', batch.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Batch>> getBatches() async => (await (await database).query('batches')).map((json) => Batch.fromMap(json)).toList();
  Future<void> updateBatch(Batch batch) async => await (await database).update('batches', batch.toMap(), where: 'id = ?', whereArgs: [batch.id]);
  Future<void> deleteBatch(String id) async => await (await database).delete('batches', where: 'id = ?', whereArgs: [id]);

  // --- CRUD Expense ---
  Future<void> insertExpense(Expense e) async => await (await database).insert('expenses', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Expense>> getExpenses() async => (await (await database).query('expenses')).map((json) => Expense.fromMap(json)).toList();
  Future<void> deleteExpense(String id) async => await (await database).delete('expenses', where: 'id = ?', whereArgs: [id]);

  // --- CRUD Mortality ---
  Future<void> insertMortality(Mortality m) async => await (await database).insert('mortality_records', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Mortality>> getMortalities() async => (await (await database).query('mortality_records')).map((json) => Mortality.fromMap(json)).toList();
  Future<void> deleteMortality(String id) async => await (await database).delete('mortality_records', where: 'id = ?', whereArgs: [id]);

  // --- CRUD EggProduction ---
  Future<void> insertEggProduction(EggProduction p) async => await (await database).insert('egg_production', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<EggProduction>> getEggProductions() async => (await (await database).query('egg_production')).map((json) => EggProduction.fromMap(json)).toList();
  Future<void> deleteEggProduction(String id) async => await (await database).delete('egg_production', where: 'id = ?', whereArgs: [id]);

  // --- CRUD Slaughter ---
  Future<void> insertSlaughter(Slaughter s) async => await (await database).insert('slaughters', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Slaughter>> getSlaughters() async => (await (await database).query('slaughters')).map((json) => Slaughter.fromMap(json)).toList();
  Future<void> deleteSlaughter(String id) async => await (await database).delete('slaughters', where: 'id = ?', whereArgs: [id]);

  // --- CRUD Sales ---
  Future<void> insertChickenSale(ChickenSale s) async => await (await database).insert('chicken_sales', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<ChickenSale>> getChickenSales() async => (await (await database).query('chicken_sales')).map((json) => ChickenSale.fromMap(json)).toList();
  Future<void> updateChickenSale(ChickenSale s) async => await (await database).update('chicken_sales', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  Future<void> deleteChickenSale(String id) async => await (await database).delete('chicken_sales', where: 'id = ?', whereArgs: [id]);

  Future<void> insertEggSale(EggSale s) async => await (await database).insert('egg_sales', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<EggSale>> getEggSales() async => (await (await database).query('egg_sales')).map((json) => EggSale.fromMap(json)).toList();
  Future<void> updateEggSale(EggSale s) async => await (await database).update('egg_sales', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  Future<void> deleteEggSale(String id) async => await (await database).delete('egg_sales', where: 'id = ?', whereArgs: [id]);

  Future<void> insertCulledBirdSale(CulledBirdSale s) async => await (await database).insert('culled_bird_sales', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<CulledBirdSale>> getCulledBirdSales() async => (await (await database).query('culled_bird_sales')).map((json) => CulledBirdSale.fromMap(json)).toList();
  Future<void> updateCulledBirdSale(CulledBirdSale s) async => await (await database).update('culled_bird_sales', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  Future<void> deleteCulledBirdSale(String id) async => await (await database).delete('culled_bird_sales', where: 'id = ?', whereArgs: [id]);
}
