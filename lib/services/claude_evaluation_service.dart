import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// AI-powered evaluation result from Claude
class AIEvaluationResult {
  final bool success;
  final double accuracy;
  final double similarity;
  final double wer;
  final double cer;
  final double mos;
  final double overallScore;
  final String level;
  final String feedback;
  final String? detailedAnalysis;
  final List<String>? improvements;
  final String? encouragement;
  final String? error;

  AIEvaluationResult({
    required this.success,
    this.accuracy = 0,
    this.similarity = 0,
    this.wer = 100,
    this.cer = 100,
    this.mos = 1,
    this.overallScore = 0,
    this.level = 'يحتاج تحسين',
    this.feedback = '',
    this.detailedAnalysis,
    this.improvements,
    this.encouragement,
    this.error,
  });

  factory AIEvaluationResult.fromJson(Map<String, dynamic> json) {
    return AIEvaluationResult(
      success: true,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0,
      wer: (json['wer'] as num?)?.toDouble() ?? 100,
      cer: (json['cer'] as num?)?.toDouble() ?? 100,
      mos: (json['mos'] as num?)?.toDouble() ?? 1,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
      level: json['level'] as String? ?? 'يحتاج تحسين',
      feedback: json['feedback'] as String? ?? '',
      detailedAnalysis: json['detailedAnalysis'] as String?,
      improvements: (json['improvements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      encouragement: json['encouragement'] as String?,
    );
  }

  factory AIEvaluationResult.error(String errorMessage) {
    return AIEvaluationResult(
      success: false,
      error: errorMessage,
    );
  }
}

/// Claude API Service for intelligent speech evaluation
/// Uses Firebase Functions on Web to avoid CORS issues
class ClaudeEvaluationService {
  /// Evaluate a child's pronunciation using Claude AI
  Future<AIEvaluationResult> evaluate({
    required String expectedWord,
    required String? transcription,
    required String childName,
    required int childAge,
    required String childLevel,
  }) async {
    if (transcription == null || transcription.trim().isEmpty) {
      return AIEvaluationResult(
        success: true,
        accuracy: 0,
        similarity: 0,
        wer: 100,
        cer: 100,
        mos: 1,
        overallScore: 0,
        level: 'لم يتم التعرف على الكلام',
        feedback:
            'لم نتمكن من سماع ما قاله $childName. دعه يحاول مرة أخرى بصوت أوضح.',
        encouragement:
            'لا بأس! المحاولة هي الخطوة الأولى نحو النجاح. هيا نحاول مرة أخرى!',
      );
    }

    if (kIsWeb) {
      return _evaluateViaFirebase(
        expectedWord: expectedWord,
        transcription: transcription,
        childName: childName,
        childAge: childAge,
        childLevel: childLevel,
      );
    } else {
      return _evaluateDirect(
        expectedWord: expectedWord,
        transcription: transcription,
        childName: childName,
        childAge: childAge,
        childLevel: childLevel,
      );
    }
  }

  /// Evaluate via Firebase Functions (for Web)
  Future<AIEvaluationResult> _evaluateViaFirebase({
    required String expectedWord,
    required String transcription,
    required String childName,
    required int childAge,
    required String childLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.claudeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'expectedWord': expectedWord,
          'transcription': transcription,
          'childName': childName,
          'childAge': childAge,
          'childLevel': childLevel,
        }),
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AIEvaluationResult.fromJson(data);
        } else {
          return AIEvaluationResult.error(
              data['error'] ?? 'Unknown error from Firebase Function');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return AIEvaluationResult.error(
              errorData['error'] ?? 'HTTP ${response.statusCode}');
        } catch (_) {
          return AIEvaluationResult.error(
              'HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Claude evaluation error (Firebase): $e');
      return AIEvaluationResult.error(e.toString());
    }
  }

