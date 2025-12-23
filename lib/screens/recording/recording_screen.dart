import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

// Conditional imports for platform-specific code
import 'recording_screen_stub.dart'
    if (dart.library.io) 'recording_screen_io.dart' as platform;

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/word_model.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/whisper_service.dart';

/// Recording Screen - For recording child's pronunciation with real audio capture
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperService _whisperService = WhisperService();

  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isTranscribing = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  ChildModel? _selectedChild;
  String? _recordingPath;
  Uint8List? _recordingBytes;
  String? _transcription;
  String? _error;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadChildren();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnackBar('يرجى منح إذن الميكروفون للتسجيل', isError: true);
    }
  }

  Future<void> _loadChildren() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId != null) {
      await context
          .read<ChildrenProvider>()
          .loadChildren(authProvider.userId!);
      final children = context.read<ChildrenProvider>().children;
      if (children.length == 1) {
        setState(() => _selectedChild = children.first);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    _pulseController.dispose();
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

  Future<void> _startRecording() async {
    // Check permissions
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnackBar('لا يوجد إذن للميكروفون', isError: true);
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _hasRecording = false;
      _transcription = null;
      _error = null;
      _recordingBytes = null;
    });

    try {
      // Get path for storing recording
      final filename = 'recording_${DateTime.now().millisecondsSinceEpoch}';
      String path;
      if (kIsWeb) {
        path = '$filename.webm';
      } else {
        path = await platform.getRecordingPath('$filename.m4a');
      }

      // Configure recording
      final config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: 16000, // Whisper works well with 16kHz
        bitRate: 128000,
      );

      // Start recording
      await _audioRecorder.start(config, path: path);
      _recordingPath = path;

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingDuration++);
        if (_recordingDuration >= 30) _stopRecording();
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _error = e.toString();
      });
      _showSnackBar('فشل في بدء التسجيل: $e', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    try {
      final path = await _audioRecorder.stop();

      if (path == null) {
        setState(() {
          _isRecording = false;
          _error = 'فشل في حفظ التسجيل';
        });
        return;
      }

      // Read audio bytes for transcription
      Uint8List? audioBytes;
      if (kIsWeb) {
        // On web, fetch the blob URL using http package
        try {
          final response = await http.get(Uri.parse(path));
          if (response.statusCode == 200) {
            audioBytes = response.bodyBytes;
          }
        } catch (e) {
          debugPrint('Error reading web audio: $e');
        }
      } else {
        // On mobile/desktop, read from file using platform-specific code
        audioBytes = await platform.readFileBytes(path);
      }

      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordingPath = path;
        _recordingBytes = audioBytes;
      });

      // Automatically transcribe
      if (audioBytes != null && audioBytes.isNotEmpty) {
        _transcribeRecording(audioBytes);
      } else {
        _showSnackBar('تم التسجيل! لكن فشل في قراءة الملف الصوتي', isError: true);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _error = e.toString();
      });
      _showSnackBar('فشل في إيقاف التسجيل: $e', isError: true);
    }
  }

  Future<void> _transcribeRecording(Uint8List audioBytes) async {
    setState(() => _isTranscribing = true);

    try {
      final fileName = kIsWeb ? 'recording.webm' : 'recording.m4a';
      final result = await _whisperService.transcribeBytes(
        audioBytes: audioBytes,
        fileName: fileName,
        language: 'ar',
      );

      setState(() {
        _isTranscribing = false;
        if (result.success && result.text != null) {
          _transcription = result.text;
          _showSnackBar('تم التعرف على: "${result.text}"', isError: false);
        } else {
          _error = result.error;
          _showSnackBar(
              'فشل في التعرف على الكلام: ${result.error}', isError: true);
        }
      });
    } catch (e) {
      setState(() {
        _isTranscribing = false;
        _error = e.toString();
      });
      _showSnackBar('خطأ في النسخ: $e', isError: true);
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    try {
      await _audioPlayer.stop();
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource(_recordingPath!));
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordingPath!));
      }
    } catch (e) {
      _showSnackBar('فشل في تشغيل التسجيل: $e', isError: true);
    }
  }

  void _submitForEvaluation() {
    if (_selectedChild == null) {
      _showSnackBar('الرجاء اختيار الطفل', isError: true);
      return;
    }

    if (!_hasRecording) {
      _showSnackBar('الرجاء تسجيل الصوت أولاً', isError: true);
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.evaluation,
      arguments: {
        'word': widget.word,
        'child': _selectedChild,
        'recordingPath':
            _recordingPath ?? 'recording_${DateTime.now().millisecondsSinceEpoch}',
        'categoryName': widget.categoryName,
        'transcription': _transcription,
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

              // Transcribing indicator
              if (_isTranscribing)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'جاري التعرف على الكلام...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Record Button
              GestureDetector(
                onTap: _isTranscribing ? null : _toggleRecording,
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
                              : _isTranscribing
                                  ? Colors.grey
                                  : AppColors.primaryGreen,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? AppColors.error
                                      : AppColors.primaryGreen)
                                  .withOpacity(0.4),
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
                    : _isTranscribing
                        ? 'جاري المعالجة...'
                        : _hasRecording
                            ? 'تم التسجيل ✓'
                            : 'اضغط للتسجيل',
                style: TextStyle(
                  color: _hasRecording
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                  fontWeight:
                      _hasRecording ? FontWeight.bold : FontWeight.normal,
                ),
              ),

              // Recording Results
              if (_hasRecording && !_isTranscribing) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Play recording button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _playRecording,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('استمع للتسجيل'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _toggleRecording,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Transcription result
                      const Text(
                        'ما تم التعرف عليه:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _transcription != null
                              ? AppColors.primaryGreen.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _transcription ?? 'لم يتم التعرف على الكلام',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _transcription != null
                                ? AppColors.primaryGreen
                                : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Comparison
                      if (_transcription != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'المطلوب: ',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              widget.word.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _transcription == widget.word.text
                                  ? Icons.check_circle
                                  : Icons.compare_arrows,
                              color: _transcription == widget.word.text
                                  ? AppColors.primaryGreen
                                  : AppColors.primaryOrange,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitForEvaluation,
                    icon: const Icon(Icons.psychology),
                    label: const Text('تقييم بالذكاء الاصطناعي'),
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
