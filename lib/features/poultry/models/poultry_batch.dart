import 'package:farma/core/constants/app_constants.dart';
import 'package:farma/core/models/base_batch.dart';
import 'poultry_enums.dart';

class PoultryBatch extends BaseBatch {
  final BatchType type;
  final BirdOrigin birdOrigin;

  const PoultryBatch({
    required super.id,
    required super.farmId,
    required super.name,
    required super.entryDate,
    required super.initialQuantity,
    required super.currentQuantity,
    required super.breedOrLineage,
    required super.acquisitionCost,
    required super.status,
    super.notes,
    super.individualTrackingEnabled,
    required this.type,
    required this.birdOrigin,
  }) : super(animalType: AnimalType.poultry);

  @override
  PoultryBatch copyWithQuantity(int newQuantity) => PoultryBatch(
    id: id, farmId: farmId, name: name, entryDate: entryDate,
    initialQuantity: initialQuantity, currentQuantity: newQuantity,
    breedOrLineage: breedOrLineage, acquisitionCost: acquisitionCost,
    status: status, notes: notes, individualTrackingEnabled: individualTrackingEnabled,
    type: type, birdOrigin: birdOrigin,
  );

  @override
  PoultryBatch copyWithStatus(BatchStatus newStatus) => PoultryBatch(
    id: id, farmId: farmId, name: name, entryDate: entryDate,
    initialQuantity: initialQuantity, currentQuantity: currentQuantity,
    breedOrLineage: breedOrLineage, acquisitionCost: acquisitionCost,
    status: newStatus, notes: notes, individualTrackingEnabled: individualTrackingEnabled,
    type: type, birdOrigin: birdOrigin,
  );

  @override
  Map<String, dynamic> toMap() => {
    ...toBaseMap(),
    'type': type.name,
    'birdOrigin': birdOrigin.name,
  };

  factory PoultryBatch.fromMap(Map<String, dynamic> map) => PoultryBatch(
    id: map['id'],
    farmId: map['farmId'],
    name: map['name'] ?? '',
    entryDate: DateTime.parse(map['entryDate']),
    initialQuantity: map['initialQuantity'],
    currentQuantity: map['currentQuantity'],
    breedOrLineage: map['breedOrLineage'] ?? '',
    acquisitionCost: (map['acquisitionCost'] ?? 0).toDouble(),
    status: BatchStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => BatchStatus.active,
    ),
    notes: map['notes'] ?? '',
    individualTrackingEnabled: (map['individualTrackingEnabled'] ?? 0) == 1,
    type: BatchType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => BatchType.meat,
    ),
    birdOrigin: BirdOrigin.values.firstWhere(
      (e) => e.name == map['birdOrigin'],
      orElse: () => BirdOrigin.purchase,
    ),
  );
}
