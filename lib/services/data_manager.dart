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

  void registerPayment(String requestId, double amount) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = _requests[index];
      req.amountPaid += amount;

      // Prevent overpayment logic if desired, or just cap it visually.
      // For now let's assume valid inputs or just cap at totalPrice.
      if (req.amountPaid > req.totalPrice) {
        req.amountPaid = req.totalPrice;
      }

      if (req.amountPaid >= req.totalPrice) {
        req.paymentStatus = PaymentStatus.paid;
      } else if (req.amountPaid > 0) {
        req.paymentStatus = PaymentStatus.partial;
      } else {
        req.paymentStatus = PaymentStatus.pending;
      }
      notifyListeners();
    }
  }

  void updateClientNotes(String clientId, String notes) {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      _clients[index].notes = notes;
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
