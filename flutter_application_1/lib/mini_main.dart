import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'models/theme_preset.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/clients_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات لتعمل على الويندوز والديسكتوب
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // تهيئة قاعدة البيانات
  await ClientManager.initialize();
  runApp(MiniMaliApp());
}

class MiniMaliApp extends StatefulWidget {
  const MiniMaliApp({super.key});

  @override
  State<MiniMaliApp> createState() => _MiniMaliAppState();
}

class _MiniMaliAppState extends State<MiniMaliApp> {
  // Theme presets
  final List<ThemePreset> presets = [
    ThemePreset(name: 'Blue', primary: Color(0xFF1153CC)),
    ThemePreset(name: 'Green', primary: Color(0xFF1AA27A)),
    ThemePreset(name: 'Orange', primary: Color(0xFFFA8C2F)),
  ];

  int _selectedPreset = 0;

  @override
  Widget build(BuildContext context) {
    final preset = presets[_selectedPreset];

    final theme = ThemeData(
      primaryColor: preset.primary,
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: preset.primary),
      scaffoldBackgroundColor: Color(0xFFF5F7FA),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: preset.primary),
      ),
      appBarTheme: AppBarTheme(backgroundColor: preset.primary, elevation: 2),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: preset.primary,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mini Mali',
      theme: theme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => LoginScreen(),
        '/home': (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: HomeScreen(
            onChangePreset: (i) => setState(() => _selectedPreset = i),
            selectedPreset: _selectedPreset,
            presets: presets,
          ),
        ),
        '/pdf_demo': (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: PdfDemoPage(),
        ),
      },
    );
  }
}

class PdfDemoPage extends StatefulWidget {
  const PdfDemoPage({super.key});

  @override
  State<PdfDemoPage> createState() => _PdfDemoPageState();
}

class _PdfDemoPageState extends State<PdfDemoPage> {
  final bool _loading = false;

  Future<void> _onApprovePressed() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم اعتماد كشف الحساب')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تجربة توليد إشعار تذكير')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _onApprovePressed,
            icon: _loading
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.picture_as_pdf),
            label: Text('اعتماد كشف الحساب'),
          ),
        ),
      ),
    );
  }
}


