import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

import '../models/enums.dart';
import '../models/client.dart';
import '../models/farm.dart';
import '../models/batch.dart';
import '../models/expense.dart';
import '../models/mortality.dart';
import '../models/egg_production.dart';
import '../models/slaughter.dart';
import '../models/sale.dart';
import '../models/partner.dart';

class DataManager extends ChangeNotifier {
  List<Client> _clients = [];
  List<Farm> _farms = [];
  List<Partner> _partners = [];
  List<Batch> _batches = [];
  List<Expense> _expenses = [];
  List<Mortality> _mortalities = [];
  List<EggProduction> _eggProductions = [];
  List<Slaughter> _slaughters = [];
  List<ChickenSale> _chickenSales = [];
  List<EggSale> _eggSales = [];
  List<CulledBirdSale> _culledBirdSales = [];

  List<Client> get clients => List.unmodifiable(_clients);
  List<Farm> get farms => List.unmodifiable(_farms);
  List<Partner> get partners => List.unmodifiable(_partners);
  List<Batch> get batches => List.unmodifiable(_batches);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Mortality> get mortalities => List.unmodifiable(_mortalities);
  List<EggProduction> get eggProductions => List.unmodifiable(_eggProductions);
  List<Slaughter> get slaughters => List.unmodifiable(_slaughters);
  List<ChickenSale> get chickenSales => List.unmodifiable(_chickenSales);
  List<EggSale> get eggSales => List.unmodifiable(_eggSales);
  List<CulledBirdSale> get culledBirdSales => List.unmodifiable(_culledBirdSales);

  String _currencySymbol = '\$';
  String get currencySymbol => _currencySymbol;

  Future<void> init() async {
    final db = DatabaseHelper.instance;
    _clients = await db.getClients();
    _farms = await db.getFarms();
    _partners = await db.getPartners();
    _batches = await db.getBatches();
    _expenses = await db.getExpenses();
    _mortalities = await db.getMortalities();
    _eggProductions = await db.getEggProductions();
    _slaughters = await db.getSlaughters();
    _chickenSales = await db.getChickenSales();
    _eggSales = await db.getEggSales();
    _culledBirdSales = await db.getCulledBirdSales();

    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString('currency_symbol') ?? '\$';

    notifyListeners();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
    notifyListeners();
  }

  // --- CRUD Client ---
  Future<void> addClient(Client client) async {
    await DatabaseHelper.instance.insertClient(client);
    _clients.add(client);
    notifyListeners();
  }

