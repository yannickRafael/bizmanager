import '../constants/app_constants.dart';

/// Abstract base for all sale types across animal modules.
abstract class BaseSale {
  final String id;
  final String batchId;
  final String? clientId;
  final PaymentStatus paymentStatus;
  final double amountPaid;
  final DateTime date;

  const BaseSale({
    required this.id,
    required this.batchId,
    this.clientId,
    required this.paymentStatus,
    required this.amountPaid,
    required this.date,
  });

  /// Total value of this sale (computed by subclass).
  double get total;

  /// Serialize to a map for SQLite storage.
  Map<String, dynamic> toMap();

  /// Base fields shared by all sale types.
  Map<String, dynamic> toBaseMap() {
    return {
      'id': id,
      'batchId': batchId,
      'clientId': clientId,
      'paymentStatus': paymentStatus.name,
      'amountPaid': amountPaid,
      'date': date.toIso8601String(),
    };
  }
}
