# توثيق مشروع نظام تحسين النطق لأطفال التوحد
## Speech Therapy System for Autistic Children

---

# الفهرس

1. [مقدمة المشروع](#1-مقدمة-المشروع)
2. [التقنيات والأدوات المستخدمة](#2-التقنيات-والأدوات-المستخدمة)
3. [هيكل المشروع](#3-هيكل-المشروع)
4. [أنماط التصميم البرمجية](#4-أنماط-التصميم-البرمجية)
5. [قاعدة البيانات](#5-قاعدة-البيانات)
6. [نماذج البيانات (Models)](#6-نماذج-البيانات-models)
7. [إدارة الحالة (State Management)](#7-إدارة-الحالة-state-management)
8. [الشاشات والواجهات](#8-الشاشات-والواجهات)
9. [الخدمات (Services)](#9-الخدمات-services)
10. [تكامل الذكاء الاصطناعي](#10-تكامل-الذكاء-الاصطناعي)
11. [نظام المصادقة والصلاحيات](#11-نظام-المصادقة-والصلاحيات)
12. [معالجة الصوت](#12-معالجة-الصوت)
13. [خوارزميات التقييم](#13-خوارزميات-التقييم)
14. [أسئلة متوقعة في المناقشة](#14-أسئلة-متوقعة-في-المناقشة)

---

# 1. مقدمة المشروع

## 1.1 نظرة عامة

**اسم المشروع:** نظام تحسين النطق لأطفال التوحد
**الإصدار:** 1.0.0
**نوع التطبيق:** تطبيق متعدد المنصات (Mobile/Web)

## 1.2 الهدف من المشروع

تطوير نظام ذكي يساعد في:
- تحسين مهارات النطق لدى أطفال التوحد
- تقييم النطق باستخدام الذكاء الاصطناعي
- متابعة تقدم الطفل عبر تقارير مفصلة
- توفير بيئة تفاعلية وجذابة للأطفال

## 1.3 الفئات المستهدفة

| الفئة | الوصف |
|-------|-------|
| **المدرب (Trainer)** | أخصائي النطق الذي يدير جلسات التدريب |
| **ولي الأمر (Parent)** | يتابع تقدم طفله ويستلم التقارير |
| **المدير (Admin)** | يدير النظام والمستخدمين والمحتوى |

## 1.4 الميزات الرئيسية

1. **تسجيل صوتي:** تسجيل نطق الطفل للكلمات
2. **تحويل الصوت لنص:** باستخدام OpenAI Whisper
3. **تقييم ذكي:** باستخدام Claude AI
4. **تقارير تفصيلية:** يومية/أسبوعية/شهرية
5. **إدارة المحتوى:** أقسام وكلمات مع صور
6. **نطق تلقائي (TTS):** لنطق الكلمات للطفل

---

# 2. التقنيات والأدوات المستخدمة

## 2.1 إطار العمل الرئيسي

### Flutter
```
إطار عمل مفتوح المصدر من Google لبناء تطبيقات متعددة المنصات
```

**مميزاته:**
- كود واحد لجميع المنصات (iOS, Android, Web, Desktop)
- أداء عالي (يُترجم لكود أصلي Native)
- واجهات مستخدم جميلة وسريعة الاستجابة
- مجتمع كبير ومكتبات متنوعة

### Dart
```
لغة البرمجة المستخدمة مع Flutter
```

**خصائصها:**
- لغة كائنية التوجه (Object-Oriented)
- تدعم البرمجة غير المتزامنة (Async/Await)
- Type-safe مع دعم Null Safety
- سهلة التعلم لمن يعرف Java أو JavaScript

## 2.2 قاعدة البيانات والخدمات السحابية

### Firebase Suite

| الخدمة | الوظيفة | الإصدار |
|--------|---------|---------|
| **Firebase Core** | التهيئة الأساسية | ^3.8.1 |
| **Firebase Auth** | المصادقة وتسجيل الدخول | ^5.3.4 |
| **Cloud Firestore** | قاعدة بيانات NoSQL | ^5.6.0 |
| **Firebase Storage** | تخزين الملفات (صور/صوت) | ^12.4.0 |
| **Firebase Functions** | وظائف سحابية | Node.js |

### لماذا Firebase؟

1. **قاعدة بيانات في الوقت الفعلي:** تحديثات فورية
2. **سهولة التكامل:** مكتبات جاهزة لـ Flutter
3. **قابلية التوسع:** تتحمل ملايين المستخدمين
4. **أمان مدمج:** قواعد أمان مرنة
5. **مجاني للبداية:** خطة مجانية سخية

## 2.3 خدمات الذكاء الاصطناعي

### OpenAI Whisper API
```
خدمة تحويل الكلام إلى نص (Speech-to-Text)
```

**المميزات:**
- دقة عالية في التعرف على الكلام
- دعم اللغة العربية
- معالجة ملفات صوتية متعددة الصيغ

### Claude AI (Anthropic)
```
نموذج ذكاء اصطناعي لتقييم النطق
```

**الاستخدام:**
- تحليل مدى تطابق النطق
- توليد ملاحظات تشجيعية
- اقتراحات للتحسين

## 2.4 المكتبات الرئيسية

```yaml
dependencies:
  # إدارة الحالة
  provider: ^6.1.1

  # الصوت
  record: ^5.1.2           # تسجيل الصوت
  audioplayers: ^6.1.0     # تشغيل الصوت
  flutter_tts: ^4.0.2      # تحويل النص لكلام

  # واجهة المستخدم
  flutter_animate: ^4.5.0  # حركات وتأثيرات
  fl_chart: ^0.69.2        # رسوم بيانية
  cached_network_image: ^3.4.1  # تخزين الصور
  google_fonts: ^6.2.1     # خط Cairo العربي

  # التقارير
  pdf: ^3.11.1             # إنشاء PDF
  printing: ^5.13.4        # طباعة

  # أخرى
  image_picker: ^1.1.2     # اختيار الصور
  http: ^1.2.0             # طلبات HTTP
```

---

# 3. هيكل المشروع

## 3.1 البنية المجلدية

```
lib/
├── main.dart                 # نقطة البداية
├── config/                   # الإعدادات
│   ├── api_config.dart       # إعدادات APIs
│   ├── constants.dart        # الثوابت
│   ├── routes.dart           # مسارات التنقل
│   └── themes.dart           # السمات والألوان
├── models/                   # نماذج البيانات
│   ├── user_model.dart
│   ├── child_model.dart
│   ├── word_model.dart
│   ├── category_model.dart
│   ├── recording_model.dart
│   └── report_model.dart
├── providers/                # إدارة الحالة
│   ├── auth_provider.dart
│   ├── children_provider.dart
│   ├── categories_provider.dart
│   └── evaluation_provider.dart
├── screens/                  # الشاشات
│   ├── auth/                 # شاشات المصادقة
│   ├── dashboard/            # لوحة التحكم
│   ├── children/             # إدارة الأطفال
│   ├── categories/           # الأقسام والكلمات
│   ├── words/                # تمارين الكلمات
│   ├── recording/            # التسجيل
│   ├── evaluation/           # التقييم
│   └── reports/              # التقارير
├── services/                 # الخدمات
│   ├── whisper_service.dart
│   ├── claude_evaluation_service.dart
│   └── speech_evaluation_service.dart
├── widgets/                  # عناصر واجهة مشتركة
│   └── common/
└── utils/                    # أدوات مساعدة
    └── permissions.dart
```

## 3.2 تدفق البيانات

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Screens   │ ←→  │  Providers  │ ←→  │  Services   │
│  (الواجهة)  │     │ (إدارة الحالة)│     │  (المنطق)   │
└─────────────┘     └─────────────┘     └─────────────┘
                           ↕
                    ┌─────────────┐
                    │  Firebase   │
                    │ (قاعدة البيانات)│
                    └─────────────┘
```

---

# 4. أنماط التصميم البرمجية

## 4.1 نمط Provider (State Management)

### ما هو Provider؟
```
نمط لإدارة الحالة في Flutter يسمح بمشاركة البيانات
بين الـ Widgets دون تمريرها يدوياً
```

### مثال عملي:

```dart
// 1. تعريف Provider
class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<void> signIn(String email, String password) async {
    // ... منطق تسجيل الدخول
    _currentUser = user;
    notifyListeners(); // إشعار المستمعين بالتغيير
  }
}

// 2. توفير Provider للتطبيق
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChildrenProvider()),
      ],
      child: MyApp(),
    ),
  );
}

// 3. استخدام Provider في Widget
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // قراءة البيانات
    final user = context.watch<AuthProvider>().currentUser;

    // استدعاء دالة
    context.read<AuthProvider>().signIn(email, password);

    return Text('مرحباً ${user?.name}');
  }
}
```

### لماذا Provider؟

| الميزة | الشرح |
|--------|-------|
| **بسيط** | سهل التعلم والاستخدام |
| **فعال** | يعيد بناء Widgets المتأثرة فقط |
| **مرن** | يتكامل مع أي معمارية |
| **رسمي** | موصى به من فريق Flutter |

## 4.2 نمط Repository

### الهدف:
```
فصل منطق الوصول للبيانات عن باقي التطبيق
```

### التطبيق في المشروع:

```dart
// CategoriesProvider يعمل كـ Repository
class CategoriesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];

  // CRUD Operations
  Future<void> loadCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    _categories = snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList();

    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .set(category.toFirestore());

    _categories.add(category);
    notifyListeners();
  }
}
```

## 4.3 نمط Factory

### الاستخدام:
```
إنشاء كائنات من بيانات خارجية (Firestore, JSON)
```

### مثال:

```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // Factory Constructor من Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'trainer',
    );
  }

  // Factory Constructor من Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'trainer',
    );
  }

  // تحويل للـ Map (للحفظ)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