  Future<void> updateClient(Client client) async {
    await DatabaseHelper.instance.updateClient(client);
    final index = _clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _clients[index] = client;
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    await DatabaseHelper.instance.deleteClient(id);
    _clients.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Client? getClientById(String id) {
    try { return _clients.firstWhere((c) => c.id == id); } catch (e) { return null; }
  }

  // --- CRUD Farm ---
  Future<void> addFarm(Farm f) async {
    await DatabaseHelper.instance.insertFarm(f);
    _farms.add(f);
    notifyListeners();
  }

  Future<void> updateFarm(Farm f) async {
    await DatabaseHelper.instance.updateFarm(f);
    final index = _farms.indexWhere((e) => e.id == f.id);
    if (index != -1) {
      _farms[index] = f;
      notifyListeners();
    }
  }

  Future<void> deleteFarm(String id) async {
    await DatabaseHelper.instance.deleteFarm(id);
    _farms.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Farm? getFarmById(String id) {
    try { return _farms.firstWhere((e) => e.id == id); } catch (e) { return null; }
  }

  // --- CRUD Partner ---
  Future<void> addPartner(Partner p) async {
    await DatabaseHelper.instance.insertPartner(p);
    _partners.add(p);
    notifyListeners();
  }

  Future<void> updatePartner(Partner p) async {
    await DatabaseHelper.instance.updatePartner(p);
    final index = _partners.indexWhere((e) => e.id == p.id);
    if (index != -1) {
      _partners[index] = p;
      notifyListeners();
    }
  }

  Future<void> deletePartner(String id) async {
    await DatabaseHelper.instance.deletePartner(id);
    _partners.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // --- CRUD Batch ---
  Future<void> addBatch(Batch b) async {
    await DatabaseHelper.instance.insertBatch(b);
    _batches.add(b);
    notifyListeners();
  }

  Future<void> updateBatch(Batch b) async {
    await DatabaseHelper.instance.updateBatch(b);
    final index = _batches.indexWhere((e) => e.id == b.id);
    if (index != -1) {
      _batches[index] = b;
      notifyListeners();
    }
  }

  Future<void> deleteBatch(String id) async {
    await DatabaseHelper.instance.deleteBatch(id);
    _batches.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Batch? getBatchById(String id) {
    try { return _batches.firstWhere((b) => b.id == id); } catch (e) { return null; }
  }

  List<Batch> getBatchesByFarmId(String farmId) {
    return _batches.where((b) => b.farmId == farmId).toList();
  }

  // --- CRUD Expense ---
  Future<void> addExpense(Expense d) async {
    await DatabaseHelper.instance.insertExpense(d);
    _expenses.add(d);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<Expense> getExpensesByBatchId(String batchId) {
    return _expenses.where((d) => d.batchId == batchId).toList();
  }

  // --- CRUD Mortality ---
  Future<void> addMortality(Mortality m) async {
    await DatabaseHelper.instance.insertMortality(m);
    _mortalities.add(m);
    
    // Update batch amount
    final batchIndex = _batches.indexWhere((b) => b.id == m.batchId);
    if (batchIndex != -1) {
      final b = _batches[batchIndex];
      final bUpdated = Batch(
        id: b.id,
        farmId: b.farmId,
        name: b.name,
        type: b.type,
        birdOrigin: b.birdOrigin,
        entryDate: b.entryDate,
        initialQuantity: b.initialQuantity,
        currentQuantity: b.currentQuantity - m.quantity,
        breedOrLineage: b.breedOrLineage,
        acquisitionCost: b.acquisitionCost,
        status: b.status,
        notes: b.notes,
      );
      await updateBatch(bUpdated);
    }
    notifyListeners();
  }

  Future<void> deleteMortality(String id) async {
    await DatabaseHelper.instance.deleteMortality(id);
    _mortalities.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<Mortality> getMortalityByBatchId(String batchId) {
    return _mortalities.where((m) => m.batchId == batchId).toList();
  }

  // --- CRUD EggProduction ---
  Future<void> addEggProduction(EggProduction p) async {
    await DatabaseHelper.instance.insertEggProduction(p);
    _eggProductions.add(p);
    notifyListeners();
  }

  Future<void> deleteEggProduction(String id) async {
    await DatabaseHelper.instance.deleteEggProduction(id);
    _eggProductions.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<EggProduction> getEggProductionsByBatchId(String batchId) {
    return _eggProductions.where((p) => p.batchId == batchId).toList();
  }

  // --- CRUD Slaughter ---
  Future<void> addSlaughter(Slaughter a) async {
    await DatabaseHelper.instance.insertSlaughter(a);
    _slaughters.add(a);
    
    // Update batch amount
    final batchIndex = _batches.indexWhere((b) => b.id == a.batchId);
    if (batchIndex != -1) {
      final b = _batches[batchIndex];
      final bUpdated = Batch(
        id: b.id,
        farmId: b.farmId,
        name: b.name,
        type: b.type,
        birdOrigin: b.birdOrigin,
        entryDate: b.entryDate,
        initialQuantity: b.initialQuantity,
        currentQuantity: b.currentQuantity - a.slaughteredQuantity,
        breedOrLineage: b.breedOrLineage,
        acquisitionCost: b.acquisitionCost,
        status: b.status,
        notes: b.notes,
      );
      await updateBatch(bUpdated);
    }
    notifyListeners();
  }

  Future<void> deleteSlaughter(String id) async {
    await DatabaseHelper.instance.deleteSlaughter(id);
    _slaughters.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<Slaughter> getSlaughtersByBatchId(String batchId) {
    return _slaughters.where((a) => a.batchId == batchId).toList();
  }

  // --- CRUD ChickenSale ---
  Future<void> addChickenSale(ChickenSale v) async {
    await DatabaseHelper.instance.insertChickenSale(v);
    _chickenSales.add(v);

    if (v.saleType == ChickenSaleType.live) {
      int soldQty = v.groups.fold(0, (sum, g) => sum + g.quantity);
      final batchIndex = _batches.indexWhere((b) => b.id == v.batchId);
      if (batchIndex != -1) {
        final b = _batches[batchIndex];
        final bUpdated = Batch(
          id: b.id,
          farmId: b.farmId,
          name: b.name,
          type: b.type,
          birdOrigin: b.birdOrigin,
          entryDate: b.entryDate,
          initialQuantity: b.initialQuantity,
          currentQuantity: b.currentQuantity - soldQty,
          breedOrLineage: b.breedOrLineage,
          acquisitionCost: b.acquisitionCost,
          status: b.status,
          notes: b.notes,
        );
        await updateBatch(bUpdated);
      }
    }
    notifyListeners();
  }

  Future<void> updateChickenSale(ChickenSale v) async {
    await DatabaseHelper.instance.updateChickenSale(v);
    final index = _chickenSales.indexWhere((e) => e.id == v.id);
    if (index != -1) {
      _chickenSales[index] = v;
      notifyListeners();
    }
  }

  Future<void> deleteChickenSale(String id) async {
    await DatabaseHelper.instance.deleteChickenSale(id);
    _chickenSales.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // --- CRUD EggSale ---
  Future<void> addEggSale(EggSale v) async {
    await DatabaseHelper.instance.insertEggSale(v);
    _eggSales.add(v);
    notifyListeners();
  }

  Future<void> updateEggSale(EggSale v) async {
    await DatabaseHelper.instance.updateEggSale(v);
    final index = _eggSales.indexWhere((e) => e.id == v.id);
    if (index != -1) {
      _eggSales[index] = v;
      notifyListeners();
    }
  }

  Future<void> deleteEggSale(String id) async {
    await DatabaseHelper.instance.deleteEggSale(id);
    _eggSales.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // --- CRUD CulledBirdSale ---
  Future<void> addCulledBirdSale(CulledBirdSale v) async {
    await DatabaseHelper.instance.insertCulledBirdSale(v);
    _culledBirdSales.add(v);

    int soldQty = v.quantity;
    final batchIndex = _batches.indexWhere((b) => b.id == v.batchId);
    if (batchIndex != -1) {
      final b = _batches[batchIndex];
      final bUpdated = Batch(
        id: b.id,
        farmId: b.farmId,
        name: b.name,
        type: b.type,
        birdOrigin: b.birdOrigin,
        entryDate: b.entryDate,
        initialQuantity: b.initialQuantity,
        currentQuantity: b.currentQuantity - soldQty,
        breedOrLineage: b.breedOrLineage,
        acquisitionCost: b.acquisitionCost,
        status: b.status,
        notes: b.notes,
      );
      await updateBatch(bUpdated);
    }
    notifyListeners();
  }

  Future<void> updateCulledBirdSale(CulledBirdSale v) async {
    await DatabaseHelper.instance.updateCulledBirdSale(v);
    final index = _culledBirdSales.indexWhere((e) => e.id == v.id);
    if (index != -1) {
      _culledBirdSales[index] = v;
      notifyListeners();
    }
  }

  Future<void> deleteCulledBirdSale(String id) async {
    await DatabaseHelper.instance.deleteCulledBirdSale(id);
    _culledBirdSales.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
