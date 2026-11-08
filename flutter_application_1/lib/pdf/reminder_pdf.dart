import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// فئة محاكاة للأيقونات (للاستخدام في PDF)
class PdfIcons {
  static const String monetizationOn = '💰';
  static const String calendarToday = '📅';
  static const String business = '🏦';
  static const String accountBalance = '🔢';
}

/// Generates a unique receipt number using timestamp + random suffix.
String generateUniqueReceiptNumber() {
  final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
  final rand = Random().nextInt(9000) + 1000;
  return '$ts-$rand';
}

/// Data model for reminder PDF generation.
class ReminderData {
  final String clientName;
  final String? clientPhone;
  final String amount;
  final String dueDate;
  final String description;
  final String accountNumber;
  final String beneficiary;
  final String receiptNumber;
  final String issuerName;

  ReminderData({
    required this.clientName,
    this.clientPhone,
    required this.amount,
    required this.dueDate,
    required this.description,
    required this.accountNumber,
    required this.beneficiary,
    String? receiptNumber,
    this.issuerName = '',
  }) : receiptNumber = receiptNumber ?? generateUniqueReceiptNumber();
}

/// Transaction entry for account statement.
class StatementTransaction {
  final String date;
  final String description;
  final double amount;
  final String type;
  final double balance;

  StatementTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.balance,
  });
}

/// Account statement metadata.
class AccountStatementData {
  final String accountName;
  final String phone;
  final String statementTitle;
  final String statementSubtitle;
  final String period;
  final List<StatementTransaction> transactions;

  AccountStatementData({
    required this.accountName,
    required this.phone,
    required this.statementTitle,
    required this.statementSubtitle,
    required this.period,
    required this.transactions,
  });
}

Future<pw.Font> _loadPdfFont() async {
  try {
    final fontData = await rootBundle.load('assets/fonts/arabic_font.ttf');
    return pw.Font.ttf(fontData.buffer.asByteData());
  } catch (_) {
    return pw.Font.helvetica();
  }
}

Future<Uint8List> generateReminderPdf(ReminderData data, {List<Uint8List> attachments = const []}) async {
  final ttf = await _loadPdfFont();
  final logoImage = await _loadLogo();

  final now = DateTime.now();
  final df = DateFormat('yyyy/MM/dd');

  final transactionType = data.amount.contains('له')
      ? 'له'
      : data.amount.contains('عليه')
          ? 'عليه'
          : '';

  final primaryColor = transactionType == 'له'
      ? PdfColor.fromInt(0xFF10B981)
      : transactionType == 'عليه'
          ? PdfColor.fromInt(0xFFEF4444)
          : PdfColor.fromInt(0xFF016B61);

  final secondaryColor = transactionType == 'له'
      ? PdfColor.fromInt(0xFFD1FAE5)
      : transactionType == 'عليه'
          ? PdfColor.fromInt(0xFFFEE2E2)
          : PdfColor.fromInt(0xFF70B2B2);

  final reminderText = StringBuffer();
  reminderText.writeln('عزيزي العميل');
  if (transactionType == 'عليه') {
    reminderText.writeln('نود تذكيركم بأن عليكم مبلغا وقدره (${data.amount}) لصالح (${data.beneficiary}).');
    reminderText.writeln('يرجى المبادرة بسداد المبلغ في أقرب وقت ممكن على الحساب رقم (${data.accountNumber}).');
  } else if (transactionType == 'له') {
    reminderText.writeln('نود إعلامكم بأن لكم مبلغا مستحقا وقدره (${data.amount}) لدى (${data.beneficiary}).');
    reminderText.writeln('يمكنكم التواصل مع الجهة المستفيدة أو مراجعة الحساب رقم (${data.accountNumber}) لاستلام المبلغ.');
  } else {
    reminderText.writeln('نود تذكيركم بوجود مبلغ (${data.amount}) لصالح (${data.beneficiary}).');
    reminderText.writeln('يرجى مراجعة الحساب رقم (${data.accountNumber}).');
  }
  reminderText.writeln('رقم السند الخاص بكم هو: (${data.receiptNumber}).');
  reminderText.writeln('تاريخ الاستحقاق: ${data.dueDate}');
  reminderText.writeln('هذا إشعار تذكيري بادروا بالوفاء.');

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context context) {
        return [
          _buildReminderHeader(ttf, logoImage, df.format(now), primaryColor, secondaryColor, transactionType),
          pw.SizedBox(height: 20),
          _buildClientInfoCard(ttf, data, df, primaryColor, secondaryColor),
          pw.SizedBox(height: 16),
          _buildReminderDetailsCard(ttf, data, primaryColor, secondaryColor, transactionType),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryColor, width: 2),
              borderRadius: pw.BorderRadius.circular(10),
              color: secondaryColor.withOpacity(0.1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '💬 رسالة تذكير',
                  style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  reminderText.toString(),
                  style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey800, lineSpacing: 1.5),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildFooter(ttf, now),
        ];
      },
    ),
  );

  if (attachments.isNotEmpty) {
    for (var i = 0; i < attachments.length; i++) {
      final image = pw.MemoryImage(attachments[i]);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    'المرفق ${i + 1}',
                    style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  return doc.save();
}

Future<pw.MemoryImage?> _loadLogo() async {
  // Temporarily disable logo loading to avoid web asset loading issues
  return null;
}

pw.Widget _buildReminderHeader(pw.Font ttf, pw.MemoryImage? logoImage, String date, PdfColor primaryColor, PdfColor secondaryColor, String transactionType) {
  return pw.Container(
    height: 80,
    decoration: pw.BoxDecoration(
      borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(12), topRight: pw.Radius.circular(12)),
      gradient: pw.LinearGradient(begin: pw.Alignment.centerRight, end: pw.Alignment.centerLeft, colors: [primaryColor, secondaryColor]),
    ),
    alignment: pw.Alignment.center,
    padding: const pw.EdgeInsets.symmetric(horizontal: 20),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (logoImage != null)
          pw.SizedBox(height: 50, width: 50, child: pw.Image(logoImage)),
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('إشعار تذكير بمبلغ مستحق', style: pw.TextStyle(font: ttf, fontSize: 18, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(15)),
              child: pw.Text(transactionType.isNotEmpty ? transactionType : 'إشعار', style: pw.TextStyle(font: ttf, fontSize: 11, color: primaryColor, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.Text(date, style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.white)),
      ],
    ),
  );
}

