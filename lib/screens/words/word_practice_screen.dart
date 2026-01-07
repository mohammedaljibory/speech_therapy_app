import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'dart:async';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/word_model.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/whisper_service.dart';
import '../recording/recording_screen_io.dart'
    if (dart.library.html) '../recording/recording_screen_web.dart' as platform;

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
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperService _whisperService = WhisperService();
  final FlutterTts _flutterTts = FlutterTts();

  // State
  bool _isPlayingCorrect = false;
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isTranscribing = false;
  bool _isEvaluating = false;
  ChildModel? _selectedChild;
  String? _recordingPath;
  Uint8List? _recordingBytes;
  String? _transcription;

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
    _initTts();
    _loadChildren();
    _checkPermissions();
  }

  /// Initialize Text-to-Speech with Arabic settings
  Future<void> _initTts() async {
    try {
      // Set error handler
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) setState(() => _isPlayingCorrect = false);
      });

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isPlayingCorrect = false);
      });

      // Try to set Arabic language
      if (kIsWeb) {
        // On web, try different Arabic variants
        var result = await _flutterTts.setLanguage('ar');
        if (result != 1) {
          result = await _flutterTts.setLanguage('ar-SA');
        }
        if (result != 1) {
          result = await _flutterTts.setLanguage('ar-EG');
        }
      } else {
        await _flutterTts.setLanguage('ar-SA');
      }

      await _flutterTts.setSpeechRate(kIsWeb ? 0.5 : 0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Log available languages for debugging
      final languages = await _flutterTts.getLanguages;
      debugPrint('Available TTS languages: $languages');
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
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

  Future<void> _checkPermissions() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnackBar('يرجى منح إذن الميكروفون للتسجيل', isError: true);
    }
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
    _audioRecorder.dispose();
    _flutterTts.stop();
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playCorrectPronunciation() async {
    setState(() => _isPlayingCorrect = true);

    try {
      // If there's a custom audio URL, play it
      if (widget.word.correctPronunciationUrl.isNotEmpty) {
        debugPrint('Playing audio URL: ${widget.word.correctPronunciationUrl}');

        bool playbackSuccess = false;

        if (kIsWeb) {
          // Use HTML5 Audio for web (more reliable)
          playbackSuccess = await platform.playAudioWeb(widget.word.correctPronunciationUrl);
          if (playbackSuccess) {
            debugPrint('HTML5 Audio playback started successfully');
            // Auto-reset playing state after a delay
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) setState(() => _isPlayingCorrect = false);
            });
          }
        } else {
          // Use audioplayers for mobile
          try {
            await _audioPlayer.stop();
            await _audioPlayer.play(UrlSource(widget.word.correctPronunciationUrl));
            playbackSuccess = true;

            _audioPlayer.onPlayerComplete.listen((_) {
              if (mounted) setState(() => _isPlayingCorrect = false);
            });
          } catch (audioError) {
            debugPrint('AudioPlayer error: $audioError');
            playbackSuccess = false;
          }
        }

        if (!playbackSuccess) {
          // Fallback to TTS
          debugPrint('Audio playback failed, falling back to TTS');
          _showSnackBar('فشل تشغيل الصوت، جاري استخدام النطق التلقائي...', isError: false);
          await _flutterTts.stop();
          await _flutterTts.speak(widget.word.text);
        }
      } else {
        // Use Text-to-Speech
        await _flutterTts.stop();
        final result = await _flutterTts.speak(widget.word.text);
        debugPrint('TTS speak result: $result for word: ${widget.word.text}');

        if (result != 1) {
          // TTS failed
          _showSnackBar('النطق التلقائي غير متوفر في المتصفح', isError: false);
          if (mounted) setState(() => _isPlayingCorrect = false);
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _showSnackBar('خطأ: $e', isError: true);
      if (mounted) setState(() => _isPlayingCorrect = false);
    }
  }

  Future<void> _startRecording() async {
    if (_selectedChild == null) {
      _showSnackBar('الرجاء اختيار الطفل أولاً', isError: true);
      return;
    }

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
      _recordingBytes = null;
    });

    try {
      final filename = 'recording_${DateTime.now().millisecondsSinceEpoch}';
      String path;
      if (kIsWeb) {
        path = '$filename.webm';
      } else {
        path = await platform.getRecordingPath('$filename.m4a');
      }

      final config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: 16000,
        bitRate: 128000,
      );

      await _audioRecorder.start(config, path: path);
      _recordingPath = path;

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingDuration++);
        if (_recordingDuration >= 30) _stopRecording();
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
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
        });
        _showSnackBar('فشل في حفظ التسجيل', isError: true);
        return;
      }

      // Read audio bytes
      Uint8List? audioBytes;
      if (kIsWeb) {
        // On web, use platform-specific blob URL reader
        audioBytes = await platform.readBlobUrl(path);
        debugPrint('Web audio bytes: ${audioBytes?.length ?? 0} bytes');
      } else {
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
        _showSnackBar('تم التسجيل! لكن فشل في قراءة الملف', isError: true);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
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
        } else {
          _showSnackBar('فشل في التعرف: ${result.error}', isError: true);
        }
      });
    } catch (e) {
      setState(() {
        _isTranscribing = false;
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
      _showSnackBar('فشل في تشغيل التسجيل', isError: true);
    }
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingDuration = 0;
      _transcription = null;
      _recordingPath = null;
      _recordingBytes = null;
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

    setState(() => _isEvaluating = true);

    try {
      Navigator.pushNamed(
        context,
        Routes.evaluation,
        arguments: {
          'word': widget.word,
          'child': _selectedChild,
          'recordingPath': _recordingPath ?? 'recording_${DateTime.now().millisecondsSinceEpoch}',
          'categoryName': widget.categoryName,
          'transcription': _transcription,
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
                      if (_hasRecording && !_isTranscribing) ...[
                        _buildTranscriptionResult(),
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
                ? Image.network(
                    widget.word.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
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

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Center(
        child: Text(
          widget.word.text[0],
          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildCorrectPronunciationButton() {
    return ElevatedButton.icon(
      onPressed: _isPlayingCorrect ? null : _playCorrectPronunciation,
      icon: Icon(_isPlayingCorrect ? Icons.stop : Icons.volume_up),
      label: Text(_isPlayingCorrect ? 'جاري التشغيل...' : 'استمع للنطق الصحيح'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
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
          onTap: _isTranscribing ? null : (_isRecording ? _stopRecording : _startRecording),
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
                    color: _isRecording
                        ? AppColors.error
                        : _isTranscribing
                            ? Colors.grey
                            : AppColors.primaryGreen,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? AppColors.error : AppColors.primaryGreen).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 50,
                    color: Colors.white,
                  ),
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
        else if (_isTranscribing)
          Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('جاري التعرف على الكلام...', style: TextStyle(color: Colors.grey)),
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

        if (_hasRecording && !_isTranscribing) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _playRecording,
                icon: const Icon(Icons.play_arrow),
                label: const Text('استمع'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _deleteRecording,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text('حذف', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }

  Widget _buildTranscriptionResult() {
    final isMatch = _transcription?.trim() == widget.word.text.trim();

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
        children: [
          Row(
            children: [
              Icon(Icons.hearing, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              const Text('ما تم التعرف عليه:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _transcription != null
                  ? (isMatch ? AppColors.primaryGreen : AppColors.primaryOrange).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _transcription != null
                    ? (isMatch ? AppColors.primaryGreen : AppColors.primaryOrange)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              _transcription ?? 'لم يتم التعرف على الكلام',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _transcription != null
                    ? (isMatch ? AppColors.primaryGreen : AppColors.primaryOrange)
                    : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('المطلوب: ', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                widget.word.text,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 18),
              ),
              const SizedBox(width: 8),
              Icon(
                isMatch ? Icons.check_circle : Icons.compare_arrows,
                color: isMatch ? AppColors.primaryGreen : AppColors.primaryOrange,
              ),
            ],
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
            : const Icon(Icons.psychology),
        label: Text(_isEvaluating ? 'جاري التقييم...' : 'تقييم بالذكاء الاصطناعي'),
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
