import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../models/account.dart';
import '../models/reminder.dart';
import '../pdf/reminder_pdf.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  List<Account> _accounts = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadAccountsAndReminders();
  }

  Future<void> _loadAccountsAndReminders() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final accJson = prefs.getString('accounts') ?? '';
      final list = <Account>[];
      for (final part in accJson.split('|||').where((e) => e.trim().isNotEmpty)) {
        try {
          list.add(Account.fromJson(jsonDecode(part) as Map<String, dynamic>));
        } catch (_) {}
      }
      final remindersJson = prefs.getStringList('reminders') ?? [];
      setState(() {
        _accounts = list;
        _reminders = remindersJson
            .map((s) => Reminder.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── generate & send Account Statement PDF ──
  Future<void> _sendAccountStatement(Account account) async {
    setState(() => _isGenerating = true);
    try {
      final now = DateTime.now();
      final periodText = '${now.year}/${now.month}/${now.day}';

      // build transaction list
      final List<StatementTransaction> txs = [];
      if (account.transactions.isNotEmpty) {
        for (final t in account.transactions) {
          final amt = (t['amount'] is num)
              ? (t['amount'] as num).toDouble()
              : double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
          final bal = (t['balance'] is num)
              ? (t['balance'] as num).toDouble()
              : double.tryParse(t['balance']?.toString() ?? '0') ?? 0.0;
          txs.add(StatementTransaction(
            date: (t['date'] ?? '').toString().split('T').first,
            description: t['description'] ?? t['desc'] ?? '',
            amount: amt,
            type: t['type'] ?? 'له',
            balance: bal,
          ));
        }
      } else {
        // no transactions: show current balance as single row
        txs.add(StatementTransaction(
          date: now.toIso8601String().split('T').first,
          description: account.notes?.isNotEmpty == true ? account.notes! : 'رصيد افتتاحي',
          amount: account.balance,
          type: account.balance >= 0 ? 'له' : 'عليه',
          balance: account.balance,
        ));
      }

      final data = AccountStatementData(
        accountName: account.name,
        phone: account.phone,
        statementTitle: 'كشف حساب',
        statementSubtitle: 'تفاصيل المعاملات المالية',
        period: periodText,
        transactions: txs,
      );

      final bytes = await generateAccountStatementPdf(data);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'statement_${account.name}_${now.millisecondsSinceEpoch}.pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال كشف حساب ${account.name} بنجاح'),
          backgroundColor: const Color(0xFF016B61),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  // ── reminders / saved list ──
  Future<void> _deleteReminderAt(int idx) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('تأكيد الحذف'),
            ],
          ),
          content: Text(
            'هل تريد حذف الإشعار الخاص بـ "${_reminders[idx].clientName}"؟',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('reminders') ?? [];
    list.removeAt(idx);
    await prefs.setStringList('reminders', list);
    await _loadAccountsAndReminders();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الإشعار بنجاح'), backgroundColor: Color(0xFF016B61)),
    );
  }

  void _viewReminderDetails(Reminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF016B61),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: const [
                Icon(Icons.notifications, color: Colors.white),
                SizedBox(width: 8),
                Text('تفاصيل الإشعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('👤 العميل', reminder.clientName),
                _buildDetailItem('📞 الهاتف', reminder.clientPhone ?? 'غير محدد'),
                _buildDetailItem('💰 المبلغ', reminder.amount),
                _buildDetailItem('📅 التاريخ', reminder.dueDate),
                _buildDetailItem('🔢 رقم الحساب', reminder.accountNumber),
                _buildDetailItem('🏢 المستفيد', reminder.beneficiary),
                _buildDetailItem('📝 الوصف', reminder.description),
                _buildDetailItem('👤 المُصدر', reminder.issuerName),
                _buildDetailItem('🔖 رقم السند', reminder.receiptNumber),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF016B61)),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value.isNotEmpty ? value : 'غير محدد', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Colors.grey),
        ],
      ),
    );
  }

  Future<File> _savePdfFile(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _sharePdfFromReminder(Reminder r) async {
    try {
      final data = ReminderData(
        clientName: r.clientName,
        clientPhone: r.clientPhone,
        amount: r.amount,
        dueDate: r.dueDate,
        description: r.description,
        accountNumber: r.accountNumber,
        beneficiary: r.beneficiary,
        receiptNumber: r.receiptNumber,
        issuerName: r.issuerName,
      );
      final bytes = await generateReminderPdf(data);
      await Printing.sharePdf(bytes: bytes, filename: 'reminder_${r.receiptNumber}.pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مشاركة PDF بنجاح'), backgroundColor: Color(0xFF016B61)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF016B61);
    final secondaryColor = const Color(0xFF70B2B2);
    final creditCount = _reminders.where((r) => r.amount.contains('له')).length;
    final debitCount = _reminders.where((r) => r.amount.contains('عليه')).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        appBar: AppBar(
          title: const Text(
            'التقارير والإشعارات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAccountsAndReminders, tooltip: 'تحديث'),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),

            // ── Stats ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: .25), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(_accounts.length.toString(), 'الحسابات', Icons.people),
                  Container(width: 1, height: 36, color: Colors.white24),
                  _buildStat(creditCount.toString(), 'له', Icons.arrow_upward, isCredit: true),
                  Container(width: 1, height: 36, color: Colors.white24),
                  _buildStat(debitCount.toString(), 'عليه', Icons.arrow_downward, isCredit: false),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Account list → tap to send statement PDF ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Color(0xFF016B61)),
                  const SizedBox(width: 8),
                  const Text('إرسال كشف الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF016B61))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF016B61).withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('اضغط على الحساب لإرسال PDF', style: TextStyle(fontSize: 10, color: Color(0xFF016B61))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Accounts grid ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF016B61)))
                  : _accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('لا توجد حسابات بعد', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('أضف حسابات من زر ➕ في الرئيسية', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            ],
                          ),
                        )
                      : _isGenerating
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF016B61)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.4,
                              ),
                              itemCount: _accounts.length,
                              itemBuilder: (ctx, i) {
                                final a = _accounts[i];
                                final isCredit = a.balance >= 0;
                                return InkWell(
                                  onTap: () => _sendAccountStatement(a),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // avatar
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                                            color: isCredit ? Colors.green : Colors.red,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          a.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF016B61)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isCredit ? 'له ${a.balance.toStringAsFixed(2)}' : 'عليه ${a.balance.abs().toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: isCredit ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.picture_as_pdf, size: 13, color: primaryColor),
                                            const SizedBox(width: 4),
                                            Text('إرسال كشف', style: TextStyle(fontSize: 11, color: primaryColor)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon, {bool isCredit = true}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
