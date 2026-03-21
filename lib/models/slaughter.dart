class Slaughter {
  final String id;
  final String batchId;
  final int slaughteredQuantity;
  final double totalWeightKg;
  final double slaughterCost;
  final DateTime date;

  Slaughter({
    required this.id,
    required this.batchId,
    required this.slaughteredQuantity,
    required this.totalWeightKg,
    required this.slaughterCost,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'slaughteredQuantity': slaughteredQuantity,
      'totalWeightKg': totalWeightKg,
      'slaughterCost': slaughterCost,
      'date': date.toIso8601String(),
    };
  }

  factory Slaughter.fromMap(Map<String, dynamic> map) {
    return Slaughter(
      id: map['id'],
      batchId: map['batchId'],
      slaughteredQuantity: map['slaughteredQuantity'],
      totalWeightKg: map['totalWeightKg'],
      slaughterCost: map['slaughterCost'],
      date: DateTime.parse(map['date']),
    );
  }
}
