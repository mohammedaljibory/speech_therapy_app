# 📦 Firestore Database Structure

## هيكل قاعدة البيانات - Database Schema

---

## 📊 Collections Overview

```
firestore/
├── users/              # المستخدمين (مدربين وأولياء أمور)
├── children/           # الأطفال
├── categories/         # الأقسام (رياضيات، علوم...)
├── words/              # الكلمات
├── recordings/         # تسجيلات الأطفال
├── evaluations/        # التقييمات
└── reports/            # التقارير
```

---

## 1️⃣ Users Collection (`users`)

```javascript
users/{userId}
{
  name: "أحمد محمد",                    // اسم المستخدم
  email: "ahmed@example.com",           // البريد الإلكتروني
  role: "trainer",                      // الدور: trainer | parent | admin
  phone: "07701234567",                 // رقم الهاتف (اختياري)
  profileImageUrl: "https://...",       // صورة الملف الشخصي
  assignedChildrenIds: ["child1", "child2"], // معرفات الأطفال المسندين
  createdAt: Timestamp,                 // تاريخ الإنشاء
  lastLoginAt: Timestamp,               // آخر تسجيل دخول
  isActive: true,                       // حالة الحساب
  settings: {                           // إعدادات المستخدم
    notifications: true,
    language: "ar"
  }
}
```

---

## 2️⃣ Children Collection (`children`)

```javascript
children/{childId}
{
  name: "علي",                          // اسم الطفل
  age: 6,                               // العمر
  gender: "male",                       // الجنس: male | female
  level: "مبتدئ",                       // المستوى: مبتدئ | متوسط | متقدم
  trainerId: "trainer123",              // معرف المدرب
  parentId: "parent456",                // معرف ولي الأمر (اختياري)
  profileImageUrl: "https://...",       // صورة الطفل
  notes: "ملاحظات عن الطفل",            // ملاحظات
  createdAt: Timestamp,                 // تاريخ الإضافة
  updatedAt: Timestamp,                 // تاريخ التحديث
  isActive: true,                       // حالة النشاط
  additionalInfo: {                     // معلومات إضافية
    diagnosis: "ASD Level 1",
    therapist: "د. سارة"
  }
}
```

---

## 3️⃣ Categories Collection (`categories`)

```javascript
categories/{categoryId}
{
  name: "رياضيات",                      // اسم القسم بالعربي
  nameEn: "Mathematics",                // اسم القسم بالإنجليزي
  icon: "calculate",                    // اسم الأيقونة
  colorValue: 4283215696,               // قيمة اللون (0xFF4CAF50)
  description: "أرقام وعمليات حسابية",  // وصف القسم
  wordCount: 25,                        // عدد الكلمات
  order: 0,                             // ترتيب العرض
  isActive: true,                       // حالة النشاط
  createdAt: Timestamp,                 // تاريخ الإنشاء
  createdBy: "admin123"                 // معرف المنشئ
}
```

---

## 4️⃣ Words Collection (`words`)

```javascript
words/{wordId}
{
  text: "واحد",                         // النص العربي
  textEn: "One",                        // النص الإنجليزي (اختياري)
  categoryId: "math",                   // معرف القسم
  imageUrl: "https://storage.../one.png",      // رابط الصورة
  correctPronunciationUrl: "https://storage.../one.mp3", // رابط النطق الصحيح
  description: "الرقم واحد",            // وصف الكلمة
  phonetic: "وَاحِد",                   // النطق الصوتي
  difficulty: 1,                        // مستوى الصعوبة (1-5)
  practiceCount: 150,                   // عدد مرات التمرين
  createdAt: Timestamp,                 // تاريخ الإضافة
  createdBy: "trainer123",              // معرف المنشئ
  isActive: true,                       // حالة النشاط
  metadata: {                           // بيانات إضافية
    syllables: 2,
    category_sub: "numbers"
  }
}
```

---

## 5️⃣ Recordings Collection (`recordings`)

```javascript
recordings/{recordingId}
{
  childId: "child123",                  // معرف الطفل
  wordId: "word456",                    // معرف الكلمة
  audioUrl: "https://storage.../rec.mp3", // رابط التسجيل
  durationMs: 2500,                     // مدة التسجيل بالميلي ثانية
  recordedAt: Timestamp,                // وقت التسجيل
  sessionId: "session789",              // معرف الجلسة (لتجميع التسجيلات)
  attemptNumber: 1,                     // رقم المحاولة
  isEvaluated: true,                    // هل تم التقييم؟
  evaluation: {                         // بيانات التقييم
    accuracy: 85.5,                     // الدقة (0-100)
    similarity: 78.2,                   // التشابه (0-100)
    wer: 15.0,                          // Word Error Rate (0-100, أقل = أفضل)
    cer: 12.5,                          // Character Error Rate (0-100, أقل = أفضل)
    mos: 4.2,                           // Mean Opinion Score (1-5)
    overallScore: 82.3,                 // النتيجة الإجمالية
    transcription: "واحد",              // ما سمعه النظام
    evaluatedAt: Timestamp,             // وقت التقييم
    evaluatedBy: "auto",                // من قيّم: auto | trainerId
    feedback: "نطق جيد، حاول إطالة الحرف الأول" // ملاحظات
  },
  notes: "ملاحظات المدرب",              // ملاحظات إضافية
  metadata: {
    deviceInfo: "Android",
    appVersion: "1.0.0"
  }
}
```

