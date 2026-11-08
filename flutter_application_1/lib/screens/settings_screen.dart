import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedTheme = 'افتراضي';
  String _selectedLanguage = 'العربية';
  bool _biometricEnabled = false;
  bool _isBiometricAvailable = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final List<String> _themes = ['افتراضي', 'داكن', 'فاتح'];
  final List<String> _languages = ['العربية', 'English'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricSupport();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _selectedTheme = prefs.getString('selected_theme') ?? 'افتراضي';
        _selectedLanguage = prefs.getString('selected_language') ?? 'العربية';
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error saving setting: $e');
    }
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricAvailable = isDeviceSupported && isAvailable;
      });
    } catch (e) {
      debugPrint('Error checking biometric support: $e');
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      setState(() => _biometricEnabled = false);
      await _saveSetting('biometric_enabled', false);
      _showSuccess('تم إيقاف قفل البصمة');
      return;
    }

    if (!_isBiometricAvailable) {
      _showError('ميزة البصمة غير متاحة على جهازك');
      return;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'قم بالمصادقة لتفعيل قفل البصمة',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        setState(() => _biometricEnabled = true);
        await _saveSetting('biometric_enabled', true);
        _showSuccess('تم تفعيل قفل البصمة');
      } else {
        setState(() => _biometricEnabled = false);
        _showError('لم يتم تفعيل البصمة، حاول مرة أخرى');
      }
    } catch (e) {
      setState(() => _biometricEnabled = false);
      _showError('فشل التحقق من البصمة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF70B2B2);
    final secondaryColor = Color(0xFF70B2B2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الإعدادات',
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              // الهيدر مع التدرج اللوني
              Container(
                height: 120,
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
                    Icon(
                      Icons.settings,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'الإعدادات والخصائص',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // قائمة الإعدادات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // إعدادات التطبيق
                    _buildSettingsSection(
                      'إعدادات التطبيق',
                      Icons.apps,
                      [
                        _buildSwitchItem(
                          'الإشعارات',
                          Icons.notifications_active,
                          'إدارة إشعارات التطبيق',
                          primaryColor,
                          _notificationsEnabled,
                          (value) {
                            setState(() => _notificationsEnabled = value);
                            _saveSetting('notifications_enabled', value);
                          },
                        ),
                        _buildDropdownItem(
                          'المظهر',
                          Icons.palette,
                          'تغيير مظهر التطبيق',
                          Colors.purple,
                          _selectedTheme,
                          _themes,
                          (value) {
                            setState(() => _selectedTheme = value!);
                            _saveSetting('selected_theme', value);
                          },
                        ),
                        _buildDropdownItem(
                          'اللغة',
                          Icons.language,
                          'تغيير لغة التطبيق',
                          Colors.blue,
                          _selectedLanguage,
                          _languages,
                          (value) {
                            setState(() => _selectedLanguage = value!);
                            _saveSetting('selected_language', value);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // الأمان
                    _buildSettingsSection(
                      'الأمان',
                      Icons.security,
                      [
                        _buildSwitchItem(
                          'قفل البصمة',
                          Icons.fingerprint,
                          _isBiometricAvailable
                              ? 'تفعيل القفل بالبصمة'
                              : 'ميزة البصمة غير متاحة على جهازك',
                          Colors.green,
                          _biometricEnabled,
                          _isBiometricAvailable ? _toggleBiometric : null,
                        ),
                        _buildSettingItem(
                          context,
                          'كلمة المرور',
                          Icons.lock,
                          'تغيير كلمة المرور',
                          Colors.orange,
                          () => _showPasswordSettings(context),
                        ),
                        _buildSettingItem(
                          context,
                          'خصوصية البيانات',
                          Icons.privacy_tip,
                          'إعدادات الخصوصية',
                          Colors.red,
                          () => _showPrivacySettings(context),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // البيانات
                    _buildSettingsSection(
                      'البيانات',
                      Icons.storage,
                      [
                        _buildSettingItem(
                          context,
                          'النسخ الاحتياطي',
                          Icons.backup,
                          'نسخ واستعادة البيانات',
                          secondaryColor,
                          () => _showBackupSettings(context),
                        ),
                        _buildSettingItem(
                          context,
                          'تصدير البيانات',
                          Icons.file_download,
                          'تصدير البيانات إلى ملف',
                          Colors.teal,
                          () => _showExportSettings(context),
                        ),
                        _buildSettingItem(
                          context,
                          'مسح البيانات',
                          Icons.delete_sweep,
                          'مسح جميع البيانات',
                          Colors.red,
                          () => _showClearDataSettings(context),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // التذييل
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Divider(color: Colors.grey[300]),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الإصدار 1.0.0',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'جميع الحقوق محفوظة © 2025',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    IconData icon,
    String subtitle,
    Color color,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Color(0xFF016B61),
          ),
        ),
        Divider(height: 1, color: Colors.grey[100], indent: 60),
      ],
    );
  }

  Widget _buildDropdownItem(
    String title,
    IconData icon,
    String subtitle,
    Color color,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          trailing: DropdownButton<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: TextStyle(fontSize: 12)),
            )).toList(),
            onChanged: onChanged,
            underline: SizedBox(),
          ),
        ),
        Divider(height: 1, color: Colors.grey[100], indent: 60),
      ],
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> items) {
    final primaryColor = Color(0xFF016B61);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 18),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          trailing: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(0xFF016B61).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF016B61),
              size: 12,
            ),
          ),
          onTap: onTap,
        ),
        if (title != 'مسح البيانات')
          Divider(height: 1, color: Colors.grey[100], indent: 60),
      ],
    );
  }

  void _showPasswordSettings(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock, size: 24, color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                'تغيير كلمة المرور',
                style: TextStyle(
                  color: Color(0xFF016B61),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    border: OutlineInputBorder(),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء', style: TextStyle(fontSize: 13)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF016B61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final savedPassword = prefs.getString('password');
                      
                      if (savedPassword != null && savedPassword.isNotEmpty && savedPassword != currentPasswordController.text) {
                        _showError('كلمة المرور الحالية غير صحيحة');
                        return;
                      }

                      if (newPasswordController.text == confirmPasswordController.text &&
                          newPasswordController.text.isNotEmpty) {
                        final navigator = Navigator.of(context);
                        // Save new password
                        await _saveSetting('password', newPasswordController.text);
                        if (!mounted) return;
                        navigator.pop();
                        _showSuccess('تم تغيير كلمة المرور بنجاح');
                      } else {
                        _showError('كلمات المرور غير متطابقة أو فارغة');
                      }
                    },
                    child: Text('حفظ', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.privacy_tip, size: 24, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                'خصوصية البيانات',
                style: TextStyle(
                  color: Color(0xFF016B61),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'بياناتك آمنة ومحمية. لا نشارك معلوماتك الشخصية مع أي طرف ثالث.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF016B61),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('موافق', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF70B2B2).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.backup, size: 24, color: Color(0xFF70B2B2)),
              ),
              SizedBox(height: 8),
              Text(
                'النسخ الاحتياطي',
                style: TextStyle(
                  color: Color(0xFF016B61),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر العملية المطلوبة:',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(Icons.backup),
                          label: Text('نسخ احتياطي'),
                          onPressed: () async {
                            final navigator = Navigator.of(ctx);
                            await _createBackup();
                            navigator.pop();
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(Icons.restore),
                          label: Text('استعادة'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _restoreBackup();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF016B61),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.email),
                      label: Text('إرسال النسخة عبر البريد الإلكتروني'),
                      onPressed: () async {
                        final navigator = Navigator.of(ctx);
                        await _shareBackupByEmail();
                        navigator.pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('إغلاق', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.file_download, size: 24, color: Colors.teal),
              ),
              SizedBox(height: 8),
              Text(
                'تصدير البيانات',
                style: TextStyle(
                  color: Color(0xFF016B61),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'سيتم تصدير جميع بياناتك إلى ملف JSON يمكنك مشاركته أو حفظه.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء', style: TextStyle(fontSize: 13)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF016B61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(ctx);
                      await _exportData();
                      navigator.pop();
                    },
                    child: Text('تصدير', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning, size: 24, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                'مسح البيانات',
                style: TextStyle(
                  color: Color(0xFF016B61),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            '⚠️ تحذير: هذا الإجراء سيحذف جميع بياناتك نهائياً ولا يمكن التراجع عنه. تأكد من عمل نسخة احتياطية أولاً.',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء', style: TextStyle(fontSize: 13)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(ctx);
                      await _clearAllData();
                      navigator.pop();
                    },
                    child: Text('مسح الكل', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<File> _createBackupFile() async {
    final prefs = await SharedPreferences.getInstance();
    final backupData = {
      'accounts': prefs.getString('accounts'),
      'clients': prefs.getString('clients'),
      'reminders': prefs.getStringList('reminders'),
      'username': prefs.getString('username'),
      'biometric_enabled': prefs.getBool('biometric_enabled'),
      'pin_enabled': prefs.getBool('pin_enabled'),
      'pin': prefs.getString('pin'),
      'notifications_enabled': prefs.getBool('notifications_enabled'),
      'selected_theme': prefs.getString('selected_theme'),
      'selected_language': prefs.getString('selected_language'),
      'backup_date': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(backupData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<void> _createBackup() async {
    try {
      await _createBackupFile();
      _showSuccess('تم إنشاء النسخة الاحتياطية بنجاح');
    } catch (e) {
      _showError('فشل في إنشاء النسخة الاحتياطية: $e');
    }
  }

  Future<void> _shareBackupByEmail() async {
    try {
      final file = await _createBackupFile();
      await Share.shareFiles(
        [file.path],
        subject: 'نسخة احتياطية من بيانات التطبيق',
        text: 'أرفقت نسخة احتياطية من بيانات التطبيق. يمكنك حفظها أو إرسالها إلى بريدك الإلكتروني.',
      );
      _showSuccess('تم تحضير النسخة الاحتياطية للمشاركة عبر البريد الإلكتروني');
    } catch (e) {
      _showError('فشل في إرسال النسخة الاحتياطية عبر البريد: $e');
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();

        if (backupData.containsKey('accounts')) {
          await prefs.setString('accounts', backupData['accounts'] ?? '');
        }
        if (backupData.containsKey('clients')) {
          await prefs.setString('clients', backupData['clients'] ?? '');
        }
        if (backupData.containsKey('reminders')) {
          final dynamic remindersData = backupData['reminders'];
          if (remindersData is List) {
            await prefs.setStringList('reminders', remindersData.cast<String>());
          }
        }
        if (backupData.containsKey('username')) {
          await prefs.setString('username', backupData['username'] ?? '');
        }

        _showSuccess('تم استعادة النسخة الاحتياطية بنجاح! أعد فتح التطبيق لتحديث البيانات.');
      }
    } catch (e) {
      _showError('فشل في استعادة البيانات: $e');
    }
  }

  Future<void> _exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exportData = {
        'accounts': prefs.getString('accounts'),
        'clients': prefs.getString('clients'),
        'reminders': prefs.getStringList('reminders'),
        'export_date': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(exportData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareFiles(
        [file.path],
        subject: 'تصدير بيانات التطبيق',
        text: 'مرفق ملف يحتوي على بيانات التطبيق الخاصة بك.',
      );

      _showSuccess('تم تصدير البيانات بنجاح');
    } catch (e) {
      _showError('فشل في تصدير البيانات: $e');
    }
  }

  Future<void> _clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _showSuccess('تم مسح جميع البيانات');
    } catch (e) {
      _showError('فشل في مسح البيانات: $e');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF016B61),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
