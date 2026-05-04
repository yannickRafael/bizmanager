import 'package:flutter/material.dart';
import '../repositories/partner_repository.dart';
import '../../core/models/partner.dart';

/// Manages partner state. Replaces the partner CRUD from the old DataManager.
class PartnerProvider extends ChangeNotifier {
  final PartnerRepository _repo = PartnerRepository();

  List<Partner> _partners = [];
  bool _isLoading = false;
  String? _error;

  List<Partner> get partners => List.unmodifiable(_partners);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _partners = await _repo.getAll();
    } catch (e) {
      _error = 'Erro ao carregar parceiros: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Partner partner) async {
    await _repo.insert(partner);
    _partners.add(partner);
    notifyListeners();
  }

  Future<void> update(Partner partner) async {
    await _repo.update(partner);
    final index = _partners.indexWhere((p) => p.id == partner.id);
    if (index != -1) {
      _partners[index] = partner;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    _partners.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
