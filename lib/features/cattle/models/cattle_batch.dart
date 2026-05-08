import '../../../core/constants/app_constants.dart';
import '../../../core/models/base_batch.dart';
import 'cattle_enums.dart';

class CattleBatch extends BaseBatch {
  final CattlePurpose purpose;

  const CattleBatch({
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
  }) : super(animalType: AnimalType.cattle);

  @override
  CattleBatch copyWithQuantity(int newQuantity) => CattleBatch(
    id: id, farmId: farmId, name: name, entryDate: entryDate,
    initialQuantity: initialQuantity, currentQuantity: newQuantity,
    breedOrLineage: breedOrLineage, acquisitionCost: acquisitionCost,
    status: status, notes: notes, individualTrackingEnabled: individualTrackingEnabled,
    maleCount: maleCount, femaleCount: femaleCount,
    purpose: purpose,
  );

  @override
  CattleBatch copyWithStatus(BatchStatus newStatus) => CattleBatch(
    id: id, farmId: farmId, name: name, entryDate: entryDate,
    initialQuantity: initialQuantity, currentQuantity: currentQuantity,
    breedOrLineage: breedOrLineage, acquisitionCost: acquisitionCost,
    status: newStatus, notes: notes, individualTrackingEnabled: individualTrackingEnabled,
    maleCount: maleCount, femaleCount: femaleCount,
    purpose: purpose,
  );

  @override
  CattleBatch copyWithGenderCounts(int maleCount, int femaleCount) => CattleBatch(
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
    'cattlePurpose': purpose.name,
  };

  factory CattleBatch.fromMap(Map<String, dynamic> map) => CattleBatch(
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
    purpose: CattlePurpose.values.firstWhere((e) => e.name == map['cattlePurpose'], orElse: () => CattlePurpose.dual),
  );
}
