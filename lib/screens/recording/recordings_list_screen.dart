import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'recording_screen_io.dart'
    if (dart.library.html) 'recording_screen_web.dart' as platform;

class RecordingsListScreen extends StatefulWidget {
  final String? childId;

  const RecordingsListScreen({super.key, this.childId});

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  List<Map<String, dynamic>> _recordings = [];
  List<ChildModel> _children = [];
  String? _selectedChildId;
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final childrenProvider = context.read<ChildrenProvider>();
      final categoriesProvider = context.read<CategoriesProvider>();

      // Load children
      await childrenProvider.loadChildren(authProvider.userId!);
      _children = childrenProvider.children;

      // Load categories and words
      await categoriesProvider.loadCategories();

      // If no child selected and we have children, select first
      if (_selectedChildId == null && _children.isNotEmpty) {
        _selectedChildId = _children.first.id;
      }

      // Load recordings for selected child
      if (_selectedChildId != null) {
        await _loadRecordings();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _loadRecordings() async {
    if (_selectedChildId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.recordingsCollection)
          .where('childId', isEqualTo: _selectedChildId)
          .orderBy('recordedAt', descending: true)
          .limit(50)
          .get();

      _recordings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error loading recordings: $e');
      _recordings = [];
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
              _buildHeader(),
              _buildChildSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recordings.isEmpty
                        ? _buildEmptyState()
                        : _buildRecordingsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CustomIconButton(
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          const Icon(Icons.mic, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text(
            'التسجيلات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
      ).animate().fadeIn(),
    );
  }

  Widget _buildChildSelector() {
    if (_children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedChildId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            hint: const Text('اختر طفل'),
            items: _children.map((child) {
              return DropdownMenuItem<String>(
                value: child.id,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Text(
                        child.name.isNotEmpty ? child.name[0] : '?',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(child.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() {
                _selectedChildId = value;
                _isLoading = true;
              });
              await _loadRecordings();
              setState(() => _isLoading = false);
            },
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.mic_none,
              size: 50,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد تسجيلات',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ جلسة تدريب لإنشاء تسجيلات',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'بدء التدريب',
            icon: Icons.play_arrow,
            onPressed: () => context.navigateTo(Routes.categories),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildRecordingsList() {
    final categoriesProvider = context.read<CategoriesProvider>();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _recordings.length,
        itemBuilder: (context, index) {
          final recording = _recordings[index];
          final wordId = recording['wordId'] as String?;
          final word = wordId != null ? categoriesProvider.getWordById(wordId) : null;
          // Get score from evaluation.overallScore or fallback to score field
          final evaluation = recording['evaluation'] as Map<String, dynamic>?;
          final score = (evaluation?['overallScore'] as num?)?.toDouble() ??
                        (recording['score'] as num?)?.toDouble() ?? 0;
          final recordedAt = recording['recordedAt'] as Timestamp?;
          // Get word text from recording if available
          final wordText = word?.text ?? recording['wordText'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showRecordingDetails(recording, wordText),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getScoreColor(score).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${score.toInt()}%',
                              style: TextStyle(
                                color: _getScoreColor(score),
                                fontWeight: FontWeight.bold,
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
                                wordText ?? 'كلمة غير معروفة',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (evaluation?['transcription'] != null || recording['transcription'] != null)
                                Text(
                                  'النص: ${evaluation?['transcription'] ?? recording['transcription']}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                              onPressed: () => _showRecordingDetails(recording, wordText),
                              tooltip: 'تفاصيل',
                            ),
                            if (word != null)
                              IconButton(
                                icon: const Icon(Icons.compare_arrows, color: AppColors.primaryOrange),
                                onPressed: () {
                                  context.navigateTo(Routes.comparison, arguments: {
                                    'childId': _selectedChildId,
                                    'wordId': word.id,
                                  });
                                },
                                tooltip: 'مقارنة',
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (recordedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('yyyy/MM/dd - HH:mm').format(recordedAt.toDate()),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
        },
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showRecordingDetails(Map<String, dynamic> recording, String? wordText) {
    final evaluation = recording['evaluation'] as Map<String, dynamic>?;
    final audioUrl = recording['audioUrl'] as String?;
    final recordedAt = recording['recordedAt'] as Timestamp?;
    // Get score from evaluation.overallScore
    final score = (evaluation?['overallScore'] as num?)?.toDouble() ??
                  (recording['score'] as num?)?.toDouble() ?? 0;

    // Extract metrics from evaluation
    final accuracy = (evaluation?['accuracy'] as num?)?.toDouble() ?? 0;
    final similarity = (evaluation?['similarity'] as num?)?.toDouble() ?? 0;
    final wer = (evaluation?['wer'] as num?)?.toDouble() ?? 0;
    final cer = (evaluation?['cer'] as num?)?.toDouble() ?? 0;
    final mos = (evaluation?['mos'] as num?)?.toDouble() ?? 0;
    final feedback = evaluation?['feedback'] as String? ?? '';
    final transcription = evaluation?['transcription'] as String? ?? recording['transcription'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isPlaying = false;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    wordText ?? 'تفاصيل التسجيل',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (recordedAt != null)
                    Text(
                      DateFormat('yyyy/MM/dd - HH:mm').format(recordedAt.toDate()),
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 24),

                  // Play Audio Button
                  if (audioUrl != null && audioUrl.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          setModalState(() => isPlaying = true);
                          if (kIsWeb) {
                            await platform.playAudioWeb(audioUrl);
                          } else {
                            await _audioPlayer.stop();
                            await _audioPlayer.play(UrlSource(audioUrl));
                          }
                          Future.delayed(const Duration(seconds: 3), () {
                            if (ctx.mounted) setModalState(() => isPlaying = false);
                          });
                        } catch (e) {
                          setModalState(() => isPlaying = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل في تشغيل الصوت: $e')),
                          );
                        }
                      },
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(isPlaying ? 'جاري التشغيل...' : 'تشغيل التسجيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Score Circle
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${score.toInt()}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(score),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transcription
                  if (transcription != null && transcription.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('ما قاله الطفل:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            transcription,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Metrics Grid
                  const Text(
                    'المقاييس التفصيلية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricTile('الدقة (Accuracy)', accuracy, '%'),
                  _buildMetricTile('التشابه (Similarity)', similarity, '%'),
                  _buildMetricTile('WER - معدل خطأ الكلمات', wer, '%', inverted: true),
                  _buildMetricTile('CER - معدل خطأ الأحرف', cer, '%', inverted: true),
                  _buildMetricTile('MOS - جودة النطق', mos, '/5', isMos: true),

                  if (feedback.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, color: AppColors.primaryPurple),
                              const SizedBox(width: 8),
                              const Text('ملاحظات التقييم', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(feedback, style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Close Button
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile(String name, double value, String suffix, {bool inverted = false, bool isMos = false}) {
    final displayValue = inverted ? (100 - value).clamp(0, 100) : value;
    final color = isMos
        ? (value >= 4 ? Colors.green : value >= 3 ? Colors.orange : Colors.red)
        : (displayValue >= 70 ? Colors.green : displayValue >= 50 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isMos ? '${value.toStringAsFixed(1)}$suffix' : '${value.toInt()}$suffix',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
