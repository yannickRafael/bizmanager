import '../models/product.dart';
import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/request.dart';

import 'database_helper.dart';

class DataManager extends ChangeNotifier {
  List<Client> _clients = [];
  List<Request> _requests = [];
  List<Product> _products = [];

  List<Client> get clients => List.unmodifiable(_clients);
  List<Request> get requests => List.unmodifiable(_requests);
  List<Product> get products => List.unmodifiable(_products);

  // Initialize Data
  Future<void> init() async {
    final db = DatabaseHelper.instance;
    _clients = await db.getClients();
    _products = await db.getProducts();
    _requests = await db.getRequests();

    // Default Products if empty
    if (_products.isEmpty) {
      await addProduct(Product(id: '1', name: 'Frango', defaultPrice: 10.0));
      await addProduct(Product(id: '2', name: 'Ovos', defaultPrice: 5.0));
    }
    notifyListeners();
  }

  Future<void> addClient(Client client) async {
    await DatabaseHelper.instance.insertClient(client);
    _clients.add(client);
    notifyListeners();
  }

  Future<void> addRequest(Request request) async {
    await DatabaseHelper.instance.insertRequest(request);
    _requests.insert(0, request); // Add to top
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product);
    _products.add(product);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> registerPayment(String requestId, double amount) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = _requests[index];
      req.amountPaid += amount;

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

      await DatabaseHelper.instance.updateRequest(req);
      notifyListeners();
    }
  }

  Future<void> updateClientNotes(String clientId, String notes) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      final client = _clients[index];
      client.notes = notes;
      await DatabaseHelper.instance.updateClient(client);
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
