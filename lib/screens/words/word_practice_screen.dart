import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/word_model.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';

class WordPracticeScreen extends StatefulWidget {
  final WordModel word;
  final String categoryName;

  const WordPracticeScreen({
    super.key,
    required this.word,
    required this.categoryName,
  });

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _transcriptionController = TextEditingController();

  // State
  bool _isPlayingCorrect = false;
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isEvaluating = false;
  ChildModel? _selectedChild;

  // Recording timer
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadChildren();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadChildren() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId != null) {
      await context.read<ChildrenProvider>().loadChildren(authProvider.userId!);
      final children = context.read<ChildrenProvider>().children;
      if (children.isNotEmpty && _selectedChild == null) {
        setState(() => _selectedChild = children.first);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  Future<void> _playCorrectPronunciation() async {
    if (widget.word.correctPronunciationUrl.isEmpty) {
      _showSnackBar('لا يوجد ملف صوتي - اكتب ما نطقه الطفل في الحقل أدناه', isError: false);
      return;
    }

    setState(() => _isPlayingCorrect = true);

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.word.correctPronunciationUrl));

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingCorrect = false);
      });
    } catch (e) {
      _showSnackBar('فشل في تشغيل الصوت', isError: true);
      setState(() => _isPlayingCorrect = false);
    }
  }

  void _startRecording() {
    if (_selectedChild == null) {
      _showSnackBar('الرجاء اختيار الطفل أولاً', isError: true);
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _hasRecording = false;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration++);

      if (_recordingDuration >= 30) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();

    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });

    _showSnackBar('تم التسجيل! اكتب ما نطقه الطفل في الحقل أدناه', isError: false);
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingDuration = 0;
      _transcriptionController.clear();
    });
  }

  Future<void> _submitForEvaluation() async {
    if (_selectedChild == null) {
      _showSnackBar('الرجاء اختيار الطفل', isError: true);
      return;
    }

    if (!_hasRecording) {
      _showSnackBar('الرجاء تسجيل الصوت أولاً', isError: true);
      return;
    }

    final transcription = _transcriptionController.text.trim();
    if (transcription.isEmpty) {
      _showSnackBar('الرجاء كتابة ما نطقه الطفل', isError: true);
      return;
    }

    setState(() => _isEvaluating = true);

    try {
      Navigator.pushNamed(
        context,
        Routes.evaluation,
        arguments: {
          'word': widget.word,
          'child': _selectedChild,
          'recordingPath': 'recording_${DateTime.now().millisecondsSinceEpoch}',
          'categoryName': widget.categoryName,
          'transcription': transcription,
        },
      );
    } catch (e) {
      _showSnackBar('فشل في إرسال التقييم', isError: true);
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showChildSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('اختر الطفل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<ChildrenProvider>(
                  builder: (context, provider, _) {
                    if (provider.children.isEmpty) {
                      return const Center(child: Text('لا يوجد أطفال مسجلين'));
                    }

                    return ListView.builder(
                      itemCount: provider.children.length,
                      itemBuilder: (context, index) {
                        final child = provider.children[index];
                        final isSelected = _selectedChild?.id == child.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.withOpacity(0.1),
                            child: Text(
                              child.name[0],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(child.name),
                          subtitle: Text('العمر: ${child.age} سنوات'),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                              : null,
                          onTap: () {
                            setState(() => _selectedChild = child);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildChildSelector(),
                      const SizedBox(height: 20),
                      _buildWordCard(),
                      const SizedBox(height: 24),
                      _buildCorrectPronunciationButton(),
                      const SizedBox(height: 32),
                      _buildRecordingSection(),
                      const SizedBox(height: 24),
                      if (_hasRecording) ...[
                        _buildTranscriptionInput(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
                const Text('تمرين النطق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(widget.categoryName, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return InkWell(
      onTap: _showChildSelector,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _selectedChild != null
                  ? AppColors.primaryBlue
                  : AppColors.primaryBlue.withOpacity(0.1),
              child: _selectedChild != null
                  ? Text(_selectedChild!.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                  : Icon(Icons.person_add, color: AppColors.primaryBlue.withOpacity(0.5)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedChild?.name ?? 'اختر الطفل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedChild != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (_selectedChild != null)
                    Text('المستوى: ${_selectedChild!.level}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildWordCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: widget.word.imageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: widget.word.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: AppColors.primaryBlue.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: AppColors.primaryBlue.withOpacity(0.1),
                child: Center(
                  child: Text(
                    widget.word.text[0],
                    style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                ),
              ),
            )
                : Container(
              height: 200,
              color: AppColors.primaryBlue.withOpacity(0.1),
              child: Center(
                child: Text(
                  widget.word.text[0],
                  style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(widget.word.text, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (widget.word.textEn != null)
                  Text(widget.word.textEn!, style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                if (widget.word.phonetic != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('/${widget.word.phonetic}/', style: TextStyle(fontSize: 16, color: AppColors.primaryPurple, fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildCorrectPronunciationButton() {
    final hasAudio = widget.word.correctPronunciationUrl.isNotEmpty;

    return ElevatedButton.icon(
      onPressed: _isPlayingCorrect ? null : _playCorrectPronunciation,
      icon: Icon(hasAudio ? (_isPlayingCorrect ? Icons.stop : Icons.volume_up) : Icons.volume_off),
      label: Text(_isPlayingCorrect ? 'جاري التشغيل...' : hasAudio ? 'استمع للنطق الصحيح' : 'لا يوجد ملف صوتي'),
      style: ElevatedButton.styleFrom(
        backgroundColor: hasAudio ? AppColors.primaryBlue : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200));
  }

  Widget _buildRecordingSection() {
    return Column(
      children: [
        const Text('سجل نطق الطفل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? AppColors.error : AppColors.primaryGreen,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? AppColors.error : AppColors.primaryGreen).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 50, color: Colors.white),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        if (_isRecording)
          Column(
            children: [
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.error),
              ),
              const SizedBox(height: 8),
              const Text('جاري التسجيل... اضغط للإيقاف', style: TextStyle(color: Colors.grey)),
            ],
          )
        else
          Text(
            _hasRecording ? 'تم التسجيل بنجاح! ✓' : 'اضغط للتسجيل',
            style: TextStyle(
              color: _hasRecording ? AppColors.primaryGreen : AppColors.textSecondary,
              fontWeight: _hasRecording ? FontWeight.bold : FontWeight.normal,
            ),
          ),

        if (_hasRecording) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _deleteRecording,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('حذف التسجيل', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }

  Widget _buildTranscriptionInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              const Text('ماذا نطق الطفل؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اكتب ما سمعته من الطفل بالضبط',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transcriptionController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: widget.word.text,
              hintStyle: TextStyle(color: Colors.grey.shade300),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                _transcriptionController.text = widget.word.text;
              },
              child: const Text('نطق صحيح ✓', style: TextStyle(color: AppColors.primaryGreen)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isEvaluating ? null : _submitForEvaluation,
        icon: _isEvaluating
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        )
            : const Icon(Icons.send),
        label: Text(_isEvaluating ? 'جاري التقييم...' : 'إرسال للتقييم'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 400));
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}