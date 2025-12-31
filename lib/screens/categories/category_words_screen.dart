import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _playingWordId;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWords();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    await context.read<CategoriesProvider>().loadWords(widget.categoryId);
  }

  Future<void> _playPronunciation(WordModel word) async {
    if (word.correctPronunciationUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد ملف صوتي لهذه الكلمة'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _playingWordId = word.id;
      _isLoadingAudio = true;
    });

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(word.correctPronunciationUrl));
      
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playingWordId = null;
          });
        }
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في تشغيل الصوت'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
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
                        final user = authProvider.user;
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
    int difficulty = word.difficulty;
    String? selectedImagePath;

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
