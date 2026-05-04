/// A farm / exploration unit. Shared across all animal types.
class Farm {
  final String id;
  final String name;
  final String address;
  final String notes;

  const Farm({
    required this.id,
    required this.name,
    required this.address,
    this.notes = '',
  });

  Farm copyWith({
    String? name,
    String? address,
    String? notes,
  }) {
    return Farm(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'notes': notes,
    };
  }

  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      notes: map['notes'] ?? '',
    );
  }
}
