import 'dart:convert';

class Reminder {
  final String receiptNumber;
  final String clientName;
  final String? clientPhone;
  final String amount;
  final String dueDate;
  final String description;
  final String accountNumber;
  final String beneficiary;
  final String issuerName;
  final String createdAt; // ISO string
  final List<String> images; // base64-encoded images

  Reminder({
    required this.receiptNumber,
    required this.clientName,
    this.clientPhone,
    required this.amount,
    required this.dueDate,
    required this.description,
    required this.accountNumber,
    required this.beneficiary,
    required this.issuerName,
    String? createdAt,
    List<String>? images,
    }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
      images = images ?? const [];

  Map<String, dynamic> toJson() => {
        'receiptNumber': receiptNumber,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'amount': amount,
        'dueDate': dueDate,
        'description': description,
        'accountNumber': accountNumber,
        'beneficiary': beneficiary,
        'issuerName': issuerName,
        'createdAt': createdAt,
        'images': images,
      };

    static Reminder fromJson(Map<String, dynamic> j) => Reminder(
        receiptNumber: j['receiptNumber'] as String,
        clientName: j['clientName'] as String,
        clientPhone: j['clientPhone'] as String?,
        amount: j['amount'] as String,
        dueDate: j['dueDate'] as String,
        description: j['description'] as String,
        accountNumber: j['accountNumber'] as String,
        beneficiary: j['beneficiary'] as String,
        issuerName: j['issuerName'] as String,
      createdAt: j['createdAt'] as String?,
      images: (j['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      );

  String toJsonString() => jsonEncode(toJson());
}
