import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Category Model - Represents word categories (Math, Science, etc.)
class CategoryModel {
  final String id;
  final String name;
  final String nameEn;
  final String icon;
  final int colorValue;
  final String? description;
  final int wordCount;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final String? createdBy;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.colorValue,
    this.description,
    this.wordCount = 0,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    this.createdBy,
  });

  /// Create from Firestore document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      icon: data['icon'] ?? 'category',
      colorValue: data['colorValue'] ?? 0xFF2196F3,
      description: data['description'],
      wordCount: data['wordCount'] ?? 0,
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  /// Create from Map
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      nameEn: map['nameEn'] ?? '',
      icon: map['icon'] ?? 'category',
      colorValue: map['color'] ?? map['colorValue'] ?? 0xFF2196F3,
      description: map['description'],
      wordCount: map['wordCount'] ?? 0,
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameEn': nameEn,
      'icon': icon,
      'colorValue': colorValue,
      'description': description,
      'wordCount': wordCount,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Get Color object
  Color get color => Color(colorValue);

  /// Get IconData from icon name
  IconData get iconData {
    switch (icon) {
      case 'calculate':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'mosque':
        return Icons.mosque;
      case 'category':
        return Icons.category;
      case 'palette':
        return Icons.palette;
      case 'pets':
        return Icons.pets;
      case 'restaurant':
        return Icons.restaurant;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'nature':
        return Icons.nature;
      case 'toys':
        return Icons.toys;
      case 'sports':
        return Icons.sports;
      case 'music_note':
        return Icons.music_note;
      case 'numbers':
        return Icons.numbers;
      case 'abc':
        return Icons.abc;
      default:
        return Icons.folder;
    }
  }

  /// Copy with method
  CategoryModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? icon,
    int? colorValue,
    String? description,
    int? wordCount,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, wordCount: $wordCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// List of available category icons
class CategoryIcons {
  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'calculate', 'label': 'حساب'},
    {'name': 'science', 'label': 'علوم'},
    {'name': 'mosque', 'label': 'مسجد'},
    {'name': 'category', 'label': 'أشكال'},
    {'name': 'palette', 'label': 'فن'},
    {'name': 'pets', 'label': 'حيوانات'},
    {'name': 'restaurant', 'label': 'طعام'},
    {'name': 'accessibility_new', 'label': 'جسم'},
    {'name': 'home', 'label': 'منزل'},
    {'name': 'school', 'label': 'مدرسة'},
    {'name': 'nature', 'label': 'طبيعة'},
    {'name': 'toys', 'label': 'ألعاب'},
    {'name': 'sports', 'label': 'رياضة'},
    {'name': 'music_note', 'label': 'موسيقى'},
    {'name': 'numbers', 'label': 'أرقام'},
    {'name': 'abc', 'label': 'حروف'},
  ];

  static IconData getIcon(String name) {
    switch (name) {
      case 'calculate':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'mosque':
        return Icons.mosque;
      case 'category':
        return Icons.category;
      case 'palette':
        return Icons.palette;
      case 'pets':
        return Icons.pets;
      case 'restaurant':
        return Icons.restaurant;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'nature':
        return Icons.nature;
      case 'toys':
        return Icons.toys;
      case 'sports':
        return Icons.sports;
      case 'music_note':
        return Icons.music_note;
      case 'numbers':
        return Icons.numbers;
      case 'abc':
        return Icons.abc;
      default:
        return Icons.folder;
    }
  }
}

/// List of available category colors
class CategoryColors {
  static const List<int> availableColors = [
    0xFF4CAF50, // Green
    0xFF2196F3, // Blue
    0xFF9C27B0, // Purple
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFFFF5722, // Deep Orange
    0xFF607D8B, // Blue Grey
    0xFF00BCD4, // Cyan
    0xFFCDDC39, // Lime
    0xFF3F51B5, // Indigo
    0xFFFFC107, // Amber
  ];
}
