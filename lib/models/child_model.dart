import 'package:cloud_firestore/cloud_firestore.dart';

/// Child Model - Represents a child in the system
class ChildModel {
  final String id;
  final String name;
  final int age;
  final String gender; // 'male', 'female'
  final String level; // 'مبتدئ', 'متوسط', 'متقدم'
  final String trainerId;
  final String? parentId;
  final String? profileImageUrl;
  final String? notes;
  // New history fields
  final String? medicalHistory; // التاريخ الطبي
  final String? familyHistory; // التاريخ العائلي (وراثة)
  final String? behaviorNotes; // ملاحظات السلوك
  final String? preferences; // ماذا يحب ويكره
  final double? height; // الطول (سم)
  final double? weight; // الوزن (كغ)
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? additionalInfo;

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
    this.medicalHistory,
    this.familyHistory,
    this.behaviorNotes,
    this.preferences,
    this.height,
    this.weight,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.additionalInfo,
  });

  /// Create from Firestore document
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
      medicalHistory: data['medicalHistory'],
      familyHistory: data['familyHistory'],
      behaviorNotes: data['behaviorNotes'],
      preferences: data['preferences'],
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      additionalInfo: data['additionalInfo'],
    );
  }

  /// Create from Map (for local use)
  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'male',
      level: map['level'] ?? 'مبتدئ',
      trainerId: map['trainerId'] ?? '',
      parentId: map['parentId'],
      profileImageUrl: map['profileImageUrl'],
      notes: map['notes'],
      medicalHistory: map['medicalHistory'],
      familyHistory: map['familyHistory'],
      behaviorNotes: map['behaviorNotes'],
      preferences: map['preferences'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      isActive: map['isActive'] ?? true,
      additionalInfo: map['additionalInfo'],
    );
  }

  /// Convert to Firestore map
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
      'medicalHistory': medicalHistory,
      'familyHistory': familyHistory,
      'behaviorNotes': behaviorNotes,
      'preferences': preferences,
      'height': height,
      'weight': weight,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'additionalInfo': additionalInfo,
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'level': level,
      'trainerId': trainerId,
      'parentId': parentId,
      'profileImageUrl': profileImageUrl,
      'notes': notes,
      'medicalHistory': medicalHistory,
      'familyHistory': familyHistory,
      'behaviorNotes': behaviorNotes,
      'preferences': preferences,
      'height': height,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'additionalInfo': additionalInfo,
    };
  }

  /// Copy with method for updates
  ChildModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? level,
    String? trainerId,
    String? parentId,
    String? profileImageUrl,
    String? notes,
    String? medicalHistory,
    String? familyHistory,
    String? behaviorNotes,
    String? preferences,
    double? height,
    double? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      level: level ?? this.level,
      trainerId: trainerId ?? this.trainerId,
      parentId: parentId ?? this.parentId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      notes: notes ?? this.notes,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      behaviorNotes: behaviorNotes ?? this.behaviorNotes,
      preferences: preferences ?? this.preferences,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  /// Get gender in Arabic
  String get genderArabic => gender == 'male' ? 'ذكر' : 'أنثى';

  /// Get level color
  int get levelColorValue {
    switch (level) {
      case 'مبتدئ':
        return 0xFF4CAF50; // Green
      case 'متوسط':
        return 0xFFFF9800; // Orange
      case 'متقدم':
        return 0xFF2196F3; // Blue
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  @override
  String toString() {
    return 'ChildModel(id: $id, name: $name, age: $age, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChildModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
