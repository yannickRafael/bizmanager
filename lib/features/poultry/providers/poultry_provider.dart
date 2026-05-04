import 'package:flutter/material.dart';
import '../repositories/poultry_repository.dart';
import '../../core/models/expense.dart';
import '../../core/models/mortality.dart';

// Legacy models (until Phase 4 creates PoultryBatch)
import '../../models/batch.dart' as legacy;
import '../../models/egg_production.dart' as legacy;
import '../../models/slaughter.dart' as legacy;
import '../../models/sale.dart' as legacy;
import '../../models/enums.dart' as legacy_enums;

/// Manages all poultry-specific state.
/// Replaces the poultry parts of the old DataManager God class.
class PoultryProvider extends ChangeNotifier {
  final PoultryRepository _repo = PoultryRepository();

  List<legacy.Batch> _batches = [];
  List<Expense> _expenses = [];
  List<Mortality> _mortalities = [];
  List<legacy.EggProduction> _eggProductions = [];
  List<legacy.Slaughter> _slaughters = [];
  List<legacy.ChickenSale> _chickenSales = [];
  List<legacy.EggSale> _eggSales = [];
  List<legacy.CulledBirdSale> _culledBirdSales = [];

  bool _isLoading = false;
  String? _error;

  // ── Getters ──
  List<legacy.Batch> get batches => List.unmodifiable(_batches);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Mortality> get mortalities => List.unmodifiable(_mortalities);
  List<legacy.EggProduction> get eggProductions => List.unmodifiable(_eggProductions);
  List<legacy.Slaughter> get slaughters => List.unmodifiable(_slaughters);
  List<legacy.ChickenSale> get chickenSales => List.unmodifiable(_chickenSales);
  List<legacy.EggSale> get eggSales => List.unmodifiable(_eggSales);
  List<legacy.CulledBirdSale> get culledBirdSales => List.unmodifiable(_culledBirdSales);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _batches = await _repo.getBatches();
      _expenses = await _repo.getExpenses();
      _mortalities = await _repo.getMortalities();
      _eggProductions = await _repo.getEggProductions();
      _slaughters = await _repo.getSlaughters();
      _chickenSales = await _repo.getChickenSales();
      _eggSales = await _repo.getEggSales();
      _culledBirdSales = await _repo.getCulledBirdSales();
    } catch (e) {
      _error = 'Erro ao carregar dados de aves: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Batch Helpers ──

  legacy.Batch? getBatchById(String id) {
    try { return _batches.firstWhere((b) => b.id == id); } catch (_) { return null; }
  }

  List<legacy.Batch> getBatchesByFarmId(String farmId) =>
      _batches.where((b) => b.farmId == farmId).toList();

  List<Expense> getExpensesByBatchId(String batchId) =>
      _expenses.where((e) => e.batchId == batchId).toList();

  List<Mortality> getMortalitiesByBatchId(String batchId) =>
      _mortalities.where((m) => m.batchId == batchId).toList();

  List<legacy.Slaughter> getSlaughtersByBatchId(String batchId) =>
      _slaughters.where((s) => s.batchId == batchId).toList();

  List<legacy.EggProduction> getEggProductionsByBatchId(String batchId) =>
      _eggProductions.where((p) => p.batchId == batchId).toList();

  // ── Batch CRUD ──

  Future<void> addBatch(legacy.Batch b) async {
    await _repo.insertBatch(b);
    _batches.add(b);
    notifyListeners();
  }

  Future<void> updateBatch(legacy.Batch b) async {
    await _repo.updateBatch(b);
    final index = _batches.indexWhere((e) => e.id == b.id);
    if (index != -1) {
      _batches[index] = b;
      notifyListeners();
    }
  }

  Future<void> deleteBatch(String id) async {
    await _repo.deleteBatch(id);
    _batches.removeWhere((b) => b.id == id);
    // Cascading is handled by DB foreign keys, clean local lists
    _expenses.removeWhere((e) => e.batchId == id);
    _mortalities.removeWhere((m) => m.batchId == id);
    _eggProductions.removeWhere((p) => p.batchId == id);
    _slaughters.removeWhere((s) => s.batchId == id);
    _chickenSales.removeWhere((s) => s.batchId == id);
    _eggSales.removeWhere((s) => s.batchId == id);
    _culledBirdSales.removeWhere((s) => s.batchId == id);
    notifyListeners();
  }

  // ── Helper: update batch quantity ──

  Future<void> _adjustBatchQuantity(String batchId, int delta) async {
    final index = _batches.indexWhere((b) => b.id == batchId);
    if (index != -1) {
      final b = _batches[index];
      final updated = legacy.Batch(
        id: b.id, farmId: b.farmId, name: b.name, type: b.type,
        birdOrigin: b.birdOrigin, entryDate: b.entryDate,
        initialQuantity: b.initialQuantity,
        currentQuantity: b.currentQuantity + delta,
        breedOrLineage: b.breedOrLineage, acquisitionCost: b.acquisitionCost,
        status: b.status, notes: b.notes,
      );
      await _repo.updateBatch(updated);
      _batches[index] = updated;
    }
  }

  // ── Expense CRUD ──

  Future<void> addExpense(Expense e) async {
    await _repo.insertExpense(e);
    _expenses.add(e);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ── Mortality CRUD ──

  Future<void> addMortality(Mortality m) async {
    await _repo.insertMortality(m);
    _mortalities.add(m);
    await _adjustBatchQuantity(m.batchId, -m.quantity);
    notifyListeners();
  }

  Future<void> deleteMortality(String id) async {
    final index = _mortalities.indexWhere((m) => m.id == id);
    if (index != -1) {
      final m = _mortalities[index];
      await _adjustBatchQuantity(m.batchId, m.quantity);
      await _repo.deleteMortality(id);
      _mortalities.removeAt(index);
      notifyListeners();
    }
  }

  // ── Egg Production CRUD ──

  Future<void> addEggProduction(legacy.EggProduction p) async {
    await _repo.insertEggProduction(p);
    _eggProductions.add(p);
    notifyListeners();
  }

  Future<void> deleteEggProduction(String id) async {
    await _repo.deleteEggProduction(id);
    _eggProductions.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ── Slaughter CRUD ──

  Future<void> addSlaughter(legacy.Slaughter s) async {
    await _repo.insertSlaughter(s);
    _slaughters.add(s);
    await _adjustBatchQuantity(s.batchId, -s.slaughteredQuantity);
    notifyListeners();
  }

  Future<void> deleteSlaughter(String id) async {
    final index = _slaughters.indexWhere((s) => s.id == id);
    if (index != -1) {
      final s = _slaughters[index];
      await _adjustBatchQuantity(s.batchId, s.slaughteredQuantity);
      await _repo.deleteSlaughter(id);
      _slaughters.removeAt(index);
      notifyListeners();
    }
  }

  // ── Chicken Sale CRUD ──

  Future<void> addChickenSale(legacy.ChickenSale v) async {
    await _repo.insertChickenSale(v);
    _chickenSales.add(v);
    if (v.saleType == legacy_enums.ChickenSaleType.live) {
      int soldQty = v.groups.fold(0, (sum, g) => sum + g.quantity);
      await _adjustBatchQuantity(v.batchId, -soldQty);
    }
    notifyListeners();
  }

  Future<void> updateChickenSale(legacy.ChickenSale v) async {
    await _repo.updateChickenSale(v);
    final index = _chickenSales.indexWhere((s) => s.id == v.id);
    if (index != -1) {
      _chickenSales[index] = v;
      notifyListeners();
    }
  }

  Future<void> deleteChickenSale(String id) async {
    final index = _chickenSales.indexWhere((s) => s.id == id);
    if (index != -1) {
      final v = _chickenSales[index];
      if (v.saleType == legacy_enums.ChickenSaleType.live) {
        int soldQty = v.groups.fold(0, (sum, g) => sum + g.quantity);
        await _adjustBatchQuantity(v.batchId, soldQty);
      }
      await _repo.deleteChickenSale(id);
      _chickenSales.removeAt(index);
      notifyListeners();
    }
  }

  // ── Egg Sale CRUD ──

  Future<void> addEggSale(legacy.EggSale v) async {
    await _repo.insertEggSale(v);
    _eggSales.add(v);
    notifyListeners();
  }

  Future<void> updateEggSale(legacy.EggSale v) async {
    await _repo.updateEggSale(v);
    final index = _eggSales.indexWhere((s) => s.id == v.id);
    if (index != -1) {
      _eggSales[index] = v;
      notifyListeners();
    }
  }

  Future<void> deleteEggSale(String id) async {
    await _repo.deleteEggSale(id);
    _eggSales.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ── Culled Bird Sale CRUD ──

  Future<void> addCulledBirdSale(legacy.CulledBirdSale v) async {
    await _repo.insertCulledBirdSale(v);
    _culledBirdSales.add(v);
    await _adjustBatchQuantity(v.batchId, -v.quantity);
    notifyListeners();
  }

  Future<void> updateCulledBirdSale(legacy.CulledBirdSale v) async {
    await _repo.updateCulledBirdSale(v);
    final index = _culledBirdSales.indexWhere((s) => s.id == v.id);
    if (index != -1) {
      _culledBirdSales[index] = v;
      notifyListeners();
    }
  }

  Future<void> deleteCulledBirdSale(String id) async {
    final index = _culledBirdSales.indexWhere((s) => s.id == id);
    if (index != -1) {
      final v = _culledBirdSales[index];
      await _adjustBatchQuantity(v.batchId, v.quantity);
      await _repo.deleteCulledBirdSale(id);
      _culledBirdSales.removeAt(index);
      notifyListeners();
    }
  }
}
