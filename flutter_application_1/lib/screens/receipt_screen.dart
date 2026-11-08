import 'package:flutter/material.dart';

class ReceiptScreen extends StatelessWidget {
  final String accountName;
  final String phone;
  final String company;
  final String recipient;
  final String sender;
  final String transferNo;
  final double amount;
  final String currency;
  final DateTime date;

  const ReceiptScreen({
    super.key,
    required this.accountName,
    required this.phone,
    required this.company,
    required this.recipient,
    required this.sender,
    required this.transferNo,
    required this.amount,
    required this.currency,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final total = amount;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('كشف حوالة')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 720),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // header
                      Column(
                        children: [
                          Text('كشف حساب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('العميل: $accountName', style: TextStyle(fontSize: 14)),
                          SizedBox(height: 2),
                          Text('رقم الهاتف: $phone', style: TextStyle(fontSize: 14)),
                          SizedBox(height: 2),
                          Text('التاجِر: $company', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 18),
                      // date / period
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('التاريخ: ${date.toIso8601String().split('T').first}'),
                          Text('العملة: $currency'),
                        ],
                      ),
                      SizedBox(height: 12),
                      // table like
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                        child: Column(
                          children: [
                            Container(
                              color: Colors.grey.shade100,
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(child: Text('له (داين)', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(child: Text('عليه (مدين)', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(child: Text('الوصف', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(child: Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            // sample previous balance row
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text(date.toIso8601String().split('T').first)),
                                  Expanded(child: Text('-')),
                                  Expanded(child: Text('-')),
                                  Expanded(child: Text('الرصيد السابق')),
                                  Expanded(child: Text('0')),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: Colors.grey.shade300),
                            // totals row
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text('-', textAlign: TextAlign.center)),
                                  Expanded(child: Text('${amount > 0 ? amount.toStringAsFixed(2) : 0}', style: TextStyle(color: Colors.green), textAlign: TextAlign.center)),
                                  // ...existing code...
                                  Expanded(child: Text('الإجمالي', textAlign: TextAlign.center)),
                                  Expanded(child: Text('-', textAlign: TextAlign.center)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      // balance box
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Text('الرصيد لكم', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text(total.toStringAsFixed(2), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      // transfer details
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تفاصيل الحوالة:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('المستلم: $recipient'),
                              Text('المرسل: $sender'),
                              Text('شركة التحويل: $company'),
                              Text('رقم الحوالة: $transferNo'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      // print footer
                      Center(child: Text('تاريخ الطباعة: ${DateTime.now().toIso8601String().split('T').first}')),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // placeholder for printing integration
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فتح طابعة (محاكاة)')));
                        },
                        icon: Icon(Icons.print),
                        label: Text('طباعة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
