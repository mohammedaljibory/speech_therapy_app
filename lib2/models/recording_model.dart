import 'package:cloud_firestore/cloud_firestore.dart';

/// Recording Model - Represents a child's recording attempt
class RecordingModel {
  final String id;
  final String childId;
  final String wordId;
  final String audioUrl;
  final int durationMs; // Duration in milliseconds
  final DateTime recordedAt;
  final String? sessionId; // To group recordings in a session
  final int attemptNumber; // Which attempt this is for the word
  final EvaluationData? evaluation;
  final bool isEvaluated;
  final String? notes;
  final Map<String, dynamic>? metadata;

  RecordingModel({
    required this.id,
    required this.childId,
    required this.wordId,
    required this.audioUrl,
    required this.durationMs,
    required this.recordedAt,
    this.sessionId,
    this.attemptNumber = 1,
    this.evaluation,
    this.isEvaluated = false,
    this.notes,
    this.metadata,
  });

  /// Create from Firestore document
  factory RecordingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordingModel(
      id: doc.id,
      childId: data['childId'] ?? '',
      wordId: data['wordId'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      durationMs: data['durationMs'] ?? 0,
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionId: data['sessionId'],
      attemptNumber: data['attemptNumber'] ?? 1,
      evaluation: data['evaluation'] != null
          ? EvaluationData.fromMap(data['evaluation'])
          : null,
      isEvaluated: data['isEvaluated'] ?? false,
      notes: data['notes'],
      metadata: data['metadata'],
    );
  }

