import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/request.dart';

class DataManager extends ChangeNotifier {
  final List<Client> _clients = [];
  final List<Request> _requests = [];

  List<Client> get clients => List.unmodifiable(_clients);
  List<Request> get requests => List.unmodifiable(_requests);

  void addClient(Client client) {
    _clients.add(client);
    notifyListeners();
  }

  void addRequest(Request request) {
    _requests.add(request);
    notifyListeners();
  }

  void updateRequestStatus(String requestId, PaymentStatus status) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].paymentStatus = status;
      notifyListeners();
    }
  }

  Client? getClientById(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Request> getRequestsByClientId(String clientId) {
    return _requests.where((r) => r.clientId == clientId).toList();
  }
}
