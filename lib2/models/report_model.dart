import 'package:cloud_firestore/cloud_firestore.dart';

/// Report Model - Contains progress reports for children
class ReportModel {
  final String id;
  final String childId;
  final String type; // 'daily', 'weekly', 'monthly'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final String generatedBy;
  final ReportMetrics metrics;
  final List<CategoryProgress> categoryProgress;
  final List<WordProgress> topWords;
  final List<WordProgress> needsImprovementWords;
  final String? notes;
  final String? pdfUrl;
  final bool isSent;
  final DateTime? sentAt;
  final String? sentTo; // Email address

  ReportModel({
    required this.id,
    required this.childId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.generatedBy,
    required this.metrics,
    required this.categoryProgress,
    required this.topWords,
    required this.needsImprovementWords,
    this.notes,
    this.pdfUrl,
    this.isSent = false,
    this.sentAt,
    this.sentTo,
  });

  /// Create from Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      childId: data['childId'] ?? '',
      type: data['type'] ?? 'daily',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      generatedBy: data['generatedBy'] ?? '',
      metrics: ReportMetrics.fromMap(data['metrics'] ?? {}),
      categoryProgress: (data['categoryProgress'] as List<dynamic>?)
              ?.map((e) => CategoryProgress.fromMap(e))
              .toList() ??
          [],
      topWords: (data['topWords'] as List<dynamic>?)
              ?.map((e) => WordProgress.fromMap(e))
              .toList() ??
          [],
      needsImprovementWords: (data['needsImprovementWords'] as List<dynamic>?)
              ?.map((e) => WordProgress.fromMap(e))
              .toList() ??
          [],
      notes: data['notes'],
      pdfUrl: data['pdfUrl'],
      isSent: data['isSent'] ?? false,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      sentTo: data['sentTo'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'generatedBy': generatedBy,
      'metrics': metrics.toMap(),
      'categoryProgress': categoryProgress.map((e) => e.toMap()).toList(),
      'topWords': topWords.map((e) => e.toMap()).toList(),
      'needsImprovementWords': needsImprovementWords.map((e) => e.toMap()).toList(),
      'notes': notes,
      'pdfUrl': pdfUrl,
      'isSent': isSent,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'sentTo': sentTo,
    };
  }

  /// Get type label in Arabic
  String get typeLabel {
    switch (type) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      default:
        return type;
    }
  }

  /// Get date range string
  String get dateRangeString {
    final startStr = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endStr = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startStr - $endStr';
  }

  /// Copy with method
  ReportModel copyWith({
    String? id,
    String? childId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? generatedAt,
    String? generatedBy,
    ReportMetrics? metrics,
    List<CategoryProgress>? categoryProgress,
    List<WordProgress>? topWords,
    List<WordProgress>? needsImprovementWords,
    String? notes,
    String? pdfUrl,
    bool? isSent,
    DateTime? sentAt,
    String? sentTo,
  }) {
    return ReportModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      generatedAt: generatedAt ?? this.generatedAt,
      generatedBy: generatedBy ?? this.generatedBy,
      metrics: metrics ?? this.metrics,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      topWords: topWords ?? this.topWords,
      needsImprovementWords: needsImprovementWords ?? this.needsImprovementWords,
      notes: notes ?? this.notes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      isSent: isSent ?? this.isSent,
      sentAt: sentAt ?? this.sentAt,
      sentTo: sentTo ?? this.sentTo,
    );
  }
}

/// Report Metrics - Aggregated metrics for a report period
class ReportMetrics {
  final int totalSessions;
  final int totalRecordings;
  final int totalWords;
  final int wordsCompleted;
  final double averageAccuracy;
  final double averageSimilarity;
  final double averageWer;
  final double averageCer;
  final double averageMos;
  final double overallProgress; // Percentage improvement
  final int practiceTimeMinutes;

  ReportMetrics({
    required this.totalSessions,
    required this.totalRecordings,
    required this.totalWords,
    required this.wordsCompleted,
    required this.averageAccuracy,
    required this.averageSimilarity,
    required this.averageWer,
    required this.averageCer,
    required this.averageMos,
    required this.overallProgress,
    required this.practiceTimeMinutes,
  });

