import 'goat_enums.dart';

class GoatMilkProduction {
  final String id;
  final String batchId;
  final double quantityLiters;
  final GoatMilkSession? session;
  final DateTime date;

  const GoatMilkProduction({
    required this.id, required this.batchId,
    required this.quantityLiters, this.session, required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId,
    'quantityLiters': quantityLiters,
    'session': session?.name, 'date': date.toIso8601String(),
  };

  factory GoatMilkProduction.fromMap(Map<String, dynamic> m) => GoatMilkProduction(
    id: m['id'], batchId: m['batchId'],
    quantityLiters: (m['quantityLiters'] ?? 0).toDouble(),
    session: m['session'] != null ? GoatMilkSession.values.firstWhere((e) => e.name == m['session']) : null,
    date: DateTime.parse(m['date']),
  );
}

class KidBirth {
  final String id;
  final String batchId;
  final int quantity;
  final String? sex;
  final String? notes;
  final DateTime date;

  const KidBirth({
    required this.id, required this.batchId,
    required this.quantity, this.sex, this.notes, required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId,
    'quantity': quantity, 'sex': sex,
    'notes': notes, 'date': date.toIso8601String(),
  };

  factory KidBirth.fromMap(Map<String, dynamic> m) => KidBirth(
    id: m['id'], batchId: m['batchId'],
    quantity: m['quantity'], sex: m['sex'],
    notes: m['notes'], date: DateTime.parse(m['date']),
  );
}

class GoatSale {
  final String id;
  final String batchId;
  final String? clientId;
  final GoatSaleType saleType;
  final int quantity;
  final double? weightKg;
  final double? pricePerKg;
  final double total;
  final String paymentStatus;
  final double amountPaid;
  final DateTime date;

  const GoatSale({
    required this.id, required this.batchId, this.clientId,
    required this.saleType, required this.quantity,
    this.weightKg, this.pricePerKg, required this.total,
    required this.paymentStatus, required this.amountPaid,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId, 'clientId': clientId,
    'saleType': saleType.name, 'quantity': quantity,
    'weightKg': weightKg, 'pricePerKg': pricePerKg,
    'total': total, 'paymentStatus': paymentStatus,
    'amountPaid': amountPaid, 'date': date.toIso8601String(),
  };

  factory GoatSale.fromMap(Map<String, dynamic> m) => GoatSale(
    id: m['id'], batchId: m['batchId'], clientId: m['clientId'],
    saleType: GoatSaleType.values.firstWhere((e) => e.name == m['saleType']),
    quantity: m['quantity'],
    weightKg: m['weightKg']?.toDouble(), pricePerKg: m['pricePerKg']?.toDouble(),
    total: (m['total'] ?? 0).toDouble(),
    paymentStatus: m['paymentStatus'] ?? 'pending',
    amountPaid: (m['amountPaid'] ?? 0).toDouble(),
    date: DateTime.parse(m['date']),
  );
}

class GoatMilkSale {
  final String id;
  final String batchId;
  final String? clientId;
  final double quantityLiters;
  final double pricePerLiter;
  final double total;
  final String paymentStatus;
  final double amountPaid;
  final DateTime date;

  const GoatMilkSale({
    required this.id, required this.batchId, this.clientId,
    required this.quantityLiters, required this.pricePerLiter,
    required this.total, required this.paymentStatus,
    required this.amountPaid, required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'batchId': batchId, 'clientId': clientId,
    'quantityLiters': quantityLiters, 'pricePerLiter': pricePerLiter,
    'total': total, 'paymentStatus': paymentStatus,
    'amountPaid': amountPaid, 'date': date.toIso8601String(),
  };

  factory GoatMilkSale.fromMap(Map<String, dynamic> m) => GoatMilkSale(
    id: m['id'], batchId: m['batchId'], clientId: m['clientId'],
    quantityLiters: (m['quantityLiters'] ?? 0).toDouble(),
    pricePerLiter: (m['pricePerLiter'] ?? 0).toDouble(),
    total: (m['total'] ?? 0).toDouble(),
    paymentStatus: m['paymentStatus'] ?? 'pending',
    amountPaid: (m['amountPaid'] ?? 0).toDouble(),
    date: DateTime.parse(m['date']),
  );
}
