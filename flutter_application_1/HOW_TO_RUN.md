# 🚀 تشغيل التطبيق - الدليل الكامل

## ⚠️ مشكلة الويب

التطبيق يستخدم **SQLite** الذي **لا يعمل على المتصفح**!

### ❌ خطأ الويب:
```
Bad state: databaseFactory not initialized
```

## ✅ الحل: تشغيل على Windows/Android/iOS

### الخيار 1: تشغيل على Windows (الأسهل) ⭐

```bash
# تأكد من تفعيل Windows Desktop
flutter config --enable-windows-desktop

# تشغيل على Windows
flutter run -d windows
```

### الخيار 2: تشغيل على Android

```bash
# تحقق من الأجهزة المتصلة
flutter devices

# تشغيل على Android
flutter run -d android
```

### الخيار 3: تشغيل على iOS (Mac فقط)

```bash
flutter run -d ios
```

## 🔍 التحقق من الأجهزة المتاحة

```bash
flutter devices
```

ستظهر لك قائمة مثل:
```
3 connected devices:

Windows (desktop) • windows • windows-x64    • Microsoft Windows
Chrome (web)      • chrome  • web-javascript • Google Chrome
Android (mobile)  • android • android-arm64  • Android 13
```

**اختر أي شيء عدا Chrome/Web!**

## 🎯 لماذا لا يعمل على الويب؟

| التقنية | الويب | الموبايل | الديسكتوب |
|---------|-------|----------|-----------|
| SQLite | ❌ لا يعمل | ✅ يعمل | ✅ يعمل |
| SharedPreferences | ✅ يعمل | ✅ يعمل | ✅ يعمل |

### الحل البديل للويب (مطبق جزئياً)

تم إنشاء ملف `database_helper_web.dart` الذي يستخدم `SharedPreferences` للويب، لكن:
- ⚠️ سعة محدودة (5-10MB)
- ⚠️ مناسب لمئات العملاء فقط
- ⚠️ لا يدعم SQL Queries

## 📋 الخطوات الموصى بها

### 1️⃣ تشغيل على Windows (موصى به)

```bash
# من مجلد المشروع
cd c:\Users\AlShaheen\Desktop\po\maliy\flutter_application_1

# تشغيل على Windows
flutter run -d windows
```

### 2️⃣ أو تشغيل على Android

```bash
# تأكد من توصيل هاتفك أو تشغيل Emulator
flutter run -d android
```

## 🛠️ إذا أردت استخدام الويب رغم ذلك

يجب تعديل الكود لاستخدام `DatabaseHelperWeb` فقط:

```dart
// في mini_main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // للويب فقط
  if (kIsWeb) {
    await ClientManager.initialize(); // سيستخدم SharedPreferences تلقائياً
  } else {
    await ClientManager.initialize(); // سيستخدم SQLite
  }
  
  runApp(MiniMaliApp());
}
```

## ✨ المميزات حسب المنصة

### Windows/Android/iOS (SQLite) ✅
- ⚡ سرعة عالية
- 📦 سعة كبيرة (GBs)
- 🔍 بحث SQL متقدم
- 💼 مناسب لآلاف العملاء

### Web (SharedPreferences) ⚠️
- 🌐 يعمل على المتصفح
- ⚠️ سعة محدودة (5-10MB)
- 🔍 بحث بسيط فقط
- 👥 مناسب لمئات العملاء

## 🎮 الأوامر المفيدة

```bash
#查看所有可用设备
flutter devices

# تشغيل على Windows
flutter run -d windows

# تشغيل على Android
flutter run -d android

# تشغيل على Chrome (لا ينصح به)
flutter run -d chrome

# بناء نسخة Windows
flutter build windows

# بناء نسخة Android APK
flutter build apk

# تنظيف المشروع
flutter clean

# تثبيت الاعتمادات
flutter pub get
```

## 🐛 حل المشاكل

### المشكلة: Windows not available
```bash
flutter config --enable-windows-desktop
flutter clean
flutter pub get
```

### المشكلة: Android device not found
1. فعل USB Debugging على هاتفك
2. وصل الهاتف بالكمبيوتر
3. أو استخدم Android Emulator

### المشكلة: Web database error
- هذا متوقع! SQLite لا يعمل على الويب
- استخدم Windows أو Android بدلاً من ذلك

## 📞 الخلاصة

**✅ الأفضل للتطوير:** Windows Desktop  
**✅ الأفضل للإنتاج:** Android/iOS  
**❌ لا تستخدم:** Web/Chrome (إلا للضرورة)

---

## 🎯ابدأ الآن:

```bash
cd c:\Users\AlShaheen\Desktop\po\maliy\flutter_application_1
flutter run -d windows
```

**استمتع بالتطبيق! 🚀**
