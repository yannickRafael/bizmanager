import 'package:flutter/material.dart';
import '../repositories/farm_repository.dart';
import '../../core/models/farm.dart';

/// Manages farm state. Replaces the farm CRUD from the old DataManager.
class FarmProvider extends ChangeNotifier {
  final FarmRepository _repo = FarmRepository();

  List<Farm> _farms = [];
  bool _isLoading = false;
  String? _error;

  List<Farm> get farms => List.unmodifiable(_farms);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _farms = await _repo.getAll();
    } catch (e) {
      _error = 'Erro ao carregar explorações: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Farm? getById(String id) {
    try {
      return _farms.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Farm farm) async {
    await _repo.insert(farm);
    _farms.add(farm);
    notifyListeners();
  }

  Future<void> update(Farm farm) async {
    await _repo.update(farm);
    final index = _farms.indexWhere((f) => f.id == farm.id);
    if (index != -1) {
      _farms[index] = farm;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    _farms.removeWhere((f) => f.id == id);
    notifyListeners();
  }
}
