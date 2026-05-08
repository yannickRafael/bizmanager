import 'package:farma/core/database/database_service.dart';
import 'package:farma/core/models/expense.dart';
import 'package:farma/core/models/mortality.dart';

// Legacy models (poultry still uses these until migration)
import 'package:farma/models/batch.dart' as legacy;
import 'package:farma/models/egg_production.dart' as legacy;
import 'package:farma/models/slaughter.dart' as legacy;
import 'package:farma/models/sale.dart' as legacy;

/// Repository for all poultry-specific data access.
///
/// Handles: PoultryBatches, EggProduction, Slaughters,
///          ChickenSales, EggSales, CulledBirdSales,
///          plus shared Expenses and Mortality for poultry batches.
class PoultryRepository {
  final _db = DatabaseService.instance;

  // ── Batches ──

  Future<void> insertBatch(legacy.Batch batch) =>
      _db.insert('batches', {...batch.toMap(), 'animalType': 'poultry'});

  Future<List<legacy.Batch>> getBatches() async {
    final maps = await _db.queryWhere('batches', where: "animalType = ? OR animalType IS NULL", whereArgs: ['poultry']);
    return maps.map((m) => legacy.Batch.fromMap(m)).toList();
  }

  Future<void> updateBatch(legacy.Batch batch) =>
      _db.update('batches', {...batch.toMap(), 'animalType': 'poultry'}, batch.id);

  Future<void> deleteBatch(String id) => _db.delete('batches', id);

  // ── Expenses (shared model, filtered by poultry batch) ──

  Future<void> insertExpense(Expense e) => _db.insert('expenses', e.toMap());

  Future<List<Expense>> getExpenses() async {
    final maps = await _db.queryAll('expenses');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getExpensesByBatchId(String batchId) async {
    final maps = await _db.queryWhere('expenses', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> deleteExpense(String id) => _db.delete('expenses', id);

  // ── Mortality (shared model) ──

  Future<void> insertMortality(Mortality m) => _db.insert('mortality_records', m.toMap());

  Future<List<Mortality>> getMortalities() async {
    final maps = await _db.queryAll('mortality_records');
    return maps.map((m) => Mortality.fromMap(m)).toList();
  }

  Future<List<Mortality>> getMortalitiesByBatchId(String batchId) async {
    final maps = await _db.queryWhere('mortality_records', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => Mortality.fromMap(m)).toList();
  }

  Future<void> deleteMortality(String id) => _db.delete('mortality_records', id);

  // ── Egg Production ──

  Future<void> insertEggProduction(legacy.EggProduction p) =>
      _db.insert('egg_production', p.toMap());

  Future<List<legacy.EggProduction>> getEggProductions() async {
    final maps = await _db.queryAll('egg_production');
    return maps.map((m) => legacy.EggProduction.fromMap(m)).toList();
  }

  Future<void> deleteEggProduction(String id) => _db.delete('egg_production', id);

  // ── Slaughters ──

  Future<void> insertSlaughter(legacy.Slaughter s) =>
      _db.insert('slaughters', s.toMap());

  Future<List<legacy.Slaughter>> getSlaughters() async {
    final maps = await _db.queryAll('slaughters');
    return maps.map((m) => legacy.Slaughter.fromMap(m)).toList();
  }

  Future<void> deleteSlaughter(String id) => _db.delete('slaughters', id);

  // ── Chicken Sales ──

  Future<void> insertChickenSale(legacy.ChickenSale s) =>
      _db.insert('chicken_sales', s.toMap());

  Future<List<legacy.ChickenSale>> getChickenSales() async {
    final maps = await _db.queryAll('chicken_sales');
    return maps.map((m) => legacy.ChickenSale.fromMap(m)).toList();
  }

  Future<void> updateChickenSale(legacy.ChickenSale s) =>
      _db.update('chicken_sales', s.toMap(), s.id);

  Future<void> deleteChickenSale(String id) => _db.delete('chicken_sales', id);

  // ── Egg Sales ──

  Future<void> insertEggSale(legacy.EggSale s) =>
      _db.insert('egg_sales', s.toMap());

  Future<List<legacy.EggSale>> getEggSales() async {
    final maps = await _db.queryAll('egg_sales');
    return maps.map((m) => legacy.EggSale.fromMap(m)).toList();
  }

  Future<void> updateEggSale(legacy.EggSale s) =>
      _db.update('egg_sales', s.toMap(), s.id);

  Future<void> deleteEggSale(String id) => _db.delete('egg_sales', id);

  // ── Culled Bird Sales ──

  Future<void> insertCulledBirdSale(legacy.CulledBirdSale s) =>
      _db.insert('culled_bird_sales', s.toMap());

  Future<List<legacy.CulledBirdSale>> getCulledBirdSales() async {
    final maps = await _db.queryAll('culled_bird_sales');
    return maps.map((m) => legacy.CulledBirdSale.fromMap(m)).toList();
  }

  Future<void> updateCulledBirdSale(legacy.CulledBirdSale s) =>
      _db.update('culled_bird_sales', s.toMap(), s.id);

  Future<void> deleteCulledBirdSale(String id) => _db.delete('culled_bird_sales', id);
}
