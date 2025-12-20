import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Firestore Seeder - Seeds initial data to Firestore
class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all initial data
  Future<void> seedAll() async {
    print('🌱 Starting Firestore seeding...');
    
    await seedCategories();
    await seedWords();
    
    print('✅ Firestore seeding completed!');
  }

  /// Seed categories
  Future<void> seedCategories() async {
    print('📁 Seeding categories...');
    
    final batch = _firestore.batch();
    final categoriesRef = _firestore.collection(AppConstants.categoriesCollection);

    final categories = [
      {
        'id': 'math',
        'name': 'رياضيات',
        'nameEn': 'Mathematics',
        'icon': 'calculate',
        'colorValue': 0xFF4CAF50,
        'description': 'الأرقام والعمليات الحسابية',
        'wordCount': 10,
        'order': 0,
      },
      {
        'id': 'science',
        'name': 'علوم',
        'nameEn': 'Science',
        'icon': 'science',
        'colorValue': 0xFF2196F3,
        'description': 'العلوم الطبيعية والتجارب',
        'wordCount': 0,
        'order': 1,
      },
      {
        'id': 'islamic',
        'name': 'إسلامية',
        'nameEn': 'Islamic Studies',
        'icon': 'mosque',
        'colorValue': 0xFF9C27B0,
        'description': 'التربية الإسلامية',
        'wordCount': 5,
        'order': 2,
      },
      {
        'id': 'shapes',
        'name': 'أشكال',
        'nameEn': 'Shapes',
        'icon': 'category',
        'colorValue': 0xFFFF9800,
        'description': 'الأشكال الهندسية',
        'wordCount': 6,
        'order': 3,
      },
      {
        'id': 'colors',
        'name': 'ألوان',
        'nameEn': 'Colors',
        'icon': 'palette',
        'colorValue': 0xFFE91E63,
        'description': 'الألوان المختلفة',
        'wordCount': 8,
        'order': 4,
      },
      {
        'id': 'animals',
        'name': 'حيوانات',
        'nameEn': 'Animals',
        'icon': 'pets',
        'colorValue': 0xFF795548,
        'description': 'الحيوانات الأليفة والبرية',
        'wordCount': 8,
        'order': 5,
      },
      {
        'id': 'food',
        'name': 'طعام',
        'nameEn': 'Food',
        'icon': 'restaurant',
        'colorValue': 0xFFFF5722,
        'description': 'الأطعمة والمشروبات',
        'wordCount': 7,
        'order': 6,
      },
      {
        'id': 'body',
        'name': 'جسم الإنسان',
        'nameEn': 'Human Body',
        'icon': 'accessibility_new',
        'colorValue': 0xFF607D8B,
        'description': 'أعضاء الجسم',
        'wordCount': 8,
        'order': 7,
      },
      {
        'id': 'family',
        'name': 'العائلة',
        'nameEn': 'Family',
        'icon': 'family_restroom',
        'colorValue': 0xFF8BC34A,
        'description': 'أفراد العائلة',
        'wordCount': 6,
        'order': 8,
      },
      {
        'id': 'clothes',
        'name': 'ملابس',
        'nameEn': 'Clothes',
        'icon': 'checkroom',
        'colorValue': 0xFF00BCD4,
        'description': 'الملابس والأزياء',
        'wordCount': 0,
        'order': 9,
      },
      {
        'id': 'home',
        'name': 'المنزل',
        'nameEn': 'Home',
        'icon': 'home',
        'colorValue': 0xFF3F51B5,
        'description': 'أثاث ومحتويات المنزل',
        'wordCount': 0,
        'order': 10,
      },
      {
        'id': 'transport',
        'name': 'مواصلات',
        'nameEn': 'Transportation',
        'icon': 'directions_car',
        'colorValue': 0xFFFFC107,
        'description': 'وسائل النقل والمواصلات',
        'wordCount': 0,
        'order': 11,
      },
    ];

    for (final category in categories) {
      final docRef = categoriesRef.doc(category['id'] as String);
      batch.set(docRef, {
        ...category,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'createdBy': 'system',
      });
    }

    await batch.commit();
    print('✅ Categories seeded: ${categories.length}');
  }

  /// Seed words
  Future<void> seedWords() async {
    print('📝 Seeding words...');
    
    final wordsRef = _firestore.collection(AppConstants.wordsCollection);
    int totalWords = 0;

    // Math words
    final mathWords = [
      {'text': 'واحد', 'textEn': 'One', 'phonetic': 'وَاحِد', 'difficulty': 1},
      {'text': 'اثنان', 'textEn': 'Two', 'phonetic': 'اِثْنَان', 'difficulty': 1},
      {'text': 'ثلاثة', 'textEn': 'Three', 'phonetic': 'ثَلَاثَة', 'difficulty': 2},
      {'text': 'أربعة', 'textEn': 'Four', 'phonetic': 'أَرْبَعَة', 'difficulty': 2},
      {'text': 'خمسة', 'textEn': 'Five', 'phonetic': 'خَمْسَة', 'difficulty': 2},
      {'text': 'ستة', 'textEn': 'Six', 'phonetic': 'سِتَّة', 'difficulty': 2},
      {'text': 'سبعة', 'textEn': 'Seven', 'phonetic': 'سَبْعَة', 'difficulty': 2},
      {'text': 'ثمانية', 'textEn': 'Eight', 'phonetic': 'ثَمَانِيَة', 'difficulty': 3},
      {'text': 'تسعة', 'textEn': 'Nine', 'phonetic': 'تِسْعَة', 'difficulty': 2},
      {'text': 'عشرة', 'textEn': 'Ten', 'phonetic': 'عَشَرَة', 'difficulty': 2},
    ];
    await _seedWordsForCategory(wordsRef, 'math', mathWords);
    totalWords += mathWords.length;

    // Colors words
    final colorWords = [
      {'text': 'أحمر', 'textEn': 'Red', 'phonetic': 'أَحْمَر', 'difficulty': 2},
      {'text': 'أزرق', 'textEn': 'Blue', 'phonetic': 'أَزْرَق', 'difficulty': 2},
      {'text': 'أخضر', 'textEn': 'Green', 'phonetic': 'أَخْضَر', 'difficulty': 2},
      {'text': 'أصفر', 'textEn': 'Yellow', 'phonetic': 'أَصْفَر', 'difficulty': 2},
      {'text': 'برتقالي', 'textEn': 'Orange', 'phonetic': 'بُرْتُقَالِي', 'difficulty': 3},
      {'text': 'أبيض', 'textEn': 'White', 'phonetic': 'أَبْيَض', 'difficulty': 2},
      {'text': 'أسود', 'textEn': 'Black', 'phonetic': 'أَسْوَد', 'difficulty': 2},
      {'text': 'بنفسجي', 'textEn': 'Purple', 'phonetic': 'بَنَفْسَجِي', 'difficulty': 3},
    ];
    await _seedWordsForCategory(wordsRef, 'colors', colorWords);
    totalWords += colorWords.length;

    // Animals words
    final animalWords = [
      {'text': 'قطة', 'textEn': 'Cat', 'phonetic': 'قِطَّة', 'difficulty': 1},
      {'text': 'كلب', 'textEn': 'Dog', 'phonetic': 'كَلْب', 'difficulty': 1},
      {'text': 'أسد', 'textEn': 'Lion', 'phonetic': 'أَسَد', 'difficulty': 2},
      {'text': 'فيل', 'textEn': 'Elephant', 'phonetic': 'فِيل', 'difficulty': 1},
      {'text': 'طائر', 'textEn': 'Bird', 'phonetic': 'طَائِر', 'difficulty': 2},
      {'text': 'سمكة', 'textEn': 'Fish', 'phonetic': 'سَمَكَة', 'difficulty': 2},
      {'text': 'دجاجة', 'textEn': 'Chicken', 'phonetic': 'دَجَاجَة', 'difficulty': 2},
      {'text': 'حصان', 'textEn': 'Horse', 'phonetic': 'حِصَان', 'difficulty': 2},
    ];
    await _seedWordsForCategory(wordsRef, 'animals', animalWords);
    totalWords += animalWords.length;

    // Shapes words
    final shapeWords = [
      {'text': 'دائرة', 'textEn': 'Circle', 'phonetic': 'دَائِرَة', 'difficulty': 2},
      {'text': 'مربع', 'textEn': 'Square', 'phonetic': 'مُرَبَّع', 'difficulty': 2},
      {'text': 'مثلث', 'textEn': 'Triangle', 'phonetic': 'مُثَلَّث', 'difficulty': 2},
      {'text': 'مستطيل', 'textEn': 'Rectangle', 'phonetic': 'مُسْتَطِيل', 'difficulty': 3},
      {'text': 'نجمة', 'textEn': 'Star', 'phonetic': 'نَجْمَة', 'difficulty': 2},
      {'text': 'قلب', 'textEn': 'Heart', 'phonetic': 'قَلْب', 'difficulty': 1},
    ];
    await _seedWordsForCategory(wordsRef, 'shapes', shapeWords);
    totalWords += shapeWords.length;

    // Body words
    final bodyWords = [
      {'text': 'رأس', 'textEn': 'Head', 'phonetic': 'رَأْس', 'difficulty': 1},
      {'text': 'عين', 'textEn': 'Eye', 'phonetic': 'عَيْن', 'difficulty': 1},
      {'text': 'أنف', 'textEn': 'Nose', 'phonetic': 'أَنْف', 'difficulty': 1},
      {'text': 'فم', 'textEn': 'Mouth', 'phonetic': 'فَم', 'difficulty': 1},
      {'text': 'أذن', 'textEn': 'Ear', 'phonetic': 'أُذُن', 'difficulty': 1},
      {'text': 'يد', 'textEn': 'Hand', 'phonetic': 'يَد', 'difficulty': 1},
      {'text': 'قدم', 'textEn': 'Foot', 'phonetic': 'قَدَم', 'difficulty': 1},
      {'text': 'أصبع', 'textEn': 'Finger', 'phonetic': 'إِصْبَع', 'difficulty': 2},
    ];
    await _seedWordsForCategory(wordsRef, 'body', bodyWords);
    totalWords += bodyWords.length;

    // Food words
    final foodWords = [
      {'text': 'تفاحة', 'textEn': 'Apple', 'phonetic': 'تُفَّاحَة', 'difficulty': 2},
      {'text': 'موز', 'textEn': 'Banana', 'phonetic': 'مَوْز', 'difficulty': 1},
      {'text': 'خبز', 'textEn': 'Bread', 'phonetic': 'خُبْز', 'difficulty': 1},
      {'text': 'حليب', 'textEn': 'Milk', 'phonetic': 'حَلِيب', 'difficulty': 2},
      {'text': 'ماء', 'textEn': 'Water', 'phonetic': 'مَاء', 'difficulty': 1},
      {'text': 'برتقالة', 'textEn': 'Orange', 'phonetic': 'بُرْتُقَالَة', 'difficulty': 3},
      {'text': 'بيضة', 'textEn': 'Egg', 'phonetic': 'بَيْضَة', 'difficulty': 2},
    ];
    await _seedWordsForCategory(wordsRef, 'food', foodWords);
    totalWords += foodWords.length;

    // Family words
    final familyWords = [
      {'text': 'أب', 'textEn': 'Father', 'phonetic': 'أَب', 'difficulty': 1},
      {'text': 'أم', 'textEn': 'Mother', 'phonetic': 'أُمّ', 'difficulty': 1},
      {'text': 'أخ', 'textEn': 'Brother', 'phonetic': 'أَخ', 'difficulty': 1},
      {'text': 'أخت', 'textEn': 'Sister', 'phonetic': 'أُخْت', 'difficulty': 1},
      {'text': 'جد', 'textEn': 'Grandfather', 'phonetic': 'جَدّ', 'difficulty': 1},
      {'text': 'جدة', 'textEn': 'Grandmother', 'phonetic': 'جَدَّة', 'difficulty': 1},
    ];
    await _seedWordsForCategory(wordsRef, 'family', familyWords);
    totalWords += familyWords.length;

    // Islamic words
    final islamicWords = [
      {'text': 'الله', 'textEn': 'Allah', 'phonetic': 'الله', 'difficulty': 1},
      {'text': 'مسجد', 'textEn': 'Mosque', 'phonetic': 'مَسْجِد', 'difficulty': 2},
      {'text': 'صلاة', 'textEn': 'Prayer', 'phonetic': 'صَلَاة', 'difficulty': 2},
      {'text': 'قرآن', 'textEn': 'Quran', 'phonetic': 'قُرْآن', 'difficulty': 2},
      {'text': 'وضوء', 'textEn': 'Ablution', 'phonetic': 'وُضُوء', 'difficulty': 2},
    ];
    await _seedWordsForCategory(wordsRef, 'islamic', islamicWords);
    totalWords += islamicWords.length;

    print('✅ Words seeded: $totalWords');
  }

  /// Helper to seed words for a category
  Future<void> _seedWordsForCategory(
    CollectionReference wordsRef,
    String categoryId,
    List<Map<String, dynamic>> words,
  ) async {
    final batch = _firestore.batch();

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final docRef = wordsRef.doc('${categoryId}_${i + 1}');
      
      batch.set(docRef, {
        'text': word['text'],
        'textEn': word['textEn'],
        'categoryId': categoryId,
        'imageUrl': '', // To be filled with actual image URL
        'correctPronunciationUrl': '', // To be filled with actual audio URL
        'description': word['textEn'],
        'phonetic': word['phonetic'],
        'difficulty': word['difficulty'],
        'practiceCount': 0,
        'createdAt': Timestamp.now(),
        'createdBy': 'system',
        'isActive': true,
        'metadata': null,
      });
    }

    await batch.commit();
  }

  /// Create a demo trainer user
  Future<void> createDemoTrainer(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'name': 'مدرب تجريبي',
      'email': 'trainer@demo.com',
      'role': 'trainer',
      'phone': '07701234567',
      'profileImageUrl': null,
      'assignedChildrenIds': [],
      'createdAt': Timestamp.now(),
      'lastLoginAt': Timestamp.now(),
      'isActive': true,
      'settings': {
        'notifications': true,
        'language': 'ar',
      },
    });
    print('✅ Demo trainer created');
  }

  /// Create demo children
  Future<void> createDemoChildren(String trainerId) async {
    final childrenRef = _firestore.collection(AppConstants.childrenCollection);
    final batch = _firestore.batch();

    final children = [
      {
        'name': 'أحمد',
        'age': 5,
        'gender': 'male',
        'level': 'مبتدئ',
        'notes': 'يحتاج تركيز على الحروف المتشابهة',
      },
      {
        'name': 'فاطمة',
        'age': 6,
        'gender': 'female',
        'level': 'متوسط',
        'notes': 'تقدم ملحوظ في الأرقام',
      },
      {
        'name': 'علي',
        'age': 4,
        'gender': 'male',
        'level': 'مبتدئ',
        'notes': 'بداية جيدة',
      },
    ];

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final docRef = childrenRef.doc('demo_child_${i + 1}');
      
      batch.set(docRef, {
        ...child,
        'trainerId': trainerId,
        'parentId': null,
        'profileImageUrl': null,
        'createdAt': Timestamp.now(),
        'updatedAt': null,
        'isActive': true,
        'additionalInfo': null,
      });
    }

    await batch.commit();
    print('✅ Demo children created: ${children.length}');

    // Update trainer's assigned children
    await _firestore.collection(AppConstants.usersCollection).doc(trainerId).update({
      'assignedChildrenIds': ['demo_child_1', 'demo_child_2', 'demo_child_3'],
    });
  }

  /// Check if data already seeded
  Future<bool> isAlreadySeeded() async {
    final categoriesSnapshot = await _firestore
        .collection(AppConstants.categoriesCollection)
        .limit(1)
        .get();
    
    return categoriesSnapshot.docs.isNotEmpty;
  }

  /// Seed only if not already seeded
  Future<void> seedIfNeeded() async {
    if (await isAlreadySeeded()) {
      print('ℹ️ Data already seeded, skipping...');
      return;
    }
    await seedAll();
  }

  /// Clear all data (USE WITH CAUTION!)
  Future<void> clearAllData() async {
    print('⚠️ Clearing all Firestore data...');
    
    final collections = [
      AppConstants.usersCollection,
      AppConstants.childrenCollection,
      AppConstants.categoriesCollection,
      AppConstants.wordsCollection,
      AppConstants.recordingsCollection,
      AppConstants.reportsCollection,
    ];

    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('🗑️ Cleared: $collection (${snapshot.docs.length} documents)');
    }

    print('✅ All data cleared');
  }
}
