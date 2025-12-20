# 🔥 Firebase Setup Guide

## دليل إعداد Firebase للمشروع

---

## 📋 الخطوات

### 1️⃣ إنشاء مشروع Firebase

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "Add Project" أو "إضافة مشروع"
3. أدخل اسم المشروع: `speech-therapy-app`
4. اختر إعدادات Google Analytics (اختياري)
5. انقر "Create Project"

---

### 2️⃣ إضافة تطبيق Flutter

#### للويب (Flutter Web):
1. في صفحة المشروع، انقر على أيقونة `</>`
2. سجّل التطبيق باسم: `speech-therapy-web`
3. انسخ `firebaseConfig`

#### للأندرويد:
1. انقر على أيقونة Android
2. أدخل Package name: `com.yourcompany.speech_therapy_app`
3. حمّل `google-services.json`
4. ضعه في: `android/app/google-services.json`

#### للـ iOS:
1. انقر على أيقونة Apple
2. أدخل Bundle ID: `com.yourcompany.speechTherapyApp`
3. حمّل `GoogleService-Info.plist`
4. ضعه في: `ios/Runner/GoogleService-Info.plist`

---

### 3️⃣ تفعيل الخدمات

#### Authentication:
1. اذهب إلى Build > Authentication
2. انقر "Get Started"
3. فعّل "Email/Password" من Sign-in providers

#### Firestore Database:
1. اذهب إلى Build > Firestore Database
2. انقر "Create database"
3. اختر "Start in production mode"
4. اختر الموقع الأقرب (مثال: `europe-west1`)

#### Storage:
1. اذهب إلى Build > Storage
2. انقر "Get Started"
3. اتبع التعليمات

---

### 4️⃣ تطبيق قواعد الأمان

#### Firestore Rules:
1. اذهب إلى Firestore Database > Rules
2. انسخ محتوى `firestore.rules` وألصقه
3. انقر "Publish"

#### Storage Rules:
1. اذهب إلى Storage > Rules
2. انسخ محتوى `storage.rules` وألصقه
3. انقر "Publish"

---

### 5️⃣ إنشاء Indexes

1. اذهب إلى Firestore Database > Indexes
2. انقر "Add index" لكل index في `firestore.indexes.json`

**أو** استخدم Firebase CLI:
```bash
firebase deploy --only firestore:indexes
```

---

### 6️⃣ تحديث إعدادات التطبيق

في ملف `lib/main.dart`، استبدل:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",              // ← من Firebase Console
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID",
  ),
);
```

---

### 7️⃣ تشغيل Seeder (البيانات الأولية)

أضف هذا الكود في مكان مناسب (مثلاً بعد تسجيل الدخول الأول):

```dart
import 'services/firestore_seeder.dart';

// في أي مكان مناسب
final seeder = FirestoreSeeder();
await seeder.seedIfNeeded(); // يضيف البيانات فقط إذا لم تكن موجودة
```

**أو لإضافة بيانات تجريبية كاملة:**

```dart
final seeder = FirestoreSeeder();
await seeder.seedAll();
await seeder.createDemoTrainer('trainer_uid_here');
await seeder.createDemoChildren('trainer_uid_here');
```

---

## 📁 هيكل الملفات المطلوبة

```
firestore_setup/
├── DATABASE_STRUCTURE.md      # توثيق هيكل قاعدة البيانات
├── firestore.rules            # قواعد أمان Firestore
├── storage.rules              # قواعد أمان Storage
├── firestore.indexes.json     # Indexes المطلوبة
├── seed_categories.json       # بيانات الأقسام
├── seed_words.json            # بيانات الكلمات
└── FIREBASE_SETUP.md          # هذا الملف
```

---

## 🔧 Firebase CLI (اختياري)

### تثبيت:
```bash
npm install -g firebase-tools
```

### تسجيل الدخول:
```bash
firebase login
```

### تهيئة المشروع:
```bash
firebase init
```

### نشر القواعد:
```bash
# Firestore rules و indexes
firebase deploy --only firestore

# Storage rules
firebase deploy --only storage
```

---

## ⚠️ ملاحظات مهمة

1. **لا تشارك** `google-services.json` أو `GoogleService-Info.plist` في GitHub
2. أضفها إلى `.gitignore`
3. استخدم **Environment Variables** للـ Web config في الـ production
4. فعّل **App Check** لحماية إضافية
5. راقب **Usage** في Firebase Console لتجنب التكاليف الزائدة

---

## 📞 الدعم

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
