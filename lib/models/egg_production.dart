import 'enums.dart';

class EggProduction {
  final String id;
  final String batchId;
  final EggUnit unit;
  final double quantity;
  final EggSize size;
  final DateTime date;

  EggProduction({
    required this.id,
    required this.batchId,
    required this.unit,
    required this.quantity,
    required this.size,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'unit': unit.name,
      'quantity': quantity,
      'size': size.name,
      'date': date.toIso8601String(),
    };
  }

  factory EggProduction.fromMap(Map<String, dynamic> map) {
    return EggProduction(
      id: map['id'],
      batchId: map['batchId'],
      unit: EggUnit.values.firstWhere((e) => e.name == map['unit']),
      quantity: map['quantity'],
      size: EggSize.values.firstWhere((e) => e.name == map['size']),
      date: DateTime.parse(map['date']),
    );
  }
}
