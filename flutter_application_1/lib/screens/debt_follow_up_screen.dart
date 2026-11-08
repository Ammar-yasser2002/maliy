import 'package:flutter/material.dart';
import '../models/account.dart';
import 'person_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DebtFollowUpScreen extends StatefulWidget {
  final List<Account> accounts;
  const DebtFollowUpScreen({super.key, required this.accounts});

  @override
  State<DebtFollowUpScreen> createState() => _DebtFollowUpScreenState();
}

class _DebtFollowUpScreenState extends State<DebtFollowUpScreen> {
  double filterAmount = 0;
  final TextEditingController _filterController = TextEditingController();

  List<Account> get filteredDebtors {
    if (filterAmount == 0) {
      return widget.accounts.where((a) => a.balance < 0).toList();
    } else {
      return widget.accounts.where((a) => a.balance < 0 && a.balance.abs() >= filterAmount).toList();
    }
  }

  double get totalDebt {
    return filteredDebtors.fold(0.0, (sum, a) => sum + a.balance.abs());
  }

  void _applyFilter() {
    setState(() {
      filterAmount = double.tryParse(_filterController.text) ?? 0;
    });
  }

  void _clearFilter() {
    setState(() {
      filterAmount = 0;
      _filterController.clear();
    });
  }

  Future<void> _sendWhatsAppMessage(Account account) async {
    final msg = 'عزيزي ${account.name}، لديك دين بقيمة ${account.balance.abs().toStringAsFixed(0)} يمني. يرجى السداد في أقرب وقت.';
    final url = Uri.parse('https://wa.me/${account.phone}?text=${Uri.encodeComponent(msg)}');
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await Clipboard.setData(ClipboardData(text: msg));
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('تم نسخ نص الرسالة، يمكنك الإرسال عبر واتساب.'),
            backgroundColor: Color(0xFF016B61),
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: msg));
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('تم نسخ نص الرسالة، يمكنك الإرسال عبر واتساب.'),
          backgroundColor: Color(0xFF016B61),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF016B61);
    final secondaryColor = Color(0xFF70B2B2);
    final debtors = filteredDebtors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'متابعة الديون',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            // بطاقة الإحصائيات
            Container(
              margin: EdgeInsets.all(12), // ✅ تقليل الهامش
              padding: EdgeInsets.all(16), // ✅ تقليل الحشوة
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16), // ✅ تقليل الزوايا
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8, // ✅ تقليل الظل
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إجمالي الديون',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14, // ✅ تصغير الخط
                            ),
                          ),
                          SizedBox(height: 2), // ✅ تقليل المسافة
                          Text(
                            '${totalDebt.toStringAsFixed(0)} ريال يمني',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20, // ✅ تصغير الخط
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(10), // ✅ تقليل الحشوة
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 24, // ✅ تصغير الأيقونة
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12), // ✅ تقليل المسافة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${debtors.length} حساب',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12, // ✅ تصغير الخط
                        ),
                      ),
                      Text(
                        '${widget.accounts.where((a) => a.balance < 0).length} إجمالي المدينين',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12, // ✅ تصغير الخط
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // أدوات التصفية
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12), // ✅ تقليل الهامش
              padding: EdgeInsets.all(12), // ✅ تقليل الحشوة
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12), // ✅ تقليل الزوايا
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6, // ✅ تقليل الظل
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تصفية حسب المبلغ',
                    style: TextStyle(
                      fontSize: 14, // ✅ تصغير الخط
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 8), // ✅ تقليل المسافة
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _filterController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'أدخل الحد الأدنى للمبلغ',
                              hintStyle: TextStyle(fontSize: 12), // ✅ تصغير الخط
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ✅ تقليل الحشوة
                              suffixIcon: Icon(Icons.filter_alt, color: primaryColor, size: 18), // ✅ تصغير الأيقونة
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6), // ✅ تقليل المسافة
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ✅ تقليل الحشوة
                        ),
                        onPressed: _applyFilter,
                        child: Text('تصفية', style: TextStyle(fontSize: 12)), // ✅ تصغير الخط
                      ),
                    ],
                  ),
                  if (filterAmount > 0) ...[
                    SizedBox(height: 6), // ✅ تقليل المسافة
                    Row(
                      children: [
                        Text(
                          'جاري عرض الديون فوق: ${filterAmount.toStringAsFixed(0)} ريال',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10, // ✅ تصغير الخط
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: _clearFilter,
                          child: Text(
                            'إلغاء التصفية',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10, // ✅ تصغير الخط
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 12), // ✅ تقليل المسافة

            // قائمة الديون
            Expanded(
              child: debtors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 60, // ✅ تصغير الأيقونة
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 12), // ✅ تقليل المسافة
                          Text(
                            filterAmount > 0 ? 'لا توجد ديون فوق المبلغ المحدد' : 'لا يوجد حسابات عليها ديون',
                            style: TextStyle(
                              fontSize: 16, // ✅ تصغير الخط
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (filterAmount > 0) ...[
                            SizedBox(height: 6), // ✅ تقليل المسافة
                            TextButton(
                              onPressed: _clearFilter,
                              child: Text(
                                'عرض جميع الديون',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // ✅ تصغير الخط
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(12), // ✅ تقليل الحشوة
                      itemCount: debtors.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8), // ✅ تقليل المسافة
                      itemBuilder: (ctx, i) {
                        final a = debtors[i];
                        final debtAmount = a.balance.abs();
                        final isLargeDebt = debtAmount >= 100000;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12), // ✅ تقليل الزوايا
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3, // ✅ تقليل الظل
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // ✅ تقليل الحشوة
                            leading: Container(
                              width: 42, // ✅ تصغير الحجم
                              height: 42,
                              decoration: BoxDecoration(
                                color: isLargeDebt ? Colors.red.withValues(alpha: 0.1) : secondaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLargeDebt ? Icons.warning : Icons.person,
                                color: isLargeDebt ? Colors.red : primaryColor,
                                size: 18, // ✅ تصغير الأيقونة
                              ),
                            ),
                            title: Text(
                              a.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // ✅ تصغير الخط
                                color: primaryColor,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'هاتف: ${a.phone}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11, // ✅ تصغير الخط
                                  ),
                                ),
                                SizedBox(height: 2), // ✅ تقليل المسافة
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1), // ✅ تقليل الحشوة
                                  decoration: BoxDecoration(
                                    color: isLargeDebt ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isLargeDebt ? 'دين كبير' : 'دين عادي',
                                    style: TextStyle(
                                      color: isLargeDebt ? Colors.red : Colors.orange,
                                      fontSize: 9, // ✅ تصغير الخط
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${debtAmount.toStringAsFixed(0)} ريال',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF25D366).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.chat, color: Color(0xFF25D366), size: 16),
                                        tooltip: 'إرسال واتساب',
                                        onPressed: () => _sendWhatsAppMessage(a),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints.tight(Size(28, 28)),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.visibility, color: primaryColor, size: 16),
                                        tooltip: 'عرض التفاصيل',
                                        onPressed: () {
                                          Navigator.of(context).push(MaterialPageRoute(
                                            builder: (_) => Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: PersonDetailScreen(
                                                personName: a.name,
                                                phone: a.phone,
                                                accountId: a.id,
                                              ),
                                            ),
                                          ));
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints.tight(Size(28, 28)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: PersonDetailScreen(
                                    personName: a.name,
                                    phone: a.phone,
                                    accountId: a.id,
                                  ),
                                ),
                              ));
                            },
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
}