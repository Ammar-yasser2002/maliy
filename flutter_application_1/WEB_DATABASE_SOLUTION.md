# حل مشكلة الويب - SQLite لا يعمل على المتصفح

## ❌ المشكلة

```
Bad state: databaseFactory not initialized
```

SQLite **لا يعمل على الويب** - يعمل فقط على Android, iOS, Windows, macOS, Linux

## ✅ الحل المطبق

تم إنشاء نظام مزدوج:

### 1. للموبايل والديسكتوب (Android/iOS/Windows/Mac/Linux)
- يستخدم **SQLite** عبر `sqflite`
- ملف: `database_helper.dart`

### 2. للويب (Web/Edge/Chrome)
- يستخدم **SharedPreferences** 
- ملف: `database_helper_web.dart`

## 🔧 كيف يعمل

الكود يكتشف المنصة تلقائياً:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // استخدم SharedPreferences
  await DatabaseHelperWeb.addClient(client);
} else {
  // استخدم SQLite
  await db.insert('clients', client.toMap());
}
```

## 📊 مقارنة

| الميزة | SQLite (موبايل) | SharedPreferences (ويب) |
|--------|-----------------|------------------------|
| السرعة | ⚡ سريع جداً | ✅ جيد |
| السعة | 📦 كبير (MBs-GBs) | ⚠️ محدود (5-10MB) |
| الاستعلامات | 🔍 SQL كاملة | ⚠️ بسيطة فقط |
| الحجم المناسب | 💼 آلاف العملاء | 👥 مئات العملاء |

## 🚀 الاستخدام

لا تحتاج لتغيير أي شيء في الكود! النظام يختار تلقائياً:

```dart
// هذا الكود يعمل على جميع المنصات
await ClientManager.addClient(client);
await ClientManager.searchClients('أحمد');
await ClientManager.deleteClient(id);
```

## ⚠️ ملاحظات مهمة للويب

1. **السعة المحدودة**: SharedPreferences يخزن حتى ~5-10MB
2. **البيانات محلية**:保存在 متصفح المستخدم فقط
3. **لا SQL**: البحث يتم في الذاكرة
4. **مناسب لـ**: مئات العملاء (ليس آلاف)

## 🎯 التشغيل على منصات مختلفة

### تشغيل على الويب:
```bash
flutter run -d chrome
# أو
flutter run -d edge
```

### تشغيل على Windows:
```bash
flutter run -d windows
```

### تشغيل على Android:
```bash
flutter run -d android
```

### تشغيل على iOS:
```bash
flutter run -d ios
```

## ✨ المميزات

✅ **كود واحد** يعمل على جميع المنصات  
✅ **اختيار تلقائي** للتقنية المناسبة  
✅ **نفس الـ API** في جميع الحالات  
✅ **سهولة الصيانة**  

## 🔮 تحسينات مستقبلية

للويب مع بيانات كبيرة، يمكنك استخدام:
- **IndexedDB** عبر `indexeddb` package
- **Drift** (SQLite للويب)
- **Backend API** مع قاعدة بيانات سحابية
