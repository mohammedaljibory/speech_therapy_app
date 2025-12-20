import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/word_model.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';

/// Recording Screen - For direct recording access
class RecordingScreen extends StatefulWidget {
  final WordModel word;
  final String categoryName;

  const RecordingScreen({
    super.key,
    required this.word,
    required this.categoryName,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _transcriptionController = TextEditingController();

  bool _isRecording = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  ChildModel? _selectedChild;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId != null) {
      await context.read<ChildrenProvider>().loadChildren(authProvider.userId!);
      final children = context.read<ChildrenProvider>().children;
      if (children.length == 1) {
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
      _showSnackBar('لا يوجد ملف صوتي', isError: true);
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.word.correctPronunciationUrl));
    } catch (e) {
      _showSnackBar('فشل في تشغيل الصوت', isError: true);
    }
  }

  void _toggleRecording() {
    if (_selectedChild == null) {
      _showChildSelector();
      return;
    }

    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _hasRecording = false;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration++);
      if (_recordingDuration >= 30) _stopRecording();
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    _showSnackBar('تم التسجيل! اكتب ما نطقه الطفل', isError: false);
  }

  void _submitForEvaluation() {
    if (_selectedChild == null) {
      _showSnackBar('الرجاء اختيار الطفل', isError: true);
      return;
    }

    final transcription = _transcriptionController.text.trim();
    if (transcription.isEmpty) {
      _showSnackBar('الرجاء كتابة ما نطقه الطفل', isError: true);
      return;
    }

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
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChildSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر الطفل أولاً',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<ChildrenProvider>(
              builder: (context, provider, _) {
                if (provider.children.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا يوجد أطفال مسجلين'),
                  );
                }

                return Column(
                  children: provider.children.map((child) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          child.name[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(child.name),
                      subtitle: Text('العمر: ${child.age}'),
                      onTap: () {
                        setState(() => _selectedChild = child);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.word.text),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedChild != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    _selectedChild!.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(_selectedChild!.name),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Word Display
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.word.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.word.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildLetterAvatar(),
                        )
                      : _buildLetterAvatar(),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              // Word Text
              Text(
                widget.word.text,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // Listen Button
              TextButton.icon(
                onPressed: _playCorrectPronunciation,
                icon: const Icon(Icons.volume_up),
                label: const Text('استمع للنطق الصحيح'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 32),

              // Timer
              if (_isRecording)
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 16),

              // Record Button
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording 
                          ? 1.0 + (_pulseController.value * 0.2)
                          : 1.0,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording 
                              ? AppColors.error 
                              : AppColors.primaryGreen,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording 
                                  ? AppColors.error 
                                  : AppColors.primaryGreen).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: _isRecording ? 5 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _isRecording 
                    ? 'اضغط للإيقاف' 
                    : _hasRecording 
                        ? 'تم التسجيل ✓' 
                        : 'اضغط للتسجيل',
                style: TextStyle(
                  color: _hasRecording 
                      ? AppColors.primaryGreen 
                      : AppColors.textSecondary,
                  fontWeight: _hasRecording ? FontWeight.bold : FontWeight.normal,
                ),
              ),

              // Transcription Input
              if (_hasRecording) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ماذا نطق الطفل؟',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
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
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitForEvaluation,
                    icon: const Icon(Icons.send),
                    label: const Text('إرسال للتقييم'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.3, end: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterAvatar() {
    return Container(
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Center(
        child: Text(
          widget.word.text[0],
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
