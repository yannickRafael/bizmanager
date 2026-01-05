enum PaymentStatus { pending, paid, partial }

class Request {
  final String id;
  final String clientId;
  final String productName;
  final double amount; // quantity
  final double totalPrice;
  final DateTime date;

  double amountPaid;
  PaymentStatus paymentStatus;

  Request({
    required this.id,
    required this.clientId,
    required this.productName,
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
      productName: map['productName'] ?? '',
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
      'productName': productName,
      'amount': amount,
      'totalPrice': totalPrice,
      'date': date.toIso8601String(),
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus.index,
    };
  }
}
