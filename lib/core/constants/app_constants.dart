/// All enums and constants shared across animal modules.

enum AnimalType {
  poultry,
  cattle,
  goat;

  String get label {
    switch (this) {
      case AnimalType.poultry:
        return 'Aves';
      case AnimalType.cattle:
        return 'Bovinos';
      case AnimalType.goat:
        return 'Caprinos';
    }
  }

  String get icon {
    switch (this) {
      case AnimalType.poultry:
        return '🐔';
      case AnimalType.cattle:
        return '🐄';
      case AnimalType.goat:
        return '🐐';
    }
  }
}

enum PaymentStatus { pending, partial, paid }

enum BatchStatus { active, closed }

enum ExpenseType { feed, vaccine, medication, labor, energy, custom }

enum PartnerType {
  chickSupplier,
  feedSupplier,
  veterinarian,
  slaughterhouse,
  cattleSupplier,
  goatSupplier,
  other,
}

const List<String> supportedCurrencies = [
  '\$', '€', '£', 'R\$', 'Kz', 'MZN', 'AOA', 'CHF',
];
