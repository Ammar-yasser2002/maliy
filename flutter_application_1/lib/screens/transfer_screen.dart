import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../models/account.dart';
import '../pdf/reminder_pdf.dart';

class TransferScreen extends StatefulWidget {
  final List<Account> accounts;
  final String? initialClientName;
  final String? initialAmount;
  final String? initialAccountNumber;
  final String? initialBeneficiary;
  final String? initialIssuerName;

  const TransferScreen({
    super.key,
    required this.accounts,
    this.initialClientName,
    this.initialAmount,
    this.initialAccountNumber,
    this.initialBeneficiary,
    this.initialIssuerName,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _recipient = TextEditingController();
  final TextEditingController _sender = TextEditingController();
  final TextEditingController _transferNo = TextEditingController();
  final TextEditingController _company = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final List<String> _images = [];
  Account? _selectedAccount;
  List<Map<String, dynamic>> _accountTransactions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialClientName != null) {
      _recipient.text = widget.initialClientName!;
    }
    if (widget.initialAmount != null) {
      _amount.text = widget.initialAmount!;
    }
    if (widget.initialAccountNumber != null) {
      _transferNo.text = widget.initialAccountNumber!;
    }
    if (widget.initialBeneficiary != null) {
      _company.text = widget.initialBeneficiary!;
    }
    if (widget.initialIssuerName != null) {
      _sender.text = widget.initialIssuerName!;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _recipient.dispose();
    _sender.dispose();
    _transferNo.dispose();
    _company.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _showConfirmation() async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF016B61).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 40,
                  color: Color(0xFF016B61),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'تم إنشاء الإشعار',
                style: TextStyle(
                  color: Color(0xFF016B61),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'تم توليد إشعار التذكير بنجاح وسيصبح جاهزًا للمشاركة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF016B61),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        _images.add(b64);
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  List<Map<String, dynamic>> _buildAccountTransactions(Account? account) {
    if (account == null) return [];

    if (account.transactions.isEmpty) {
      return [
        {
          'date': '',
          'description': account.notes ?? 'رصيد حالي',
          'amount': account.balance.abs(),
          'type': account.balance >= 0 ? 'له' : 'عليه',
          'balance': account.balance,
          'selected': true,
        }
      ];
    }

    return account.transactions.map((t) {
      final amount = (t['amount'] is num)
          ? (t['amount'] as num).toDouble()
          : double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
      final balance = (t['balance'] is num)
          ? (t['balance'] as num).toDouble()
          : double.tryParse(t['balance']?.toString() ?? '0') ?? 0.0;
      return {
        'date': t['date'] ?? '',
        'description': t['description'] ?? t['desc'] ?? '',
        'amount': amount,
        'type': t['type'] ?? 'له',
        'balance': balance,
        'selected': true,
      };
    }).toList();
  }

  Future<void> _generateAndSharePdf() async {
    if (_selectedAccount == null) return;

    try {
      final transactions = _selectedAccount!.transactions.map((t) {
        return StatementTransaction(
          date: t['date'] ?? '',
          description: t['description'] ?? '',
          amount: (t['amount'] is num)
              ? (t['amount'] as num).toDouble()
              : double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0,
          type: t['type'] ?? 'له',
          balance: (t['balance'] is num)
              ? (t['balance'] as num).toDouble()
              : double.tryParse(t['balance']?.toString() ?? '0') ?? 0.0,
        );
      }).toList();

      final data = AccountStatementData(
        accountName: _selectedAccount!.name,
        phone: _selectedAccount!.phone,
        statementTitle: 'كشف حساب',
        statementSubtitle: 'تفاصيل المعاملات المالية',
        period: '',
        transactions: transactions,
      );

      final messenger = ScaffoldMessenger.of(context);
      final bytes = await generateAccountStatementPdf(data);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'account_statement_${_selectedAccount!.name}.pdf',
      );

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم توليد كشف الحساب وأصبح جاهزاً للمشاركة'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في توليد كشف الحساب: $e')),
      );
    }
  }

  Future<void> _generateAndSendReminderPdf() async {
    if (_selectedAccount == null) return;

    final reminder = ReminderData(
      clientName: _recipient.text.trim().isEmpty
          ? _selectedAccount!.name
          : _recipient.text.trim(),
      clientPhone: _selectedAccount!.phone,
      amount: _amount.text.trim(),
      dueDate: DateTime.now().toLocal().toString().split(' ').first,
      description: _description.text.trim().isEmpty
          ? 'إشعار تذكير بالمبلغ المستحق'
          : _description.text.trim(),
      accountNumber: _transferNo.text.trim(),
      beneficiary: _company.text.trim(),
      issuerName: _sender.text.trim(),
    );

    final attachments = _images.map(base64Decode).toList();
    final bytes = await generateReminderPdf(reminder, attachments: attachments);

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reminder_${_selectedAccount!.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد معاملات لهذا الحساب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _generateAndSendReminderPdf();
      if (!mounted) return;
      await _showConfirmation();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء إرسال الإشعار: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF016B61);
    const secondaryColor = Color(0xFF70B2B2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'توليد إشعار تذكير',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FBFF), Color(0xFFF0F7FF)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info, color: primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'المعلومات الأساسية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<Account>(
                            initialValue: _selectedAccount,
                            decoration: const InputDecoration(
                              labelText: 'اختر الحساب',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            items: widget.accounts
                                .map(
                                  (acc) => DropdownMenuItem(
                                    value: acc,
                                    child: Text(acc.name,
                                        style: const TextStyle(
                                            color: primaryColor)),
                                  ),
                                )
                                .toList(),
                            onChanged: (acc) {
                              setState(() {
                                _selectedAccount = acc;
                                _recipient.text = acc?.name ?? '';
                                _transferNo.text = acc?.id ?? '';
                                _accountTransactions = _buildAccountTransactions(acc);
                              });
                            },
                            validator: (value) =>
                                value == null ? 'اختر حساباً' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedAccount != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.list_alt, color: primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'المعاملات والأرصدة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: secondaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'العميل',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedAccount!.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'رقم الهاتف',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedAccount!.phone,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'الفترة',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        DateTime.now().toLocal().toString().split(' ').first,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF8F6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: secondaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Row(
                                    children: const [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'التاريخ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'عليه',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'له',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'التفاصيل',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'الرصيد',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                ..._accountTransactions.map((t) {
                                  final amount = (t['amount'] is num)
                                      ? (t['amount'] as num).toDouble()
                                      : double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
                                  final balance = (t['balance'] is num)
                                      ? (t['balance'] as num).toDouble()
                                      : double.tryParse(t['balance']?.toString() ?? '0') ?? 0.0;
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                (t['date'] ?? '').toString().split('T').first,
                                                style: const TextStyle(color: Colors.black87),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                t['type'] == 'عليه'
                                                    ? amount.toStringAsFixed(2)
                                                    : '-',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.red),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                t['type'] == 'له'
                                                    ? amount.toStringAsFixed(2)
                                                    : '-',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.green),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                t['description'] ?? '',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.black87),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                balance.toStringAsFixed(2),
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'الإجمالي',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        _selectedAccount!.balance.abs().toStringAsFixed(2),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedAccount!.balance >= 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedAccount!.balance >= 0
                                            ? 'له ${_selectedAccount!.balance.abs().toStringAsFixed(2)}'
                                            : 'عليه ${_selectedAccount!.balance.abs().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _selectedAccount!.balance >= 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'الرصيد الحالي',
                                        style: TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.description),
                              label: const Text('كشف الحساب'),
                              onPressed: _generateAndSharePdf,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.attach_file, color: primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'المرفقات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_images.isNotEmpty) ...[
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (ctx, i) {
                                final b64 = _images[i];
                                return Stack(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: secondaryColor,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          base64Decode(b64),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _images.removeAt(i)),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemCount: _images.length,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('اختيار من الأستوديو'),
                                onPressed: () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('التقاط صورة'),
                                onPressed: () => _pickImage(ImageSource.camera),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            elevation: 4,
                          ),
                          onPressed: _submit,
                          child: const Text(
                            'توليد إشعار',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
