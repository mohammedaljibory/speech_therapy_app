import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../config/themes.dart';
import '../../models/recording_model.dart';
import '../../models/word_model.dart';
import '../../providers/evaluation_provider.dart';
import '../../providers/categories_provider.dart';

class ComparisonScreen extends StatefulWidget {
  final String childId;
  final String wordId;

  const ComparisonScreen({
    super.key,
    required this.childId,
    required this.wordId,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<RecordingModel> _recordings = [];
  WordModel? _word;
  bool _isLoading = true;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load recordings for this word
      final evaluationProvider = context.read<EvaluationProvider>();
      final recordings = await evaluationProvider.loadRecordingsForWord(
        childId: widget.childId,
        wordId: widget.wordId,
      );

      // Load word details
      final categoriesProvider = context.read<CategoriesProvider>();
      final word = categoriesProvider.getWordById(widget.wordId);

      setState(() {
        _recordings = recordings;
        _word = word;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _playRecording(String audioUrl, String recordingId) async {
    try {
      if (_playingId == recordingId) {
        await _audioPlayer.stop();
        setState(() => _playingId = null);
      } else {
        await _audioPlayer.stop();
        setState(() => _playingId = recordingId);
        await _audioPlayer.play(UrlSource(audioUrl));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _playingId = null);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تشغيل التسجيل')),
      );
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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recordings.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مقارنة التسجيلات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_word != null)
                  Text(
                    'كلمة: ${_word!.text}',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_recordings.length} تسجيل',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تسجيلات للمقارنة',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتسجيل الكلمة عدة مرات لرؤية التقدم',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_word != null) _buildWordCard(),
          const SizedBox(height: 20),
          _buildProgressChart(),
          const SizedBox(height: 20),
          _buildStatsSummary(),
          const SizedBox(height: 20),
          _buildRecordingsList(),
        ],
      ),
    );
  }

  Widget _buildWordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_word!.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _word!.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
              ),
            )
          else
            _buildImagePlaceholder(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _word!.text,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_word!.textEn != null)
                  Text(
                    _word!.textEn!,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (_word!.phonetic != null)
                  Text(
                    '/${_word!.phonetic}/',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryPurple,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _word?.text[0] ?? '?',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    final evaluatedRecordings = _recordings
        .where((r) => r.isEvaluated && r.evaluation != null)
        .toList()
        .reversed
        .toList();

    if (evaluatedRecordings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'تطور الدرجات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < evaluatedRecordings.length) {
                          return Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (evaluatedRecordings.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: evaluatedRecordings.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.evaluation!.overallScore,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primaryBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: AppColors.primaryBlue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryBlue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200));
  }

  Widget _buildStatsSummary() {
    final evaluatedRecordings = _recordings
        .where((r) => r.isEvaluated && r.evaluation != null)
        .toList();

    if (evaluatedRecordings.isEmpty) return const SizedBox.shrink();

    final scores = evaluatedRecordings.map((r) => r.evaluation!.overallScore).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final improvement = scores.length > 1 ? scores.last - scores.first : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'المتوسط',
            avgScore.toStringAsFixed(0),
            Icons.analytics,
            AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'الأعلى',
            maxScore.toStringAsFixed(0),
            Icons.arrow_upward,
            AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'التحسن',
            '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(0)}',
            improvement >= 0 ? Icons.trending_up : Icons.trending_down,
            improvement >= 0 ? AppColors.primaryGreen : AppColors.error,
          ),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'جميع التسجيلات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recordings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final recording = _recordings[index];
            return _buildRecordingCard(recording, index);
          },
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 400));
  }

  Widget _buildRecordingCard(RecordingModel recording, int index) {
    final isPlaying = _playingId == recording.id;
    final hasEvaluation = recording.isEvaluated && recording.evaluation != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? AppColors.primaryBlue : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasEvaluation
                      ? Color(recording.evaluation!.levelColorValue).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#${_recordings.length - index}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasEvaluation
                          ? Color(recording.evaluation!.levelColorValue)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy/MM/dd - HH:mm').format(recording.recordedAt),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'المدة: ${recording.formattedDuration} ثانية',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasEvaluation) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(recording.evaluation!.levelColorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        recording.evaluation!.levelEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recording.evaluation!.overallScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(recording.evaluation!.levelColorValue),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'غير مقيّم',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _playRecording(recording.audioUrl, recording.id),
                icon: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          if (hasEvaluation) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricChip('الدقة', recording.evaluation!.accuracy),
                _buildMetricChip('التشابه', recording.evaluation!.similarity),
                _buildMetricChip('MOS', recording.evaluation!.mos, isMos: true),
              ],
            ),
            if (recording.evaluation!.transcription != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ما تم التعرف عليه: "${recording.evaluation!.transcription}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, double value, {bool isMos = false}) {
    final displayValue = isMos ? value.toStringAsFixed(1) : '${value.toStringAsFixed(0)}%';
    return Column(
      children: [
        Text(
          displayValue,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