  factory ReportMetrics.fromMap(Map<String, dynamic> map) {
    return ReportMetrics(
      totalSessions: map['totalSessions'] ?? 0,
      totalRecordings: map['totalRecordings'] ?? 0,
      totalWords: map['totalWords'] ?? 0,
      wordsCompleted: map['wordsCompleted'] ?? 0,
      averageAccuracy: (map['averageAccuracy'] ?? 0).toDouble(),
      averageSimilarity: (map['averageSimilarity'] ?? 0).toDouble(),
      averageWer: (map['averageWer'] ?? 0).toDouble(),
      averageCer: (map['averageCer'] ?? 0).toDouble(),
      averageMos: (map['averageMos'] ?? 0).toDouble(),
      overallProgress: (map['overallProgress'] ?? 0).toDouble(),
      practiceTimeMinutes: map['practiceTimeMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalRecordings': totalRecordings,
      'totalWords': totalWords,
      'wordsCompleted': wordsCompleted,
      'averageAccuracy': averageAccuracy,
      'averageSimilarity': averageSimilarity,
      'averageWer': averageWer,
      'averageCer': averageCer,
      'averageMos': averageMos,
      'overallProgress': overallProgress,
      'practiceTimeMinutes': practiceTimeMinutes,
    };
  }

  /// Get overall level
  String get overallLevel {
    final avgScore = (averageAccuracy + averageSimilarity + (100 - averageWer) + (100 - averageCer)) / 4;
    if (avgScore >= 90) return 'ممتاز';
    if (avgScore >= 70) return 'جيد';
    if (avgScore >= 50) return 'متوسط';
    return 'يحتاج تحسين';
  }

  /// Get formatted practice time
  String get formattedPracticeTime {
    final hours = practiceTimeMinutes ~/ 60;
    final minutes = practiceTimeMinutes % 60;
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }
}

/// Category Progress - Progress for a specific category
class CategoryProgress {
  final String categoryId;
  final String categoryName;
  final int totalWords;
  final int completedWords;
  final double averageScore;
  final double progressPercentage;

  CategoryProgress({
    required this.categoryId,
    required this.categoryName,
    required this.totalWords,
    required this.completedWords,
    required this.averageScore,
    required this.progressPercentage,
  });

  factory CategoryProgress.fromMap(Map<String, dynamic> map) {
    return CategoryProgress(
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      totalWords: map['totalWords'] ?? 0,
      completedWords: map['completedWords'] ?? 0,
      averageScore: (map['averageScore'] ?? 0).toDouble(),
      progressPercentage: (map['progressPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'totalWords': totalWords,
      'completedWords': completedWords,
      'averageScore': averageScore,
      'progressPercentage': progressPercentage,
    };
  }
}

/// Word Progress - Progress for a specific word
class WordProgress {
  final String wordId;
  final String wordText;
  final String categoryName;
  final int attemptCount;
  final double bestScore;
  final double latestScore;
  final double improvement; // Percentage improvement from first to latest

  WordProgress({
    required this.wordId,
    required this.wordText,
    required this.categoryName,
    required this.attemptCount,
    required this.bestScore,
    required this.latestScore,
    required this.improvement,
  });

  factory WordProgress.fromMap(Map<String, dynamic> map) {
    return WordProgress(
      wordId: map['wordId'] ?? '',
      wordText: map['wordText'] ?? '',
      categoryName: map['categoryName'] ?? '',
      attemptCount: map['attemptCount'] ?? 0,
      bestScore: (map['bestScore'] ?? 0).toDouble(),
      latestScore: (map['latestScore'] ?? 0).toDouble(),
      improvement: (map['improvement'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wordId': wordId,
      'wordText': wordText,
      'categoryName': categoryName,
      'attemptCount': attemptCount,
      'bestScore': bestScore,
      'latestScore': latestScore,
      'improvement': improvement,
    };
  }
}
