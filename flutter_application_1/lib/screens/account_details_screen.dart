import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/account.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Account account;
  final Function(Account)? onUpdate;
  const AccountDetailsScreen({super.key, required this.account, this.onUpdate});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  List<Map<String, dynamic>> get transactions => widget.account.transactions;

  Color getTypeColor(String type) => type == 'له' ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF016B61);
    final secondaryColor = Color(0xFF70B2B2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تفاصيل الحساب',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditAccountDialog(context);
                    break;
                  case 'delete':
                    _showDeleteAccountDialog(context);
                    break;
                  case 'share':
                    _shareAccountInfo();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: primaryColor),
                      SizedBox(width: 8),
                      Text('تعديل الحساب'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف الحساب'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('مشاركة المعلومات'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Color(0xFFF8FBFF),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // الهيدر مع التدرج اللوني
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.account.name.isNotEmpty
                            ? widget.account.name[0]
                            : '?',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.account.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'إدارة المعاملات والأرصدة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // بطاقة المعلومات الأساسية
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.phone, color: primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'رقم الهاتف:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.account.phone,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'الرصيد الحالي:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.account.balance.abs().toStringAsFixed(0)} ريال يمني',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.account.balance == 0
                                ? Colors.grey
                                : (widget.account.balance > 0
                                      ? Colors.green
                                      : Colors.red),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.account.balance >= 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.account.balance >= 0 ? 'له' : 'عليه',
                        style: TextStyle(
                          color: widget.account.balance >= 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // عنوان قسم المعاملات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.history, color: primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'سجل المعاملات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${transactions.length} معاملة',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // قائمة المعاملات
              if (transactions.isEmpty)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد معاملات مسجلة',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'سيظهر هنا سجل جميع المعاملات الخاصة بهذا الحساب',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...transactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: getTypeColor(tx['type']).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tx['type'] == 'له'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: getTypeColor(tx['type']),
                        ),
                      ),
                      title: Text(
                        tx['desc']?.isNotEmpty == true ? tx['desc'] : 'معاملة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatDate(tx['date']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: getTypeColor(tx['type']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tx['type'],
                              style: TextStyle(
                                color: getTypeColor(tx['type']),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${tx['amount']} ${tx['currency'] ?? 'ريال'}',
                                style: TextStyle(
                                  color: getTypeColor(tx['type']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${tx['balance']} رصيد',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            onSelected: (value) =>
                                _handleTransactionAction(value, index, tx),
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      color: primaryColor,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text('عرض التفاصيل'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text('تعديل'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'whatsapp',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat,
                                      color: Color(0xFF25D366),
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text('واتساب'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'sms',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sms,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text('رسالة نصية'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text('حذف'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        _showTransactionDetails(context, tx);
                      },
                    ),
                  );
                }),

              SizedBox(height: 20),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddTransactionDialog(context);
          },
          tooltip: 'إضافة معاملة',
          backgroundColor: primaryColor,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }

  void _handleTransactionAction(
    String action,
    int index,
    Map<String, dynamic> transaction,
  ) {
    switch (action) {
      case 'view':
        _showTransactionDetails(context, transaction);
        break;
      case 'edit':
        _showEditTransactionDialog(context, index, transaction);
        break;
      case 'whatsapp':
        _sendWhatsAppMessage(transaction);
        break;
      case 'sms':
        _sendSMSMessage(transaction);
        break;
      case 'delete':
        _showDeleteTransactionDialog(context, index);
        break;
    }
  }

  void _showEditAccountDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.account.name);
    final phoneController = TextEditingController(text: widget.account.phone);
    final balanceController = TextEditingController(
      text: widget.account.balance.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF016B61),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'تعديل الحساب',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'اسم الحساب', Icons.person),
                SizedBox(height: 12),
                _buildTextField(phoneController, 'رقم الهاتف', Icons.phone),
                SizedBox(height: 12),
                _buildTextField(
                  balanceController,
                  'الرصيد',
                  Icons.account_balance_wallet,
                  TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF016B61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      widget.account.phone = phoneController.text.trim();
                      widget.account.balance =
                          double.tryParse(balanceController.text) ??
                          widget.account.balance;
                      if (widget.onUpdate != null) {
                        widget.onUpdate!(widget.account);
                      }
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تعديل الحساب بنجاح'),
                          backgroundColor: Color(0xFF016B61),
                        ),
                      );
                    },
                    child: Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('تأكيد الحذف'),
            ],
          ),
          content: Text(
            'هل تريد حذف الحساب "${widget.account.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // TODO: تنفيذ حذف الحساب من القائمة الرئيسية
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // العودة للشاشة السابقة
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف الحساب بنجاح'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareAccountInfo() async {
    final message =
        '''
💼 معلومات الحساب:
👤 الاسم: ${widget.account.name}
📞 الهاتف: ${widget.account.phone}
💰 الرصيد: ${widget.account.balance.toStringAsFixed(0)} ريال يمني
📊 الحالة: ${widget.account.balance >= 0 ? 'له' : 'عليه'}
🔄 عدد المعاملات: ${transactions.length}
    ''';

    await Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ معلومات الحساب إلى الحافظة'),
        backgroundColor: Color(0xFF016B61),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String transactionType = 'له';

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF016B61),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'إضافة معاملة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  descController,
                  'وصف المعاملة',
                  Icons.description,
                ),
                SizedBox(height: 12),
                _buildTextField(
                  amountController,
                  'المبلغ',
                  Icons.attach_money,
                  TextInputType.number,
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF70B2B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: transactionType,
                    decoration: InputDecoration(
                      labelText: 'نوع المعاملة',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'له',
                        child: Text(
                          'له',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'عليه',
                        child: Text(
                          'عليه',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      transactionType = value ?? 'له';
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF016B61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      final newBalance = transactionType == 'له'
                          ? widget.account.balance + amount
                          : widget.account.balance - amount;

                      final newTransaction = {
                        'date': DateTime.now().toIso8601String(),
                        'type': transactionType,
                        'amount': amount,
                        'currency': 'ريال يمني',
                        'desc': descController.text,
                        'balance': newBalance,
                      };

                      widget.account.transactions.insert(0, newTransaction);
                      widget.account.balance = newBalance;

                      if (widget.onUpdate != null) {
                        widget.onUpdate!(widget.account);
                      }
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إضافة المعاملة بنجاح'),
                          backgroundColor: Color(0xFF016B61),
                        ),
                      );
                    },
                    child: Text('إضافة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionDialog(
    BuildContext context,
    int index,
    Map<String, dynamic> transaction,
  ) {
    final descController = TextEditingController(text: transaction['desc']);
    final amountController = TextEditingController(
      text: transaction['amount'].toString(),
    );
    String transactionType = transaction['type'];

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF016B61),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'تعديل المعاملة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  descController,
                  'وصف المعاملة',
                  Icons.description,
                ),
                SizedBox(height: 12),
                _buildTextField(
                  amountController,
                  'المبلغ',
                  Icons.attach_money,
                  TextInputType.number,
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF70B2B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: transactionType,
                    decoration: InputDecoration(
                      labelText: 'نوع المعاملة',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'له',
                        child: Text(
                          'له',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'عليه',
                        child: Text(
                          'عليه',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      transactionType = value ?? 'له';
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF016B61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // TODO: تحديث المعاملة وإعادة حساب الرصيد
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تعديل المعاملة بنجاح'),
                          backgroundColor: Color(0xFF016B61),
                        ),
                      );
                    },
                    child: Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteTransactionDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('تأكيد الحذف'),
            ],
          ),
          content: Text(
            'هل تريد حذف هذه المعاملة؟ لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                widget.account.transactions.removeAt(index);
                // TODO: إعادة حساب الرصيد بعد الحذف
                if (widget.onUpdate != null) widget.onUpdate!(widget.account);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف المعاملة بنجاح'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendWhatsAppMessage(Map<String, dynamic> transaction) async {
    final message =
        '''
💼 معاملة حساب ${widget.account.name}
📝 ${transaction['desc']?.isNotEmpty == true ? transaction['desc'] : 'معاملة'}
💰 المبلغ: ${transaction['amount']} ${transaction['currency'] ?? 'ريال'}
📊 النوع: ${transaction['type']}
📅 التاريخ: ${_formatDate(transaction['date'])}
💳 الرصيد: ${transaction['balance']} ريال
    ''';

    final url = Uri.parse(
      'https://wa.me/${widget.account.phone}?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نسخ الرسالة، يمكنك الإرسال عبر واتساب'),
            backgroundColor: Color(0xFF016B61),
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ الرسالة، يمكنك الإرسال عبر واتساب'),
          backgroundColor: Color(0xFF016B61),
        ),
      );
    }
  }

  Future<void> _sendSMSMessage(Map<String, dynamic> transaction) async {
    final message =
        '''
معاملة حساب ${widget.account.name}
${transaction['desc']?.isNotEmpty == true ? transaction['desc'] : 'معاملة'}
المبلغ: ${transaction['amount']} ${transaction['currency'] ?? 'ريال'}
النوع: ${transaction['type']}
التاريخ: ${_formatDate(transaction['date'])}
الرصيد: ${transaction['balance']} ريال
    ''';

    final url = Uri.parse(
      'sms:${widget.account.phone}?body=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نسخ الرسالة، يمكنك الإرسال كرسالة نصية'),
            backgroundColor: Color(0xFF016B61),
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ الرسالة، يمكنك الإرسال كرسالة نصية'),
          backgroundColor: Color(0xFF016B61),
        ),
      );
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF016B61),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'تفاصيل المعاملة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTransactionDetailItem(
                  '📝 الوصف',
                  transaction['desc']?.isNotEmpty == true
                      ? transaction['desc']
                      : 'لا يوجد وصف',
                ),
                _buildTransactionDetailItem(
                  '💰 المبلغ',
                  '${transaction['amount']} ${transaction['currency'] ?? 'ريال'}',
                ),
                _buildTransactionDetailItem(
                  '📅 التاريخ',
                  _formatDate(transaction['date']),
                ),
                _buildTransactionDetailItem('📊 النوع', transaction['type']),
                _buildTransactionDetailItem(
                  '💳 الرصيد بعد المعاملة',
                  '${transaction['balance']} ريال',
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('إغلاق'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF016B61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _shareTransactionInfo(transaction);
                      Navigator.of(ctx).pop();
                    },
                    child: Text('مشاركة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareTransactionInfo(Map<String, dynamic> transaction) async {
    final message =
        '''
💼 معاملة حساب ${widget.account.name}
📝 ${transaction['desc']?.isNotEmpty == true ? transaction['desc'] : 'معاملة'}
💰 المبلغ: ${transaction['amount']} ${transaction['currency'] ?? 'ريال'}
📊 النوع: ${transaction['type']}
📅 التاريخ: ${_formatDate(transaction['date'])}
💳 الرصيد: ${transaction['balance']} ريال
    ''';

    await Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ معلومات المعاملة إلى الحافظة'),
        backgroundColor: Color(0xFF016B61),
      ),
    );
  }

  Widget _buildTransactionDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Divider(height: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
  ]) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF70B2B2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(icon, color: Color(0xFF016B61), size: 20),
        ),
      ),
    );
  }
}
