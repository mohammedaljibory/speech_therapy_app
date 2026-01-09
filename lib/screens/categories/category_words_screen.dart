import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../recording/recording_screen_io.dart'
    if (dart.library.html) '../recording/recording_screen_web.dart' as platform;

import '../../config/themes.dart';
import '../../models/word_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';

class CategoryWordsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryWordsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryWordsScreen> createState() => _CategoryWordsScreenState();
}

class _CategoryWordsScreenState extends State<CategoryWordsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  String? _playingWordId;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWords();
    });
  }

  /// Initialize Audio Player with error handling
  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingWordId = null);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('AudioPlayer state: $state');
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        if (mounted) setState(() => _playingWordId = null);
      }
    });

    // Set release mode to stop after playing
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Initialize Text-to-Speech with Arabic settings
  Future<void> _initTts() async {
    try {
      // Set error handler
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) setState(() => _playingWordId = null);
      });

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _playingWordId = null);
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadWords() async {
    await context.read<CategoriesProvider>().loadWords(widget.categoryId);
  }

  Future<void> _playPronunciation(WordModel word) async {
    setState(() {
      _playingWordId = word.id;
      _isLoadingAudio = true;
    });

    try {
      // If there's a custom audio URL, play it
      if (word.correctPronunciationUrl.isNotEmpty) {
        debugPrint('Playing audio URL: ${word.correctPronunciationUrl}');

        bool playbackSuccess = false;

        if (kIsWeb) {
          // Use HTML5 Audio for web (more reliable)
          playbackSuccess = await platform.playAudioWeb(word.correctPronunciationUrl);
          if (playbackSuccess) {
            debugPrint('HTML5 Audio playback started successfully');
            // Auto-reset playing state after a delay (since we can't easily track HTML5 audio end)
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && _playingWordId == word.id) {
                setState(() => _playingWordId = null);
              }
            });
          }
        } else {
          // Use audioplayers for mobile
          try {
            await _audioPlayer.stop();
            await _audioPlayer.play(UrlSource(word.correctPronunciationUrl));
            playbackSuccess = true;
            debugPrint('AudioPlayer playback started successfully');
          } catch (audioError) {
            debugPrint('AudioPlayer error: $audioError');
            playbackSuccess = false;
          }
        }

        if (!playbackSuccess) {
          debugPrint('Audio playback failed, falling back to TTS');
          // If audio fails, try TTS as fallback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل تشغيل الصوت، جاري استخدام النطق التلقائي...'),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          // Fallback to TTS
          await _flutterTts.stop();
          await _flutterTts.speak(word.text);
        }
      } else {
        // Use Text-to-Speech
        await _flutterTts.stop();
        final result = await _flutterTts.speak(word.text);
        debugPrint('TTS speak result: $result for word: ${word.text}');

        if (result != 1) {
          // TTS failed, show message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('النطق التلقائي غير متوفر - الكلمة: ${word.text}'),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 2),
              ),
            );
            setState(() => _playingWordId = null);
          }
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _playingWordId = null);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAudio = false);
      }
    }
  }

  void _startPractice(WordModel word) {
    // Navigate to practice/recording screen
    Navigator.pushNamed(
      context,
      '/word-practice',
      arguments: {
        'word': word,
        'categoryName': widget.categoryName,
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
            colors: [
              AppColors.backgroundLight,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Consumer<CategoriesProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (provider.error != null) {
                      return _buildErrorState(provider.error!);
                    }

                    final words = provider.words;

                    if (words.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: _loadWords,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: words.length,
                        itemBuilder: (context, index) {
                          return _buildWordCard(words[index], index);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.categoryName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          Consumer<CategoriesProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.words.length} كلمة',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildWordCard(WordModel word, int index) {
    final isPlaying = _playingWordId == word.id;

    return GestureDetector(
      onTap: () => _startPractice(word),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Word Image
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    word.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: word.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                word.text[0],
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),

                    // Difficulty Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(word.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            word.difficulty,
                            (i) => const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Edit Button (for admin/trainer)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final user = authProvider.currentUser;
                        final canEdit = (user?.isAdmin ?? false) || (user?.isTrainer ?? false);
                        if (!canEdit) return const SizedBox.shrink();

                        return Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => _showEditWordDialog(word),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Word Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Arabic Text
                      Text(
                        word.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // English Text (if available)
                      if (word.textEn != null && word.textEn!.isNotEmpty)
                        Text(
                          word.textEn!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const Spacer(),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Play Sound Button
                          _buildActionButton(
                            icon: isPlaying ? Icons.stop : Icons.volume_up,
                            color: AppColors.primaryBlue,
                            onTap: () => _playPronunciation(word),
                            isLoading: isPlaying && _isLoadingAudio,
                          ),
                          const SizedBox(width: 12),
                          // Practice Button
                          _buildActionButton(
                            icon: Icons.mic,
                            color: AppColors.primaryGreen,
                            onTap: () => _startPractice(word),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: 50 * index),
        ).slideY(
          begin: 0.2,
          end: 0,
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: 50 * index),
        );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(
                icon,
                color: color,
                size: 20,
              ),
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return AppColors.primaryGreen;
      case 2:
        return AppColors.secondaryTeal;
      case 3:
        return AppColors.primaryOrange;
      case 4:
        return AppColors.primaryPink;
      case 5:
        return AppColors.secondaryRed;
      default:
        return AppColors.primaryBlue;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open,
              size: 64,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد كلمات',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تتم إضافة كلمات لهذا القسم بعد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/add-word',
                arguments: {'categoryId': widget.categoryId},
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة كلمة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
        );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadWords,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show edit word dialog for admins/trainers to change image and word details
  void _showEditWordDialog(WordModel word) {
    final textController = TextEditingController(text: word.text);
    final textEnController = TextEditingController(text: word.textEn ?? '');
    final imageUrlController = TextEditingController(text: word.imageUrl);
    final phoneticController = TextEditingController(text: word.phonetic ?? '');
    final audioUrlController = TextEditingController(text: word.correctPronunciationUrl);
    int difficulty = word.difficulty;
    String? selectedImagePath;

    // Audio recording state
    final audioRecorder = AudioRecorder();
    bool isRecording = false;
    bool isUploading = false;
    String? recordingPath;
    Uint8List? recordingBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final image = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 800,
              imageQuality: 85,
            );
            if (image != null) {
              setDialogState(() {
                selectedImagePath = image.path;
                imageUrlController.text = image.path;
              });
            }
          }

          // Start recording audio
          Future<void> startRecording() async {
            try {
              final hasPermission = await audioRecorder.hasPermission();
              if (!hasPermission) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى منح إذن الميكروفون')),
                );
                return;
              }

              final filename = 'word_audio_${DateTime.now().millisecondsSinceEpoch}';
              String path;
              String extension;
              AudioEncoder encoder;

              if (kIsWeb) {
                // Use opus/webm on web (native MediaRecorder format)
                extension = 'webm';
                encoder = AudioEncoder.opus;
                path = '$filename.$extension';
              } else {
                // Use AAC on mobile for smaller file size
                extension = 'm4a';
                encoder = AudioEncoder.aacLc;
                path = '/tmp/$filename.$extension';
              }

              final config = RecordConfig(
                encoder: encoder,
                sampleRate: 16000,
                bitRate: 128000,
              );

              await audioRecorder.start(config, path: path);
              setDialogState(() {
                isRecording = true;
                recordingPath = path;
              });
            } catch (e) {
              debugPrint('Error starting recording: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('فشل في بدء التسجيل: $e')),
              );
            }
          }

          // Stop recording and upload
          Future<void> stopRecordingAndUpload() async {
            try {
              final path = await audioRecorder.stop();
              if (path == null) {
                setDialogState(() => isRecording = false);
                return;
              }

              setDialogState(() {
                isRecording = false;
                isUploading = true;
              });

              // Read audio bytes using platform-specific method
              Uint8List? audioBytes;
              if (kIsWeb) {
                audioBytes = await platform.readBlobUrl(path);
              } else {
                audioBytes = await platform.readFileBytes(path);
              }

              if (audioBytes == null || audioBytes.isEmpty) {
                throw Exception('فشل في قراءة ملف الصوت');
              }

              // Upload to Firebase Storage
              final audioExtension = kIsWeb ? 'webm' : 'm4a';
              final contentType = kIsWeb ? 'audio/webm' : 'audio/mp4';

              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('word_audio')
                  .child('${word.id}_${DateTime.now().millisecondsSinceEpoch}.$audioExtension');

              debugPrint('Uploading audio: ${audioBytes.length} bytes as $contentType');

              final uploadTask = await storageRef.putData(
                audioBytes,
                SettableMetadata(contentType: contentType),
              );

              final downloadUrl = await uploadTask.ref.getDownloadURL();

              setDialogState(() {
                audioUrlController.text = downloadUrl;
                isUploading = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم رفع الصوت بنجاح!'),
                  backgroundColor: AppColors.success,
                ),
              );
            } catch (e) {
              debugPrint('Error uploading audio: $e');
              setDialogState(() {
                isRecording = false;
                isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('فشل في رفع الصوت: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('تعديل الكلمة'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview
                  const Text('الصورة', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (selectedImagePath != null || imageUrlController.text.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: selectedImagePath ?? imageUrlController.text,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                ),
                              )
                            else
                              const Center(
                                child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                              ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image URL Input
                  CustomTextField(
                    controller: imageUrlController,
                    label: 'رابط الصورة (URL)',
                    prefixIcon: Icons.link,
                    hint: 'https://example.com/image.jpg',
                  ),
                  const SizedBox(height: 16),

                  // Word Text
                  CustomTextField(
                    controller: textController,
                    label: 'الكلمة بالعربي',
                    prefixIcon: Icons.text_fields,
                  ),
                  const SizedBox(height: 12),

                  // English Text
                  CustomTextField(
                    controller: textEnController,
                    label: 'الكلمة بالإنجليزي',
                    prefixIcon: Icons.translate,
                  ),
                  const SizedBox(height: 12),

                  // Phonetic
                  CustomTextField(
                    controller: phoneticController,
                    label: 'النطق الصوتي',
                    prefixIcon: Icons.record_voice_over,
                  ),
                  const SizedBox(height: 16),

                  // Audio URL Section
                  const Text('الصوت', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Record Audio Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRecording
                          ? AppColors.error.withOpacity(0.1)
                          : isUploading
                              ? AppColors.primaryBlue.withOpacity(0.1)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRecording ? AppColors.error : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Record/Stop Button
                        GestureDetector(
                          onTap: isUploading
                              ? null
                              : (isRecording ? stopRecordingAndUpload : startRecording),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isRecording ? AppColors.error : AppColors.primaryGreen,
                            ),
                            child: isUploading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    isRecording ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUploading
                                    ? 'جاري رفع الصوت...'
                                    : isRecording
                                        ? 'جاري التسجيل... اضغط للإيقاف'
                                        : 'اضغط لتسجيل صوتك',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isRecording ? AppColors.error : AppColors.textPrimary,
                                ),
                              ),
                              if (audioUrlController.text.isNotEmpty && !isRecording && !isUploading)
                                const Text(
                                  'تم تسجيل صوت ✓',
                                  style: TextStyle(color: AppColors.success, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        // Play button (if has audio)
                        if (audioUrlController.text.isNotEmpty && !isRecording && !isUploading)
                          IconButton(
                            onPressed: () async {
                              try {
                                debugPrint('Testing audio URL: ${audioUrlController.text}');
                                if (kIsWeb) {
                                  final success = await platform.playAudioWeb(audioUrlController.text);
                                  if (!success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('فشل في تشغيل الصوت')),
                                    );
                                  }
                                } else {
                                  await _audioPlayer.stop();
                                  await _audioPlayer.play(UrlSource(audioUrlController.text));
                                }
                                debugPrint('Audio playback started');
                              } catch (e) {
                                debugPrint('Audio playback error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('فشل في تشغيل الصوت: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_circle, color: AppColors.primaryBlue),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Upload Audio File Button
                  OutlinedButton.icon(
                    onPressed: isUploading || isRecording
                        ? null
                        : () async {
                            try {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.audio,
                                allowMultiple: false,
                                withData: true,
                              );

                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                final bytes = file.bytes;

                                if (bytes == null || bytes.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('فشل في قراءة الملف')),
                                  );
                                  return;
                                }

                                setDialogState(() => isUploading = true);

                                // Determine content type from extension
                                final extension = file.extension?.toLowerCase() ?? 'mp3';
                                String contentType;
                                switch (extension) {
                                  case 'mp3':
                                    contentType = 'audio/mpeg';
                                    break;
                                  case 'wav':
                                    contentType = 'audio/wav';
                                    break;
                                  case 'm4a':
                                    contentType = 'audio/mp4';
                                    break;
                                  case 'ogg':
                                    contentType = 'audio/ogg';
                                    break;
                                  case 'webm':
                                    contentType = 'audio/webm';
                                    break;
                                  default:
                                    contentType = 'audio/mpeg';
                                }

                                // Upload to Firebase Storage
                                final storageRef = FirebaseStorage.instance
                                    .ref()
                                    .child('word_audio')
                                    .child('${word.id}_${DateTime.now().millisecondsSinceEpoch}.$extension');

                                debugPrint('Uploading audio file: ${bytes.length} bytes as $contentType');

                                final uploadTask = await storageRef.putData(
                                  bytes,
                                  SettableMetadata(contentType: contentType),
                                );

                                final downloadUrl = await uploadTask.ref.getDownloadURL();

                                setDialogState(() {
                                  audioUrlController.text = downloadUrl;
                                  isUploading = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم رفع الملف بنجاح'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isUploading = false);
                              debugPrint('Upload error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل في رفع الملف: $e')),
                              );
                            }
                          },
                    icon: Icon(
                      Icons.upload_file,
                      color: isUploading || isRecording ? Colors.grey : AppColors.primaryOrange,
                    ),
                    label: Text(
                      'رفع ملف صوتي',
                      style: TextStyle(
                        color: isUploading || isRecording ? Colors.grey : AppColors.primaryOrange,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isUploading || isRecording ? Colors.grey : AppColors.primaryOrange,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Or use URL
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('أو أدخل رابط', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: audioUrlController,
                          label: 'رابط الصوت (URL)',
                          prefixIcon: Icons.link,
                          hint: 'https://example.com/audio.mp3',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Test audio button
                      IconButton(
                        onPressed: () async {
                          if (audioUrlController.text.isNotEmpty) {
                            try {
                              if (kIsWeb) {
                                final success = await platform.playAudioWeb(audioUrlController.text);
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('فشل في تشغيل الصوت'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } else {
                                await _audioPlayer.stop();
                                await _audioPlayer.play(UrlSource(audioUrlController.text));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('فشل في تشغيل الصوت'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } else {
                            // Test TTS
                            await _flutterTts.speak(textController.text);
                          }
                        },
                        icon: const Icon(Icons.play_circle, color: AppColors.primaryGreen),
                        tooltip: 'تجربة الصوت',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اتركه فارغاً لاستخدام النطق التلقائي (TTS)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // Difficulty
                  const Text('مستوى الصعوبة', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final level = i + 1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => difficulty = level),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: difficulty >= level
                                  ? AppColors.primaryOrange
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.star,
                              color: difficulty >= level ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final provider = context.read<CategoriesProvider>();

                  final success = await provider.updateWord(
                    wordId: word.id,
                    text: textController.text.isNotEmpty ? textController.text : null,
                    textEn: textEnController.text.isNotEmpty ? textEnController.text : null,
                    imageUrl: imageUrlController.text.isNotEmpty ? imageUrlController.text : null,
                    phonetic: phoneticController.text.isNotEmpty ? phoneticController.text : null,
                    correctPronunciationUrl: audioUrlController.text,
                    difficulty: difficulty,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث الكلمة بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('فشل في تحديث الكلمة'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حفظ التغييرات'),
              ),
            ],
          );
        },
      ),
    );
  }
}