pw.Widget _buildClientInfoCard(pw.Font ttf, ReminderData data, DateFormat df, PdfColor primaryColor, PdfColor secondaryColor) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(10), border: pw.Border.all(color: secondaryColor, width: 1)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('👤 معلومات العميل', style: pw.TextStyle(font: ttf, fontSize: 15, fontWeight: pw.FontWeight.bold, color: primaryColor)),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('الاسم: ${data.clientName}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.SizedBox(height: 6),
                if (data.clientPhone?.isNotEmpty == true)
                  pw.Text('الهاتف: ${data.clientPhone}', style: pw.TextStyle(font: ttf, fontSize: 12)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('رقم السند: ${data.receiptNumber}', style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 6),
                pw.Text('تاريخ الإصدار: ${df.format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildReminderDetailsCard(pw.Font ttf, ReminderData data, PdfColor primaryColor, PdfColor secondaryColor, String transactionType) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(begin: pw.Alignment.topRight, end: pw.Alignment.bottomLeft, colors: [secondaryColor.withOpacity(0.2), secondaryColor.withOpacity(0.05)]),
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: primaryColor, width: 2),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('💰 تفاصيل المعاملة', style: pw.TextStyle(font: ttf, fontSize: 15, fontWeight: pw.FontWeight.bold, color: primaryColor)),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: primaryColor.withOpacity(0.3))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('المبلغ:', style: pw.TextStyle(font: ttf, fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Text(data.amount, style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          ]),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(color: transactionType == 'له' ? PdfColor.fromInt(0xFFD1FAE5) : transactionType == 'عليه' ? PdfColor.fromInt(0xFFFEE2E2) : PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Text(transactionType == 'له' ? '✅' : transactionType == 'عليه' ? '⚠️' : 'ℹ️', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(width: 8),
            pw.Text('نوع المعاملة: ${transactionType.isNotEmpty ? transactionType : 'غير محدد'}', style: pw.TextStyle(font: ttf, fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          ]),
        ),
        pw.SizedBox(height: 12),
        if (data.beneficiary.isNotEmpty)
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('المستفيد:', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(data.beneficiary, style: pw.TextStyle(font: ttf, fontSize: 12)),
          ]),
        pw.SizedBox(height: 8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('رقم الحساب:', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(data.accountNumber, style: pw.TextStyle(font: ttf, fontSize: 12)),
        ]),
        if (data.description.isNotEmpty) pw.SizedBox(height: 8),
        if (data.description.isNotEmpty)
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('البيان:', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(data.description, style: pw.TextStyle(font: ttf, fontSize: 12), textAlign: pw.TextAlign.right),
          ]),
        if (data.dueDate.isNotEmpty) pw.SizedBox(height: 8),
        if (data.dueDate.isNotEmpty)
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('تاريخ الاستحقاق:', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(data.dueDate, style: pw.TextStyle(font: ttf, fontSize: 12)),
          ]),
      ],
    ),
  );
}

