import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../database/database_helper_web.dart';

// مدير العملاء — يعتمد على SharedPreferences على جميع المنصات
// ويقوم بمزامنة البيانات تلقائياً مع SQLite على الأجهزة المحمولة عبر ClientsScreen
class ClientManager {
  static final List<Client> _clients = [];
  static bool _initialized = false;

  // تحميل العملاء من قاعدة البيانات
  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        _clients.clear();
        final dbClients = await DatabaseHelperWeb.getAllClients();
        _clients.addAll(dbClients);
        _initialized = true;
        print('✅ تم تهيئة ClientManager (${dbClients.length} عميل)');
      } catch (e) {
        print('❌ Error initializing ClientManager: $e');
      }
    }
  }

  // الحصول على قائمة العملاء
  static List<Client> get clients => List.unmodifiable(_clients);

  // إضافة عميل جديد
  static Future<void> addClient(Client client) async {
    await DatabaseHelperWeb.addClient(client);
    final newClient = client.copyWith(id: DateTime.now().millisecondsSinceEpoch.toInt());
    _clients.insert(0, newClient);
  }

  // تحديث عميل موجود
  static Future<void> updateClient(Client client) async {
    await DatabaseHelperWeb.updateClient(client);
    final index = _clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _clients[index] = client;
    }
  }

  // حذف عميل
  static Future<void> deleteClient(int id) async {
    await DatabaseHelperWeb.deleteClient(id);
    _clients.removeWhere((c) => c.id == id);
  }

  // التحقق من وجود العميل وإضافته إذا لم يكن موجوداً
  static Future<void> addClientIfNotExists(String name, String phone) async {
    if (name.isEmpty) {
      print('⚠️ اسم العميل فارغ - تم الإلغاء');
      return;
    }

    print('🔍 جارِ التحقق من وجود العميل: "$name" ($phone)');

    final exists = await DatabaseHelperWeb.clientExists(phone, name);

    if (exists) {
      print('✅ العميل موجود مسبقاً في قاعدة البيانات');
      return;
    }

    print('➕ العميل غير موجود - جارِ الإضافة...');
    final client = Client(
      name: name,
      phone: phone,
      email: '',
      address: '',
      company: '',
      notes: '',
    );

    try {
      await addClient(client);
      print('✅ تم إضافة العميل "$name" بنجاح إلى قاعدة البيانات');
    } catch (e) {
      print('❌ خطأ في إضافة العميل: $e');
      rethrow;
    }
  }

  // البحث عن العملاء
  static Future<List<Client>> searchClients(String query) async {
    return await DatabaseHelperWeb.searchClients(query);
  }

  // الحصول على عدد العملاء
  static Future<int> getClientCount() async {
    return await DatabaseHelperWeb.getClientCount();
  }

  // إعادة تحميل العملاء من قاعدة البيانات
  static Future<void> reload() async {
    _clients.clear();
    final dbClients = await DatabaseHelperWeb.getAllClients();
    _clients.addAll(dbClients);
  }
}

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _search = '';
  final TextEditingController _clientSearchController = TextEditingController();
  List<Client> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final clients = await ClientManager.searchClients(_search);
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading clients: $e');
      setState(() => _isLoading = false);
    }
  }

  void _refreshClients() {
    _loadClients();
  }

  Future<void> _addClient() async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final notesC = TextEditingController();

    final result = await showDialog<bool?>(
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
            child: Text(
              'إضافة عميل جديد',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameC, 'اسم العميل *', Icons.person, true),
                  SizedBox(height: 12),
                  _buildTextField(phoneC, 'رقم الهاتف', Icons.phone),
                  SizedBox(height: 12),
                  _buildTextField(notesC, 'ملاحظات إضافية', Icons.note),
                  SizedBox(height: 8),
                  Text(
                    '* حقل مطلوب',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
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
                    onPressed: () => Navigator.of(ctx).pop(false),
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
                      if (nameC.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('يرجى إدخال اسم العميل'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop(true);
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

    if (result == true && nameC.text.trim().isNotEmpty) {
      final newClient = Client(
        name: nameC.text.trim(),
        phone: phoneC.text.trim(),
        notes: notesC.text.trim(),
        email: '',
        address: '',
        company: '',
      );

      await ClientManager.addClient(newClient);
      _refreshClients();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة العميل ${nameC.text.trim()} بنجاح'),
          backgroundColor: Color(0xFF016B61),
        ),
      );
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    bool required = false,
    int maxLines = 1,
  ]) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF70B2B2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF016B61)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          prefixIcon: Icon(icon, color: Color(0xFF016B61), size: 20),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Future<void> _deleteClient(int idx) async {
    // تحقق من صحة الـ index
    if (idx < 0 || idx >= _clients.length) {
      print('❌ خطأ: index غير صالح ($idx)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في عملية الحذف'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog<bool>(
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
            'هل تريد حذف العميل "${_clients[idx].name}"؟ لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('حذف'),
            ),
          ],
        ),
      ),
    ).then((v) async {
      if (v == true) {
        // تحقق مرة أخرى من صحة الـ index
        if (idx < 0 || idx >= _clients.length) {
          print('❌ خطأ: index غير صالح بعد الحوار ($idx)');
          return;
        }

        final deletedClient = _clients[idx];
        if (deletedClient.id != null) {
          await ClientManager.deleteClient(deletedClient.id!);
          _refreshClients();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف العميل ${deletedClient.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _viewClientDetails(Client client) {
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
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    client.name.isNotEmpty ? client.name[0] : '?',
                    style: TextStyle(color: Color(0xFF016B61)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    client.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                _buildDetailItem('📞 الهاتف', client.phone),
                if (client.notes.isNotEmpty)
                  _buildDetailItem('📝 الملاحظات', client.notes),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF016B61),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF016B61);
    final secondaryColor = Color(0xFF70B2B2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة العملاء',
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
        backgroundColor: Color(0xFFF8FBFF),
        body: Column(
          children: [
            // شريط البحث
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _clientSearchController,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم العميل أو الهاتف...',
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  suffixIcon: _clientSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _clientSearchController.clear();
                              _search = '';
                            });
                            _loadClients();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  setState(() => _search = v.trim());
                  _loadClients(); // Search from database
                },
              ),
            ),

            // إحصائيات سريعة
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    _clients.length.toString(),
                    'إجمالي العملاء',
                    Icons.people,
                  ),
                  _buildStatItem(
                    _clients.where((c) => c.notes.isNotEmpty).length.toString(),
                    'ملاحظات',
                    Icons.note,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // قائمة العملاء
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : _clients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _search.isEmpty
                                ? 'لا يوجد عملاء مسجلين'
                                : 'لا توجد نتائج للبحث',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_search.isEmpty) ...[
                            SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                              onPressed: _addClient,
                              child: Text('إضافة أول عميل'),
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
                      itemCount: _clients.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final c = _clients[i];
                        final firstLetter = c.name.isNotEmpty ? c.name[0] : '?';
                        final avatarColors = [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.teal,
                          Colors.pink,
                        ];
                        final colorIndex =
                            c.name.hashCode % avatarColors.length;
                        final avatarColor = avatarColors[colorIndex];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
                              c.name,
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
                                        c.phone,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (c.phone.isNotEmpty)
                                      IconButton(
                                        icon: Icon(
                                          Icons.message,
                                          size: 18,
                                          color: Color(0xFF25D366),
                                        ),
                                        onPressed: () =>
                                            _openWhatsApp(c.phone, c.name),
                                        tooltip: 'إرسال عبر واتساب',
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                  ],
                                ),
                                if (c.notes.isNotEmpty)
                                  Text(
                                    '📝 ${c.notes}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: primaryColor,
                                  ),
                                  onPressed: () => _viewClientDetails(c),
                                  tooltip: 'عرض التفاصيل',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _deleteClient(_clients.indexOf(c)),
                                  tooltip: 'حذف العميل',
                                ),
                              ],
                            ),
                            onTap: () => _viewClientDetails(c),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addClient,
          tooltip: 'إضافة عميل',
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
            child: Icon(Icons.person_add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
        ),
      ],
    );
  }

  void _openWhatsApp(String phone, String name) async {
    final url = 'https://wa.me/$phone?text=مرحباً ${Uri.encodeComponent(name)}';
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
