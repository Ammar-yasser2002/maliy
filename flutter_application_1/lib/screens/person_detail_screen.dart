import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import '../pdf/reminder_pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personName;
  final String phone;
  final String? accountId;
  const PersonDetailScreen({
    super.key,
    required this.personName,
    required this.phone,
    this.accountId,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  List<Reminder> _items = [];
  double totalIn = 0.0; // positive to us (له)
  double totalOut = 0.0; // owes (عليه)

  @override
  void initState() {
    super.initState();
    _loadPersonReminders();
  }

  Future<void> _loadPersonReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('reminders') ?? <String>[];
      final List<Reminder> items = [];
      for (var s in listJson) {
        try {
          final m = Reminder.fromJson(jsonDecode(s) as Map<String, dynamic>);
          // If accountId provided, prefer filtering by account id
          if (widget.accountId != null && widget.accountId!.isNotEmpty) {
            if (m.accountNumber == widget.accountId) items.add(m);
          } else {
            // fallback: match by name or phone
            if (m.clientName == widget.personName ||
                (m.clientPhone != null && m.clientPhone == widget.phone)) {
              items.add(m);
            }
          }
        } catch (_) {}
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _items = items;
      });
      _recalcTotals();
    } catch (e) {
      debugPrint('Load person reminders failed: $e');
    }
  }

  void _recalcTotals() {
    double inTot = 0.0;
    double outTot = 0.0;
    for (var r in _items) {
      final match = RegExp(r"[0-9]+(?:[\\.,][0-9]+)?").firstMatch(r.amount);
      final v = match != null
          ? double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0.0
          : 0.0;
      // Heuristic: if amount string contains 'عليه' treat as out (owes), otherwise in.
      if (r.amount.contains('عليه') || r.amount.contains('علي')) {
        outTot += v;
      } else {
        inTot += v;
      }
    }
    setState(() {
      totalIn = inTot;
      totalOut = outTot;
    });
  }

  Future<void> _deleteReminder(String receiptNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('reminders') ?? <String>[];
      final remaining = <String>[];
      for (var s in listJson) {
        try {
          final m = Reminder.fromJson(jsonDecode(s) as Map<String, dynamic>);
          if (m.receiptNumber != receiptNumber) remaining.add(s);
        } catch (_) {
          remaining.add(s);
        }
      }
      await prefs.setStringList('reminders', remaining);
      await _loadPersonReminders();
    } catch (e) {
      debugPrint('Failed to delete reminder: $e');
    }
  }

  Future<void> _sharePdf(Reminder rem) async {
    final data = ReminderData(
      clientName: rem.clientName,
      clientPhone: rem.clientPhone,
      amount: rem.amount,
      dueDate: rem.dueDate,
      description: rem.description,
      accountNumber: rem.accountNumber,
      beneficiary: rem.beneficiary,
      issuerName: rem.issuerName,
    );
    final bytes = await generateReminderPdf(data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reminder_${rem.receiptNumber}.pdf',
    );
  }

  Future<void> _copyPlainText(Reminder rem) async {
    final plain = generateReminderPlainText(
      ReminderData(
        clientName: rem.clientName,
        clientPhone: rem.clientPhone,
        amount: rem.amount,
        dueDate: rem.dueDate,
        description: rem.description,
        accountNumber: rem.accountNumber,
        beneficiary: rem.beneficiary,
        issuerName: rem.issuerName,
      ),
    );
    await Clipboard.setData(ClipboardData(text: plain));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم نسخ نص الإشعار')));
    }
  }

  Future<void> _showEditDialog(Reminder rem) async {
    final descC = TextEditingController(text: rem.description);
    final amtC = TextEditingController(text: rem.amount);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تعديل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descC),
              SizedBox(height: 8),
              TextField(controller: amtC),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final listJson = prefs.getStringList('reminders') ?? <String>[];
        final updated = <String>[];
        for (var s in listJson) {
          try {
            final m = Reminder.fromJson(jsonDecode(s) as Map<String, dynamic>);
            if (m.receiptNumber == rem.receiptNumber) {
              final newRem = Reminder(
                receiptNumber: m.receiptNumber,
                clientName: m.clientName,
                clientPhone: m.clientPhone,
                amount: amtC.text,
                dueDate: m.dueDate,
                description: descC.text,
                accountNumber: m.accountNumber,
                beneficiary: m.beneficiary,
                issuerName: m.issuerName,
                createdAt: m.createdAt,
                images: m.images,
              );
              updated.add(newRem.toJsonString());
            } else {
              updated.add(s);
            }
          } catch (_) {
            updated.add(s);
          }
        }
        await prefs.setStringList('reminders', updated);
        await _loadPersonReminders();
      } catch (e) {
        debugPrint('Edit failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: 24,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E62C8), Color(0xFF1A54B8)],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.personName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'إدارة المعاملات والأرصدة',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // filter/search card overlapping
            Transform.translate(
              offset: Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1E62C8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'له',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'المعاملات',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Text(
                            '${_items.length} معاملة',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextField(
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'ابحث في المعاملات...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: _items.isEmpty
                  ? Center(child: Text('لا توجد عمليات لهذا الشخص'))
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final rem = _items[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          rem.createdAt,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          rem.clientName,
                                          style: TextStyle(
                                            color: Color(0xFF1E62C8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          rem.amount,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: rem.amount.contains('عليه')
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          rem.dueDate,
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                if (rem.description.isNotEmpty)
                                  Text(
                                    rem.description,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 15,
                                    ),
                                  ),
                                if (rem.beneficiary.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'المستفيد: ${rem.beneficiary}',
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                if (rem.issuerName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'الجهة المرسلة: ${rem.issuerName}',
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.green[50],
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.chat,
                                              color: Colors.green,
                                            ),
                                            onPressed: () async {
                                              final reminderData = ReminderData(
                                                clientName: rem.clientName,
                                                clientPhone: rem.clientPhone,
                                                amount: rem.amount,
                                                dueDate: rem.dueDate,
                                                description: rem.description,
                                                accountNumber:
                                                    rem.accountNumber,
                                                beneficiary: rem.beneficiary,
                                                issuerName: rem.issuerName,
                                              );
                                              final msg =
                                                  generateReminderPlainText(
                                                    reminderData,
                                                  );
                                              final url = Uri.parse(
                                                'https://wa.me/?text=${Uri.encodeComponent(msg)}',
                                              );
                                              await Clipboard.setData(
                                                ClipboardData(text: msg),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'تم نسخ نص الإشعار، يمكنك الإرسال عبر واتساب.',
                                                  ),
                                                ),
                                              );
                                              await launchUrl(url);
                                            },
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text('واتساب'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.blue[50],
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.message,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _copyPlainText(rem),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text('SMS'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.orange[50],
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                            ),
                                            onPressed: () =>
                                                _showEditDialog(rem),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text('تعديل'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.red[50],
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) =>
                                                    Directionality(
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      child: AlertDialog(
                                                        title: Text(
                                                          'تأكيد الحذف',
                                                        ),
                                                        content: Text(
                                                          'حذف هذه العملية؟',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  ctx,
                                                                ).pop(false),
                                                            child: Text(
                                                              'إلغاء',
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  ctx,
                                                                ).pop(true),
                                                            child: Text('حذف'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                              );
                                              if (ok == true) {
                                                await _deleteReminder(
                                                  rem.receiptNumber,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text('حذف'),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // totals bar
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        totalOut.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('عليه'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        (totalIn).toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('له'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        (totalIn - totalOut).toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('الصافي'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
