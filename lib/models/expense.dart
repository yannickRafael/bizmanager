import 'enums.dart';

class Expense {
  final String id;
  final String batchId;
  final ExpenseType type;
  final String? customCategory;
  final String description;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.batchId,
    required this.type,
    this.customCategory,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'type': type.name,
      'customCategory': customCategory,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      batchId: map['batchId'],
      type: ExpenseType.values.firstWhere((e) => e.name == map['type']),
      customCategory: map['customCategory'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
