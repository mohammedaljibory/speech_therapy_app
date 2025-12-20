import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/themes.dart';
import '../../config/constants.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedAge = 5;
  String _selectedGender = 'male';
  String _selectedLevel = AppConstants.childLevels.first;
  String? _profileImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final childrenProvider = context.read<ChildrenProvider>();

    final child = await childrenProvider.addChild(
      name: _nameController.text,
      age: _selectedAge,
      gender: _selectedGender,
      level: _selectedLevel,
      trainerId: authProvider.userId!,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (child != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إضافة الطفل بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && childrenProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(childrenProvider.error!),
          backgroundColor: AppColors.error,
        ),
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
            colors: [
              Color(0xFFF0F8FF),
              Color(0xFFFFFBF5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Image
                        _buildProfileImagePicker()
                            .animate()
                            .fadeIn()
                            .scale(delay: 100.ms),

                        const SizedBox(height: 32),

                        // Name Field
                        _buildSectionTitle('معلومات الطفل'),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _nameController,
                          label: 'اسم الطفل',
                          hint: 'أدخل اسم الطفل',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم الطفل';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.2),

                        const SizedBox(height: 24),

                        // Age Selector
                        _buildSectionTitle('العمر'),
                        const SizedBox(height: 12),
                        _buildAgeSelector()
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideX(begin: 0.2),

                        const SizedBox(height: 24),

                        // Gender Selector
                        _buildSectionTitle('الجنس'),
                        const SizedBox(height: 12),
                        _buildGenderSelector()
                            .animate()
                            .fadeIn(delay: 250.ms)
                            .slideX(begin: 0.2),

                        const SizedBox(height: 24),

                        // Level Selector
                        _buildSectionTitle('المستوى'),
                        const SizedBox(height: 12),
                        _buildLevelSelector()
                            .animate()
                            .fadeIn(delay: 300.ms)
                            .slideX(begin: 0.2),

                        const SizedBox(height: 24),

                        // Notes Field
                        _buildSectionTitle('ملاحظات (اختياري)'),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _notesController,
                          hint: 'أضف ملاحظات عن الطفل...',
                          maxLines: 3,
                        ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.2),

                        const SizedBox(height: 40),

                        // Save Button
                        Consumer<ChildrenProvider>(
                          builder: (context, provider, _) {
                            return CustomButton(
                              text: 'حفظ',
                              icon: Icons.check,
                              isLoading: provider.isLoading,
                              onPressed: _handleSave,
                            );
                          },
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
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
            icon: Icons.close,
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Text(
            'إضافة طفل جديد',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: -0.2),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientPrimary,
                ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _profileImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.network(
                        _profileImagePath!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 15, // Ages 1-15
        itemBuilder: (context, index) {
          final age = index + 1;
          final isSelected = age == _selectedAge;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAge = age;
              });
            },
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: AppColors.gradientPrimary)
                    : null,
                color: isSelected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$age',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildGenderOption(
            gender: 'male',
            label: 'ذكر',
            icon: Icons.male,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGenderOption(
            gender: 'female',
            label: 'أنثى',
            icon: Icons.female,
            color: AppColors.primaryPink,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required String gender,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Row(
      children: AppConstants.childLevels.map((level) {
        final isSelected = _selectedLevel == level;
        final colors = {
          'مبتدئ': AppColors.primaryGreen,
          'متوسط': AppColors.primaryOrange,
          'متقدم': AppColors.primaryBlue,
        };
        final color = colors[level] ?? AppColors.primaryBlue;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLevel = level;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                left: level == AppConstants.childLevels.first ? 0 : 6,
                right: level == AppConstants.childLevels.last ? 0 : 6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