  /// Evaluate directly via Claude API (for Mobile/Desktop)
  Future<AIEvaluationResult> _evaluateDirect({
    required String expectedWord,
    required String transcription,
    required String childName,
    required int childAge,
    required String childLevel,
  }) async {
    if (!ApiConfig.isClaudeConfigured) {
      return AIEvaluationResult.error('Claude API key not configured');
    }

    try {
      final prompt = _buildEvaluationPrompt(
        expectedWord: expectedWord,
        transcription: transcription,
        childName: childName,
        childAge: childAge,
        childLevel: childLevel,
      );

      final response = await http.post(
        Uri.parse(ApiConfig.claudeDirectUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiConfig.claudeApiKey,
          'anthropic-version': ApiConfig.claudeApiVersion,
        },
        body: json.encode({
          'model': ApiConfig.claudeModel,
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content']?[0]?['text'] as String?;

        if (content != null) {
          return _parseEvaluationResponse(content);
        } else {
          return AIEvaluationResult.error('Empty response from Claude');
        }
      } else {
        final errorData = json.decode(response.body);
        return AIEvaluationResult.error(
          errorData['error']?['message'] ?? 'API error (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Claude evaluation error: $e');
      return AIEvaluationResult.error(e.toString());
    }
  }

  String _buildEvaluationPrompt({
    required String expectedWord,
    required String transcription,
    required String childName,
    required int childAge,
    required String childLevel,
  }) {
    return '''
أنت مساعد متخصص في علاج النطق للأطفال المصابين بالتوحد. مهمتك تقييم نطق الطفل وتقديم ملاحظات مشجعة ومفيدة.

معلومات الطفل:
- الاسم: $childName
- العمر: $childAge سنوات
- المستوى: $childLevel

الكلمة المطلوب نطقها: "$expectedWord"
ما نطقه الطفل: "$transcription"

قم بتقييم النطق وأرجع النتيجة بصيغة JSON فقط (بدون أي نص إضافي) كالتالي:

{
  "accuracy": <رقم من 0 إلى 100 يمثل دقة النطق>,
  "similarity": <رقم من 0 إلى 100 يمثل التشابه النصي>,
  "wer": <معدل خطأ الكلمات من 0 إلى 100، أقل أفضل>,
  "cer": <معدل خطأ الأحرف من 0 إلى 100، أقل أفضل>,
  "mos": <تقييم جودة النطق من 1 إلى 5>,
  "overallScore": <الدرجة الإجمالية من 0 إلى 100>,
  "level": "<ممتاز أو جيد جداً أو جيد أو مقبول أو يحتاج تحسين>",
  "feedback": "<ملاحظة قصيرة ومشجعة للطفل باللغة العربية>",
  "detailedAnalysis": "<تحليل مفصل للنطق للمدرب>",
  "improvements": ["<اقتراح تحسين 1>", "<اقتراح تحسين 2>"],
  "encouragement": "<رسالة تشجيعية قصيرة ومحببة للطفل>"
}

ملاحظات مهمة:
1. كن مشجعاً ولطيفاً - هذا طفل مصاب بالتوحد ويحتاج دعماً
2. استخدم لغة بسيطة مناسبة لعمر الطفل
3. ركز على الإيجابيات حتى لو كان النطق غير صحيح
4. قدم اقتراحات عملية وبسيطة للتحسين
5. إذا كان النطق صحيحاً تماماً، أعطِ درجات عالية واحتفل مع الطفل
6. إذا كان النطق قريباً، شجع الطفل وأخبره أنه على الطريق الصحيح

أرجع JSON فقط بدون أي نص قبله أو بعده.
''';
  }

  AIEvaluationResult _parseEvaluationResponse(String response) {
    try {
      String jsonStr = response.trim();

      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```json?\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
      }

      // Find JSON object in response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }

      final data = json.decode(jsonStr) as Map<String, dynamic>;
      return AIEvaluationResult.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing Claude response: $e');
      debugPrint('Response was: $response');

      return AIEvaluationResult(
        success: true,
        accuracy: 50,
        similarity: 50,
        wer: 50,
        cer: 50,
        mos: 2.5,
        overallScore: 50,
        level: 'متوسط',
        feedback: 'تم التقييم بنجاح. استمر في المحاولة!',
        error: 'Warning: Could not parse full response',
      );
    }
  }
}