```

## 4.4 نمط Singleton

### الاستخدام:
```
ضمان وجود نسخة واحدة فقط من الخدمة
```

### مثال:

```dart
class WhisperService {
  // نسخة واحدة فقط
  static final WhisperService _instance = WhisperService._internal();

  // Factory constructor يرجع نفس النسخة دائماً
  factory WhisperService() => _instance;

  // Constructor خاص
  WhisperService._internal();

  Future<TranscriptionResult> transcribe(String audioPath) async {
    // ... المنطق
  }
}

// الاستخدام
final service = WhisperService(); // دائماً نفس النسخة
```

---

# 5. قاعدة البيانات

## 5.1 Cloud Firestore

### ما هو Firestore؟
```
قاعدة بيانات NoSQL سحابية من Google
تخزن البيانات في مستندات (Documents) داخل مجموعات (Collections)
```

### مميزاته:
- **NoSQL:** مرن، لا يحتاج Schema محدد
- **Real-time:** تحديثات فورية
- **Offline:** يعمل بدون إنترنت
- **Scalable:** يتوسع تلقائياً

## 5.2 هيكل قاعدة البيانات

```
firestore/
├── users/                    # المستخدمين
│   └── {userId}/
│       ├── name: string
│       ├── email: string
│       ├── role: string      # admin/trainer/parent
│       ├── phone: string?
│       ├── profileImageUrl: string?
│       ├── assignedChildrenIds: array
│       ├── createdAt: timestamp
│       ├── lastLoginAt: timestamp
│       └── isActive: boolean
│
├── children/                 # الأطفال
│   └── {childId}/
│       ├── name: string
│       ├── age: number
│       ├── gender: string    # male/female
│       ├── level: string     # مبتدئ/متوسط/متقدم
│       ├── trainerId: string
│       ├── parentId: string?
│       ├── profileImageUrl: string?
│       ├── notes: string?
│       ├── createdAt: timestamp
│       └── isActive: boolean
│
├── categories/               # أقسام الكلمات
│   └── {categoryId}/
│       ├── name: string      # بالعربي
│       ├── nameEn: string    # بالإنجليزي
│       ├── icon: string      # اسم الأيقونة
│       ├── colorValue: number
│       ├── wordCount: number
│       ├── order: number
│       └── isActive: boolean
│
├── words/                    # الكلمات
│   └── {wordId}/
│       ├── text: string      # الكلمة بالعربي
│       ├── textEn: string?   # بالإنجليزي
│       ├── categoryId: string
│       ├── imageUrl: string
│       ├── correctPronunciationUrl: string
│       ├── phonetic: string? # النطق الصوتي
│       ├── difficulty: number # 1-5
│       ├── practiceCount: number
│       └── isActive: boolean
│
├── recordings/               # التسجيلات
│   └── {recordingId}/
│       ├── childId: string
│       ├── wordId: string
│       ├── audioUrl: string
│       ├── durationMs: number
│       ├── recordedAt: timestamp
│       ├── evaluation: map   # نتائج التقييم
│       │   ├── accuracy: number
│       │   ├── similarity: number
│       │   ├── wer: number
│       │   ├── cer: number
│       │   ├── mos: number
│       │   ├── overallScore: number
│       │   ├── feedback: string
│       │   └── improvements: array
│       └── isEvaluated: boolean
│
└── reports/                  # التقارير
    └── {reportId}/
        ├── childId: string
        ├── type: string      # daily/weekly/monthly
        ├── startDate: timestamp
        ├── endDate: timestamp
        ├── metrics: map
        │   ├── totalSessions: number
        │   ├── totalRecordings: number
        │   ├── averageScore: number
        │   └── improvementRate: number
        └── generatedAt: timestamp
```

## 5.3 استعلامات Firestore

### استعلام بسيط:
```dart
// جلب كل الأطفال النشطين
final snapshot = await _firestore
    .collection('children')
    .where('isActive', isEqualTo: true)
    .get();
```

### استعلام مركب:
```dart
// جلب تسجيلات طفل معين مرتبة بالتاريخ
final snapshot = await _firestore
    .collection('recordings')
    .where('childId', isEqualTo: childId)
    .where('isEvaluated', isEqualTo: true)
    .orderBy('recordedAt', descending: true)
    .limit(10)
    .get();
