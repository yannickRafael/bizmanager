import 'package:farma/core/database/database_service.dart';
import 'package:farma/core/models/expense.dart';
import 'package:farma/core/models/mortality.dart';
import '../models/poultry_batch.dart';
import '../models/poultry_models.dart';

class PoultryRepository {
  final _db = DatabaseService.instance;

  // ── Batches ──

  Future<void> insertBatch(PoultryBatch batch) =>
      _db.insert('batches', batch.toMap());

  Future<List<PoultryBatch>> getBatches() async {
    final maps = await _db.queryWhere(
      'batches',
      where: "animalType = ? OR animalType IS NULL",
      whereArgs: ['poultry'],
    );
    return maps.map((m) => PoultryBatch.fromMap(m)).toList();
  }

  Future<void> updateBatch(PoultryBatch batch) =>
      _db.update('batches', batch.toMap(), batch.id);

  Future<void> deleteBatch(String id) => _db.delete('batches', id);

  // ── Expenses ──

  Future<void> insertExpense(Expense e) => _db.insert('expenses', e.toMap());

  Future<List<Expense>> getExpenses() async {
    final maps = await _db.queryAll('expenses');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> deleteExpense(String id) => _db.delete('expenses', id);

  // ── Mortality ──

  Future<void> insertMortality(Mortality m) =>
      _db.insert('mortality_records', m.toMap());

  Future<List<Mortality>> getMortalities() async {
    final maps = await _db.queryAll('mortality_records');
    return maps.map((m) => Mortality.fromMap(m)).toList();
  }

  Future<void> deleteMortality(String id) =>
      _db.delete('mortality_records', id);

  // ── Egg Production ──

  Future<void> insertEggProduction(EggProduction p) =>
      _db.insert('egg_production', p.toMap());

  Future<List<EggProduction>> getEggProductions() async {
    final maps = await _db.queryAll('egg_production');
    return maps.map((m) => EggProduction.fromMap(m)).toList();
  }

  Future<void> deleteEggProduction(String id) =>
      _db.delete('egg_production', id);

  // ── Slaughters ──

  Future<void> insertSlaughter(Slaughter s) =>
      _db.insert('slaughters', s.toMap());

  Future<List<Slaughter>> getSlaughters() async {
    final maps = await _db.queryAll('slaughters');
    return maps.map((m) => Slaughter.fromMap(m)).toList();
  }

  Future<void> deleteSlaughter(String id) => _db.delete('slaughters', id);

  // ── Chicken Sales ──

  Future<void> insertChickenSale(ChickenSale s) =>
      _db.insert('chicken_sales', s.toMap());

  Future<List<ChickenSale>> getChickenSales() async {
    final maps = await _db.queryAll('chicken_sales');
    return maps.map((m) => ChickenSale.fromMap(m)).toList();
  }

  Future<void> updateChickenSale(ChickenSale s) =>
      _db.update('chicken_sales', s.toMap(), s.id);

  Future<void> deleteChickenSale(String id) =>
      _db.delete('chicken_sales', id);

  // ── Egg Sales ──

  Future<void> insertEggSale(EggSale s) =>
      _db.insert('egg_sales', s.toMap());

  Future<List<EggSale>> getEggSales() async {
    final maps = await _db.queryAll('egg_sales');
    return maps.map((m) => EggSale.fromMap(m)).toList();
  }

  Future<void> updateEggSale(EggSale s) =>
      _db.update('egg_sales', s.toMap(), s.id);

  Future<void> deleteEggSale(String id) => _db.delete('egg_sales', id);

  // ── Culled Bird Sales ──

  Future<void> insertCulledBirdSale(CulledBirdSale s) =>
      _db.insert('culled_bird_sales', s.toMap());

  Future<List<CulledBirdSale>> getCulledBirdSales() async {
    final maps = await _db.queryAll('culled_bird_sales');
    return maps.map((m) => CulledBirdSale.fromMap(m)).toList();
  }

  Future<void> updateCulledBirdSale(CulledBirdSale s) =>
      _db.update('culled_bird_sales', s.toMap(), s.id);

  Future<void> deleteCulledBirdSale(String id) =>
      _db.delete('culled_bird_sales', id);
}