---

## 6️⃣ Reports Collection (`reports`)

```javascript
reports/{reportId}
{
  childId: "child123",                  // معرف الطفل
  type: "weekly",                       // نوع التقرير: daily | weekly | monthly
  startDate: Timestamp,                 // بداية الفترة
  endDate: Timestamp,                   // نهاية الفترة
  generatedAt: Timestamp,               // وقت إنشاء التقرير
  generatedBy: "trainer123",            // معرف المنشئ
  
  metrics: {                            // الإحصائيات الإجمالية
    totalSessions: 12,                  // عدد الجلسات
    totalRecordings: 85,                // عدد التسجيلات
    totalWords: 30,                     // عدد الكلمات
    wordsCompleted: 22,                 // الكلمات المكتملة
    averageAccuracy: 78.5,              // متوسط الدقة
    averageSimilarity: 72.3,            // متوسط التشابه
    averageWer: 18.5,                   // متوسط WER
    averageCer: 15.2,                   // متوسط CER
    averageMos: 3.8,                    // متوسط MOS
    overallProgress: 12.5,              // نسبة التحسن
    practiceTimeMinutes: 180            // وقت التمرين بالدقائق
  },
  
  categoryProgress: [                   // تقدم كل قسم
    {
      categoryId: "math",
      categoryName: "رياضيات",
      totalWords: 10,
      completedWords: 8,
      averageScore: 82.5,
      progressPercentage: 80
    }
  ],
  
  topWords: [                           // أفضل الكلمات
    {
      wordId: "word1",
      wordText: "واحد",
      categoryName: "رياضيات",
      attemptCount: 5,
      bestScore: 95.0,
      latestScore: 92.0,
      improvement: 15.0
    }
  ],
  
  needsImprovementWords: [              // كلمات تحتاج تحسين
    {
      wordId: "word2",
      wordText: "ثلاثة",
      categoryName: "رياضيات",
      attemptCount: 8,
      bestScore: 45.0,
      latestScore: 50.0,
      improvement: 5.0
    }
  ],
  
  notes: "ملاحظات المدرب على التقرير",
  pdfUrl: "https://storage.../report.pdf", // رابط ملف PDF
  isSent: true,                         // هل تم الإرسال؟
  sentAt: Timestamp,                    // وقت الإرسال
  sentTo: "parent@email.com"            // أرسل إلى
}
```

---

## 🔐 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isTrainer() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'trainer';
    }
    
    function isParent() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'parent';
    }
    
    function isAdmin() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isAdmin();
    }
    
    // Children collection
    match /children/{childId} {
      allow read: if isAuthenticated() && (
        resource.data.trainerId == request.auth.uid ||
        resource.data.parentId == request.auth.uid ||
        isAdmin()
      );
      allow create: if isTrainer() || isAdmin();
      allow update: if isTrainer() && resource.data.trainerId == request.auth.uid || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Categories collection
    match /categories/{categoryId} {
      allow read: if isAuthenticated();
      allow write: if isTrainer() || isAdmin();
    }
    
    // Words collection
    match /words/{wordId} {
      allow read: if isAuthenticated();
      allow write: if isTrainer() || isAdmin();
    }
    
    // Recordings collection
    match /recordings/{recordingId} {
      allow read: if isAuthenticated();
      allow create: if isTrainer() || isAdmin();
      allow update: if isTrainer() || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if isAuthenticated();
      allow create: if isTrainer() || isAdmin();
      allow update: if isTrainer() || isAdmin();
      allow delete: if isAdmin();
    }
  }
}
```

---

## 📁 Storage Structure

```
firebase-storage/
├── images/
│   ├── words/
│   │   ├── math/
│   │   │   ├── one.png
│   │   │   ├── two.png
│   │   │   └── ...
│   │   ├── science/
│   │   └── ...
│   ├── profiles/
│   │   ├── users/
│   │   └── children/
│   └── categories/
│
├── audio/
│   ├── correct_pronunciations/
│   │   ├── math/
│   │   │   ├── one.mp3
│   │   │   └── ...
│   │   └── ...
│   └── child_recordings/
│       ├── {childId}/
│       │   ├── {date}/
│       │   │   └── {recordingId}.mp3
│       │   └── ...
│       └── ...
│
└── reports/
    └── {childId}/
        └── {reportId}.pdf
```

---

## 🔗 Indexes Required

Create these composite indexes in Firestore:

```
Collection: recordings
Fields: childId (Ascending), recordedAt (Descending)

Collection: recordings  
Fields: childId (Ascending), wordId (Ascending), recordedAt (Descending)

Collection: words
Fields: categoryId (Ascending), text (Ascending)

Collection: children
Fields: trainerId (Ascending), name (Ascending)

Collection: reports
Fields: childId (Ascending), generatedAt (Descending)
```
