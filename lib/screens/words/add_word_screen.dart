import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/themes.dart';
import '../../providers/categories_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';

class AddWordScreen extends StatefulWidget {
  final String? categoryId;
  const AddWordScreen({super.key, this.categoryId});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _textEnController = TextEditingController();
  final _phoneticController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedCategoryId;
  int _difficulty = 1;
  String? _imagePath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    context.read<CategoriesProvider>().loadCategories();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textEnController.dispose();
    _phoneticController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (image != null) setState(() => _imagePath = image.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر القسم')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Use image URL if provided, otherwise use picked image path
      final imageUrl = _imageUrlController.text.isNotEmpty 
          ? _imageUrlController.text 
          : _imagePath ?? '';

      await context.read<CategoriesProvider>().addWord(
        text: _textController.text,
        textEn: _textEnController.text.isNotEmpty ? _textEnController.text : null,
        categoryId: _selectedCategoryId!,
        imageUrl: imageUrl,
        correctPronunciationUrl: '', // No audio recording for now
        phonetic: _phoneticController.text.isNotEmpty ? _phoneticController.text : null,
        difficulty: _difficulty,
        createdBy: context.read<AuthProvider>().userId ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الكلمة'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة كلمة جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              const Text('صورة الكلمة', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Image URL Input
              CustomTextField(
                controller: _imageUrlController,
                label: 'رابط الصورة (URL)',
                prefixIcon: Icons.link,
                hint: 'https://example.com/image.jpg',
              ),
              
              const SizedBox(height: 12),
              
              const Center(child: Text('أو', style: TextStyle(color: Colors.grey))),
              
              const SizedBox(height: 12),
              
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imagePath != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imagePath!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () => setState(() => _imagePath = null),
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('اضغط لاختيار صورة من الجهاز'),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Text Fields
              CustomTextField(
                controller: _textController,
                label: 'الكلمة بالعربي *',
                prefixIcon: Icons.text_fields,
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _textEnController,
                label: 'الكلمة بالإنجليزي',
                prefixIcon: Icons.translate,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneticController,
                label: 'النطق الصوتي',
                prefixIcon: Icons.record_voice_over,
                hint: 'مثال: قِطَّة',
              ),

              const SizedBox(height: 24),

              // Category Selector
              const Text('القسم *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<CategoriesProvider>(
                builder: (context, provider, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('اختر القسم'),
                        value: _selectedCategoryId,
                        items: provider.categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Difficulty
              const Text('مستوى الصعوبة', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final level = i + 1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _difficulty = level),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _difficulty >= level 
                              ? AppColors.primaryOrange 
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.star,
                          color: _difficulty >= level ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Info Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryBlue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'يمكنك إضافة صورة عبر رابط URL أو اختيارها من الجهاز. النطق الصوتي اختياري.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('إضافة الكلمة', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