pw.Widget _buildFooter(pw.Font ttf, DateTime now) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(gradient: pw.LinearGradient(colors: [PdfColors.grey100, PdfColors.grey200]), borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: PdfColors.grey400)),
    child: pw.Column(children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('📍 هذا إشعار تذكيري فقط', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
        pw.Text('🕒 ${DateFormat('HH:mm').format(now)}', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700)),
      ]),
      pw.SizedBox(height: 6),
      pw.Divider(color: PdfColors.grey400, thickness: 1),
      pw.SizedBox(height: 4),
      pw.Text('تم إنشاء هذا الإشعار تلقائيا من النظام', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
    ]),
  );
}

Future<Uint8List> generateAccountStatementPdf(AccountStatementData data) async {
  final ttf = await _loadPdfFont();
  final logoImage = await _loadLogo();
  final now = DateTime.now();
  final df = DateFormat('yyyy/MM/dd');

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context context) {
        return [
          _buildStatementHeader(ttf, logoImage, data.statementTitle, data.statementSubtitle, df.format(now)),
          pw.SizedBox(height: 20),
          _buildStatementAccountInfo(ttf, data, df),
          pw.SizedBox(height: 16),
          _buildStatementTable(ttf, data.transactions),
          pw.SizedBox(height: 20),
          _buildStatementFooter(ttf),
        ];
      },
    ),
  );

  return doc.save();
}

pw.Widget _buildStatementHeader(pw.Font ttf, pw.MemoryImage? logoImage, String title, String subtitle, String date) {
  return pw.Container(
    height: 100,
    decoration: pw.BoxDecoration(
      borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(12), topRight: pw.Radius.circular(12)),
      gradient: pw.LinearGradient(begin: pw.Alignment.centerRight, end: pw.Alignment.centerLeft, colors: [PdfColor.fromInt(0xFF016B61), PdfColor.fromInt(0xFF0D9488)]),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoImage != null)
          pw.SizedBox(height: 56, width: 56, child: pw.Image(logoImage)),
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(title, style: pw.TextStyle(font: ttf, fontSize: 20, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(subtitle, style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.white)),
          ],
        ),
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('تاريخ الإصدار', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.white.withOpacity(0.85))),
            pw.SizedBox(height: 4),
            pw.Text(date, style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildStatementAccountInfo(pw.Font ttf, AccountStatementData data, DateFormat df) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(10), border: pw.Border.all(color: PdfColor.fromInt(0xFF70B2B2), width: 1)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(' معلومات الحساب', style: pw.TextStyle(font: ttf, fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF016B61))),
              pw.SizedBox(height: 10),
              pw.Text('الاسم: ${data.accountName}', style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.SizedBox(height: 6),
              if (data.phone.isNotEmpty) pw.Text('الهاتف: ${data.phone}', style: pw.TextStyle(font: ttf, fontSize: 12)),
            ]),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('الفترة', style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(data.period.isNotEmpty ? data.period : 'غير محددة', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('تاريخ الإصدار', style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(df.format(DateTime.now()), style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
        ],
      ),
    ]),
  );
}

