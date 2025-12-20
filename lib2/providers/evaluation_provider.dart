import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recording_model.dart';
import '../models/report_model.dart';
import '../config/constants.dart';

/// Evaluation Provider - Manages recordings and evaluations
class EvaluationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RecordingModel> _recordings = [];
  List<ReportModel> _reports = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<RecordingModel> get recordings => _recordings;
  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load recordings for a child
  Future<void> loadRecordings(String childId) async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.recordingsCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('recordedAt', descending: true)
          .get();

      _recordings = snapshot.docs
          .map((doc) => RecordingModel.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في تحميل التسجيلات');
      _setLoading(false);
      debugPrint('Error loading recordings: $e');
    }
  }

  /// Load recordings for a specific word
  Future<List<RecordingModel>> loadRecordingsForWord({
    required String childId,
    required String wordId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.recordingsCollection)
          .where('childId', isEqualTo: childId)
          .where('wordId', isEqualTo: wordId)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RecordingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading recordings for word: $e');
      return [];
    }
  }

  /// Add new recording
  Future<RecordingModel?> addRecording({
    required String childId,
    required String wordId,
    required String audioUrl,
    required int durationMs,
    String? sessionId,
    int attemptNumber = 1,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final docRef = _firestore.collection(AppConstants.recordingsCollection).doc();

      final recording = RecordingModel(
        id: docRef.id,
        childId: childId,
        wordId: wordId,
        audioUrl: audioUrl,
        durationMs: durationMs,
        recordedAt: DateTime.now(),
        sessionId: sessionId,
        attemptNumber: attemptNumber,
      );

      await docRef.set(recording.toFirestore());

      _recordings.insert(0, recording);
      _setLoading(false);
      notifyListeners();
      return recording;
    } catch (e) {
      _setError('فشل في حفظ التسجيل');
      _setLoading(false);
      debugPrint('Error adding recording: $e');
      return null;
    }
  }

  /// Update recording with evaluation
  Future<bool> updateRecordingEvaluation({
    required String recordingId,
    required EvaluationData evaluation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore
          .collection(AppConstants.recordingsCollection)
          .doc(recordingId)
          .update({
        'evaluation': evaluation.toMap(),
        'isEvaluated': true,
      });

      // Update local list
      final index = _recordings.indexWhere((r) => r.id == recordingId);
      if (index != -1) {
        _recordings[index] = _recordings[index].copyWith(
          evaluation: evaluation,
          isEvaluated: true,
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في حفظ التقييم');
      _setLoading(false);
      debugPrint('Error updating evaluation: $e');
      return false;
    }
  }

  /// Add manual evaluation (MOS score from trainer)
  Future<bool> addManualEvaluation({
    required String recordingId,
    required double mosScore,
    String? feedback,
    required String evaluatedBy,
  }) async {
    try {
      final recording = _recordings.firstWhere((r) => r.id == recordingId);
      
      if (recording.evaluation == null) {
        _setError('لم يتم تقييم التسجيل آلياً بعد');
        return false;
      }

      final newOverallScore = EvaluationData.calculateOverallScore(
        accuracy: recording.evaluation!.accuracy,
        similarity: recording.evaluation!.similarity,
        wer: recording.evaluation!.wer,
        cer: recording.evaluation!.cer,
        mos: mosScore,
      );

      final updatedEvaluation = recording.evaluation!.copyWith(
        mos: mosScore,
        overallScore: newOverallScore,
        feedback: feedback,
        evaluatedBy: evaluatedBy,
        evaluatedAt: DateTime.now(),
      );

      return await updateRecordingEvaluation(
        recordingId: recordingId,
        evaluation: updatedEvaluation,
      );
    } catch (e) {
      _setError('فشل في إضافة التقييم اليدوي');
      debugPrint('Error adding manual evaluation: $e');
      return false;
    }
  }

  /// Delete recording
  Future<bool> deleteRecording(String recordingId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore
          .collection(AppConstants.recordingsCollection)
          .doc(recordingId)
          .delete();

      _recordings.removeWhere((r) => r.id == recordingId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في حذف التسجيل');
      _setLoading(false);
      debugPrint('Error deleting recording: $e');
      return false;
    }
  }

  // ============ REPORTS MANAGEMENT ============

  /// Load reports for a child
  Future<void> loadReports(String childId) async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.reportsCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('generatedAt', descending: true)
          .get();

      _reports = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في تحميل التقارير');
      _setLoading(false);
      debugPrint('Error loading reports: $e');
    }
  }

  /// Generate report
  Future<ReportModel?> generateReport({
    required String childId,
    required String type, // 'daily', 'weekly', 'monthly'
    required String generatedBy,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Calculate date range based on type
      final now = DateTime.now();
      DateTime startDate;
      
      switch (type) {
        case 'daily':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'weekly':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }

      // Get recordings for the period
      final recordingsSnapshot = await _firestore
          .collection(AppConstants.recordingsCollection)
          .where('childId', isEqualTo: childId)
          .where('recordedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('recordedAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final periodRecordings = recordingsSnapshot.docs
          .map((doc) => RecordingModel.fromFirestore(doc))
          .toList();

      // Calculate metrics
      final metrics = _calculateMetrics(periodRecordings);

      // Get category progress (simplified for now)
      final categoryProgress = <CategoryProgress>[];

      // Get top and needs improvement words
      final topWords = <WordProgress>[];
      final needsImprovementWords = <WordProgress>[];

      // Create report
      final docRef = _firestore.collection(AppConstants.reportsCollection).doc();

      final report = ReportModel(
        id: docRef.id,
        childId: childId,
        type: type,
        startDate: startDate,
        endDate: now,
        generatedAt: DateTime.now(),
        generatedBy: generatedBy,
        metrics: metrics,
        categoryProgress: categoryProgress,
        topWords: topWords,
        needsImprovementWords: needsImprovementWords,
        notes: notes,
      );

      await docRef.set(report.toFirestore());

      _reports.insert(0, report);
      _setLoading(false);
      notifyListeners();
      return report;
    } catch (e) {
      _setError('فشل في إنشاء التقرير');
      _setLoading(false);
      debugPrint('Error generating report: $e');
      return null;
    }
  }

  /// Calculate metrics from recordings
  ReportMetrics _calculateMetrics(List<RecordingModel> recordings) {
    if (recordings.isEmpty) {
      return ReportMetrics(
        totalSessions: 0,
        totalRecordings: 0,
        totalWords: 0,
        wordsCompleted: 0,
        averageAccuracy: 0,
        averageSimilarity: 0,
        averageWer: 0,
        averageCer: 0,
        averageMos: 0,
        overallProgress: 0,
        practiceTimeMinutes: 0,
      );
    }

    final evaluatedRecordings = recordings.where((r) => r.isEvaluated).toList();
    final uniqueWords = recordings.map((r) => r.wordId).toSet();
    final uniqueSessions = recordings
        .where((r) => r.sessionId != null)
        .map((r) => r.sessionId)
        .toSet();

    double totalAccuracy = 0;
    double totalSimilarity = 0;
    double totalWer = 0;
    double totalCer = 0;
    double totalMos = 0;
    int totalDurationMs = 0;

    for (final recording in recordings) {
      totalDurationMs += recording.durationMs;
      
      if (recording.evaluation != null) {
        totalAccuracy += recording.evaluation!.accuracy;
        totalSimilarity += recording.evaluation!.similarity;
        totalWer += recording.evaluation!.wer;
        totalCer += recording.evaluation!.cer;
        totalMos += recording.evaluation!.mos;
      }
    }

    final evalCount = evaluatedRecordings.length;

    return ReportMetrics(
      totalSessions: uniqueSessions.length,
      totalRecordings: recordings.length,
      totalWords: uniqueWords.length,
      wordsCompleted: evaluatedRecordings
          .where((r) => r.evaluation!.overallScore >= 70)
          .map((r) => r.wordId)
          .toSet()
          .length,
      averageAccuracy: evalCount > 0 ? totalAccuracy / evalCount : 0,
      averageSimilarity: evalCount > 0 ? totalSimilarity / evalCount : 0,
      averageWer: evalCount > 0 ? totalWer / evalCount : 0,
      averageCer: evalCount > 0 ? totalCer / evalCount : 0,
      averageMos: evalCount > 0 ? totalMos / evalCount : 0,
      overallProgress: 0, // Would need historical data to calculate
      practiceTimeMinutes: totalDurationMs ~/ 60000,
    );
  }

  /// Mark report as sent
  Future<bool> markReportAsSent({
    required String reportId,
    required String sentTo,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.reportsCollection)
          .doc(reportId)
          .update({
        'isSent': true,
        'sentAt': Timestamp.now(),
        'sentTo': sentTo,
      });

      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = _reports[index].copyWith(
          isSent: true,
          sentAt: DateTime.now(),
          sentTo: sentTo,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error marking report as sent: $e');
      return false;
    }
  }

  /// Get statistics for dashboard
  Future<Map<String, dynamic>> getChildStatistics(String childId) async {
    try {
      // Get all recordings
      final recordingsSnapshot = await _firestore
          .collection(AppConstants.recordingsCollection)
          .where('childId', isEqualTo: childId)
          .get();

      final allRecordings = recordingsSnapshot.docs
          .map((doc) => RecordingModel.fromFirestore(doc))
          .toList();

      // Get today's recordings
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayRecordings = allRecordings
          .where((r) => r.recordedAt.isAfter(todayStart))
          .toList();

      // Calculate averages
      final evaluatedAll = allRecordings.where((r) => r.isEvaluated).toList();
      final evaluatedToday = todayRecordings.where((r) => r.isEvaluated).toList();

      double avgScoreAll = 0;
      double avgScoreToday = 0;

      if (evaluatedAll.isNotEmpty) {
        avgScoreAll = evaluatedAll
                .map((r) => r.evaluation!.overallScore)
                .reduce((a, b) => a + b) /
            evaluatedAll.length;
      }

      if (evaluatedToday.isNotEmpty) {
        avgScoreToday = evaluatedToday
                .map((r) => r.evaluation!.overallScore)
                .reduce((a, b) => a + b) /
            evaluatedToday.length;
      }

      return {
        'totalRecordings': allRecordings.length,
        'todayRecordings': todayRecordings.length,
        'totalWords': allRecordings.map((r) => r.wordId).toSet().length,
        'averageScoreAll': avgScoreAll,
        'averageScoreToday': avgScoreToday,
        'evaluatedCount': evaluatedAll.length,
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }

  /// Get recordings with filters
  List<RecordingModel> getFilteredRecordings({
    String? wordId,
    bool? isEvaluated,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _recordings.where((r) {
      if (wordId != null && r.wordId != wordId) return false;
      if (isEvaluated != null && r.isEvaluated != isEvaluated) return false;
      if (fromDate != null && r.recordedAt.isBefore(fromDate)) return false;
      if (toDate != null && r.recordedAt.isAfter(toDate)) return false;
      return true;
    }).toList();
  }

  // Helper methods
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

  /// Clear all data
  void clear() {
    _recordings = [];
    _reports = [];
    _error = null;
    notifyListeners();
  }
}
