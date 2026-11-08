import 'dart:convert';

class Account {
  final String id;
  final String name;
  String phone;
  double balance;
  bool active;
  String? notes;
  final List<String> images; // base64 encoded
  final String createdAt; // ISO date string
  List<Map<String, dynamic>> transactions;

  Account({
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
    this.active = true,
    this.notes,
    List<String>? images,
    String? createdAt,
    List<Map<String, dynamic>>? transactions,
  }) : images = images ?? [], createdAt = createdAt ?? DateTime.now().toIso8601String(), transactions = transactions ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'balance': balance,
        'active': active,
        'notes': notes,
        'images': images,
        'createdAt': createdAt,
        'transactions': transactions,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        balance: (j['balance'] is num) ? (j['balance'] as num).toDouble() : double.tryParse((j['balance'] ?? '0').toString()) ?? 0.0,
        active: j['active'] ?? true,
        notes: j['notes'],
        images: List<String>.from(j['images'] ?? []),
        createdAt: j['createdAt'],
        transactions: (j['transactions'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      );

  String toJsonString() => jsonEncode(toJson());
}