```

### الاستماع للتغييرات (Real-time):
```dart
_firestore
    .collection('children')
    .where('trainerId', isEqualTo: trainerId)
    .snapshots()
    .listen((snapshot) {
      _children = snapshot.docs
          .map((doc) => ChildModel.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
```

---

# 6. نماذج البيانات (Models)

## 6.1 UserModel

```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profileImageUrl;
  final List<String> assignedChildrenIds;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  // التحقق من الدور
  bool get isAdmin => role == 'admin';
  bool get isTrainer => role == 'trainer';
  bool get isParent => role == 'parent';

  // Constructor
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.assignedChildrenIds = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  // Factory من Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'trainer',
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
      assignedChildrenIds: List<String>.from(
        data['assignedChildrenIds'] ?? []
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  // تحويل لـ Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'assignedChildrenIds': assignedChildrenIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'isActive': isActive,
    };
  }

  // نسخة معدلة (Immutable Pattern)
  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImageUrl,
    List<String>? assignedChildrenIds,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      assignedChildrenIds: assignedChildrenIds ?? this.assignedChildrenIds,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isActive: isActive,
    );
  }
}
```

## 6.2 ChildModel

```dart
class ChildModel {
  final String id;
  final String name;
  final int age;
  final String gender;      // male/female
  final String level;       // مبتدئ/متوسط/متقدم
  final String trainerId;
  final String? parentId;
  final String? profileImageUrl;
  final String? notes;
  final DateTime createdAt;
  final bool isActive;

  // الحصول على اسم الجنس بالعربي
  String get genderLabel => gender == 'male' ? 'ذكر' : 'أنثى';

