import 'package:farma/core/database/database_service.dart';
import 'package:farma/core/models/expense.dart';
import 'package:farma/core/models/mortality.dart';
import 'package:farma/features/goats/models/goat_batch.dart';
import 'package:farma/features/goats/models/goat_models.dart';

/// Repository for all goat-specific data access.
class GoatRepository {
  final _db = DatabaseService.instance;

  // ── Batches ──

  Future<void> insertBatch(GoatBatch batch) =>
      _db.insert('batches', batch.toMap());

  Future<List<GoatBatch>> getBatches() async {
    final maps = await _db.queryWhere('batches', where: "animalType = ?", whereArgs: ['goat']);
    return maps.map((m) => GoatBatch.fromMap(m)).toList();
  }

  Future<void> updateBatch(GoatBatch batch) =>
      _db.update('batches', batch.toMap(), batch.id);

  Future<void> deleteBatch(String id) => _db.delete('batches', id);

  // ── Expenses ──

  Future<void> insertExpense(Expense e) => _db.insert('expenses', e.toMap());

  Future<List<Expense>> getExpensesByBatchId(String batchId) async {
    final maps = await _db.queryWhere('expenses', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> deleteExpense(String id) => _db.delete('expenses', id);

  // ── Mortality ──

  Future<void> insertMortality(Mortality m) => _db.insert('mortality_records', m.toMap());

  Future<List<Mortality>> getMortalitiesByBatchId(String batchId) async {
    final maps = await _db.queryWhere('mortality_records', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => Mortality.fromMap(m)).toList();
  }

  Future<void> deleteMortality(String id) => _db.delete('mortality_records', id);

  // ── Goat Milk Production ──

  Future<void> insertMilkProduction(GoatMilkProduction p) =>
      _db.insert('goat_milk_production', p.toMap());

  Future<List<GoatMilkProduction>> getMilkProductionByBatchId(String batchId) async {
    final maps = await _db.queryWhere('goat_milk_production', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => GoatMilkProduction.fromMap(m)).toList();
  }

  Future<List<GoatMilkProduction>> getAllMilkProduction() async {
    final maps = await _db.queryAll('goat_milk_production');
    return maps.map((m) => GoatMilkProduction.fromMap(m)).toList();
  }

  Future<void> deleteMilkProduction(String id) => _db.delete('goat_milk_production', id);

  // ── Kid Births ──

  Future<void> insertKidBirth(KidBirth b) => _db.insert('kid_births', b.toMap());

  Future<List<KidBirth>> getKidBirthsByBatchId(String batchId) async {
    final maps = await _db.queryWhere('kid_births', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => KidBirth.fromMap(m)).toList();
  }

  Future<void> deleteKidBirth(String id) => _db.delete('kid_births', id);

  // ── Goat Sales ──

  Future<void> insertGoatSale(GoatSale s) => _db.insert('goat_sales', s.toMap());

  Future<List<GoatSale>> getAllGoatSales() async {
    final maps = await _db.queryAll('goat_sales');
    return maps.map((m) => GoatSale.fromMap(m)).toList();
  }

  Future<void> updateGoatSale(GoatSale s) => _db.update('goat_sales', s.toMap(), s.id);
  Future<void> deleteGoatSale(String id) => _db.delete('goat_sales', id);

  // ── Goat Milk Sales ──

  Future<void> insertMilkSale(GoatMilkSale s) => _db.insert('goat_milk_sales', s.toMap());

  Future<List<GoatMilkSale>> getAllMilkSales() async {
    final maps = await _db.queryAll('goat_milk_sales');
    return maps.map((m) => GoatMilkSale.fromMap(m)).toList();
  }

  Future<void> updateMilkSale(GoatMilkSale s) => _db.update('goat_milk_sales', s.toMap(), s.id);
  Future<void> deleteMilkSale(String id) => _db.delete('goat_milk_sales', id);
}
