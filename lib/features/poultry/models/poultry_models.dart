import 'dart:convert';
import 'package:farma/core/constants/app_constants.dart';
import 'poultry_enums.dart';

class ChickenGroup {
  final int quantity;
  final double pricePerHead;
  final double subtotal;

  ChickenGroup({required this.quantity, required this.pricePerHead})
      : subtotal = quantity * pricePerHead;

  Map<String, dynamic> toMap() => {
    'quantity': quantity,
    'pricePerHead': pricePerHead,
    'subtotal': subtotal,
  };

  factory ChickenGroup.fromMap(Map<String, dynamic> m) =>
      ChickenGroup(quantity: m['quantity'], pricePerHead: m['pricePerHead']);
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
    required this.id, required this.batchId, this.clientId,
    required this.saleType, required this.date,
    required this.paymentStatus, required this.amountPaid,
    required this.groups,
  });

  double get total => groups.fold(0.0, (s, g) => s + g.subtotal);

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId, 'clientId': clientId,
    'saleType': saleType.name, 'date': date.toIso8601String(),
    'paymentStatus': paymentStatus.name, 'amountPaid': amountPaid,
    'groups': jsonEncode(groups.map((g) => g.toMap()).toList()),
  };

  factory ChickenSale.fromMap(Map<String, dynamic> m) {
    List<dynamic> parsed = [];
    if (m['groups'] != null && m['groups'].toString().isNotEmpty) {
      try { parsed = jsonDecode(m['groups']); } catch (_) {}
    }
    return ChickenSale(
      id: m['id'], batchId: m['batchId'], clientId: m['clientId'],
      saleType: ChickenSaleType.values.firstWhere((e) => e.name == m['saleType']),
      date: DateTime.parse(m['date']),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == m['paymentStatus'], orElse: () => PaymentStatus.pending),
      amountPaid: (m['amountPaid'] ?? 0).toDouble(),
      groups: parsed.map((e) => ChickenGroup.fromMap(e)).toList(),
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
    required this.id, required this.batchId, this.clientId,
    required this.unit, required this.quantity, required this.unitPrice,
    required this.paymentStatus, required this.amountPaid, required this.date,
  }) : total = quantity * unitPrice;

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId, 'clientId': clientId,
    'unit': unit.name, 'quantity': quantity, 'unitPrice': unitPrice,
    'total': total, 'paymentStatus': paymentStatus.name,
    'amountPaid': amountPaid, 'date': date.toIso8601String(),
  };

  factory EggSale.fromMap(Map<String, dynamic> m) => EggSale(
    id: m['id'], batchId: m['batchId'], clientId: m['clientId'],
    unit: EggUnit.values.firstWhere((e) => e.name == m['unit']),
    quantity: (m['quantity'] ?? 0).toDouble(),
    unitPrice: (m['unitPrice'] ?? 0).toDouble(),
    paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == m['paymentStatus'], orElse: () => PaymentStatus.pending),
    amountPaid: (m['amountPaid'] ?? 0).toDouble(),
    date: DateTime.parse(m['date']),
  );
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
    required this.id, required this.batchId, this.clientId,
    required this.quantity, required this.pricePerHead,
    required this.paymentStatus, required this.amountPaid, required this.date,
  }) : total = quantity * pricePerHead;

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId, 'clientId': clientId,
    'quantity': quantity, 'pricePerHead': pricePerHead,
    'total': total, 'paymentStatus': paymentStatus.name,
    'amountPaid': amountPaid, 'date': date.toIso8601String(),
  };

  factory CulledBirdSale.fromMap(Map<String, dynamic> m) => CulledBirdSale(
    id: m['id'], batchId: m['batchId'], clientId: m['clientId'],
    quantity: m['quantity'],
    pricePerHead: (m['pricePerHead'] ?? 0).toDouble(),
    paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == m['paymentStatus'], orElse: () => PaymentStatus.pending),
    amountPaid: (m['amountPaid'] ?? 0).toDouble(),
    date: DateTime.parse(m['date']),
  );
}

class EggProduction {
  final String id;
  final String batchId;
  final EggUnit unit;
  final double quantity;
  final EggSize size;
  final DateTime date;

  const EggProduction({
    required this.id, required this.batchId, required this.unit,
    required this.quantity, required this.size, required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId, 'unit': unit.name,
    'quantity': quantity, 'size': size.name, 'date': date.toIso8601String(),
  };

  factory EggProduction.fromMap(Map<String, dynamic> m) => EggProduction(
    id: m['id'], batchId: m['batchId'],
    unit: EggUnit.values.firstWhere((e) => e.name == m['unit']),
    quantity: (m['quantity'] ?? 0).toDouble(),
    size: EggSize.values.firstWhere((e) => e.name == m['size'], orElse: () => EggSize.medium),
    date: DateTime.parse(m['date']),
  );
}

class Slaughter {
  final String id;
  final String batchId;
  final int slaughteredQuantity;
  final double totalWeightKg;
  final double slaughterCost;
  final DateTime date;

  const Slaughter({
    required this.id, required this.batchId,
    required this.slaughteredQuantity, required this.totalWeightKg,
    required this.slaughterCost, required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId,
    'slaughteredQuantity': slaughteredQuantity,
    'totalWeightKg': totalWeightKg, 'slaughterCost': slaughterCost,
    'date': date.toIso8601String(),
  };

  factory Slaughter.fromMap(Map<String, dynamic> m) => Slaughter(
    id: m['id'], batchId: m['batchId'],
    slaughteredQuantity: m['slaughteredQuantity'],
    totalWeightKg: (m['totalWeightKg'] ?? 0).toDouble(),
    slaughterCost: (m['slaughterCost'] ?? 0).toDouble(),
    date: DateTime.parse(m['date']),
  );
}
