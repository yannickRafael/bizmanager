import 'enums.dart';

class Partner {
  final String id;
  final String name;
  final PartnerType type;
  final String phone;
  final String address;
  final String notes;

  Partner({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.address,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'phone': phone,
      'address': address,
      'notes': notes,
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'],
      name: map['name'],
      type: PartnerType.values.firstWhere((e) => e.name == map['type']),
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
