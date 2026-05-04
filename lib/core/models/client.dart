/// A buyer / customer. Shared across all animal types.
/// Fixed: `notes` is now `final` (was mutable in the old codebase).
class Client {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String notes;

  const Client({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.notes = '',
  });

  Client copyWith({
    String? name,
    String? phoneNumber,
    String? address,
    String? notes,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'notes': notes,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
