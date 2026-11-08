class Client {
  final int? id;
  String name;
  String phone;
  String email;
  String address;
  String company;
  String notes;
  final String createdAt;

  Client({
    this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.company = '',
    this.notes = '',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Convert Client to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'company': company,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  // Create Client from Map (database query result)
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      company: map['company'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt:
          map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  // Create a copy of the client with updated values
  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? company,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
