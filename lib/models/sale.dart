import 'dart:convert';
import 'enums.dart';

class ChickenGroup {
  final int quantity;
  final double pricePerHead;
  final double subtotal;

  ChickenGroup({
    required this.quantity,
    required this.pricePerHead,
  }) : subtotal = quantity * pricePerHead;

  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'pricePerHead': pricePerHead,
      'subtotal': subtotal,
    };
  }

  factory ChickenGroup.fromMap(Map<String, dynamic> map) {
    return ChickenGroup(
      quantity: map['quantity'],
      pricePerHead: map['pricePerHead'],
    );
  }
}

class ChickenSale {
  final String id;
  final String batchId;
  final String? clientId;
  final ChickenSaleType saleType;
  final DateTime date;
  final PaymentStatus paymentStatus;
  final double amountPaid;
  final List<ChickenGroup> groups;

  ChickenSale({
    required this.id,
    required this.batchId,
    this.clientId,
    required this.saleType,
    required this.date,
    required this.paymentStatus,
    required this.amountPaid,
    required this.groups,
  });

  double get total {
    return groups.fold(0.0, (sum, g) => sum + g.subtotal);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'clientId': clientId,
      'saleType': saleType.name,
      'date': date.toIso8601String(),
      'paymentStatus': paymentStatus.name,
      'amountPaid': amountPaid,
      'groups': jsonEncode(groups.map((g) => g.toMap()).toList()),
    };
  }

  factory ChickenSale.fromMap(Map<String, dynamic> map) {
    List<dynamic> parsedGroups = [];
    if (map['groups'] != null && map['groups'].toString().isNotEmpty) {
      try {
        parsedGroups = jsonDecode(map['groups']);
      } catch (e) {
        parsedGroups = [];
      }
    }
    return ChickenSale(
      id: map['id'],
      batchId: map['batchId'],
      clientId: map['clientId'],
      saleType: ChickenSaleType.values.firstWhere((e) => e.name == map['saleType']),
      date: DateTime.parse(map['date']),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == map['paymentStatus']),
      amountPaid: map['amountPaid'] ?? 0.0,
      groups: parsedGroups.map((e) => ChickenGroup.fromMap(e)).toList(),
    );
  }
}

class EggSale {
  final String id;
  final String batchId;
  final String? clientId;
  final EggUnit unit;
  final double quantity;
  final double unitPrice;
  final double total;
  final PaymentStatus paymentStatus;
  final double amountPaid;
  final DateTime date;

  EggSale({
    required this.id,
    required this.batchId,
    this.clientId,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.paymentStatus,
    required this.amountPaid,
    required this.date,
  }) : total = quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'clientId': clientId,
      'unit': unit.name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'paymentStatus': paymentStatus.name,
      'amountPaid': amountPaid,
      'date': date.toIso8601String(),
    };
  }

  factory EggSale.fromMap(Map<String, dynamic> map) {
    return EggSale(
      id: map['id'],
      batchId: map['batchId'],
      clientId: map['clientId'],
      unit: EggUnit.values.firstWhere((e) => e.name == map['unit']),
      quantity: map['quantity'],
      unitPrice: map['unitPrice'],
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == map['paymentStatus']),
      amountPaid: map['amountPaid'] ?? 0.0,
      date: DateTime.parse(map['date']),
    );
  }
}

class CulledBirdSale {
  final String id;
  final String batchId;
  final String? clientId;
  final int quantity;
  final double pricePerHead;
  final double total;
  final PaymentStatus paymentStatus;
  final double amountPaid;
  final DateTime date;

  CulledBirdSale({
    required this.id,
    required this.batchId,
    this.clientId,
    required this.quantity,
    required this.pricePerHead,
    required this.paymentStatus,
    required this.amountPaid,
    required this.date,
  }) : total = quantity * pricePerHead;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'clientId': clientId,
      'quantity': quantity,
      'pricePerHead': pricePerHead,
      'total': total,
      'paymentStatus': paymentStatus.name,
      'amountPaid': amountPaid,
      'date': date.toIso8601String(),
    };
  }

  factory CulledBirdSale.fromMap(Map<String, dynamic> map) {
    return CulledBirdSale(
      id: map['id'],
      batchId: map['batchId'],
      clientId: map['clientId'],
      quantity: map['quantity'],
      pricePerHead: map['pricePerHead'],
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == map['paymentStatus']),
      amountPaid: map['amountPaid'] ?? 0.0,
      date: DateTime.parse(map['date']),
    );
  }
}
