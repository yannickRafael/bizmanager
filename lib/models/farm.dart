class Farm {
  final String id;
  final String name;
  final String address;
  final String notes;

  Farm({
    required this.id,
    required this.name,
    required this.address,
    this.notes = '',
  });

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
