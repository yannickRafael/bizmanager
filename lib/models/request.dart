enum ProductType { chicken, eggs }

enum PaymentStatus { pending, paid, partial }

class Request {
  final String id;
  final String clientId;
  final ProductType type;
  final double amount; // quantity
  final double totalPrice;
  final DateTime date;

  double amountPaid;
  PaymentStatus paymentStatus;

  Request({
    required this.id,
    required this.clientId,
    required this.type,
    required this.amount,
    required this.totalPrice,
    required this.date,
    this.amountPaid = 0.0,
    this.paymentStatus = PaymentStatus.pending,
  });

  factory Request.fromMap(Map<String, dynamic> map) {
    return Request(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      type: ProductType.values[map['type'] ?? 0],
      amount: (map['amount'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      paymentStatus: PaymentStatus.values[map['paymentStatus'] ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'type': type.index,
      'amount': amount,
      'totalPrice': totalPrice,
      'date': date.toIso8601String(),
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus.index,
    };
  }
}
