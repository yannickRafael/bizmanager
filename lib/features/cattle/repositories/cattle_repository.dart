import 'package:farma/core/database/database_service.dart';
import 'package:farma/core/models/expense.dart';
import 'package:farma/core/models/mortality.dart';
import 'package:farma/features/cattle/models/cattle_batch.dart';
import 'package:farma/features/cattle/models/cattle_models.dart';

/// Repository for all cattle-specific data access.
class CattleRepository {
  final _db = DatabaseService.instance;

  // ── Batches ──

  Future<void> insertBatch(CattleBatch batch) =>
      _db.insert('batches', batch.toMap());

  Future<List<CattleBatch>> getBatches() async {
    final maps = await _db.queryWhere('batches', where: "animalType = ?", whereArgs: ['cattle']);
    return maps.map((m) => CattleBatch.fromMap(m)).toList();
  }

  Future<void> updateBatch(CattleBatch batch) =>
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

  // ── Milk Production ──

  Future<void> insertMilkProduction(MilkProduction p) =>
      _db.insert('milk_production', p.toMap());

  Future<List<MilkProduction>> getMilkProductionByBatchId(String batchId) async {
    final maps = await _db.queryWhere('milk_production', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => MilkProduction.fromMap(m)).toList();
  }

  Future<List<MilkProduction>> getAllMilkProduction() async {
    final maps = await _db.queryAll('milk_production');
    return maps.map((m) => MilkProduction.fromMap(m)).toList();
  }

  Future<void> deleteMilkProduction(String id) => _db.delete('milk_production', id);

  // ── Calf Births ──

  Future<void> insertCalfBirth(CalfBirth b) => _db.insert('calf_births', b.toMap());

  Future<List<CalfBirth>> getCalfBirthsByBatchId(String batchId) async {
    final maps = await _db.queryWhere('calf_births', where: 'batchId = ?', whereArgs: [batchId]);
    return maps.map((m) => CalfBirth.fromMap(m)).toList();
  }

  Future<void> deleteCalfBirth(String id) => _db.delete('calf_births', id);

  // ── Cattle Sales ──

  Future<void> insertCattleSale(CattleSale s) => _db.insert('cattle_sales', s.toMap());

  Future<List<CattleSale>> getAllCattleSales() async {
    final maps = await _db.queryAll('cattle_sales');
    return maps.map((m) => CattleSale.fromMap(m)).toList();
  }

  Future<void> updateCattleSale(CattleSale s) => _db.update('cattle_sales', s.toMap(), s.id);
  Future<void> deleteCattleSale(String id) => _db.delete('cattle_sales', id);

  // ── Milk Sales ──

  Future<void> insertMilkSale(MilkSale s) => _db.insert('milk_sales', s.toMap());

  Future<List<MilkSale>> getAllMilkSales() async {
    final maps = await _db.queryAll('milk_sales');
    return maps.map((m) => MilkSale.fromMap(m)).toList();
  }

  Future<void> updateMilkSale(MilkSale s) => _db.update('milk_sales', s.toMap(), s.id);
  Future<void> deleteMilkSale(String id) => _db.delete('milk_sales', id);
}
