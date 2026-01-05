class Client {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  String notes;

  Client({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.notes = '',
  });

  // Factory to create a Client from a Map (e.g., from JSON/DB in future)
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  // Method to convert Client to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'notes': notes,
    };
  }
}
