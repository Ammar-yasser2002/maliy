import 'package:flutter_application_1/screens/transfer_screen.dart';

import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/account.dart';
import '../models/theme_preset.dart';
import 'reports_screen.dart';
import 'add_transaction_sheet.dart';
import 'accounts_screen.dart';
import 'clients_screen.dart';
import 'settings_screen.dart';
import 'debt_follow_up_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onChangePreset;
  final int selectedPreset;
  final List<ThemePreset> presets;
  const HomeScreen({
    super.key,
    required this.onChangePreset,
    required this.selectedPreset,
    required this.presets,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // لوحة التحكم (الرئيسية) - لا شيء
    } else if (index == 1) {
      // الحسابات
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountsScreen(
            accounts: accounts,
            onUpdate: (updated) async {
              setState(() {
                accounts = updated;
                filteredAccounts = List.from(accounts);
              });
              await _saveAccounts(updated);
            },
          ),
        ),
      );
    } else if (index == 2) {
      // التقارير
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ReportsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // حساب الرصيد الإجمالي، له، عليه
    double total = accounts.fold(0, (p, a) => p + a.balance);
    double forMe = accounts
        .where((a) => a.balance > 0)
        .fold(0, (p, a) => p + a.balance);
    double againstMe = accounts
        .where((a) => a.balance < 0)
        .fold(0, (p, a) => p + a.balance.abs());
    String username = _savedName ?? 'المستخدم';

    return Scaffold(
      backgroundColor: Color(0xFFF4F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF70B2B2), Color(0xFF016B61)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // الاسم أولاً
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً،',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '$username!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            final dueCount = accounts.where((a) => a.balance < 0).length;
                            showDialog(
                              context: context,
                              builder: (ctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.notifications, color: Color(0xFF016B61)),
                                      SizedBox(width: 8),
                                      Text('الإشعارات'),
                                    ],
                                  ),
                                  content: Text(dueCount > 0
                                      ? 'لديك $dueCount حسابات عليها دين. يرجى مراجعة قسم الحسابات.'
                                      : 'لا يوجد إشعارات جديدة حالياً.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: Text('حسناً'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.notifications, color: Colors.white, size: 28),
                              if (accounts.any((a) => a.balance < 0))
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          tooltip: 'الإشعارات',
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(),
                              ),
                            );
                            // بعد العودة من صفحة البروفايل، أعد تحميل الصورة
                            _loadSavedProfile();
                          },
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: _avatarBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _avatarBytes!,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Color(0xFF016B61),
                                    size: 32,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Container(
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
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم أو الرقم...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF016B61)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      filteredAccounts = List.from(accounts);
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (q) {
                          setState(() {
                            _searchQuery = q.trim();
                            filteredAccounts = accounts
                                .where(
                                  (a) =>
                                      a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                      a.phone.contains(_searchQuery),
                                )
                                .toList();
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildBalanceCardWithIcon(
                            'الرصيد',
                            total,
                            Colors.blue,
                            Icons.account_balance_wallet,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildBalanceCardWithIcon(
                            'له',
                            forMe,
                            Colors.green,
                            Icons.arrow_downward,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildBalanceCardWithIcon(
                            'عليه',
                            againstMe,
                            Colors.orange,
                            Icons.arrow_upward,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildBalanceCardWithIcon(
                            'الحسابات',
                            accounts.length.toDouble(),
                            Colors.purple,
                            Icons.people,
                            isInt: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Dashboard buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    // أيقونة الحسابات في اليمين
                    _buildDashboardButton(Icons.account_circle, 'الحسابات', () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AccountsScreen(
                            accounts: accounts,
                            onUpdate: (updated) async {
                              setState(() {
                                accounts = updated;
                                filteredAccounts = List.from(accounts);
                              });
                              await _saveAccounts(updated);
                            },
                          ),
                        ),
                      );
                    }),
                    // أيقونة متابعة الديون في اليمين
                    _buildDashboardButton(
                      Icons.assignment_turned_in,
                      'متابعة الديون',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DebtFollowUpScreen(accounts: accounts),
                          ),
                        );
                      },
                    ),
                    // أيقونة العملاء في الوسط
                    _buildDashboardButton(Icons.group, 'العملاء', () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ClientsScreen()),
                      );
                    }),
                    // أيقونة الإشعارات في اليسار
                    _buildDashboardButton(Icons.notifications, 'الأشعار', () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransferScreen(accounts: accounts),
                        ),
                      );
                    }),
                    // أيقونة الإعدادات في اليسار
                    _buildDashboardButton(Icons.settings, 'الإعدادات', () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                      );
                    }),
                    // أيقونة التقارير في الوسط
                    _buildDashboardButton(Icons.receipt_long, 'التقارير', () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ReportsScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccountDialog,
        tooltip: 'إضافة',
        backgroundColor: Color(0xFF016B61),
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF016B61),
        unselectedItemColor: Colors.grey,
        onTap: _onNavBarTap,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'لوحة التحكم',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحسابات'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'التقارير',
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, double value, Color color) {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCardWithIcon(
    String title,
    double value,
    Color color,
    IconData icon, {
    bool isInt = false,
  }) {
    // تحسين تنسيق الأرقام
    String displayValue;
    Color displayColor = color;

    if (value == 0) {
      // الصفر باللون الرمادي
      displayColor = Colors.grey;
      displayValue = isInt ? '0' : '0.00';
    } else {
      // إخفاء الإشارة السالبة مع كلمة "عليه"
      displayValue = isInt
          ? value.abs().toInt().toString()
          : value.abs().toStringAsFixed(2);
    }

    return Container(
      width: 90,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: displayColor.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: displayColor, size: 22),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 2),
          Text(
            displayValue,
            style: TextStyle(
              color: displayColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              radius: 24,
              child: Icon(icon, color: Colors.blue, size: 28),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final int _currentIndex = 0;
  List<Account> accounts = [];
  List<Account> filteredAccounts = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _searchField =
      'الكل'; // خيارات: الكل، الاسم، رقم الحساب، الهاتف، الرصيد، الملاحظات
  Uint8List? _avatarBytes;
  String? _savedName;

  @override
  void initState() {
    super.initState();
    filteredAccounts = List.from(accounts);
    _loadSavedProfile();
    _loadAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String input) {
    // remove common Arabic diacritics and normalize case
    final diacritics = RegExp(r'[\u064B-\u0652\u0670]');
    return input.replaceAll(diacritics, '').toLowerCase();
  }

  Future<void> _loadSavedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString('profile_image_b64');
      final username = prefs.getString('username');
      if (b64 != null && b64.isNotEmpty) {
        setState(() {
          _avatarBytes = base64Decode(b64);
        });
      }
      if (username != null && username.isNotEmpty) {
        setState(() {
          _savedName = username;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString('accounts');
      if (accountsJson != null && accountsJson.isNotEmpty) {
        final accountsList = accountsJson
            .split('|||')
            .where((e) => e.isNotEmpty)
            .map((e) => Account.fromJson(jsonDecode(e)))
            .toList();
        setState(() {
          accounts = accountsList;
          filteredAccounts = List.from(accounts);
        });
      } else {
        setState(() {
          accounts = [];
          filteredAccounts = [];
        });
      }
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() {
        accounts = [];
        filteredAccounts = [];
      });
    }
  }

  Future<void> _saveAccounts(List<Account> accounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = accounts.map((account) => jsonEncode(account.toJson())).join('|||');
      await prefs.setString('accounts', accountsJson);
    } catch (e) {
      print('Error saving accounts: $e');
    }
  }

  void _openAddTransaction() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: AddTransactionSheet(),
      ),
    );

    if (result != null) {
      setState(() {
        // interpret transaction type: 'عليه' should be negative balance
        double amt = (result['amount'] ?? 0).toDouble();
        if ((result['type'] ?? 'له') == 'عليه') amt = -amt;
        // If an account with this name exists, update its balance instead of creating a new account
        final name = (result['name'] ?? 'حساب جديد').toString().trim();
        final idx = accounts.indexWhere(
          (a) => a.name.toLowerCase() == name.toLowerCase(),
        );
        if (idx != -1) {
          accounts[idx].balance += amt;
        } else {
          accounts.add(
            Account(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              phone: '-',
              balance: amt,
            ),
          );
        }
        // update filtered list according to current search
        if (_searchQuery.isEmpty) {
          filteredAccounts = List.from(accounts);
        } else {
          filteredAccounts = accounts.where((a) {
            final q = _searchQuery.toLowerCase();
            return a.name.toLowerCase().contains(q) ||
                a.phone.toLowerCase().contains(q);
          }).toList();
        }
      });
      await _saveAccounts(accounts);
    }
  }

  Future<void> _addAccountDialog() async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final balC = TextEditingController(text: '0');
    final notesC = TextEditingController();
    final amountC = TextEditingController();
    String operationType = 'له';
    String addType = 'حساب جديد';
    Account? selectedAccount;
    List<String> pickedImages = [];

    final form = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // صور مرفقة
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'صور مرفقة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    ...pickedImages.map(
                      (img) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(img),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_a_photo, color: Colors.blue),
                      tooltip: 'التقاط صورة',
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 60,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          pickedImages.add(base64Encode(bytes));
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.photo_library, color: Colors.green),
                      tooltip: 'اختيار من الاستديو',
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickMultiImage(
                          imageQuality: 60,
                        );
                        if (picked.isNotEmpty) {
                          for (final img in picked) {
                            final bytes = await img.readAsBytes();
                            pickedImages.add(base64Encode(bytes));
                          }
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 18,
                        child: Icon(Icons.category, color: Colors.blue),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down),
                          initialValue: addType,
                          decoration: InputDecoration(
                            labelText: 'نوع الإضافة',
                            border: InputBorder.none,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'حساب جديد',
                              child: Text('إضافة حساب جديد'),
                            ),
                            DropdownMenuItem(
                              value: 'عملية لحساب موجود',
                              child: Text('إضافة عملية لحساب موجود'),
                            ),
                          ],
                          onChanged: (v) {
                            addType = v ?? 'حساب جديد';
                            (ctx as Element).markNeedsBuild();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                if (addType == 'حساب جديد') ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          radius: 18,
                          child: Icon(Icons.person_add, color: Colors.green),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: nameC,
                            decoration: InputDecoration(
                              labelText: 'اسم الحساب',
                              border: InputBorder.none,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'أدخل الاسم'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          radius: 18,
                          child: Icon(Icons.phone, color: Colors.orange),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: phoneC,
                            decoration: InputDecoration(
                              labelText: 'رقم الهاتف',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          radius: 18,
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: balC,
                            decoration: InputDecoration(
                              labelText: 'الرصيد',
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade100,
                          radius: 18,
                          child: Icon(
                            Icons.account_circle,
                            color: Colors.blueGrey,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<Account>(
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down),
                            initialValue: selectedAccount,
                            decoration: InputDecoration(
                              labelText: 'اختر الحساب',
                              border: InputBorder.none,
                            ),
                            items: accounts
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              selectedAccount = v;
                              (ctx as Element).markNeedsBuild();
                            },
                            validator: (v) => v == null ? 'اختر حساباً' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          radius: 18,
                          child: Icon(Icons.compare_arrows, color: Colors.red),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down),
                            initialValue: operationType,
                            decoration: InputDecoration(
                              labelText: 'نوع العملية',
                              border: InputBorder.none,
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
                            onChanged: (v) {
                              operationType = v ?? 'له';
                              (ctx as Element).markNeedsBuild();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          radius: 18,
                          child: Icon(Icons.attach_money, color: Colors.teal),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: amountC,
                            decoration: InputDecoration(
                              labelText: 'المبلغ',
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'أدخل مبلغاً'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          radius: 18,
                          child: Icon(Icons.description, color: Colors.indigo),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: notesC,
                            decoration: InputDecoration(
                              labelText: 'البيان',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (form.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text('إضافة'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        if (addType == 'حساب جديد') {
          accounts.add(
            Account(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: nameC.text.trim(),
              phone: phoneC.text.trim(),
              balance: double.tryParse(balC.text) ?? 0.0,
              images: pickedImages,
            ),
          );
        } else if (addType == 'عملية لحساب موجود' && selectedAccount != null) {
          double amount = double.tryParse(amountC.text) ?? 0.0;
          if (operationType == 'له') {
            selectedAccount!.balance += amount;
          } else {
            selectedAccount!.balance -= amount;
          }
          // أضف العملية إلى قائمة معاملات الحساب
          selectedAccount!.transactions.add({
            'date': DateTime.now().toIso8601String(),
            'type': operationType,
            'amount': amount,
            'currency': 'يمني',
            'desc': notesC.text,
            'balance': selectedAccount!.balance,
            'images': List<String>.from(pickedImages),
          });
          // أضف الصور للعملية (تضاف أيضًا للحساب)
          if (pickedImages.isNotEmpty) {
            selectedAccount!.images.addAll(pickedImages);
          }
        }
      });

      if (addType == 'حساب جديد') {
        final name = nameC.text.trim();
        if (name.isNotEmpty) {
          try {
            await ClientManager.addClientIfNotExists(name, phoneC.text.trim());
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تمت إضافة الحساب، لكن فشل حفظ العميل: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      await _saveAccounts(accounts);
    }
  }
}
