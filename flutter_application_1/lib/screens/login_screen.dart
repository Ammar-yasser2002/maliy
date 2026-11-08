import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadBiometricSetting();
  }

  bool get _hasBiometricSupport {
    return !kIsWeb;
  }

  Future<void> _checkBiometricSupport() async {
    if (!_hasBiometricSupport) {
      setState(() {
        _isBiometricAvailable = false;
      });
      return;
    }

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricAvailable = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      print('Error checking biometric support: $e');
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }

  Future<void> _loadBiometricSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      });

      // If biometric is enabled, try to authenticate immediately
      if (_isBiometricEnabled && _isBiometricAvailable) {
        await _authenticateWithBiometrics();
      }
    } catch (e) {
      print('Error loading biometric setting: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_hasBiometricSupport) {
      _showError('المصادقة بالبصمة غير مدعومة على هذا الجهاز');
      return;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'استخدم البصمة لتسجيل الدخول',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        // Save username if not exists
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString('username') == null) {
          await prefs.setString('username', 'user');
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (e.toString().contains('notEnrolled')) {
        _showError('لم يتم تسجيل البصمة في الجهاز');
      } else if (e.toString().contains('lockedOut')) {
        _showError('تم قفل المصادقة البيومترية');
      } else {
        print('Biometric authentication error: $e');
      }
    }
  }

  Future<void> _toggleBiometric(bool? value) async {
    if (! _hasBiometricSupport) {
      _showError('المصادقة بالبصمة غير مدعومة على هذا الجهاز');
      return;
    }

    if (value == true) {
      // Try to authenticate first before enabling
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'قم بالمصادقة لتفعيل تسجيل الدخول بالبصمة',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_enabled', true);
          setState(() {
            _isBiometricEnabled = true;
          });
          _showSuccess('تم تفعيل تسجيل الدخول بالبصمة');
        }
      } catch (e) {
        setState(() {
          _isBiometricEnabled = false;
        });
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      setState(() {
        _isBiometricEnabled = false;
      });
      _showSuccess('تم إيقاف تسجيل الدخول بالبصمة');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF016B61)),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('password');
      final savedUsername = prefs.getString('username');

      if (savedPassword != null) {
        if (_passwordController.text != savedPassword) {
          setState(() {
            _error = 'كلمة المرور غير صحيحة';
            _isLoading = false;
          });
          return;
        }

        if (savedUsername != null && savedUsername != _usernameController.text) {
          setState(() {
            _error = 'اسم المستخدم غير صحيح';
            _isLoading = false;
          });
          return;
        }
      } else {
        await prefs.setString('password', _passwordController.text);
      }

      await prefs.setString('username', _usernameController.text);
    } catch (e) {
      print('فشل في حفظ بيانات تسجيل الدخول: $e');
      setState(() {
        _error = 'حدث خطأ أثناء تسجيل الدخول';
        _isLoading = false;
      });
      return;
    }

    await Future.delayed(Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _showResetPasswordDialog() async {
    final userController = TextEditingController(text: _usernameController.text);
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إعادة تعيين كلمة المرور'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userController,
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
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
                    labelText: 'تأكيد كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = userController.text.trim();
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (username.isEmpty) {
                  _showError('يرجى إدخال اسم المستخدم');
                  return;
                }
                if (newPassword.isEmpty || confirmPassword.isEmpty) {
                  _showError('يرجى إدخال كلمة المرور الجديدة وتأكيدها');
                  return;
                }
                if (newPassword != confirmPassword) {
                  _showError('كلمات المرور غير متطابقة');
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                final storedUsername = prefs.getString('username');

                if (storedUsername != null && storedUsername != username) {
                  _showError('اسم المستخدم غير متطابق مع الحساب المسجل');
                  return;
                }

                await prefs.setString('password', newPassword);
                await prefs.setString('username', username);
                Navigator.of(ctx).pop();
                _showSuccess('تم إعادة تعيين كلمة المرور بنجاح');
              },
              child: Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF016B61);
    final secondaryColor = Color(0xFF70B2B2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الجزء العلوي
                  Column(
                    children: [
                      // Header مع التصميم المحسن
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            stops: [0.3, 0.9],
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: primaryColor,
                                size: 42,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'مرحباً بعودتك',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // نموذج تسجيل الدخول
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // حقل اسم المستخدم
                              TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'اسم المستخدم',
                                  labelStyle: TextStyle(color: primaryColor),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: primaryColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: secondaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: secondaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: secondaryColor.withOpacity(0.05),
                                ),
                                validator: (value) =>
                                    _validateRequired(value, 'اسم المستخدم'),
                              ),

                              SizedBox(height: 20),

                              // حقل كلمة المرور
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  labelStyle: TextStyle(color: primaryColor),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: primaryColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: secondaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: secondaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: secondaryColor.withOpacity(0.05),
                                ),
                                validator: (value) =>
                                    _validateRequired(value, 'كلمة المرور'),
                                onFieldSubmitted: (_) => _login(),
                              ),

                              SizedBox(height: 8),

                              // نسيت كلمة المرور (اختياري)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _showResetPasswordDialog,
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 30),

                              // زر الدخول
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: primaryColor.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'دخول',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              if (_error != null) ...[
                                SizedBox(height: 20),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 24),

                              // زر البصمة
                              if (_isBiometricAvailable) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: secondaryColor.withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'أو',
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: secondaryColor.withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.fingerprint,
                                      size: 35,
                                      color: primaryColor,
                                    ),
                                    label: Text(
                                      'تسجيل الدخول بالبصمة',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    onPressed: _authenticateWithBiometrics,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // الجزء السفلي
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Divider(color: secondaryColor.withOpacity(0.3)),
                        SizedBox(height: 16),
                        Text(
                          'الإصدار 1.0.0',
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