  // الحصول على لون المستوى
  Color get levelColor {
    switch (level) {
      case 'مبتدئ': return Colors.green;
      case 'متوسط': return Colors.orange;
      case 'متقدم': return Colors.red;
      default: return Colors.grey;
    }
  }

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.level,
    required this.trainerId,
    this.parentId,
    this.profileImageUrl,
    this.notes,
    required this.createdAt,
    this.isActive = true,
  });

  factory ChildModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChildModel(
      id: doc.id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? 'male',
      level: data['level'] ?? 'مبتدئ',
      trainerId: data['trainerId'] ?? '',
      parentId: data['parentId'],
      profileImageUrl: data['profileImageUrl'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'level': level,
      'trainerId': trainerId,
      'parentId': parentId,
      'profileImageUrl': profileImageUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
```

## 6.3 WordModel

```dart
class WordModel {
  final String id;
  final String text;              // الكلمة بالعربي
  final String? textEn;           // بالإنجليزي (اختياري)
  final String categoryId;
  final String imageUrl;
  final String correctPronunciationUrl;  // رابط الصوت الصحيح
  final String? phonetic;         // النطق الصوتي
  final int difficulty;           // 1-5
  final int practiceCount;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;

  // الحصول على تسمية الصعوبة
  String get difficultyLabel {
    switch (difficulty) {
      case 1: return 'سهل جداً';
      case 2: return 'سهل';
      case 3: return 'متوسط';
      case 4: return 'صعب';
      case 5: return 'صعب جداً';
      default: return 'غير محدد';
    }
  }

  // الحصول على لون الصعوبة
  int get difficultyColorValue {
    switch (difficulty) {
      case 1: return 0xFF4CAF50;  // أخضر
      case 2: return 0xFF8BC34A;  // أخضر فاتح
      case 3: return 0xFFFF9800;  // برتقالي
      case 4: return 0xFFFF5722;  // برتقالي غامق
      case 5: return 0xFFF44336;  // أحمر
      default: return 0xFF9E9E9E; // رمادي
    }
  }

  WordModel({
    required this.id,
    required this.text,
    this.textEn,
    required this.categoryId,
    required this.imageUrl,
    required this.correctPronunciationUrl,
    this.phonetic,
    this.difficulty = 1,
    this.practiceCount = 0,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  // ... fromFirestore, toFirestore, copyWith
}
```

## 6.4 RecordingModel مع EvaluationData

```dart
// بيانات التقييم
class EvaluationData {
  final double accuracy;      // دقة النطق (0-100)
  final double similarity;    // التشابه (0-100)
  final double wer;           // Word Error Rate
  final double cer;           // Character Error Rate
  final double mos;           // Mean Opinion Score (1-5)
  final double overallScore;  // الدرجة الكلية (0-100)
  final String feedback;      // الملاحظات
  final List<String> improvements;  // اقتراحات التحسين
  final String encouragement; // رسالة تشجيعية

  EvaluationData({
    required this.accuracy,
    required this.similarity,
    required this.wer,
    required this.cer,
    required this.mos,
    required this.overallScore,
    required this.feedback,
    required this.improvements,
    required this.encouragement,
  });

  // الحصول على مستوى الأداء
  String get performanceLevel {
    if (overallScore >= 90) return 'ممتاز';
    if (overallScore >= 70) return 'جيد';
    if (overallScore >= 50) return 'متوسط';
    return 'يحتاج تحسين';
  }

  // لون المستوى
  Color get levelColor {
    if (overallScore >= 90) return Colors.green;
    if (overallScore >= 70) return Colors.blue;
    if (overallScore >= 50) return Colors.orange;
    return Colors.red;
  }

  factory EvaluationData.fromMap(Map<String, dynamic> map) {
    return EvaluationData(
      accuracy: (map['accuracy'] ?? 0).toDouble(),
      similarity: (map['similarity'] ?? 0).toDouble(),
      wer: (map['wer'] ?? 0).toDouble(),
      cer: (map['cer'] ?? 0).toDouble(),
      mos: (map['mos'] ?? 0).toDouble(),
      overallScore: (map['overallScore'] ?? 0).toDouble(),
      feedback: map['feedback'] ?? '',
      improvements: List<String>.from(map['improvements'] ?? []),
      encouragement: map['encouragement'] ?? '',
    );
  }
}

// نموذج التسجيل
class RecordingModel {
  final String id;
  final String childId;
  final String wordId;
  final String audioUrl;
  final int durationMs;
  final DateTime recordedAt;
  final String? transcription;  // النص المستخرج
  final EvaluationData? evaluation;
  final bool isEvaluated;

  RecordingModel({
    required this.id,
    required this.childId,
    required this.wordId,
    required this.audioUrl,
    required this.durationMs,
    required this.recordedAt,
    this.transcription,
    this.evaluation,
    this.isEvaluated = false,
  });

  // ... fromFirestore, toFirestore
}
```

---

# 7. إدارة الحالة (State Management)

## 7.1 AuthProvider

```dart
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  String? get userId => _auth.currentUser?.uid;

  AuthProvider() {
    _init();
  }

  // الاستماع لتغييرات حالة المصادقة
  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // تحميل بيانات المستخدم
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);

        // تحديث وقت آخر تسجيل دخول
        await _firestore
            .collection('users')
            .doc(uid)
            .update({'lastLoginAt': Timestamp.now()});
      }
    } catch (e) {
      _error = 'فشل في تحميل بيانات المستخدم';
    }
  }

  // تسجيل الدخول
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        _setLoading(false);
        return true;
      }

      _setError('فشل في تسجيل الدخول');
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // التسجيل
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _setLoading(true);

    try {
      // إنشاء حساب المصادقة
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // إنشاء مستند المستخدم في Firestore
        final user = UserModel(
          id: credential.user!.uid,
          name: name.trim(),
          email: email.trim(),
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toFirestore());

        _currentUser = user;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ترجمة أخطاء Firebase للعربية
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      default:
        return 'حدث خطأ في المصادقة';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
```

## 7.2 CategoriesProvider

```dart
class CategoriesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  List<WordModel> _words = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<WordModel> get words => _words;
  CategoryModel? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  // تحميل الأقسام
  Future<void> loadCategories() async {
    _setLoading(true);

    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      _categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      // إنشاء أقسام افتراضية إذا لم توجد
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }
    } catch (e) {
      _error = 'فشل في تحميل الأقسام';
    } finally {
      _setLoading(false);
    }
  }

  // تحميل كلمات قسم معين
  Future<void> loadWords(String categoryId) async {
    _setLoading(true);

    try {
      final snapshot = await _firestore
          .collection('words')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('text')
          .get();

      _words = snapshot.docs
          .map((doc) => WordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = 'فشل في تحميل الكلمات';
    } finally {
      _setLoading(false);
    }
  }

  // إضافة كلمة جديدة
  Future<WordModel?> addWord({
    required String text,
    String? textEn,
    required String categoryId,
    required String imageUrl,
    required String correctPronunciationUrl,
    String? phonetic,
    int difficulty = 1,
    required String createdBy,
  }) async {
    try {
      final docRef = _firestore.collection('words').doc();

      final word = WordModel(
        id: docRef.id,
        text: text.trim(),
        textEn: textEn?.trim(),
        categoryId: categoryId,
        imageUrl: imageUrl,
        correctPronunciationUrl: correctPronunciationUrl,
        phonetic: phonetic?.trim(),
        difficulty: difficulty,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await docRef.set(word.toFirestore());

      // تحديث عدد كلمات القسم
      await _firestore
          .collection('categories')
          .doc(categoryId)
          .update({'wordCount': FieldValue.increment(1)});

      _words.add(word);
      notifyListeners();
      return word;
    } catch (e) {
      _error = 'فشل في إضافة الكلمة';
      return null;
    }
  }

  // تحديث كلمة
  Future<bool> updateWord({
    required String wordId,
    String? text,
    String? textEn,
    String? imageUrl,
    String? correctPronunciationUrl,
    String? phonetic,
    int? difficulty,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (text != null) updates['text'] = text.trim();
      if (textEn != null) updates['textEn'] = textEn.trim();
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (correctPronunciationUrl != null) {
        updates['correctPronunciationUrl'] = correctPronunciationUrl;
      }
      if (phonetic != null) updates['phonetic'] = phonetic.trim();
      if (difficulty != null) updates['difficulty'] = difficulty;

      await _firestore
          .collection('words')
          .doc(wordId)
          .update(updates);

      // تحديث القائمة المحلية
      final index = _words.indexWhere((w) => w.id == wordId);
      if (index != -1) {
        _words[index] = _words[index].copyWith(
          text: text,
          textEn: textEn,
          imageUrl: imageUrl,
          correctPronunciationUrl: correctPronunciationUrl,
          phonetic: phonetic,
          difficulty: difficulty,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث الكلمة';
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

---

# 8. الشاشات والواجهات

## 8.1 هيكل الشاشة النموذجي

```dart
class WordPracticeScreen extends StatefulWidget {
  final WordModel word;
  final String categoryName;

  const WordPracticeScreen({
    super.key,
    required this.word,
    required this.categoryName,
  });

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  // الحالة المحلية
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // التهيئة
  }

  @override
  void dispose() {
    // التنظيف
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: Column(
        children: [
          _buildWordCard(),
          _buildRecordingControls(),
        ],
      ),
    );
  }

  Widget _buildWordCard() {
    return Card(
      child: Column(
        children: [
          Image.network(widget.word.imageUrl),
          Text(widget.word.text),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return ElevatedButton(
      onPressed: _isRecording ? _stopRecording : _startRecording,
      child: Icon(_isRecording ? Icons.stop : Icons.mic),
    );
  }

  Future<void> _startRecording() async {
    setState(() => _isRecording = true);
    // ... منطق التسجيل
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    // ... منطق الإيقاف
  }
}
```

## 8.2 التنقل بين الشاشات

```dart
// تعريف المسارات في routes.dart
class Routes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String children = '/children';
  static const String childProfile = '/children/profile';
  static const String categories = '/categories';
  static const String categoryWords = '/category-words';
  static const String wordPractice = '/word-practice';
  static const String recording = '/recording';
  static const String evaluation = '/evaluation';
  static const String reports = '/reports';

  // توليد المسارات
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen(), settings);

      case dashboard:
        return _buildRoute(const TrainerDashboard(), settings);

      case childProfile:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          ChildProfileScreen(child: args['child']),
          settings,
        );

      case categoryWords:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          CategoryWordsScreen(
            categoryId: args['categoryId'],
            categoryName: args['categoryName'],
          ),
          settings,
        );

      case wordPractice:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          WordPracticeScreen(
            word: args['word'],
            categoryName: args['categoryName'],
          ),
          settings,
        );

      default:
        return _buildRoute(
          Scaffold(body: Center(child: Text('صفحة غير موجودة'))),
          settings,
        );
    }
  }

  // بناء المسار مع حركة انتقالية
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// استخدام التنقل
Navigator.pushNamed(
  context,
  Routes.wordPractice,
  arguments: {
    'word': selectedWord,
    'categoryName': 'الحيوانات',
  },
);
```

## 8.3 Consumer و Provider في الواجهة

```dart
class CategoriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأقسام')),
      body: Consumer<CategoriesProvider>(
        builder: (context, provider, child) {
          // حالة التحميل
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // حالة الخطأ
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  ElevatedButton(
                    onPressed: () => provider.loadCategories(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          // عرض البيانات
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
            ),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return CategoryCard(
                category: category,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.categoryWords,
                  arguments: {
                    'categoryId': category.id,
                    'categoryName': category.name,
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

# 9. الخدمات (Services)

## 9.1 WhisperService - تحويل الصوت لنص

```dart
class WhisperService {
  static const String _baseUrl = 'https://api.openai.com/v1/audio/transcriptions';

  /// تحويل ملف صوتي إلى نص
  Future<TranscriptionResult> transcribeBytes({
    required Uint8List audioBytes,
    required String fileName,
    String language = 'ar',
  }) async {
    try {
      // على الويب: استخدام Firebase Function (لتجنب CORS)
      if (kIsWeb) {
        return await _transcribeViaFunction(audioBytes, fileName, language);
      }

      // على الموبايل: استدعاء مباشر لـ API
      return await _transcribeDirect(audioBytes, fileName, language);
    } catch (e) {
      return TranscriptionResult(
        success: false,
        error: 'فشل في التحويل: $e',
      );
    }
  }

  Future<TranscriptionResult> _transcribeDirect(
    Uint8List audioBytes,
    String fileName,
    String language,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

    request.headers['Authorization'] = 'Bearer ${ApiConfig.openAiApiKey}';

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      audioBytes,
      filename: fileName,
    ));

    request.fields['model'] = 'whisper-1';
    request.fields['language'] = language;

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      return TranscriptionResult(
        success: true,
        text: json['text'],
      );
    } else {
      return TranscriptionResult(
        success: false,
        error: 'خطأ: ${response.statusCode}',
      );
    }
  }

  Future<TranscriptionResult> _transcribeViaFunction(
    Uint8List audioBytes,
    String fileName,
    String language,
  ) async {
    // تشفير الصوت بـ Base64
    final base64Audio = base64Encode(audioBytes);

    final response = await http.post(
      Uri.parse(ApiConfig.whisperFunctionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'audio': base64Audio,
        'filename': fileName,
        'language': language,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return TranscriptionResult(
          success: true,
          text: json['text'],
        );
      }
    }

    return TranscriptionResult(
      success: false,
      error: 'فشل في الاتصال بالخدمة',
    );
  }
}

class TranscriptionResult {
  final bool success;
  final String? text;
  final String? error;

  TranscriptionResult({
    required this.success,
    this.text,
    this.error,
  });
}
```

## 9.2 ClaudeEvaluationService - التقييم بالذكاء الاصطناعي

```dart
class ClaudeEvaluationService {
  /// تقييم نطق الطفل
  Future<EvaluationResult> evaluate({
    required String expectedWord,
    required String transcription,
    required String childName,
    required int childAge,
    required String childLevel,
  }) async {
    try {
      if (kIsWeb) {
        return await _evaluateViaFunction(
          expectedWord, transcription, childName, childAge, childLevel,
        );
      }
      return await _evaluateDirect(
        expectedWord, transcription, childName, childAge, childLevel,
      );
    } catch (e) {
      return EvaluationResult.error('فشل في التقييم: $e');
    }
  }

  Future<EvaluationResult> _evaluateDirect(
    String expectedWord,
    String transcription,
    String childName,
    int childAge,
    String childLevel,
  ) async {
    final prompt = _buildPrompt(
      expectedWord, transcription, childName, childAge, childLevel,
    );

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ApiConfig.claudeApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-sonnet-20240229',
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final content = json['content'][0]['text'];
      return _parseResponse(content);
    }

    return EvaluationResult.error('خطأ في الاتصال');
  }

  String _buildPrompt(
    String expectedWord,
    String transcription,
    String childName,
    int childAge,
    String childLevel,
  ) {
    return '''
أنت مساعد متخصص في تقييم نطق أطفال التوحد.

معلومات الطفل:
- الاسم: $childName
- العمر: $childAge سنوات
- المستوى: $childLevel

الكلمة المطلوبة: "$expectedWord"
ما نطقه الطفل: "$transcription"

قم بتقييم النطق وأعد النتيجة بصيغة JSON:
{
  "accuracy": <0-100>,
  "similarity": <0-100>,
  "wer": <0-100>,
  "cer": <0-100>,
  "mos": <1-5>,
  "overallScore": <0-100>,
  "feedback": "<ملاحظات مشجعة بالعربي>",
  "improvements": ["<اقتراح 1>", "<اقتراح 2>"],
  "encouragement": "<رسالة تشجيعية للطفل>"
}

ملاحظات:
- كن مشجعاً ولطيفاً
- استخدم لغة بسيطة مناسبة للأطفال
- ركز على الإيجابيات أولاً
''';
  }

  EvaluationResult _parseResponse(String content) {
    try {
      // استخراج JSON من الرد
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        return EvaluationResult(
          success: true,
          data: EvaluationData.fromMap(json),
        );
      }
    } catch (e) {
      // fallback
    }

    return EvaluationResult.error('فشل في تحليل الرد');
  }
}
```

## 9.3 SpeechEvaluationService - التقييم المحلي

```dart
class SpeechEvaluationService {
  /// حساب مسافة Levenshtein بين نصين
  /// (عدد التعديلات المطلوبة لتحويل نص لآخر)
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // حذف
          matrix[i][j - 1] + 1,      // إضافة
          matrix[i - 1][j - 1] + cost, // استبدال
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// حساب نسبة التشابه
  double calculateSimilarity(String expected, String actual) {
    if (expected.isEmpty && actual.isEmpty) return 100.0;
    if (expected.isEmpty || actual.isEmpty) return 0.0;

    final cleanExpected = _cleanArabicText(expected);
    final cleanActual = _cleanArabicText(actual);

    final distance = _levenshteinDistance(cleanExpected, cleanActual);
    final maxLength = [cleanExpected.length, cleanActual.length].reduce(
      (a, b) => a > b ? a : b,
    );

    return ((maxLength - distance) / maxLength * 100).clamp(0.0, 100.0);
  }

  /// حساب Word Error Rate (نسبة خطأ الكلمات)
  double calculateWER(String expected, String actual) {
    final expectedWords = _cleanArabicText(expected).split(' ');
    final actualWords = _cleanArabicText(actual).split(' ');

    if (expectedWords.isEmpty) return actualWords.isEmpty ? 0.0 : 100.0;

    final distance = _levenshteinDistance(
      expectedWords.join(' '),
      actualWords.join(' '),
    );

    return (distance / expectedWords.length * 100).clamp(0.0, 100.0);
  }

  /// حساب Character Error Rate (نسبة خطأ الحروف)
  double calculateCER(String expected, String actual) {
    final cleanExpected = _cleanArabicText(expected);
    final cleanActual = _cleanArabicText(actual);

    if (cleanExpected.isEmpty) return cleanActual.isEmpty ? 0.0 : 100.0;

    final distance = _levenshteinDistance(cleanExpected, cleanActual);

    return (distance / cleanExpected.length * 100).clamp(0.0, 100.0);
  }

  /// حساب Mean Opinion Score (درجة الجودة 1-5)
  double calculateMOS(double similarity, double wer, double cer) {
    // معادلة مرجحة
    final score = (similarity * 0.4) +
                  ((100 - wer) * 0.35) +
                  ((100 - cer) * 0.25);

    // تحويل لمقياس 1-5
    return (score / 20).clamp(1.0, 5.0);
  }

  /// حساب الدرجة الكلية
  double calculateOverallScore({
    required double accuracy,
    required double similarity,
    required double wer,
    required double cer,
    required double mos,
  }) {
    return (accuracy * 0.30) +
           (similarity * 0.25) +
           ((100 - wer) * 0.20) +
           ((100 - cer) * 0.15) +
           (mos * 20 * 0.10);
  }

  /// تنظيف النص العربي (إزالة التشكيل)
  String _cleanArabicText(String text) {
    // إزالة التشكيل
    final diacritics = RegExp(r'[\u064B-\u065F\u0670]');
    String cleaned = text.replaceAll(diacritics, '');

    // توحيد الهمزات
    cleaned = cleaned
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');

    // إزالة المسافات الزائدة
    return cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// تقييم شامل
  EvaluationData evaluate(String expected, String actual) {
    final similarity = calculateSimilarity(expected, actual);
    final wer = calculateWER(expected, actual);
    final cer = calculateCER(expected, actual);
    final mos = calculateMOS(similarity, wer, cer);

    // الدقة (هل تطابق تماماً؟)
    final accuracy = _cleanArabicText(expected) == _cleanArabicText(actual)
        ? 100.0
        : similarity;

    final overallScore = calculateOverallScore(
      accuracy: accuracy,
      similarity: similarity,
      wer: wer,
      cer: cer,
      mos: mos,
    );

    return EvaluationData(
      accuracy: accuracy,
      similarity: similarity,
      wer: wer,
      cer: cer,
      mos: mos,
      overallScore: overallScore,
      feedback: _generateFeedback(overallScore),
      improvements: _generateImprovements(expected, actual),
      encouragement: _generateEncouragement(overallScore),
    );
  }

  String _generateFeedback(double score) {
    if (score >= 90) return 'ممتاز! نطق رائع جداً 🌟';
    if (score >= 70) return 'جيد جداً! أحسنت 👏';
    if (score >= 50) return 'جيد! استمر في المحاولة 💪';
    return 'حاول مرة أخرى، أنت تستطيع! 🎯';
  }

  String _generateEncouragement(double score) {
    if (score >= 90) return 'أنت بطل! 🏆';
    if (score >= 70) return 'عمل رائع! 🌈';
    if (score >= 50) return 'أنت تتحسن! ⭐';
    return 'لا تستسلم، حاول مرة أخرى! 💫';
  }

  List<String> _generateImprovements(String expected, String actual) {
    final improvements = <String>[];

    if (actual.length < expected.length * 0.5) {
      improvements.add('حاول نطق الكلمة كاملة');
    }
    if (actual.contains(' ') && !expected.contains(' ')) {
      improvements.add('الكلمة واحدة، انطقها متصلة');
    }

    return improvements;
  }
}
```

---

# 10. تكامل الذكاء الاصطناعي

## 10.1 OpenAI Whisper

### ما هو Whisper؟
```
نموذج ذكاء اصطناعي من OpenAI للتعرف على الكلام
يحول الصوت إلى نص بدقة عالية
```

### كيف يعمل في المشروع:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  تسجيل صوت  │ ──► │  Whisper    │ ──► │    نص      │
│   الطفل    │     │    API      │     │  مستخرج    │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                    "قِطَّة" ◄──┘
```

### المميزات:
- دعم 99+ لغة (بما فيها العربية)
- دقة عالية حتى مع الضوضاء
- يتعامل مع لهجات مختلفة

## 10.2 Claude AI

### ما هو Claude؟
```
نموذج لغوي متقدم من Anthropic
يُستخدم لتحليل وتقييم النطق بذكاء
```

### دوره في المشروع:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ الكلمة +    │ ──► │   Claude    │ ──► │   تقييم    │
│ النص المستخرج│     │     AI      │     │   شامل     │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
              ┌─────────────────────┐
              │ • نسبة الدقة       │
              │ • ملاحظات تشجيعية  │
              │ • اقتراحات تحسين   │
              │ • رسالة للطفل      │
              └─────────────────────┘
```

### لماذا Claude للتقييم؟
1. **فهم السياق:** يفهم أن المستخدم طفل ويحتاج تشجيع
2. **مرونة:** يتكيف مع مستوى الطفل
3. **لغة طبيعية:** ملاحظات بلغة بسيطة وودودة
4. **تحليل عميق:** يلاحظ أنماط الأخطاء

## 10.3 Firebase Functions

### لماذا نحتاج Functions؟
```
مشكلة CORS: المتصفح يمنع الاتصال المباشر بـ APIs خارجية
الحل: Functions تعمل كوسيط (Proxy)
```

### كيف تعمل:

```
[متصفح الويب]
      │
      ▼ (لا يوجد CORS)
[Firebase Function]
      │
      ▼ (Server-to-Server)
[OpenAI / Claude API]
```

### كود Function (Node.js):

```javascript
// functions/index.js
const functions = require('firebase-functions');
const fetch = require('node-fetch');

exports.whisperTranscribe = functions.https.onRequest(async (req, res) => {
  // السماح بـ CORS
  res.set('Access-Control-Allow-Origin', '*');

  if (req.method === 'OPTIONS') {
    res.status(200).send('');
    return;
  }

  try {
    const { audio, filename, language } = req.body;

    // فك تشفير Base64
    const audioBuffer = Buffer.from(audio, 'base64');

    // إنشاء FormData
    const FormData = require('form-data');
    const form = new FormData();
    form.append('file', audioBuffer, { filename });
    form.append('model', 'whisper-1');
    form.append('language', language || 'ar');

    // استدعاء Whisper API
    const response = await fetch(
      'https://api.openai.com/v1/audio/transcriptions',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
          ...form.getHeaders(),
        },
        body: form,
      }
    );

    const data = await response.json();

    res.json({
      success: true,
      text: data.text,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

exports.claudeEvaluate = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');

  if (req.method === 'OPTIONS') {
    res.status(200).send('');
    return;
  }

  try {
    const { expectedWord, transcription, childName, childAge, childLevel } = req.body;

    const prompt = `
أنت مساعد متخصص في تقييم نطق أطفال التوحد...
[نفس الـ prompt السابق]
`;

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 1024,
        messages: [{ role: 'user', content: prompt }],
      }),
    });

    const data = await response.json();
    const content = data.content[0].text;

    // استخراج JSON من الرد
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      res.json({
        success: true,
        evaluation: JSON.parse(jsonMatch[0]),
      });
    } else {
      throw new Error('Invalid response format');
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
```

---

# 11. نظام المصادقة والصلاحيات

## 11.1 Firebase Authentication

### طرق المصادقة المدعومة:
- البريد الإلكتروني وكلمة المرور (المستخدمة)
- Google Sign-In
- Phone Authentication
- Anonymous

### تدفق المصادقة:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    تسجيل    │ ──► │  Firebase   │ ──► │   إنشاء    │
│   الدخول   │     │    Auth     │     │   Token    │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                    ┌─────────────┐     ┌─────────────┐
                    │  Firestore  │ ◄── │   تحميل    │
                    │   (users)   │     │  البيانات  │
                    └─────────────┘     └─────────────┘
```

## 11.2 نظام الأدوار (Roles)

### الأدوار المتاحة:

| الدور | الصلاحيات |
|-------|----------|
| **admin** | كل الصلاحيات + إدارة المستخدمين |
| **trainer** | إدارة الأطفال المعينين + إنشاء محتوى |
| **parent** | عرض بيانات أطفاله فقط |

### التحقق من الصلاحيات:

```dart
// في UserModel
bool get isAdmin => role == 'admin';
bool get isTrainer => role == 'trainer';
bool get isParent => role == 'parent';

// في الواجهة
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    final user = auth.currentUser;

    // إخفاء زر الإضافة لغير المدربين
    if (user?.isTrainer != true && user?.isAdmin != true) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () => _addWord(),
      child: const Icon(Icons.add),
    );
  },
)
```

### قواعد أمان Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // دالة للتحقق من المصادقة
    function isAuthenticated() {
      return request.auth != null;
    }

    // دالة للتحقق من الدور
    function hasRole(role) {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }

    // المستخدمين
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if hasRole('admin') || request.auth.uid == userId;
    }

    // الأطفال
    match /children/{childId} {
      allow read: if isAuthenticated();
      allow create: if hasRole('admin') || hasRole('trainer');
      allow update, delete: if hasRole('admin') ||
                              resource.data.trainerId == request.auth.uid;
    }

    // الكلمات
    match /words/{wordId} {
      allow read: if isAuthenticated();
      allow write: if hasRole('admin') || hasRole('trainer');
    }

    // التسجيلات
    match /recordings/{recordingId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if hasRole('admin') || hasRole('trainer');
    }
  }
}
```

---

# 12. معالجة الصوت

## 12.1 التسجيل الصوتي

### المكتبة المستخدمة:
```yaml
record: ^5.1.2
```

### دعم المنصات:
- **iOS/Android:** تسجيل أصلي بجودة عالية
- **Web:** استخدام MediaRecorder API

### كود التسجيل:

```dart
class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  /// بدء التسجيل
  Future<bool> startRecording(String path) async {
    // التحقق من الإذن
    if (!await _recorder.hasPermission()) {
      return false;
    }

    // إعدادات التسجيل
    final config = RecordConfig(
      encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
      sampleRate: 16000,    // مناسب لـ Whisper
      bitRate: 128000,
      numChannels: 1,       // Mono
    );

    await _recorder.start(config, path: path);
    return true;
  }

  /// إيقاف التسجيل
  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  /// إلغاء التسجيل
  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }
}
```

### معالجة الويب:

```dart
// recording_screen_web.dart
import 'dart:html' as html;

