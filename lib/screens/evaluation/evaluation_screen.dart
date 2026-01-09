import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../config/api_config.dart';
import '../../models/word_model.dart';
import '../../models/child_model.dart';
import '../../models/recording_model.dart';
import '../../providers/evaluation_provider.dart';
import '../../services/claude_evaluation_service.dart';
import '../../services/speech_evaluation_service.dart';

class EvaluationScreen extends StatefulWidget {
  final WordModel word;
  final ChildModel child;
  final String recordingPath;
  final String categoryName;
  final String? transcription;

  const EvaluationScreen({
    super.key,
    required this.word,
    required this.child,
    required this.recordingPath,
    required this.categoryName,
    this.transcription,
  });

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ClaudeEvaluationService _claudeService = ClaudeEvaluationService();
  final SpeechEvaluationService _fallbackService = SpeechEvaluationService();

  bool _isEvaluating = true;
  bool _isPlayingCorrect = false;
  bool _isPlayingRecording = false;
  bool _usedAI = false;
  AIEvaluationResult? _aiResult;
  EvaluationResult? _fallbackResult;
  String? _error;

  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreAnimationController, curve: Curves.easeOutCubic),
    );
    _runEvaluation();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  Future<void> _runEvaluation() async {
    setState(() => _isEvaluating = true);

    try {
      // Try Claude AI evaluation first
      if (ApiConfig.isClaudeConfigured) {
        final aiResult = await _claudeService.evaluate(
          expectedWord: widget.word.text,
          transcription: widget.transcription,
          childName: widget.child.name,
          childAge: widget.child.age,
          childLevel: widget.child.level,
        );

        if (aiResult.success) {
          setState(() {
            _aiResult = aiResult;
            _usedAI = true;
            _isEvaluating = false;
          });
          await _saveRecording(aiResult);
          _scoreAnimationController.forward();
          return;
        } else {
          debugPrint('Claude evaluation failed: ${aiResult.error}');
        }
      }

      // Fallback to local evaluation
      await Future.delayed(const Duration(milliseconds: 500));
      final result = _fallbackService.evaluateTranscription(
        transcription: widget.transcription,
        expectedText: widget.word.text,
        durationMs: 2000,
      );

      setState(() {
        _fallbackResult = result;
        _usedAI = false;
        _isEvaluating = false;
      });

      await _saveRecordingFromFallback(result);
      _scoreAnimationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isEvaluating = false;
      });
    }
  }

  Future<void> _saveRecording(AIEvaluationResult result) async {
    try {
      final evaluationProvider = context.read<EvaluationProvider>();

      final recording = await evaluationProvider.addRecording(
        childId: widget.child.id,
        wordId: widget.word.id,
        audioUrl: widget.recordingPath,
        durationMs: 2000,
      );

      if (recording != null) {
        await evaluationProvider.updateRecordingEvaluation(
          recordingId: recording.id,
          evaluation: EvaluationData(
            accuracy: result.accuracy,
            similarity: result.similarity,
            wer: result.wer,
            cer: result.cer,
            mos: result.mos,
            overallScore: result.overallScore,
            transcription: widget.transcription,
            evaluatedAt: DateTime.now(),
            feedback: result.feedback,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving recording: $e');
    }
  }

  Future<void> _saveRecordingFromFallback(EvaluationResult result) async {
    try {
      final evaluationProvider = context.read<EvaluationProvider>();

      final recording = await evaluationProvider.addRecording(
        childId: widget.child.id,
        wordId: widget.word.id,
        audioUrl: widget.recordingPath,
        durationMs: result.durationMs,
      );

      if (recording != null) {
        await evaluationProvider.updateRecordingEvaluation(
          recordingId: recording.id,
          evaluation: EvaluationData(
            accuracy: result.accuracy,
            similarity: result.similarity,
            wer: result.wer,
            cer: result.cer,
            mos: result.mos,
            overallScore: result.overallScore,
            transcription: result.transcription,
            evaluatedAt: DateTime.now(),
            feedback: result.feedback,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving recording: $e');
    }
  }

  Future<void> _playRecording() async {
    setState(() => _isPlayingRecording = true);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.recordingPath));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingRecording = false);
      });
    } catch (e) {
      setState(() => _isPlayingRecording = false);
    }
  }

  // Getters for unified access to results
  double get _overallScore => _aiResult?.overallScore ?? _fallbackResult?.overallScore ?? 0;
  double get _accuracy => _aiResult?.accuracy ?? _fallbackResult?.accuracy ?? 0;
  double get _similarity => _aiResult?.similarity ?? _fallbackResult?.similarity ?? 0;
  double get _wer => _aiResult?.wer ?? _fallbackResult?.wer ?? 100;
  double get _cer => _aiResult?.cer ?? _fallbackResult?.cer ?? 100;
  double get _mos => _aiResult?.mos ?? _fallbackResult?.mos ?? 0;
  String get _level => _aiResult?.level ?? _fallbackResult?.level ?? 'يحتاج تحسين';
  String get _feedback => _aiResult?.feedback ?? _fallbackResult?.feedback ?? '';
  String? get _transcription => widget.transcription ?? _fallbackResult?.transcription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F7FF), Color(0xFFFFFBF5)],
          ),
        ),
        child: SafeArea(
          child: _isEvaluating
              ? _buildLoading()
              : _error != null
                  ? _buildError()
                  : _buildResults(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI Brain Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              size: 60,
              color: AppColors.primaryPurple,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: const Duration(seconds: 2),
                color: AppColors.primaryPurple.withOpacity(0.3),
              ),
          const SizedBox(height: 24),
          Text(
            ApiConfig.isClaudeConfigured
                ? 'جاري التقييم بالذكاء الاصطناعي...'
                : 'جاري تحليل النطق...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.transcription != null) ...[
            Text(
              'ما قاله ${widget.child.name}: "${widget.transcription}"',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('حدث خطأ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _error ?? 'خطأ غير معروف',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _runEvaluation,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final scoreColor = _overallScore >= 70
        ? AppColors.primaryGreen
        : _overallScore >= 50
            ? AppColors.primaryOrange
            : AppColors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Text(
                  'نتيجة التقييم - ${widget.word.text}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // AI Badge
              if (_usedAI)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 16, color: AppColors.primaryPurple),
                      SizedBox(width: 4),
                      Text(
                        'AI',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Score Circle
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final score = (_overallScore * _scoreAnimation.value).round();
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: scoreColor.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: _scoreAnimation.value * _overallScore / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            if (_usedAI)
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.primaryPurple,
                                size: 20,
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _level,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < _overallScore / 20 ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

          const SizedBox(height: 24),

          // Comparison
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('مقارنة النطق', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('المطلوب', style: TextStyle(color: Colors.grey)),
                        Text(
                          widget.word.text,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _transcription == widget.word.text
                          ? Icons.check_circle
                          : Icons.compare_arrows,
                      color: _transcription == widget.word.text
                          ? AppColors.primaryGreen
                          : AppColors.primaryOrange,
                      size: 32,
                    ),
                    Column(
                      children: [
                        const Text('ما قاله', style: TextStyle(color: Colors.grey)),
                        Text(
                          _transcription ?? '—',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _transcription == widget.word.text
                                ? AppColors.primaryGreen
                                : AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Metrics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('التفاصيل', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildMetricRow('الدقة (Accuracy)', _accuracy),
                _buildMetricRow('التشابه (Similarity)', _similarity),
                _buildMetricRow('WER - معدل خطأ الكلمات', _wer, inverted: true),
                _buildMetricRow('CER - معدل خطأ الأحرف', _cer, inverted: true),
                _buildMetricRow('MOS - جودة النطق', _mos * 20), // MOS is 0-5, convert to percentage
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Feedback
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _usedAI
                  ? AppColors.primaryPurple.withOpacity(0.1)
                  : AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: _usedAI
                  ? Border.all(color: AppColors.primaryPurple.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _usedAI ? Icons.psychology : Icons.lightbulb,
                      color: _usedAI ? AppColors.primaryPurple : AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _usedAI ? 'تقييم الذكاء الاصطناعي' : 'ملاحظات',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_feedback, style: const TextStyle(height: 1.5)),

                // Additional AI insights
                if (_usedAI && _aiResult != null) ...[
                  if (_aiResult!.detailedAnalysis != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'تحليل مفصل للمدرب:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiResult!.detailedAnalysis!,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                  if (_aiResult!.improvements != null &&
                      _aiResult!.improvements!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'اقتراحات للتحسين:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ...(_aiResult!.improvements!.map(
                      (improvement) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.primaryPurple)),
                            Expanded(
                              child: Text(
                                improvement,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                  if (_aiResult!.encouragement != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _aiResult!.encouragement!,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Play Recording
          ElevatedButton.icon(
            onPressed: _isPlayingRecording ? null : _playRecording,
            icon: Icon(_isPlayingRecording ? Icons.pause : Icons.play_arrow),
            label: Text(_isPlayingRecording ? 'جاري التشغيل...' : 'استمع لتسجيلك'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('حاول مرة أخرى'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(
                    context,
                    (r) => r.settings.name == Routes.categoryWords || r.isFirst,
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('كلمة أخرى'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // API status indicator
          Text(
            _usedAI ? 'تم التقييم بواسطة Claude AI' : 'تم التقييم محلياً',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String name, double value, {bool inverted = false}) {
    final displayValue = inverted ? (100 - value).clamp(0, 100) : value;
    final color = displayValue >= 70
        ? AppColors.primaryGreen
        : displayValue >= 50
            ? AppColors.primaryOrange
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name),
              Text(
                '${value.round()}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
