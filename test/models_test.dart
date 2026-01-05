import 'package:bizmanager/models/client.dart';
import 'package:bizmanager/models/request.dart';
import 'package:bizmanager/services/data_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models Test', () {
    test('Client toMap and fromMap', () {
      final client = Client(
        id: '1',
        name: 'John',
        phoneNumber: '123',
        address: 'Main St',
      );
      final map = client.toMap();
      final newClient = Client.fromMap(map);

      expect(newClient.id, client.id);
      expect(newClient.name, client.name);
    });

    test('Request toMap and fromMap', () {
      final date = DateTime.now();
      final request = Request(
        id: '100',
        clientId: '1',
        type: ProductType.eggs,
        amount: 10,
        totalPrice: 50,
        date: date,
      );
      final map = request.toMap();
      final newRequest = Request.fromMap(map);

      expect(newRequest.id, request.id);
      expect(newRequest.type, ProductType.eggs);
      // DateTime might lose some precision in iso string if not careful, but usually okay
      expect(newRequest.date.toIso8601String(), date.toIso8601String());
    });
  });

  group('DataManager Test', () {
    test('Add Client', () {
      final manager = DataManager();
      expect(manager.clients.length, 0);

      final client = Client(
        id: '1',
        name: 'John',
        phoneNumber: '123',
        address: 'Main St',
      );
      manager.addClient(client);

      expect(manager.clients.length, 1);
      expect(manager.clients.first.name, 'John');

      manager.updateClientNotes('1', 'Has change of \$50');
      expect(manager.clients.first.notes, 'Has change of \$50');
    });

    test('Add Request and Update Status', () {
      final manager = DataManager();
      final request = Request(
        id: '100',
        clientId: '1',
        type: ProductType.chicken,
        amount: 5,
        totalPrice: 100,
        date: DateTime.now(),
      );

      manager.addRequest(request);
      expect(manager.requests.length, 1);
      expect(manager.requests.first.paymentStatus, PaymentStatus.pending);

      // Partial Payment
      manager.registerPayment('100', 50);
      expect(manager.requests.first.paymentStatus, PaymentStatus.partial);
      expect(manager.requests.first.amountPaid, 50);

      // Full Payment
      manager.registerPayment('100', 50);
      expect(manager.requests.first.paymentStatus, PaymentStatus.paid);
      expect(manager.requests.first.amountPaid, 100);
    });
  });
}
