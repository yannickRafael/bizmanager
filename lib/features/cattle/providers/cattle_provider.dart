import 'package:flutter/material.dart';
import '../repositories/cattle_repository.dart';
import '../../core/models/expense.dart';
import '../../core/models/mortality.dart';
import '../models/cattle_batch.dart';
import '../models/cattle_models.dart';

/// Manages all cattle-specific state.
class CattleProvider extends ChangeNotifier {
  final CattleRepository _repo = CattleRepository();

  List<CattleBatch> _batches = [];
  List<Expense> _expenses = [];
  List<Mortality> _mortalities = [];
  List<MilkProduction> _milkProductions = [];
  List<CalfBirth> _calfBirths = [];
  List<CattleSale> _cattleSales = [];
  List<MilkSale> _milkSales = [];

  bool _isLoading = false;
  String? _error;

  // ── Getters ──
  List<CattleBatch> get batches => List.unmodifiable(_batches);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Mortality> get mortalities => List.unmodifiable(_mortalities);
  List<MilkProduction> get milkProductions => List.unmodifiable(_milkProductions);
  List<CalfBirth> get calfBirths => List.unmodifiable(_calfBirths);
  List<CattleSale> get cattleSales => List.unmodifiable(_cattleSales);
  List<MilkSale> get milkSales => List.unmodifiable(_milkSales);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _batches = await _repo.getBatches();
      _cattleSales = await _repo.getAllCattleSales();
      _milkSales = await _repo.getAllMilkSales();
      _milkProductions = await _repo.getAllMilkProduction();
      // Expenses and mortalities are loaded per-batch as needed
    } catch (e) {
      _error = 'Erro ao carregar dados de bovinos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  CattleBatch? getBatchById(String id) {
    try { return _batches.firstWhere((b) => b.id == id); } catch (_) { return null; }
  }

  List<CattleBatch> getBatchesByFarmId(String farmId) =>
      _batches.where((b) => b.farmId == farmId).toList();

  // ── Batch CRUD ──

  Future<void> addBatch(CattleBatch b) async {
    await _repo.insertBatch(b);
    _batches.add(b);
    notifyListeners();
  }

  Future<void> updateBatch(CattleBatch b) async {
    await _repo.updateBatch(b);
    final idx = _batches.indexWhere((e) => e.id == b.id);
    if (idx != -1) { _batches[idx] = b; notifyListeners(); }
  }

  Future<void> deleteBatch(String id) async {
    await _repo.deleteBatch(id);
    _batches.removeWhere((b) => b.id == id);
    _expenses.removeWhere((e) => e.batchId == id);
    _mortalities.removeWhere((m) => m.batchId == id);
    _milkProductions.removeWhere((p) => p.batchId == id);
    _calfBirths.removeWhere((c) => c.batchId == id);
    _cattleSales.removeWhere((s) => s.batchId == id);
    _milkSales.removeWhere((s) => s.batchId == id);
    notifyListeners();
  }

  // ── Quantity adjustment (uses copyWithQuantity) ──

  Future<void> _adjustBatchQuantity(String batchId, int delta) async {
    final idx = _batches.indexWhere((b) => b.id == batchId);
    if (idx != -1) {
      final updated = _batches[idx].copyWithQuantity(_batches[idx].currentQuantity + delta);
      await _repo.updateBatch(updated);
      _batches[idx] = updated;
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
    final idx = _mortalities.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final m = _mortalities[idx];
      await _adjustBatchQuantity(m.batchId, m.quantity);
      await _repo.deleteMortality(id);
      _mortalities.removeAt(idx);
      notifyListeners();
    }
  }

  // ── Milk Production ──

  Future<void> addMilkProduction(MilkProduction p) async {
    await _repo.insertMilkProduction(p);
    _milkProductions.add(p);
    notifyListeners();
  }

  Future<void> deleteMilkProduction(String id) async {
    await _repo.deleteMilkProduction(id);
    _milkProductions.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ── Calf Births ──

  Future<void> addCalfBirth(CalfBirth b) async {
    await _repo.insertCalfBirth(b);
    _calfBirths.add(b);
    await _adjustBatchQuantity(b.batchId, b.quantity);
    notifyListeners();
  }

  Future<void> deleteCalfBirth(String id) async {
    final idx = _calfBirths.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final b = _calfBirths[idx];
      await _adjustBatchQuantity(b.batchId, -b.quantity);
      await _repo.deleteCalfBirth(id);
      _calfBirths.removeAt(idx);
      notifyListeners();
    }
  }

  // ── Cattle Sales ──

  Future<void> addCattleSale(CattleSale s) async {
    await _repo.insertCattleSale(s);
    _cattleSales.add(s);
    await _adjustBatchQuantity(s.batchId, -s.quantity);
    notifyListeners();
  }

  Future<void> updateCattleSale(CattleSale s) async {
    await _repo.updateCattleSale(s);
    final idx = _cattleSales.indexWhere((e) => e.id == s.id);
    if (idx != -1) { _cattleSales[idx] = s; notifyListeners(); }
  }

  Future<void> deleteCattleSale(String id) async {
    final idx = _cattleSales.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final s = _cattleSales[idx];
      await _adjustBatchQuantity(s.batchId, s.quantity);
      await _repo.deleteCattleSale(id);
      _cattleSales.removeAt(idx);
      notifyListeners();
    }
  }

  // ── Milk Sales ──

  Future<void> addMilkSale(MilkSale s) async {
    await _repo.insertMilkSale(s);
    _milkSales.add(s);
    notifyListeners();
  }

  Future<void> updateMilkSale(MilkSale s) async {
    await _repo.updateMilkSale(s);
    final idx = _milkSales.indexWhere((e) => e.id == s.id);
    if (idx != -1) { _milkSales[idx] = s; notifyListeners(); }
  }

  Future<void> deleteMilkSale(String id) async {
    await _repo.deleteMilkSale(id);
    _milkSales.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
