import '../constants/app_constants.dart';

/// Abstract base for all animal batches (poultry flocks, cattle herds, goat herds).
///
/// Subclasses add animal-specific fields (e.g. poultryType, cattlePurpose)
/// and must implement [copyWithQuantity] and [toMap].
abstract class BaseBatch {
  final String id;
  final String farmId;
  final String name;
  final AnimalType animalType;
  final DateTime entryDate;
  final int initialQuantity;
  final int currentQuantity;
  final String breedOrLineage;
  final double acquisitionCost;
  final BatchStatus status;
  final String notes;

  /// Future-proofing: when true, this batch links to individual animal records
  /// in the `individual_animals` table.
  final bool individualTrackingEnabled;

  /// Known male count. Females = [femaleCount]. Unknown = [currentQuantity] - male - female.
  final int maleCount;
  final int femaleCount;

  const BaseBatch({
    required this.id,
    required this.farmId,
    required this.name,
    required this.animalType,
    required this.entryDate,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.breedOrLineage,
    required this.acquisitionCost,
    required this.status,
    this.notes = '',
    this.individualTrackingEnabled = false,
    this.maleCount = 0,
    this.femaleCount = 0,
  });

  /// Create a copy with an updated quantity (used by mortality, sales, slaughter).
  /// Eliminates the 12-field manual reconstruction pattern.
  BaseBatch copyWithQuantity(int newQuantity);

  /// Create a copy with an updated status.
  BaseBatch copyWithStatus(BatchStatus newStatus);

  /// Serialize to a map for SQLite storage.
  Map<String, dynamic> toMap();

  /// Base fields shared by all batch types.
  Map<String, dynamic> toBaseMap() {
    return {
      'id': id,
      'farmId': farmId,
      'name': name,
      'animalType': animalType.name,
      'entryDate': entryDate.toIso8601String(),
      'initialQuantity': initialQuantity,
      'currentQuantity': currentQuantity,
      'breedOrLineage': breedOrLineage,
      'acquisitionCost': acquisitionCost,
      'status': status.name,
      'notes': notes,
      'individualTrackingEnabled': individualTrackingEnabled ? 1 : 0,
      'maleCount': maleCount,
      'femaleCount': femaleCount,
    };
  }
}
