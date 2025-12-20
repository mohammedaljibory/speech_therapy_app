import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Firestore Seeder - Seeds initial data with images to Firestore
class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all initial data
  Future<void> seedAll() async {
    print('🌱 Starting Firestore seeding...');
    
    await seedCategories();
    await seedWordsWithImages();
    
    print('✅ Firestore seeding completed!');
  }

  /// Seed categories
  Future<void> seedCategories() async {
    print('📁 Seeding categories...');
    
    final batch = _firestore.batch();
    final categoriesRef = _firestore.collection(AppConstants.categoriesCollection);

    final categories = [
      {
        'id': 'animals',
        'name': 'حيوانات',
        'nameEn': 'Animals',
        'icon': 'pets',
        'colorValue': 0xFF795548,
        'description': 'الحيوانات الأليفة والبرية',
        'wordCount': 8,
        'order': 0,
      },
      {
        'id': 'food',
        'name': 'طعام',
        'nameEn': 'Food',
        'icon': 'restaurant',
        'colorValue': 0xFFFF5722,
        'description': 'الأطعمة والفواكه',
        'wordCount': 8,
        'order': 1,
      },
      {
        'id': 'colors',
        'name': 'ألوان',
        'nameEn': 'Colors',
        'icon': 'palette',
        'colorValue': 0xFFE91E63,
        'description': 'الألوان المختلفة',
        'wordCount': 8,
        'order': 2,
      },
      {
        'id': 'body',
        'name': 'جسم الإنسان',
        'nameEn': 'Human Body',
        'icon': 'accessibility_new',
        'colorValue': 0xFF607D8B,
        'description': 'أعضاء الجسم',
        'wordCount': 8,
        'order': 3,
      },
      {
        'id': 'family',
        'name': 'العائلة',
        'nameEn': 'Family',
        'icon': 'family_restroom',
        'colorValue': 0xFF8BC34A,
        'description': 'أفراد العائلة',
        'wordCount': 6,
        'order': 4,
      },
      {
        'id': 'shapes',
        'name': 'أشكال',
        'nameEn': 'Shapes',
        'icon': 'category',
        'colorValue': 0xFFFF9800,
        'description': 'الأشكال الهندسية',
        'wordCount': 6,
        'order': 5,
      },
      {
        'id': 'math',
        'name': 'أرقام',
        'nameEn': 'Numbers',
        'icon': 'calculate',
        'colorValue': 0xFF4CAF50,
        'description': 'الأرقام من 1 إلى 10',
        'wordCount': 10,
        'order': 6,
      },
      {
        'id': 'transport',
        'name': 'مواصلات',
        'nameEn': 'Transportation',
        'icon': 'directions_car',
        'colorValue': 0xFFFFC107,
        'description': 'وسائل النقل',
        'wordCount': 6,
        'order': 7,
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

  /// Seed words with real images
  Future<void> seedWordsWithImages() async {
    print('📝 Seeding words with images...');
    
    final wordsRef = _firestore.collection(AppConstants.wordsCollection);

    // ============ ANIMALS ============
    final animalWords = [
      {'text': 'قطة', 'textEn': 'Cat', 'phonetic': 'قِطَّة', 'difficulty': 1, 'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400'},
      {'text': 'كلب', 'textEn': 'Dog', 'phonetic': 'كَلْب', 'difficulty': 1, 'imageUrl': 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400'},
      {'text': 'أسد', 'textEn': 'Lion', 'phonetic': 'أَسَد', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?w=400'},
      {'text': 'فيل', 'textEn': 'Elephant', 'phonetic': 'فِيل', 'difficulty': 1, 'imageUrl': 'https://images.unsplash.com/photo-1557050543-4d5f4e07ef46?w=400'},
      {'text': 'طائر', 'textEn': 'Bird', 'phonetic': 'طَائِر', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1444464666168-49d633b86797?w=400'},
      {'text': 'سمكة', 'textEn': 'Fish', 'phonetic': 'سَمَكَة', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1524704654690-b56c05c78a00?w=400'},
      {'text': 'أرنب', 'textEn': 'Rabbit', 'phonetic': 'أَرْنَب', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=400'},
      {'text': 'حصان', 'textEn': 'Horse', 'phonetic': 'حِصَان', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?w=400'},
    ];
    await _seedWordsForCategory(wordsRef, 'animals', animalWords);

    // ============ FOOD ============
    final foodWords = [
      {'text': 'تفاحة', 'textEn': 'Apple', 'phonetic': 'تُفَّاحَة', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1584306670957-acf935f5033c?w=400'},
      {'text': 'موز', 'textEn': 'Banana', 'phonetic': 'مَوْز', 'difficulty': 1, 'imageUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400'},
      {'text': 'برتقالة', 'textEn': 'Orange', 'phonetic': 'بُرْتُقَالَة', 'difficulty': 3, 'imageUrl': 'https://images.unsplash.com/photo-1547514701-42782101795e?w=400'},
      {'text': 'خبز', 'textEn': 'Bread', 'phonetic': 'خُبْز', 'difficulty': 1, 'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400'},
      {'text': 'حليب', 'textEn': 'Milk', 'phonetic': 'حَلِيب', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400'},
      {'text': 'ماء', 'textEn': 'Water', 'phonetic': 'مَاء', 'difficulty': 1, 'imageUrl': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400'},
      {'text': 'عنب', 'textEn': 'Grapes', 'phonetic': 'عِنَب', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=400'},
      {'text': 'جزر', 'textEn': 'Carrot', 'phonetic': 'جَزَر', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400'},
    ];
    await _seedWordsForCategory(wordsRef, 'food', foodWords);

    // ============ COLORS ============
    final colorWords = [
      {'text': 'أحمر', 'textEn': 'Red', 'phonetic': 'أَحْمَر', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1562157873-818bc0726f68?w=400'},
      {'text': 'أزرق', 'textEn': 'Blue', 'phonetic': 'أَزْرَق', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=400'},
      {'text': 'أخضر', 'textEn': 'Green', 'phonetic': 'أَخْضَر', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1564419320461-6870880221ad?w=400'},
      {'text': 'أصفر', 'textEn': 'Yellow', 'phonetic': 'أَصْفَر', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400'},
      {'text': 'برتقالي', 'textEn': 'Orange', 'phonetic': 'بُرْتُقَالِي', 'difficulty': 3, 'imageUrl': 'https://images.unsplash.com/photo-1557682250-33bd709cbe85?w=400'},
      {'text': 'أبيض', 'textEn': 'White', 'phonetic': 'أَبْيَض', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1533628635777-112b2239b1c7?w=400'},
      {'text': 'أسود', 'textEn': 'Black', 'phonetic': 'أَسْوَد', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=400'},
      {'text': 'وردي', 'textEn': 'Pink', 'phonetic': 'وَرْدِي', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400'},
    ];
    await _seedWordsForCategory(wordsRef, 'colors', colorWords);

    // ============ BODY ============
    final bodyWords = [
      {'text': 'رأس', 'textEn': 'Head', 'phonetic': 'رَأْس', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3048/3048127.png'},
      {'text': 'عين', 'textEn': 'Eye', 'phonetic': 'عَيْن', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/747/747445.png'},
      {'text': 'أنف', 'textEn': 'Nose', 'phonetic': 'أَنْف', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2914/2914330.png'},
      {'text': 'فم', 'textEn': 'Mouth', 'phonetic': 'فَم', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3163/3163003.png'},
      {'text': 'أذن', 'textEn': 'Ear', 'phonetic': 'أُذُن', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png'},
      {'text': 'يد', 'textEn': 'Hand', 'phonetic': 'يَد', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2415/2415425.png'},
      {'text': 'قدم', 'textEn': 'Foot', 'phonetic': 'قَدَم', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3048/3048383.png'},
      {'text': 'شعر', 'textEn': 'Hair', 'phonetic': 'شَعْر', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2621/2621022.png'},
    ];
    await _seedWordsForCategory(wordsRef, 'body', bodyWords);

    // ============ FAMILY ============
    final familyWords = [
      {'text': 'أب', 'textEn': 'Father', 'phonetic': 'أَب', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/4139/4139981.png'},
      {'text': 'أم', 'textEn': 'Mother', 'phonetic': 'أُمّ', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/4140/4140037.png'},
      {'text': 'أخ', 'textEn': 'Brother', 'phonetic': 'أَخ', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/4139/4139964.png'},
      {'text': 'أخت', 'textEn': 'Sister', 'phonetic': 'أُخْت', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/4140/4140048.png'},
      {'text': 'جد', 'textEn': 'Grandfather', 'phonetic': 'جَدّ', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/4139/4139993.png'},
      {'text': 'جدة', 'textEn': 'Grandmother', 'phonetic': 'جَدَّة', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/4140/4140061.png'},
    ];
    await _seedWordsForCategory(wordsRef, 'family', familyWords);

    // ============ SHAPES ============
    final shapeWords = [
      {'text': 'دائرة', 'textEn': 'Circle', 'phonetic': 'دَائِرَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/481/481078.png'},
      {'text': 'مربع', 'textEn': 'Square', 'phonetic': 'مُرَبَّع', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/5765/5765135.png'},
      {'text': 'مثلث', 'textEn': 'Triangle', 'phonetic': 'مُثَلَّث', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/5765/5765157.png'},
      {'text': 'مستطيل', 'textEn': 'Rectangle', 'phonetic': 'مُسْتَطِيل', 'difficulty': 3, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3098/3098287.png'},
      {'text': 'نجمة', 'textEn': 'Star', 'phonetic': 'نَجْمَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png'},
      {'text': 'قلب', 'textEn': 'Heart', 'phonetic': 'قَلْب', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/833/833472.png'},
    ];
    await _seedWordsForCategory(wordsRef, 'shapes', shapeWords);

    // ============ NUMBERS ============
    final mathWords = [
      {'text': 'واحد', 'textEn': 'One', 'phonetic': 'وَاحِد', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3742/3742908.png'},
      {'text': 'اثنان', 'textEn': 'Two', 'phonetic': 'اِثْنَان', 'difficulty': 1, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3742/3742932.png'},
      {'text': 'ثلاثة', 'textEn': 'Three', 'phonetic': 'ثَلَاثَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3742/3742956.png'},
      {'text': 'أربعة', 'textEn': 'Four', 'phonetic': 'أَرْبَعَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3742/3742968.png'},
      {'text': 'خمسة', 'textEn': 'Five', 'phonetic': 'خَمْسَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3742/3742980.png'},
      {'text': 'ستة', 'textEn': 'Six', 'phonetic': 'سِتَّة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3742/3742992.png'},
      {'text': 'سبعة', 'textEn': 'Seven', 'phonetic': 'سَبْعَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3743/3743004.png'},
      {'text': 'ثمانية', 'textEn': 'Eight', 'phonetic': 'ثَمَانِيَة', 'difficulty': 3, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3743/3743016.png'},
      {'text': 'تسعة', 'textEn': 'Nine', 'phonetic': 'تِسْعَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3743/3743028.png'},
      {'text': 'عشرة', 'textEn': 'Ten', 'phonetic': 'عَشَرَة', 'difficulty': 2, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3743/3743040.png'},
    ];
    await _seedWordsForCategory(wordsRef, 'math', mathWords);

    // ============ TRANSPORT ============
    final transportWords = [
      {'text': 'سيارة', 'textEn': 'Car', 'phonetic': 'سَيَّارَة', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=400'},
      {'text': 'طائرة', 'textEn': 'Airplane', 'phonetic': 'طَائِرَة', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=400'},
      {'text': 'قطار', 'textEn': 'Train', 'phonetic': 'قِطَار', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1474487548417-781cb71495f3?w=400'},
      {'text': 'باص', 'textEn': 'Bus', 'phonetic': 'بَاص', 'difficulty': 1, 'imageUrl': 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400'},
      {'text': 'دراجة', 'textEn': 'Bicycle', 'phonetic': 'دَرَّاجَة', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=400'},
      {'text': 'سفينة', 'textEn': 'Ship', 'phonetic': 'سَفِينَة', 'difficulty': 2, 'imageUrl': 'https://images.unsplash.com/photo-1534190760961-74e8c1c5c3da?w=400'},
    ];
    await _seedWordsForCategory(wordsRef, 'transport', transportWords);

    print('✅ All words with images seeded!');
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
        'imageUrl': word['imageUrl'] ?? '',
        'correctPronunciationUrl': '',
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
    print('  ✅ ${words.length} words seeded for $categoryId');
  }

  /// Force re-seed (delete old and create new)
  Future<void> forceReseed() async {
    print('🔄 Force re-seeding...');
    
    final wordsSnapshot = await _firestore.collection(AppConstants.wordsCollection).get();
    for (final doc in wordsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('  🗑️ Old words deleted');

    final categoriesSnapshot = await _firestore.collection(AppConstants.categoriesCollection).get();
    for (final doc in categoriesSnapshot.docs) {
      await doc.reference.delete();
    }
    print('  🗑️ Old categories deleted');

    await seedAll();
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
}
