import 'package:flutter/material.dart';
import '../repositories/goat_repository.dart';
import '../../core/models/expense.dart';
import '../../core/models/mortality.dart';
import '../models/goat_batch.dart';
import '../models/goat_models.dart';

/// Manages all goat-specific state.
class GoatProvider extends ChangeNotifier {
  final GoatRepository _repo = GoatRepository();

  List<GoatBatch> _batches = [];
  List<Expense> _expenses = [];
  List<Mortality> _mortalities = [];
  List<GoatMilkProduction> _milkProductions = [];
  List<KidBirth> _kidBirths = [];
  List<GoatSale> _goatSales = [];
  List<GoatMilkSale> _milkSales = [];

  bool _isLoading = false;
  String? _error;

  // ── Getters ──
  List<GoatBatch> get batches => List.unmodifiable(_batches);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Mortality> get mortalities => List.unmodifiable(_mortalities);
  List<GoatMilkProduction> get milkProductions => List.unmodifiable(_milkProductions);
  List<KidBirth> get kidBirths => List.unmodifiable(_kidBirths);
  List<GoatSale> get goatSales => List.unmodifiable(_goatSales);
  List<GoatMilkSale> get milkSales => List.unmodifiable(_milkSales);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _batches = await _repo.getBatches();
      _goatSales = await _repo.getAllGoatSales();
      _milkSales = await _repo.getAllMilkSales();
      _milkProductions = await _repo.getAllMilkProduction();
    } catch (e) {
      _error = 'Erro ao carregar dados de caprinos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  GoatBatch? getBatchById(String id) {
    try { return _batches.firstWhere((b) => b.id == id); } catch (_) { return null; }
  }

  List<GoatBatch> getBatchesByFarmId(String farmId) =>
      _batches.where((b) => b.farmId == farmId).toList();

  // ── Batch CRUD ──

  Future<void> addBatch(GoatBatch b) async {
    await _repo.insertBatch(b);
    _batches.add(b);
    notifyListeners();
  }

  Future<void> updateBatch(GoatBatch b) async {
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
    _kidBirths.removeWhere((k) => k.batchId == id);
    _goatSales.removeWhere((s) => s.batchId == id);
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

  // ── Goat Milk Production ──

  Future<void> addMilkProduction(GoatMilkProduction p) async {
    await _repo.insertMilkProduction(p);
    _milkProductions.add(p);
    notifyListeners();
  }

  Future<void> deleteMilkProduction(String id) async {
    await _repo.deleteMilkProduction(id);
    _milkProductions.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ── Kid Births ──

  Future<void> addKidBirth(KidBirth b) async {
    await _repo.insertKidBirth(b);
    _kidBirths.add(b);
    await _adjustBatchQuantity(b.batchId, b.quantity);
    notifyListeners();
  }

  Future<void> deleteKidBirth(String id) async {
    final idx = _kidBirths.indexWhere((k) => k.id == id);
    if (idx != -1) {
      final k = _kidBirths[idx];
      await _adjustBatchQuantity(k.batchId, -k.quantity);
      await _repo.deleteKidBirth(id);
      _kidBirths.removeAt(idx);
      notifyListeners();
    }
  }

  // ── Goat Sales ──

  Future<void> addGoatSale(GoatSale s) async {
    await _repo.insertGoatSale(s);
    _goatSales.add(s);
    await _adjustBatchQuantity(s.batchId, -s.quantity);
    notifyListeners();
  }

  Future<void> updateGoatSale(GoatSale s) async {
    await _repo.updateGoatSale(s);
    final idx = _goatSales.indexWhere((e) => e.id == s.id);
    if (idx != -1) { _goatSales[idx] = s; notifyListeners(); }
  }

  Future<void> deleteGoatSale(String id) async {
    final idx = _goatSales.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final s = _goatSales[idx];
      await _adjustBatchQuantity(s.batchId, s.quantity);
      await _repo.deleteGoatSale(id);
      _goatSales.removeAt(idx);
      notifyListeners();
    }
  }

  // ── Goat Milk Sales ──

  Future<void> addMilkSale(GoatMilkSale s) async {
    await _repo.insertMilkSale(s);
    _milkSales.add(s);
    notifyListeners();
  }

  Future<void> updateMilkSale(GoatMilkSale s) async {
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
