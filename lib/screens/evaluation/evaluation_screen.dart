import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/word_model.dart';
import '../../models/child_model.dart';
import '../../models/recording_model.dart';
import '../../providers/evaluation_provider.dart';
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
  final SpeechEvaluationService _evaluationService = SpeechEvaluationService();

  bool _isEvaluating = true;
  bool _isPlayingCorrect = false;
  bool _isPlayingRecording = false;
  EvaluationResult? _result;
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
      await Future.delayed(const Duration(milliseconds: 500));

      final result = _evaluationService.evaluateTranscription(
        transcription: widget.transcription,
        expectedText: widget.word.text,
        durationMs: 2000,
      );

      setState(() {
        _result = result;
        _isEvaluating = false;
      });

      await _saveRecording(result);
      _scoreAnimationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isEvaluating = false;
      });
    }
  }

  Future<void> _saveRecording(EvaluationResult result) async {
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
          child: _isEvaluating ? _buildLoading() : _error != null ? _buildError() : _buildResults(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text('جاري تحليل النطق...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (widget.transcription != null) ...[
            const SizedBox(height: 8),
            Text('تم التعرف على: "${widget.transcription}"', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('حدث خطأ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('حاول مرة أخرى')),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final result = _result!;
    final scoreColor = result.overallScore >= 70 ? AppColors.primaryGreen : 
                       result.overallScore >= 50 ? AppColors.primaryOrange : AppColors.error;

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
            ],
          ),
          
          const SizedBox(height: 24),

          // Score Circle
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final score = (result.overallScore * _scoreAnimation.value).round();
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
                            value: _scoreAnimation.value * result.overallScore / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          ),
                        ),
                        Text('$score', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: scoreColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(result.level, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scoreColor)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => Icon(
                        i < result.overallScore / 20 ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      )),
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
                        Text(widget.word.text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      ],
                    ),
                    Icon(
                      result.transcription == widget.word.text ? Icons.check_circle : Icons.compare_arrows,
                      color: result.transcription == widget.word.text ? AppColors.primaryGreen : AppColors.primaryOrange,
                      size: 32,
                    ),
                    Column(
                      children: [
                        const Text('ما قلته', style: TextStyle(color: Colors.grey)),
                        Text(
                          result.transcription ?? '—',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: result.transcription == widget.word.text ? AppColors.primaryGreen : AppColors.primaryOrange,
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
                _buildMetricRow('الدقة', result.accuracy),
                _buildMetricRow('التشابه', result.similarity),
                _buildMetricRow('WER (أقل أفضل)', result.wer, inverted: true),
                _buildMetricRow('CER (أقل أفضل)', result.cer, inverted: true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Feedback
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.primaryPurple),
                    SizedBox(width: 8),
                    Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(result.feedback ?? '', style: const TextStyle(height: 1.5)),
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
                  onPressed: () => Navigator.popUntil(context, (r) => r.settings.name == Routes.categoryWords || r.isFirst),
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
        ],
      ),
    );
  }

  Widget _buildMetricRow(String name, double value, {bool inverted = false}) {
    final displayValue = inverted ? (100 - value).clamp(0, 100) : value;
    final color = displayValue >= 70 ? AppColors.primaryGreen : 
                  displayValue >= 50 ? AppColors.primaryOrange : AppColors.error;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name),
              Text('${value.round()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
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
