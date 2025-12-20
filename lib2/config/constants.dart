/// Application Constants
class AppConstants {
  // App Info
  static const String appName = 'نظام تحسين النطق';
  static const String appNameEn = 'Speech Therapy System';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String childrenCollection = 'children';
  static const String categoriesCollection = 'categories';
  static const String wordsCollection = 'words';
  static const String recordingsCollection = 'recordings';
  static const String reportsCollection = 'reports';
  static const String evaluationsCollection = 'evaluations';
  
  // Storage Paths
  static const String imagesPath = 'images';
  static const String audioPath = 'audio';
  static const String correctPronunciationsPath = 'correct_pronunciations';
  static const String childRecordingsPath = 'child_recordings';
  static const String reportsPath = 'reports';
  
  // User Roles
  static const String roleTrainer = 'trainer';
  static const String roleParent = 'parent';
  static const String roleAdmin = 'admin';
  
  // Report Types
  static const String reportDaily = 'daily';
  static const String reportWeekly = 'weekly';
  static const String reportMonthly = 'monthly';
  
  // Evaluation Metrics
  static const String metricAccuracy = 'accuracy';
  static const String metricSimilarity = 'similarity';
  static const String metricWER = 'wer';
  static const String metricCER = 'cer';
  static const String metricMOS = 'mos';
  
  // Categories (Default)
  static const List<Map<String, dynamic>> defaultCategories = [
    {
      'id': 'math',
      'name': 'رياضيات',
      'nameEn': 'Mathematics',
      'icon': 'calculate',
      'color': 0xFF4CAF50,
    },
    {
      'id': 'science',
      'name': 'علوم',
      'nameEn': 'Science',
      'icon': 'science',
      'color': 0xFF2196F3,
    },
    {
      'id': 'islamic',
      'name': 'إسلامية',
      'nameEn': 'Islamic',
      'icon': 'mosque',
      'color': 0xFF9C27B0,
    },
    {
      'id': 'shapes',
      'name': 'أشكال',
      'nameEn': 'Shapes',
      'icon': 'category',
      'color': 0xFFFF9800,
    },
    {
      'id': 'colors',
      'name': 'ألوان',
      'nameEn': 'Colors',
      'icon': 'palette',
      'color': 0xFFE91E63,
    },
    {
      'id': 'animals',
      'name': 'حيوانات',
      'nameEn': 'Animals',
      'icon': 'pets',
      'color': 0xFF795548,
    },
    {
      'id': 'food',
      'name': 'طعام',
      'nameEn': 'Food',
      'icon': 'restaurant',
      'color': 0xFFFF5722,
    },
    {
      'id': 'body',
      'name': 'جسم الإنسان',
      'nameEn': 'Human Body',
      'icon': 'accessibility_new',
      'color': 0xFF607D8B,
    },
  ];
  
  // Child Levels
  static const List<String> childLevels = [
    'مبتدئ',
    'متوسط',
    'متقدم',
  ];
  
  // Audio Settings
  static const int sampleRate = 44100;
  static const int bitRate = 128000;
  static const int maxRecordingDuration = 30; // seconds
  
  // Evaluation Thresholds
  static const double excellentThreshold = 90.0;
  static const double goodThreshold = 70.0;
  static const double averageThreshold = 50.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}

/// Evaluation Level based on score
enum EvaluationLevel {
  excellent,
  good,
  average,
  needsImprovement,
}

extension EvaluationLevelExtension on EvaluationLevel {
  String get arabicName {
    switch (this) {
      case EvaluationLevel.excellent:
        return 'ممتاز';
      case EvaluationLevel.good:
        return 'جيد';
      case EvaluationLevel.average:
        return 'متوسط';
      case EvaluationLevel.needsImprovement:
        return 'يحتاج تحسين';
    }
  }
  
  String get emoji {
    switch (this) {
      case EvaluationLevel.excellent:
        return '🌟';
      case EvaluationLevel.good:
        return '😊';
      case EvaluationLevel.average:
        return '👍';
      case EvaluationLevel.needsImprovement:
        return '💪';
    }
  }
  
  static EvaluationLevel fromScore(double score) {
    if (score >= AppConstants.excellentThreshold) {
      return EvaluationLevel.excellent;
    } else if (score >= AppConstants.goodThreshold) {
      return EvaluationLevel.good;
    } else if (score >= AppConstants.averageThreshold) {
      return EvaluationLevel.average;
    } else {
      return EvaluationLevel.needsImprovement;
    }
  }
}
