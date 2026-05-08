import 'package:flutter/material.dart';
import 'package:farma/core/models/expense.dart';
import 'package:farma/core/models/mortality.dart';
import '../repositories/poultry_repository.dart';
import '../models/poultry_batch.dart';
import '../models/poultry_models.dart';
import '../models/poultry_enums.dart';

class PoultryProvider extends ChangeNotifier {
  final PoultryRepository _repo = PoultryRepository();

  List<PoultryBatch> _batches = [];
  List<Expense> _expenses = [];
  List<Mortality> _mortalities = [];
  List<EggProduction> _eggProductions = [];
  List<Slaughter> _slaughters = [];
  List<ChickenSale> _chickenSales = [];
  List<EggSale> _eggSales = [];
  List<CulledBirdSale> _culledBirdSales = [];

  bool _isLoading = false;
  String? _error;

  List<PoultryBatch> get batches => List.unmodifiable(_batches);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Mortality> get mortalities => List.unmodifiable(_mortalities);
  List<EggProduction> get eggProductions => List.unmodifiable(_eggProductions);
  List<Slaughter> get slaughters => List.unmodifiable(_slaughters);
  List<ChickenSale> get chickenSales => List.unmodifiable(_chickenSales);
  List<EggSale> get eggSales => List.unmodifiable(_eggSales);
  List<CulledBirdSale> get culledBirdSales => List.unmodifiable(_culledBirdSales);
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

  PoultryBatch? getBatchById(String id) {
    try { return _batches.firstWhere((b) => b.id == id); } catch (_) { return null; }
  }

  List<PoultryBatch> getBatchesByFarmId(String farmId) =>
      _batches.where((b) => b.farmId == farmId).toList();

  List<Expense> getExpensesByBatchId(String batchId) =>
      _expenses.where((e) => e.batchId == batchId).toList();

  List<Mortality> getMortalitiesByBatchId(String batchId) =>
      _mortalities.where((m) => m.batchId == batchId).toList();

  List<Slaughter> getSlaughtersByBatchId(String batchId) =>
      _slaughters.where((s) => s.batchId == batchId).toList();

  List<EggProduction> getEggProductionsByBatchId(String batchId) =>
      _eggProductions.where((p) => p.batchId == batchId).toList();

  // ── Batch CRUD ──

  Future<void> addBatch(PoultryBatch b) async {
    await _repo.insertBatch(b);
    _batches.add(b);
    notifyListeners();
  }

  Future<void> updateBatch(PoultryBatch b) async {
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
    _expenses.removeWhere((e) => e.batchId == id);
    _mortalities.removeWhere((m) => m.batchId == id);
    _eggProductions.removeWhere((p) => p.batchId == id);
    _slaughters.removeWhere((s) => s.batchId == id);
    _chickenSales.removeWhere((s) => s.batchId == id);
    _eggSales.removeWhere((s) => s.batchId == id);
    _culledBirdSales.removeWhere((s) => s.batchId == id);
    notifyListeners();
  }

  Future<void> _adjustBatchQuantity(String batchId, int delta, {String? sex}) async {
    final index = _batches.indexWhere((b) => b.id == batchId);
    if (index != -1) {
      final b = _batches[index];
      PoultryBatch updated = b.copyWithQuantity(b.currentQuantity + delta) as PoultryBatch;
      if (sex == 'Macho') {
        updated = updated.copyWithGenderCounts(
          (b.maleCount + delta).clamp(0, b.initialQuantity), b.femaleCount) as PoultryBatch;
      } else if (sex == 'Fêmea') {
        updated = updated.copyWithGenderCounts(
          b.maleCount, (b.femaleCount + delta).clamp(0, b.initialQuantity)) as PoultryBatch;
      }
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
    await _adjustBatchQuantity(m.batchId, -m.quantity, sex: m.sex);
    notifyListeners();
  }

  Future<void> deleteMortality(String id) async {
    final index = _mortalities.indexWhere((m) => m.id == id);
    if (index != -1) {
      final m = _mortalities[index];
      await _adjustBatchQuantity(m.batchId, m.quantity, sex: m.sex);
      await _repo.deleteMortality(id);
      _mortalities.removeAt(index);
      notifyListeners();
    }
  }

  // ── Egg Production CRUD ──

  Future<void> addEggProduction(EggProduction p) async {
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

  Future<void> addSlaughter(Slaughter s) async {
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

  Future<void> addChickenSale(ChickenSale v) async {
    await _repo.insertChickenSale(v);
    _chickenSales.add(v);
    if (v.saleType == ChickenSaleType.live) {
      int soldQty = v.groups.fold(0, (s, g) => s + g.quantity);
      await _adjustBatchQuantity(v.batchId, -soldQty);
    }
    notifyListeners();
  }

  Future<void> updateChickenSale(ChickenSale v) async {
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
      if (v.saleType == ChickenSaleType.live) {
        int soldQty = v.groups.fold(0, (s, g) => s + g.quantity);
        await _adjustBatchQuantity(v.batchId, soldQty);
      }
      await _repo.deleteChickenSale(id);
      _chickenSales.removeAt(index);
      notifyListeners();
    }
  }

  // ── Egg Sale CRUD ──

  Future<void> addEggSale(EggSale v) async {
    await _repo.insertEggSale(v);
    _eggSales.add(v);
    notifyListeners();
  }

  Future<void> updateEggSale(EggSale v) async {
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

  Future<void> addCulledBirdSale(CulledBirdSale v) async {
    await _repo.insertCulledBirdSale(v);
    _culledBirdSales.add(v);
    await _adjustBatchQuantity(v.batchId, -v.quantity);
    notifyListeners();
  }

  Future<void> updateCulledBirdSale(CulledBirdSale v) async {
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
