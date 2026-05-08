/// A mortality / loss record linked to a batch. Shared across all animal types.
class Mortality {
  final String id;
  final String batchId;
  final int quantity;
  final String? cause;
  final String? sex;
  final DateTime date;

  const Mortality({
    required this.id,
    required this.batchId,
    required this.quantity,
    this.cause,
    this.sex,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'quantity': quantity,
      'cause': cause,
      'sex': sex,
      'date': date.toIso8601String(),
    };
  }

  factory Mortality.fromMap(Map<String, dynamic> map) {
    return Mortality(
      id: map['id'],
      batchId: map['batchId'],
      quantity: map['quantity'],
      cause: map['cause'],
      sex: map['sex'],
      date: DateTime.parse(map['date']),
    );
  }
}
