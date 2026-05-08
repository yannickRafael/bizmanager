import '../../../core/constants/app_constants.dart';
import '../../../core/models/base_batch.dart';
import 'goat_enums.dart';

class GoatBatch extends BaseBatch {
  final GoatPurpose purpose;

  const GoatBatch({
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
    super.maleCount,
    super.femaleCount,
    required this.purpose,
  }) : super(animalType: AnimalType.goat);

  @override
  GoatBatch copyWithQuantity(int newQuantity) => GoatBatch(
    id: id, farmId: farmId, name: name, entryDate: entryDate,
    initialQuantity: initialQuantity, currentQuantity: newQuantity,
    breedOrLineage: breedOrLineage, acquisitionCost: acquisitionCost,
    status: status, notes: notes, individualTrackingEnabled: individualTrackingEnabled,
    maleCount: maleCount, femaleCount: femaleCount,
    purpose: purpose,
  );

  @override
  GoatBatch copyWithStatus(BatchStatus newStatus) => GoatBatch(
    id: id, farmId: farmId, name: name, entryDate: entryDate,
    initialQuantity: initialQuantity, currentQuantity: currentQuantity,
    breedOrLineage: breedOrLineage, acquisitionCost: acquisitionCost,
    status: newStatus, notes: notes, individualTrackingEnabled: individualTrackingEnabled,
    maleCount: maleCount, femaleCount: femaleCount,
    purpose: purpose,
  );

  @override
  GoatBatch copyWithGenderCounts(int maleCount, int femaleCount) => GoatBatch(
    id: id, farmId: farmId, name: name, entryDate: entryDate,
    initialQuantity: initialQuantity, currentQuantity: currentQuantity,
    breedOrLineage: breedOrLineage, acquisitionCost: acquisitionCost,
    status: status, notes: notes, individualTrackingEnabled: individualTrackingEnabled,
    maleCount: maleCount, femaleCount: femaleCount,
    purpose: purpose,
  );

  @override
  Map<String, dynamic> toMap() => {
    ...toBaseMap(),
    'goatPurpose': purpose.name,
  };

  factory GoatBatch.fromMap(Map<String, dynamic> map) => GoatBatch(
    id: map['id'],
    farmId: map['farmId'],
    name: map['name'] ?? '',
    entryDate: DateTime.parse(map['entryDate']),
    initialQuantity: map['initialQuantity'],
    currentQuantity: map['currentQuantity'],
    breedOrLineage: map['breedOrLineage'] ?? '',
    acquisitionCost: (map['acquisitionCost'] ?? 0).toDouble(),
    status: BatchStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => BatchStatus.active),
    notes: map['notes'] ?? '',
    individualTrackingEnabled: (map['individualTrackingEnabled'] ?? 0) == 1,
    maleCount: map['maleCount'] ?? 0,
    femaleCount: map['femaleCount'] ?? 0,
    purpose: GoatPurpose.values.firstWhere((e) => e.name == map['goatPurpose'], orElse: () => GoatPurpose.dual),
  );
}