pw.Widget _buildStatementTable(pw.Font ttf, List<StatementTransaction> transactions) {
  final totalCredit = transactions.where((tx) => tx.type == 'له').fold<double>(0, (sum, tx) => sum + tx.amount);
  final totalDebit = transactions.where((tx) => tx.type == 'عليه').fold<double>(0, (sum, tx) => sum + tx.amount);
  final closingBalance = transactions.isNotEmpty ? transactions.last.balance : 0.0;

  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
    pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(10), border: pw.Border.all(color: PdfColor.fromInt(0xFF016B61), width: 2)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('📊 تفاصيل المعاملات', style: pw.TextStyle(font: ttf, fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF016B61))),
        pw.SizedBox(height: 16),
        pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
          pw.TableRow(decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF70B2B2).withOpacity(0.2)), children: [
            _tableCell(ttf, 'الرصيد', isHeader: true),
            _tableCell(ttf, 'التفاصيل', isHeader: true),
            _tableCell(ttf, 'لـكم', isHeader: true),
            _tableCell(ttf, 'عـليكم', isHeader: true),
            _tableCell(ttf, 'التاريخ', isHeader: true),
          ]),
          ...transactions.map((tx) => pw.TableRow(children: [
                _tableCell(ttf, tx.balance.toStringAsFixed(2), color: tx.balance >= 0 ? PdfColors.green : PdfColors.red, align: pw.TextAlign.center),
                _tableCell(ttf, tx.description, align: pw.TextAlign.right),
                _tableCell(ttf, tx.type == 'له' ? tx.amount.toStringAsFixed(2) : '-', align: pw.TextAlign.center, color: tx.type == 'له' ? PdfColors.green : PdfColors.black),
                _tableCell(ttf, tx.type == 'عليه' ? tx.amount.toStringAsFixed(2) : '-', align: pw.TextAlign.center, color: tx.type == 'عليه' ? PdfColors.red : PdfColors.black),
                _tableCell(ttf, tx.date, align: pw.TextAlign.center),
              ])),
        ]),
      ]),
    ),
    pw.SizedBox(height: 16),
    _buildStatementSummaryCard(ttf, totalCredit, totalDebit, closingBalance),
  ]);
}

pw.Widget _buildStatementSummaryCard(pw.Font ttf, double credit, double debit, double closingBalance) {
  final isCredit = closingBalance >= 0;
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColor.fromInt(0xFF016B61), width: 1),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            pw.Text('إجـمالي الرصيد ', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColor.fromInt(0xFF016B61), fontWeight: pw.FontWeight.bold)),
            pw.Text(isCredit ? 'له' : 'عليه', style: pw.TextStyle(font: ttf, fontSize: 12, color: isCredit ? PdfColors.green : PdfColors.red, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(height: 4),
          pw.Text(closingBalance.toStringAsFixed(2), style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold, color: isCredit ? PdfColors.green : PdfColors.red)),
        ]),
      ]),
    ]),
  );
}

pw.Widget _tableCell(pw.Font ttf, String text, {bool isHeader = false, PdfColor? color, pw.TextAlign align = pw.TextAlign.center}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(font: ttf, fontSize: isHeader ? 12 : 10, fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black),
    ),
  );
}

pw.Widget _buildStatementFooter(pw.Font ttf) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(gradient: pw.LinearGradient(colors: [PdfColors.grey100, PdfColors.grey200]), borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: PdfColors.grey400)),
    child: pw.Text('تم إنشاء كشف الحساب تلقائيا من النظام', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
  );
}

String generateReminderPlainText(ReminderData data) {
  final transactionType = data.amount.contains('له')
      ? 'له'
      : data.amount.contains('عليه')
          ? 'عليه'
          : '';

  final buffer = StringBuffer();
  buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
  buffer.writeln('📋 *إشعار تذكير بمبلغ مستحق*');
  buffer.writeln('━━━━━━━━━━━━━━━━━━━━\n');
  buffer.writeln('👤 *العميل:* ${data.clientName}');
  if (transactionType == 'عليه') {
    buffer.writeln('🔴 *نوع المعاملة:* عليكم');
  } else if (transactionType == 'له') {
    buffer.writeln('🟢 *نوع المعاملة:* لكم');
  }
 
  buffer.writeln('💬 *رسالة تذكير:*');
  buffer.writeln(transactionType == 'عليه'
      ? 'نود تذكيركم بأن عليكم المبلغ المذكور أعلاه. يرجى المبادرة بالسداد في أقرب وقت ممكن.'
      : transactionType == 'له'
          ? 'نود إعلامكم بأن لكم المبلغ المذكور أعلاه. يمكنكم التواصل لاستلام المبلغ.'
          : 'نود تذكيركم بالمعاملة المذكورة أعلاه.');
  if (data.clientPhone?.isNotEmpty == true) buffer.writeln('\n📞 *للتواصل:* ${data.clientPhone}');
  buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━');
  buffer.writeln('📍 *ملاحظة:* هذا إشعار تذكيري فقط');
  buffer.writeln('🕒 *وقت الإصدار:* ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}');
  buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
  return buffer.toString();
}

extension on PdfColor {
  /// Returns this color with the given [opacity] (0.0 – 1.0).
  PdfColor withOpacity(double opacity) {
    final a = opacity.clamp(0.0, 1.0);
    return PdfColor(red, green, blue, a);
  }
}
