import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Result of speech evaluation
class EvaluationResult {
  final double accuracy;      // 0-100: How accurate the pronunciation is
  final double similarity;    // 0-100: Text similarity (Levenshtein-based)
  final double wer;           // Word Error Rate (lower is better, 0-100)
  final double cer;           // Character Error Rate (lower is better, 0-100)
  final double mos;           // Mean Opinion Score (1-5)
  final double overallScore;  // 0-100: Combined score
  final String? transcription; // What was said (from speech-to-text)
  final String level;         // ممتاز، جيد، متوسط، يحتاج تحسين
  final String? feedback;     // Feedback message
  final int durationMs;       // Recording duration

  EvaluationResult({
    required this.accuracy,
    required this.similarity,
    required this.wer,
    required this.cer,
    required this.mos,
    required this.overallScore,
    this.transcription,
    required this.level,
    this.feedback,
    required this.durationMs,
  });
}

/// Speech Evaluation Service with REAL text comparison
class SpeechEvaluationService {
  
  /// Evaluate transcription against expected text
  /// 
  /// This method takes the transcription from Web Speech API
  /// and compares it to the expected word using real algorithms
  EvaluationResult evaluateTranscription({
    required String? transcription,
    required String expectedText,
    required int durationMs,
  }) {
    // If no transcription, return poor score
    if (transcription == null || transcription.trim().isEmpty) {
      return EvaluationResult(
        accuracy: 0,
        similarity: 0,
        wer: 100,
        cer: 100,
        mos: 1,
        overallScore: 0,
        transcription: null,
        level: 'لم يتم التعرف على الكلام',
        feedback: 'لم نتمكن من التعرف على ما قلته. حاول التحدث بصوت أوضح.',
        durationMs: durationMs,
      );
    }

    final cleanTranscription = _cleanArabicText(transcription);
    final cleanExpected = _cleanArabicText(expectedText);

    // Calculate all metrics
    final similarity = _calculateSimilarity(cleanTranscription, cleanExpected);
    final wer = _calculateWER(cleanTranscription, cleanExpected);
    final cer = _calculateCER(cleanTranscription, cleanExpected);
    final accuracy = _calculateAccuracy(cleanTranscription, cleanExpected);
    
    // MOS based on overall quality (simulated based on other metrics)
    final mos = _calculateMOS(accuracy, similarity, wer, cer);
    
    // Calculate overall score
    final overallScore = _calculateOverallScore(
      accuracy: accuracy,
      similarity: similarity,
      wer: wer,
      cer: cer,
      mos: mos,
    );

    // Get level and feedback
    final level = _getLevel(overallScore);
    final feedback = _generateFeedback(
      overallScore: overallScore,
      expectedText: expectedText,
      transcription: cleanTranscription,
      accuracy: accuracy,
    );

    return EvaluationResult(
      accuracy: accuracy,
      similarity: similarity,
      wer: wer,
      cer: cer,
      mos: mos,
      overallScore: overallScore,
      transcription: cleanTranscription,
      level: level,
      feedback: feedback,
      durationMs: durationMs,
    );
  }

  /// Clean Arabic text for comparison
  String _cleanArabicText(String text) {
    // Remove diacritics (تشكيل)
    final diacritics = RegExp(r'[\u064B-\u065F\u0670]');
    String cleaned = text.replaceAll(diacritics, '');
    
    // Remove extra spaces
    cleaned = cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Normalize some Arabic characters
    cleaned = cleaned
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
    
    return cleaned.toLowerCase();
  }

  /// Calculate similarity using Levenshtein distance (0-100)
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 100.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLen = math.max(s1.length, s2.length);
    