  /// Create from Map
  factory RecordingModel.fromMap(Map<String, dynamic> map) {
    return RecordingModel(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      wordId: map['wordId'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      durationMs: map['durationMs'] ?? 0,
      recordedAt: map['recordedAt'] is Timestamp
          ? (map['recordedAt'] as Timestamp).toDate()
          : DateTime.now(),
      sessionId: map['sessionId'],
      attemptNumber: map['attemptNumber'] ?? 1,
      evaluation: map['evaluation'] != null
          ? EvaluationData.fromMap(map['evaluation'])
          : null,
      isEvaluated: map['isEvaluated'] ?? false,
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'wordId': wordId,
      'audioUrl': audioUrl,
      'durationMs': durationMs,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'sessionId': sessionId,
      'attemptNumber': attemptNumber,
      'evaluation': evaluation?.toMap(),
      'isEvaluated': isEvaluated,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'wordId': wordId,
      'audioUrl': audioUrl,
      'durationMs': durationMs,
      'recordedAt': recordedAt.toIso8601String(),
      'sessionId': sessionId,
      'attemptNumber': attemptNumber,
      'evaluation': evaluation?.toMap(),
      'isEvaluated': isEvaluated,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Copy with method
  RecordingModel copyWith({
    String? id,
    String? childId,
    String? wordId,
    String? audioUrl,
    int? durationMs,
    DateTime? recordedAt,
    String? sessionId,
    int? attemptNumber,
    EvaluationData? evaluation,
    bool? isEvaluated,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      wordId: wordId ?? this.wordId,
      audioUrl: audioUrl ?? this.audioUrl,
      durationMs: durationMs ?? this.durationMs,
      recordedAt: recordedAt ?? this.recordedAt,
      sessionId: sessionId ?? this.sessionId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      evaluation: evaluation ?? this.evaluation,
      isEvaluated: isEvaluated ?? this.isEvaluated,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted duration
  String get formattedDuration {
    final seconds = durationMs ~/ 1000;
    final ms = durationMs % 1000;
    return '${seconds.toString().padLeft(2, '0')}.${(ms ~/ 100).toString()}';
  }

  @override
  String toString() {
    return 'RecordingModel(id: $id, childId: $childId, wordId: $wordId)';
  }
}

/// Evaluation Data - Contains all evaluation metrics
class EvaluationData {
  final double accuracy; // 0-100
  final double similarity; // 0-100
  final double wer; // Word Error Rate 0-100 (lower is better)
  final double cer; // Character Error Rate 0-100 (lower is better)
  final double mos; // Mean Opinion Score 1-5
  final double overallScore; // Calculated overall score 0-100
  final String? transcription; // What the AI heard
  final DateTime evaluatedAt;
  final String? evaluatedBy; // 'auto' or trainer ID
  final String? feedback;

  EvaluationData({
    required this.accuracy,
    required this.similarity,
    required this.wer,
    required this.cer,
    required this.mos,
    required this.overallScore,
    this.transcription,
    required this.evaluatedAt,
    this.evaluatedBy,
    this.feedback,
  });

  /// Create from Map
  factory EvaluationData.fromMap(Map<String, dynamic> map) {
    return EvaluationData(
      accuracy: (map['accuracy'] ?? 0).toDouble(),
      similarity: (map['similarity'] ?? 0).toDouble(),
      wer: (map['wer'] ?? 0).toDouble(),
      cer: (map['cer'] ?? 0).toDouble(),
      mos: (map['mos'] ?? 0).toDouble(),
      overallScore: (map['overallScore'] ?? 0).toDouble(),
      transcription: map['transcription'],
      evaluatedAt: map['evaluatedAt'] is Timestamp
          ? (map['evaluatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      evaluatedBy: map['evaluatedBy'],
      feedback: map['feedback'],
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy,
      'similarity': similarity,
      'wer': wer,
      'cer': cer,
      'mos': mos,
      'overallScore': overallScore,
      'transcription': transcription,
      'evaluatedAt': Timestamp.fromDate(evaluatedAt),
      'evaluatedBy': evaluatedBy,
      'feedback': feedback,
    };
  }

  /// Calculate overall score from metrics
  static double calculateOverallScore({
    required double accuracy,
    required double similarity,
    required double wer,
    required double cer,
    required double mos,
  }) {
    // Weighted average:
    // - Accuracy: 30%
    // - Similarity: 25%
    // - WER (inverted): 20%
    // - CER (inverted): 15%
    // - MOS (scaled to 100): 10%
    
    final werScore = 100 - wer; // Invert WER
    final cerScore = 100 - cer; // Invert CER
    final mosScore = (mos / 5) * 100; // Scale MOS to 100
    
    return (accuracy * 0.30) +
        (similarity * 0.25) +
        (werScore * 0.20) +
        (cerScore * 0.15) +
        (mosScore * 0.10);
  }

  /// Get evaluation level
  String get level {
    if (overallScore >= 90) return 'ممتاز';
    if (overallScore >= 70) return 'جيد';
    if (overallScore >= 50) return 'متوسط';
    return 'يحتاج تحسين';
  }

  /// Get level emoji
  String get levelEmoji {
    if (overallScore >= 90) return '🌟';
    if (overallScore >= 70) return '😊';
    if (overallScore >= 50) return '👍';
    return '💪';
  }

  /// Get level color
  int get levelColorValue {
    if (overallScore >= 90) return 0xFF4CAF50; // Green
    if (overallScore >= 70) return 0xFF8BC34A; // Light Green
    if (overallScore >= 50) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Copy with method
  EvaluationData copyWith({
    double? accuracy,
    double? similarity,
    double? wer,
    double? cer,
    double? mos,
    double? overallScore,
    String? transcription,
    DateTime? evaluatedAt,
    String? evaluatedBy,
    String? feedback,
  }) {
    return EvaluationData(
      accuracy: accuracy ?? this.accuracy,
      similarity: similarity ?? this.similarity,
      wer: wer ?? this.wer,
      cer: cer ?? this.cer,
      mos: mos ?? this.mos,
      overallScore: overallScore ?? this.overallScore,
      transcription: transcription ?? this.transcription,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      evaluatedBy: evaluatedBy ?? this.evaluatedBy,
      feedback: feedback ?? this.feedback,
    );
  }
}
