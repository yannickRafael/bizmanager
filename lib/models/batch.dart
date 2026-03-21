import 'enums.dart';

class Batch {
  final String id;
  final String farmId;
  final String name;
  final BatchType type;
  final BirdOrigin birdOrigin;
  final DateTime entryDate;
  final int initialQuantity;
  final int currentQuantity;
  final String breedOrLineage;
  final double acquisitionCost;
  final BatchStatus status;
  final String notes;

  Batch({
    required this.id,
    required this.farmId,
    required this.name,
    required this.type,
    required this.birdOrigin,
    required this.entryDate,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.breedOrLineage,
    required this.acquisitionCost,
    required this.status,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'name': name,
      'type': type.name,
      'birdOrigin': birdOrigin.name,
      'entryDate': entryDate.toIso8601String(),
      'initialQuantity': initialQuantity,
      'currentQuantity': currentQuantity,
      'breedOrLineage': breedOrLineage,
      'acquisitionCost': acquisitionCost,
      'status': status.name,
      'notes': notes,
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      farmId: map['farmId'],
      name: map['name'],
      type: BatchType.values.firstWhere((e) => e.name == map['type']),
      birdOrigin: BirdOrigin.values.firstWhere((e) => e.name == map['birdOrigin']),
      entryDate: DateTime.parse(map['entryDate']),
      initialQuantity: map['initialQuantity'],
      currentQuantity: map['currentQuantity'],
      breedOrLineage: map['breedOrLineage'],
      acquisitionCost: map['acquisitionCost'],
      status: BatchStatus.values.firstWhere((e) => e.name == map['status']),
      notes: map['notes'] ?? '',
    );
  }
}