    return ((1 - (distance / maxLen)) * 100).clamp(0, 100);
  }

  /// Levenshtein distance algorithm
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = math.min(
          math.min(v1[j] + 1, v0[j + 1] + 1),
          v0[j] + cost,
        );
      }

      final temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  /// Calculate Word Error Rate (WER)
  double _calculateWER(String transcription, String expected) {
    final transWords = transcription.split(' ').where((w) => w.isNotEmpty).toList();
    final expWords = expected.split(' ').where((w) => w.isNotEmpty).toList();

    if (expWords.isEmpty) return 0;
    if (transWords.isEmpty) return 100;

    // For single word, use character-level comparison
    if (expWords.length == 1 && transWords.length == 1) {
      final distance = _levenshteinDistance(transWords[0], expWords[0]);
      return (distance / expWords[0].length * 100).clamp(0, 100);
    }

    // For multiple words, use word-level comparison
    int substitutions = 0;
    int deletions = 0;
    int insertions = 0;

    // Simple word matching
    final matched = <int>{};
    for (int i = 0; i < transWords.length; i++) {
      bool found = false;
      for (int j = 0; j < expWords.length; j++) {
        if (!matched.contains(j) && transWords[i] == expWords[j]) {
          matched.add(j);
          found = true;
          break;
        }
      }
      if (!found) {
        // Check if it's a substitution or insertion
        if (i < expWords.length) {
          substitutions++;
        } else {
          insertions++;
        }
      }
    }
    deletions = expWords.length - matched.length;

    final wer = ((substitutions + deletions + insertions) / expWords.length) * 100;
    return wer.clamp(0, 100);
  }

  /// Calculate Character Error Rate (CER)
  double _calculateCER(String transcription, String expected) {
    if (expected.isEmpty) return 0;
    if (transcription.isEmpty) return 100;

    final distance = _levenshteinDistance(transcription, expected);
    return ((distance / expected.length) * 100).clamp(0, 100);
  }

  /// Calculate accuracy based on exact match and similarity
  double _calculateAccuracy(String transcription, String expected) {
    // Exact match
    if (transcription == expected) return 100;
    
    // Check if transcription contains the expected word
    if (transcription.contains(expected)) return 95;
    if (expected.contains(transcription) && transcription.length > expected.length * 0.7) {
      return 90;
    }
    
    // Use similarity as base for accuracy
    final similarity = _calculateSimilarity(transcription, expected);
    
    // Boost accuracy if first character matches (important for Arabic)
    double boost = 0;
    if (transcription.isNotEmpty && expected.isNotEmpty && 
        transcription[0] == expected[0]) {
      boost = 10;
    }
    
    return (similarity + boost).clamp(0, 100);
  }

  /// Calculate MOS (Mean Opinion Score) based on other metrics
  double _calculateMOS(double accuracy, double similarity, double wer, double cer) {
    // Convert metrics to a 1-5 scale
    final avgScore = (accuracy + similarity + (100 - wer) + (100 - cer)) / 4;
    return (avgScore / 20).clamp(1, 5);
  }

  /// Calculate overall score using weighted average
  double _calculateOverallScore({
    required double accuracy,
    required double similarity,
    required double wer,
    required double cer,
    required double mos,
  }) {
    // Weights as defined in requirements
    const accuracyWeight = 0.30;
    const similarityWeight = 0.25;
    const werWeight = 0.20;
    const cerWeight = 0.15;
    const mosWeight = 0.10;

    final score = (accuracy * accuracyWeight) +
        (similarity * similarityWeight) +
        ((100 - wer) * werWeight) +  // Invert WER (lower is better)
        ((100 - cer) * cerWeight) +  // Invert CER (lower is better)
        ((mos * 20) * mosWeight);    // Scale MOS to 0-100

    return score.clamp(0, 100);
  }

  /// Get level string based on score
  String _getLevel(double score) {
    if (score >= 90) return 'ممتاز';
    if (score >= 75) return 'جيد جداً';
    if (score >= 60) return 'جيد';
    if (score >= 40) return 'مقبول';
    return 'يحتاج تحسين';
  }

  /// Generate feedback based on evaluation
  String _generateFeedback({
    required double overallScore,
    required String expectedText,
    required String transcription,
    required double accuracy,
  }) {
    if (overallScore >= 90) {
      return 'ممتاز! 🌟 نطقك لكلمة "$expectedText" كان واضحاً وصحيحاً. استمر في العمل الرائع!';
    } else if (overallScore >= 75) {
      return 'جيد جداً! 👍 نطقك لـ "$expectedText" قريب جداً من الصحيح. حاول التركيز على مخارج الحروف.';
    } else if (overallScore >= 60) {
      return 'جيد! 💪 تحتاج لمزيد من التمرين على "$expectedText". استمع للنطق الصحيح وحاول مرة أخرى.';
    } else if (overallScore >= 40) {
      if (transcription != expectedText) {
        return 'قلت: "$transcription" بينما المطلوب: "$expectedText". حاول الاستماع جيداً للنطق الصحيح ثم أعد المحاولة.';
      }
      return 'مقبول. كلمة "$expectedText" تحتاج تمريناً أكثر. استمع جيداً للنطق الصحيح وكرر ببطء.';
    } else {
      return 'لا بأس! 🎯 كلمة "$expectedText" صعبة قليلاً. جرب أن تقولها ببطء مقطعاً مقطعاً.';
    }
  }

  /// Legacy method for backward compatibility
  Future<EvaluationResult> evaluate({
    required String recordingPath,
    required String expectedText,
    required String correctPronunciationUrl,
  }) async {
    // This is called when we don't have transcription yet
    // Return a pending result that will be updated with real transcription
    await Future.delayed(const Duration(seconds: 1));
    
    return EvaluationResult(
      accuracy: 0,
      similarity: 0,
      wer: 100,
      cer: 100,
      mos: 1,
      overallScore: 0,
      transcription: null,
      level: 'جاري التحليل...',
      feedback: 'يرجى الانتظار...',
      durationMs: 0,
    );
  }
}
