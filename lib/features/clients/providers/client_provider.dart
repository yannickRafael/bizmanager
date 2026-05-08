import 'package:flutter/material.dart';
import '../repositories/client_repository.dart';
import 'package:farma/core/models/client.dart';

/// Manages client state. Replaces the client CRUD from the old DataManager.
class ClientProvider extends ChangeNotifier {
  final ClientRepository _repo = ClientRepository();

  List<Client> _clients = [];
  bool _isLoading = false;
  String? _error;

  List<Client> get clients => List.unmodifiable(_clients);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _clients = await _repo.getAll();
    } catch (e) {
      _error = 'Erro ao carregar clientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Client? getById(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Client client) async {
    await _repo.insert(client);
    _clients.add(client);
    notifyListeners();
  }

  Future<void> update(Client client) async {
    await _repo.update(client);
    final index = _clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _clients[index] = client;
      notifyListeners();
    }
  }

  /// Immutable notes update — uses copyWith instead of mutating the object.
  Future<void> updateNotes(String clientId, String notes) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      final updated = _clients[index].copyWith(notes: notes);
      await _repo.update(updated);
      _clients[index] = updated;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    _clients.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