/// قراءة ملف من Blob URL
Future<Uint8List?> readBlobUrl(String blobUrl) async {
  try {
    final xhr = html.HttpRequest();
    xhr.open('GET', blobUrl);
    xhr.responseType = 'arraybuffer';

    final completer = Completer<Uint8List?>();

    xhr.onLoad.listen((_) {
      if (xhr.status == 200) {
        final buffer = xhr.response as ByteBuffer;
        completer.complete(buffer.asUint8List());
      } else {
        completer.complete(null);
      }
    });

    xhr.send();
    return await completer.future;
  } catch (e) {
    return null;
  }
}
```

## 12.2 تشغيل الصوت

### المكتبة المستخدمة:
```yaml
audioplayers: ^6.1.0
```

### كود التشغيل:

```dart
final AudioPlayer _audioPlayer = AudioPlayer();

/// تشغيل من URL
Future<void> playFromUrl(String url) async {
  await _audioPlayer.stop();
  await _audioPlayer.play(UrlSource(url));
}

/// تشغيل من ملف محلي
Future<void> playFromFile(String path) async {
  await _audioPlayer.stop();
  await _audioPlayer.play(DeviceFileSource(path));
}

/// الاستماع لنهاية التشغيل
_audioPlayer.onPlayerComplete.listen((_) {
  setState(() => _isPlaying = false);
});
```

## 12.3 Text-to-Speech (TTS)

### المكتبة المستخدمة:
```yaml
flutter_tts: ^4.0.2
```

### الإعداد:

```dart
final FlutterTts _tts = FlutterTts();

