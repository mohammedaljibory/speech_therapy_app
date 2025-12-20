import 'package:cloud_firestore/cloud_firestore.dart';

/// Word Model - Represents a word for practice
class WordModel {
  final String id;
  final String text;
  final String? textEn;
  final String categoryId;
  final String imageUrl;
  final String correctPronunciationUrl;
  final String? description;
  final String? phonetic; // النطق الصوتي
  final int difficulty; // 1-5
  final int practiceCount;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  WordModel({
    required this.id,
    required this.text,
    this.textEn,
    required this.categoryId,
    required this.imageUrl,
    required this.correctPronunciationUrl,
    this.description,
    this.phonetic,
    this.difficulty = 1,
    this.practiceCount = 0,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.metadata,
  });

  /// Create from Firestore document
  factory WordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordModel(
      id: doc.id,
      text: data['text'] ?? '',
      textEn: data['textEn'],
      categoryId: data['categoryId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      correctPronunciationUrl: data['correctPronunciationUrl'] ?? '',
      description: data['description'],
      phonetic: data['phonetic'],
      difficulty: data['difficulty'] ?? 1,
      practiceCount: data['practiceCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  /// Create from Map
  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      textEn: map['textEn'],
      categoryId: map['categoryId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      correctPronunciationUrl: map['correctPronunciationUrl'] ?? '',
      description: map['description'],
      phonetic: map['phonetic'],
      difficulty: map['difficulty'] ?? 1,
      practiceCount: map['practiceCount'] ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'textEn': textEn,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'correctPronunciationUrl': correctPronunciationUrl,
      'description': description,
      'phonetic': phonetic,
      'difficulty': difficulty,
      'practiceCount': practiceCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'textEn': textEn,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'correctPronunciationUrl': correctPronunciationUrl,
      'description': description,
      'phonetic': phonetic,
      'difficulty': difficulty,
      'practiceCount': practiceCount,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Copy with method
  WordModel copyWith({
    String? id,
    String? text,
    String? textEn,
    String? categoryId,
    String? imageUrl,
    String? correctPronunciationUrl,
    String? description,
    String? phonetic,
    int? difficulty,
    int? practiceCount,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return WordModel(
      id: id ?? this.id,
      text: text ?? this.text,
      textEn: textEn ?? this.textEn,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      correctPronunciationUrl: correctPronunciationUrl ?? this.correctPronunciationUrl,
      description: description ?? this.description,
      phonetic: phonetic ?? this.phonetic,
      difficulty: difficulty ?? this.difficulty,
      practiceCount: practiceCount ?? this.practiceCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get difficulty label in Arabic
  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'سهل جداً';
      case 2:
        return 'سهل';
      case 3:
        return 'متوسط';
      case 4:
        return 'صعب';
      case 5:
        return 'صعب جداً';
      default:
        return 'غير محدد';
    }
  }

  /// Get difficulty color
  int get difficultyColorValue {
    switch (difficulty) {
      case 1:
        return 0xFF4CAF50; // Green
      case 2:
        return 0xFF8BC34A; // Light Green
      case 3:
        return 0xFFFF9800; // Orange
      case 4:
        return 0xFFFF5722; // Deep Orange
      case 5:
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  @override
  String toString() {
    return 'WordModel(id: $id, text: $text, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
