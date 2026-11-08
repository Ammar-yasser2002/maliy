import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/account.dart';
import 'account_details_screen.dart';
import 'clients_screen.dart';

class AccountsScreen extends StatefulWidget {
  final List<Account> accounts;
  final Function(List<Account>)? onUpdate;

  const AccountsScreen({super.key, required this.accounts, this.onUpdate});

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late List<Account> _accounts;
  final TextEditingController _searchController = TextEditingController();
  List<Account> _filteredAccounts = [];
  String _filterType = 'all'; // 'all', 'debt', 'credit'

  @override
  void initState() {
    super.initState();
    _accounts = List.from(widget.accounts);
    _filteredAccounts = List.from(_accounts);
  }

  void _applyFilters(String query) {
    setState(() {
      List<Account> filtered = List.from(_accounts);

      // Apply type filter
      if (_filterType == 'debt') {
        filtered = filtered.where((a) => a.balance < 0).toList();
      } else if (_filterType == 'credit') {
        filtered = filtered.where((a) => a.balance > 0).toList();
      }

      // Apply search filter
      if (query.isNotEmpty) {
        filtered = filtered.where((account) {
          return account.name.toLowerCase().contains(query.toLowerCase()) ||
              account.phone.contains(query);
        }).toList();
      }

      _filteredAccounts = filtered;
    });
  }

  void _filterAccounts(String query) {
    _applyFilters(query);
  }

  void _setFilterType(String type) {
    setState(() {
      _filterType = type;
    });
    _applyFilters(_searchController.text);
  }

  void _openAddAccountDialog() async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final balC = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    String balanceType = 'credit'; // 'credit' = له, 'debt' = عليه

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'إضافة حساب جديد',
            style: TextStyle(
              color: Color(0xFF016B61),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF70B2B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: nameC,
                    decoration: InputDecoration(
                      labelText: 'الاسم',
                      labelStyle: TextStyle(color: Color(0xFF016B61)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'أدخل الاسم' : null,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF70B2B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: phoneC,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      labelStyle: TextStyle(color: Color(0xFF016B61)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF70B2B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: balC,
                    decoration: InputDecoration(
                      labelText: 'الرصيد',
                      labelStyle: TextStyle(color: Color(0xFF016B61)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setDialogState(() => balanceType = 'credit'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: balanceType == 'credit'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: balanceType == 'credit'
                                  ? Colors.green
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'له',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: balanceType == 'credit'
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => balanceType = 'debt'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: balanceType == 'debt'
                                ? Colors.red.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: balanceType == 'debt'
                                  ? Colors.red
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'عليه',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: balanceType == 'debt'
                                  ? Colors.red
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF016B61),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      double balance = double.tryParse(balC.text) ?? 0.0;
      // تحويل الرصيد إلى سالب إذا كان "عليه"
      if (balanceType == 'debt' && balance > 0) {
        balance = -balance;
      }

      setState(() {
        final newAccount = Account(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameC.text.trim(),
          phone: phoneC.text.trim(),
          balance: balance,
        );
        _accounts.add(newAccount);
        _filterAccounts(_searchController.text);
      });
      widget.onUpdate?.call(List.from(_accounts));

      // إضافة العميل تلقائياً إلى قسم العملاء (حتى لو رقم الهاتف فارغ)
      final phone = phoneC.text.trim();
      final name = nameC.text.trim();

      if (name.isNotEmpty) {
        try {
          await ClientManager.addClientIfNotExists(name, phone);
        } catch (e) {
          print('❌ خطأ في إضافة العميل: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إضافة الحساب ولكن فشل إضافة العميل: $e'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة الحساب والعميل بنجاح'),
          backgroundColor: Color(0xFF016B61),
        ),
      );
    }
  }

  double get totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  int get debtorsCount {
    return _accounts.where((account) => account.balance < 0).length;
  }

  int get creditorsCount {
    return _accounts.where((account) => account.balance > 0).length;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF016B61);
    final secondaryColor = Color(0xFF70B2B2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF8FBFF),
        appBar: AppBar(
          title: Text(
            'إدارة الحسابات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
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
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => _setFilterType('all'),
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStatItem(
                      Icons.people,
                      '${_accounts.length}',
                      'إجمالي الحسابات',
                      isActive: _filterType == 'all',
                    ),
                  ),
                  InkWell(
                    onTap: () => _setFilterType('credit'),
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStatItem(
                      Icons.arrow_upward,
                      '$creditorsCount',
                      'له',
                      isActive: _filterType == 'credit',
                    ),
                  ),
                  InkWell(
                    onTap: () => _setFilterType('debt'),
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStatItem(
                      Icons.arrow_downward,
                      '$debtorsCount',
                      'عليه',
                      isActive: _filterType == 'debt',
                    ),
                  ),
                ],
              ),
            ),

            // شريط البحث
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterAccounts,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن حساب...',
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // قائمة الحسابات
            Expanded(
              child: _filteredAccounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _accounts.isEmpty
                                ? 'لا توجد حسابات بعد'
                                : 'لا توجد نتائج للبحث',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_accounts.isEmpty) ...[
                            SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                              onPressed: _openAddAccountDialog,
                              child: Text('إضافة حساب جديد'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 80,
                      ),
                      itemCount: _filteredAccounts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final acc = _filteredAccounts[index];
                        final isDebt = acc.balance < 0;
                        final balanceColor = acc.balance == 0
                            ? Colors.grey
                            : (isDebt ? Colors.red : Colors.green);
                        final firstLetter = acc.name.isNotEmpty
                            ? acc.name[0]
                            : '?';
                        final avatarColors = [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.teal,
                          Colors.pink,
                        ];
                        final colorIndex =
                            acc.name.hashCode % avatarColors.length;
                        final avatarColor = avatarColors[colorIndex];

                        return Container(
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
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: avatarColor.withOpacity(0.2),
                              child: Text(
                                firstLetter,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: avatarColor,
                                ),
                              ),
                            ),
                            title: Text(
                              acc.name,
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
                                      Icons.phone,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        acc.phone,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (acc.phone.isNotEmpty)
                                      IconButton(
                                        icon: Icon(
                                          Icons.message,
                                          size: 18,
                                          color: Color(
                                            0xFF25D366,
                                          ), // WhatsApp green
                                        ),
                                        onPressed: () => _openWhatsApp(
                                          acc.phone,
                                          acc.name,
                                          acc.balance,
                                        ),
                                        tooltip: 'إرسال عبر واتساب',
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${acc.balance.toStringAsFixed(0)} ريال',
                                  style: TextStyle(
                                    color: balanceColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDebt
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isDebt ? 'عليه' : 'له',
                                    style: TextStyle(
                                      color: balanceColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AccountDetailsScreen(
                                    account: acc,
                                    onUpdate: (updatedAcc) {
                                      setState(() {
                                        final originalIndex = _accounts
                                            .indexWhere((a) => a.id == acc.id);
                                        if (originalIndex != -1) {
                                          _accounts[originalIndex] = updatedAcc;
                                          _filterAccounts(
                                            _searchController.text,
                                          );
                                        }
                                      });
                                      widget.onUpdate?.call(
                                        List.from(_accounts),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddAccountDialog,
          tooltip: 'إضافة حساب',
          backgroundColor: primaryColor,
          elevation: 4,
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label, {
    bool isActive = false,
  }) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isActive ? 0.4 : 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(String phone, String name, double balance) async {
    final message =
        'مرحباً، $name\nرصيدك الحالي هو: ${balance.toStringAsFixed(0)} ريال';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح واتساب'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