Future<void> initTts() async {
  // تعيين اللغة العربية
  await _tts.setLanguage('ar-SA');

  // سرعة بطيئة للأطفال
  await _tts.setSpeechRate(0.4);

  // مستوى الصوت
  await _tts.setVolume(1.0);

  // طبقة الصوت
  await _tts.setPitch(1.0);

  // معالج الانتهاء
  _tts.setCompletionHandler(() {
    setState(() => _isSpeaking = false);
  });
}

/// نطق كلمة
Future<void> speak(String text) async {
  await _tts.stop();
  await _tts.speak(text);
}
```

### ملاحظة على الويب:
```
TTS على الويب يعتمد على دعم المتصفح
قد لا تتوفر اللغة العربية في كل المتصفحات
```

---

# 13. خوارزميات التقييم

## 13.1 خوارزمية Levenshtein Distance

### الشرح:
```
تحسب عدد التعديلات المطلوبة لتحويل نص إلى آخر
التعديلات: إضافة، حذف، أو استبدال حرف
```

### مثال:
```
النص 1: "قطة"
النص 2: "قطه"

التعديلات: استبدال 'ة' بـ 'ه' = 1 تعديل
المسافة = 1
```

### الكود:
```dart
int levenshteinDistance(String s1, String s2) {
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  // إنشاء مصفوفة
  List<List<int>> dp = List.generate(
    s1.length + 1,
    (_) => List.filled(s2.length + 1, 0),
  );

  // تهيئة الصف والعمود الأول
  for (int i = 0; i <= s1.length; i++) dp[i][0] = i;
  for (int j = 0; j <= s2.length; j++) dp[0][j] = j;

  // ملء المصفوفة
  for (int i = 1; i <= s1.length; i++) {
    for (int j = 1; j <= s2.length; j++) {
      int cost = s1[i-1] == s2[j-1] ? 0 : 1;

      dp[i][j] = [
        dp[i-1][j] + 1,       // حذف
        dp[i][j-1] + 1,       // إضافة
        dp[i-1][j-1] + cost,  // استبدال أو تطابق
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return dp[s1.length][s2.length];
}
```

### التعقيد الزمني: O(n × m)
### التعقيد المكاني: O(n × m)

## 13.2 نسبة التشابه (Similarity)

### المعادلة:
```
التشابه = (الحد_الأقصى - المسافة) / الحد_الأقصى × 100
```

### مثال:
```
"قطة" vs "قطه"
المسافة = 1
الحد الأقصى = 3 (طول أطول كلمة)
التشابه = (3 - 1) / 3 × 100 = 66.7%
```

## 13.3 Word Error Rate (WER)

### الشرح:
```
نسبة الخطأ على مستوى الكلمات
يُستخدم في تقييم أنظمة التعرف على الكلام
```

### المعادلة:
```
WER = (S + D + I) / N × 100

S = عدد الاستبدالات
D = عدد الحذوفات
I = عدد الإضافات
N = عدد الكلمات في النص المرجعي
```

## 13.4 Character Error Rate (CER)

### الشرح:
```
نفس WER لكن على مستوى الحروف
أدق للغات مثل العربية
```

## 13.5 Mean Opinion Score (MOS)

### الشرح:
```
مقياس جودة من 1 إلى 5
يُحسب من المقاييس الأخرى بشكل مرجح
```

### الحساب:
```dart
double calculateMOS(double similarity, double wer, double cer) {
  final score = (similarity * 0.4) +
                ((100 - wer) * 0.35) +
                ((100 - cer) * 0.25);

  return (score / 20).clamp(1.0, 5.0);
}
```

## 13.6 الدرجة الكلية (Overall Score)

### المعادلة:
```
الدرجة = (الدقة × 0.30) +
         (التشابه × 0.25) +
         ((100 - WER) × 0.20) +
         ((100 - CER) × 0.15) +
         (MOS × 20 × 0.10)
```

### الأوزان:
| المقياس | الوزن | السبب |
|---------|-------|-------|
| الدقة | 30% | الأهم: هل نطق الكلمة صح؟ |
| التشابه | 25% | مدى قرب النطق |
| WER | 20% | أخطاء الكلمات |
| CER | 15% | أخطاء الحروف |
| MOS | 10% | الجودة العامة |

---

# 14. أسئلة متوقعة في المناقشة

## 14.1 أسئلة عامة

### س: لماذا اخترت Flutter؟
```
ج: لعدة أسباب:
1. كود واحد لجميع المنصات (iOS, Android, Web)
2. أداء عالي يقارب التطبيقات الأصلية
3. واجهات مستخدم جميلة وسريعة
4. دعم ممتاز من Google ومجتمع كبير
5. Hot Reload يسرع التطوير
```

### س: لماذا Firebase وليس قاعدة بيانات أخرى؟
```
ج: مميزات Firebase:
1. Real-time: تحديثات فورية للبيانات
2. Offline: يعمل بدون إنترنت
3. Serverless: لا حاجة لإدارة خوادم
4. أمان مدمج مع قواعد مرنة
5. تكامل سهل مع Flutter
6. خطة مجانية سخية للبداية
```

### س: ما الفرق بين NoSQL و SQL؟
```
ج:
NoSQL (Firestore):
- مرن، لا يحتاج Schema
- أفضل للقراءة السريعة
- يتوسع أفقياً بسهولة
- Documents و Collections

SQL (MySQL, PostgreSQL):
- Schema صارم
- علاقات قوية (Foreign Keys)
- استعلامات معقدة (JOIN)
- جداول وصفوف
```

## 14.2 أسئلة تقنية

### س: اشرح نمط Provider
```
ج: Provider هو نمط لإدارة الحالة في Flutter:

1. ChangeNotifier: كلاس يحمل البيانات
2. notifyListeners(): ينبه عند تغير البيانات
3. Consumer: Widget يستمع للتغييرات
4. context.read(): للقراءة مرة واحدة
5. context.watch(): للاستماع المستمر

الفوائد:
- فصل المنطق عن الواجهة
- تجنب تمرير البيانات يدوياً
- أداء جيد (يعيد بناء ما يلزم فقط)
```

### س: كيف يعمل Whisper API؟
```
ج: Whisper هو نموذج تعلم عميق للتعرف على الكلام:

1. يستقبل ملف صوتي
2. يحوله لـ Mel Spectrogram
3. يمرره عبر شبكة Transformer
4. ينتج نص مكتوب

مميزاته:
- تدريب على 680,000 ساعة صوت
- دعم 99+ لغة
- دقة عالية مع الضوضاء
```

### س: ما هو CORS ولماذا نحتاج Firebase Functions؟
```
ج: CORS = Cross-Origin Resource Sharing

المشكلة:
- المتصفح يمنع طلبات HTTP من domain لآخر
- لا يمكن استدعاء OpenAI API مباشرة من الويب

الحل:
- Firebase Function كوسيط (Proxy)
- المتصفح يتصل بـ Function (نفس الـ domain)
- Function تتصل بـ API (server-to-server، لا CORS)
```

### س: اشرح خوارزمية Levenshtein
```
ج: خوارزمية لحساب المسافة بين نصين:

- تحسب أقل عدد تعديلات لتحويل نص لآخر
- التعديلات: إضافة، حذف، استبدال

الخطوات:
1. إنشاء مصفوفة (n+1) × (m+1)
2. تهيئة الحدود (0, 1, 2, ...)
3. لكل خانة: min(أعلى+1, يسار+1, قطري+cost)
4. النتيجة في الخانة الأخيرة

التعقيد: O(n×m) زمن ومساحة
```

### س: كيف تتعامل مع الأخطاء في التطبيق؟
```
ج: عدة مستويات:

1. Try-Catch للاستثناءات:
   try {
     await api.call();
   } catch (e) {
     showError(e.message);
   }

2. حالات في Provider:
   - isLoading: عرض مؤشر تحميل
   - error: عرض رسالة خطأ
   - data: عرض البيانات

3. رسائل بالعربي:
   - ترجمة أخطاء Firebase
   - رسائل واضحة للمستخدم

4. Fallback:
   - TTS إذا فشل الصوت
   - تقييم محلي إذا فشل AI
```

## 14.3 أسئلة عن المشروع

### س: لماذا اخترت أطفال التوحد؟
```
ج:
1. حاجة حقيقية: صعوبات النطق شائعة عندهم
2. نقص الأدوات: قلة التطبيقات العربية المتخصصة
3. التكنولوجيا مفيدة: AI يساعد في التقييم الموضوعي
4. بيئة آمنة: التطبيق لا يحكم، يشجع
```

### س: كيف يساعد التطبيق في تحسين النطق؟
```
ج: عدة طرق:

1. الاستماع للنطق الصحيح:
   - TTS أو صوت مسجل
   - تكرار عدة مرات

2. التسجيل والتقييم:
   - تسجيل نطق الطفل
   - تحليل بالذكاء الاصطناعي
   - ملاحظات فورية

3. التتبع والتقارير:
   - متابعة التقدم
   - تحديد نقاط الضعف
   - تقارير للأهل والمدرب

4. التحفيز:
   - رسائل تشجيعية
   - نجوم ودرجات
   - واجهة ملونة وجذابة
```

### س: ما التحديات التي واجهتك؟
```
ج:
1. CORS على الويب:
   - الحل: Firebase Functions

2. TTS باللغة العربية:
   - ليس كل المتصفحات تدعمه
   - الحل: السماح برفع صوت مسجل

3. دقة التعرف على كلام الأطفال:
   - نطق غير واضح أحياناً
   - الحل: تقييم مرن مع تشجيع

4. تصميم مناسب للأطفال:
   - ألوان مريحة
   - أيقونات كبيرة
   - تعليمات بسيطة
```

### س: كيف تضمن أمان البيانات؟
```
ج: عدة طبقات:

1. Firebase Auth:
   - تسجيل دخول آمن
   - تشفير كلمات المرور

2. Firestore Rules:
   - التحقق من المصادقة
   - التحقق من الدور
   - منع الوصول غير المصرح

3. HTTPS:
   - كل الاتصالات مشفرة

4. Environment Variables:
   - API Keys في متغيرات البيئة
   - لا تُخزن في الكود
```

## 14.4 أسئلة عن التطوير المستقبلي

### س: ما الميزات التي يمكن إضافتها؟
```
ج:
1. ألعاب تعليمية تفاعلية
2. نظام مكافآت ونقاط
3. تحليل أنماط النطق بـ ML
4. دعم لغات إضافية
5. تطبيق للوالدين منفصل
6. تكامل مع أجهزة ذكية
7. جلسات فيديو مباشرة
```

### س: كيف يمكن تحسين الأداء؟
```
ج:
1. Lazy Loading للصور
2. Pagination للقوائم الطويلة
3. Caching للبيانات المتكررة
4. Compression للصوت قبل الرفع
5. تحسين استعلامات Firestore
```

---

# الخاتمة

هذا المشروع يمثل تطبيقاً عملياً لعدة مفاهيم برمجية متقدمة:

1. **تطوير متعدد المنصات** باستخدام Flutter
2. **قواعد بيانات NoSQL** مع Firebase
3. **الذكاء الاصطناعي** للتعرف على الكلام والتقييم
4. **أنماط التصميم** مثل Provider و Repository
5. **البرمجة غير المتزامنة** مع async/await
6. **أمان التطبيقات** والمصادقة
7. **خوارزميات** مثل Levenshtein Distance

المشروع يجمع بين الجانب التقني والإنساني، حيث يستخدم أحدث التقنيات لمساعدة فئة تحتاج دعماً خاصاً.

---

**إعداد:** نظام توثيق آلي
**التاريخ:** يناير 2026
**الإصدار:** 1.0
